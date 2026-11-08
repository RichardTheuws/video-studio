#!/usr/bin/env bash
# fal.sh — the ONE fal.ai layer of the video studio (key, upload, submit, wait, result, costs).
# Why: dozens of productions each grew their own polling loop and their own way of finding the key, and the
# same bug (a data URI passed via argv → a request with no body) was logged twice. One library, one fix.
# Client imagery goes through fal's own storage (fal-cdn), NEVER through a public host of your own.
#
# Use as a command:
#   fal.sh key                              → print the key (for $(…)); looks in env → $VIDEO_STUDIO_ENV (explicit file) →
#                                             ~/.config/video-studio/.env. Deliberately no ./.env: that depends on the caller's cwd.
#   fal.sh upload <file>                    → print the fal-cdn URL (temporary storage at fal, no host of your own)
#   fal.sh submit <endpoint> <req.json>     → print status_url and response_url (2 lines); body via file, never argv
#   fal.sh wait <status_url> [max_s]        → block until COMPLETED (exit 1 on FAILED/timeout)
#   fal.sh result <response_url> <out.json> → fetch the result (retries on 400/425 right after COMPLETED)
#   fal.sh run <endpoint> <req.json> <out.json> [max_s] → submit + wait + result + cost line in one go
#   fal.sh cancel <endpoint> <request_id>
#   fal.sh price <endpoint>                 → price line from the pricing API (unit_price unit)
#   fal.sh costs [costs.jsonl]              → sum up the cost log
#   fal.sh delete <file_url>                → delete a file at fal (upload or output) right away
# Privacy defaults: no request history kept at fal (X-Fal-Store-IO: 0), uploads expire after 24 h, outputs after 7 days.
# Use as a library:  source fal.sh; fal_upload photo.jpg
#
# Cost log: every run appends one line to ${FAL_COST_LOG:-./costs.jsonl}
#   {"ts","endpoint","request_id","duration","unit_price","unit","est_usd"}
# est_usd is an estimate from unit_price × duration (only when unit=seconds); otherwise unit_price (per audio/clip) or null.
set -uo pipefail

FAL_QUEUE="https://queue.fal.run"
FAL_REST="https://rest.alpha.fal.ai"
FAL_PRICING="https://api.fal.ai/v1/models/pricing"
# Privacy knobs (fal docs, read 2026-11-08): without the header fal keeps request input/output for 90 days, and cdn files
# stay up to the account default (publicly readable URL). Hence the defaults: no request history, uploads expire after
# 24 h, outputs after 7 days (we download immediately). Override with FAL_UPLOAD_TTL / FAL_OUTPUT_TTL (seconds).
FAL_UPLOAD_TTL="${FAL_UPLOAD_TTL:-86400}"
FAL_OUTPUT_TTL="${FAL_OUTPUT_TTL:-604800}"
_fal_ttl() { printf 'X-Fal-Object-Lifecycle-Preference: {"expiration_duration_seconds": %s}' "$1"; }

_fal_read_env() { # $1=file $2=key → value without quotes
  [ -f "$1" ] || return 1
  local v; v=$(grep -E "^${2}=" "$1" | head -1 | cut -d= -f2- | tr -d '"'"'"' \r')
  [ -n "$v" ] && printf '%s' "$v"
}

fal_key() {
  if [ -n "${FAL_AI_KEY:-}" ]; then printf '%s' "$FAL_AI_KEY"; return 0; fi
  local f
  for f in "${VIDEO_STUDIO_ENV:-}" "$HOME/.config/video-studio/.env"; do
    [ -n "$f" ] || continue
    _fal_read_env "$f" FAL_AI_KEY && return 0
  done
  echo "fal.sh: FAL_AI_KEY not found (env, \$VIDEO_STUDIO_ENV, ~/.config/video-studio/.env)" >&2
  return 1
}

_fal_auth() { local k; k=$(fal_key) || return 1; printf 'Authorization: Key %s' "$k"; }

_fal_mime() {
  case "${1##*.}" in
    jpg|jpeg) echo image/jpeg;; png) echo image/png;; webp) echo image/webp;;
    mp4) echo video/mp4;; mov) echo video/quicktime;; webm) echo video/webm;;
    wav) echo audio/wav;; mp3) echo audio/mpeg;; json) echo application/json;;
    *) echo application/octet-stream;; esac
}

fal_upload() { # <file> → fal-cdn URL on stdout
  local f="${1:?file}" auth mime r up fu code
  [ -f "$f" ] || { echo "fal_upload: $f does not exist" >&2; return 1; }
  auth=$(_fal_auth) || return 1; mime=$(_fal_mime "$f")
  r=$(curl -s --max-time 30 -XPOST "$FAL_REST/storage/upload/initiate?storage_type=fal-cdn-v3" \
        -H "$auth" -H "content-type: application/json" -H "$(_fal_ttl "$FAL_UPLOAD_TTL")" \
        -d "$(jq -n --arg ct "$mime" --arg fn "$(basename "$f")" '{content_type:$ct,file_name:$fn}')")
  up=$(jq -r '.upload_url // empty' <<<"$r"); fu=$(jq -r '.file_url // empty' <<<"$r")
  [ -n "$up" ] && [ -n "$fu" ] || { echo "fal_upload: initiate failed: $(head -c 200 <<<"$r")" >&2; return 1; }
  code=$(curl -s --max-time 180 -X PUT -H "content-type: $mime" --data-binary @"$f" "$up" -o /dev/null -w '%{http_code}')
  [ "$code" = "200" ] || { echo "fal_upload: PUT $code for $f" >&2; return 1; }
  printf '%s\n' "$fu"
}

fal_submit() { # <endpoint> <req.json> → status_url \n response_url
  local ep="${1:?endpoint}" req="${2:?req.json}" auth r su ru
  [ -s "$req" ] || { echo "fal_submit: $req is empty/missing" >&2; return 1; }
  jq -e . "$req" >/dev/null || { echo "fal_submit: $req is not valid JSON" >&2; return 1; }
  auth=$(_fal_auth) || return 1
  r=$(curl -s --max-time 60 -XPOST "$FAL_QUEUE/$ep" -H "$auth" -H "content-type: application/json" \
        -H "X-Fal-Store-IO: 0" -H "$(_fal_ttl "$FAL_OUTPUT_TTL")" --data-binary @"$req")
  su=$(jq -r '.status_url // empty' <<<"$r"); ru=$(jq -r '.response_url // empty' <<<"$r")
  [ -n "$su" ] && [ -n "$ru" ] || { echo "fal_submit: no queue response: $(head -c 300 <<<"$r")" >&2; return 1; }
  printf '%s\n%s\n' "$su" "$ru"
}

fal_wait() { # <status_url> [max_s=1800] → 0 on COMPLETED
  local su="${1:?status_url}" max="${2:-1800}" auth t0 st r
  auth=$(_fal_auth) || return 1; t0=$(date +%s)
  while :; do
    r=$(curl -s --max-time 30 -H "$auth" "$su"); st=$(jq -r '.status // empty' <<<"$r" 2>/dev/null)
    case "$st" in
      COMPLETED) return 0;;
      FAILED|CANCELLED) echo "fal_wait: $st — $(head -c 300 <<<"$r")" >&2; return 1;;
      "") # Flux Dev sometimes returns the result right away, without a status
         jq -e '.images or .video or .audio_file' <<<"$r" >/dev/null 2>&1 && return 0;;
    esac
    [ $(( $(date +%s) - t0 )) -ge "$max" ] && { echo "fal_wait: timeout after ${max}s ($st)" >&2; return 1; }
    sleep 5
  done
}

fal_result() { # <response_url> <out.json>
  local ru="${1:?response_url}" out="${2:?out.json}" auth i code
  auth=$(_fal_auth) || return 1
  for i in 1 2 3 4 5 6; do
    code=$(curl -s --max-time 60 -H "$auth" "$ru" -o "$out" -w '%{http_code}')
    [ "$code" = "200" ] && jq -e . "$out" >/dev/null 2>&1 && return 0
    sleep $((i*3))   # brief 400/425 right after COMPLETED (models.md)
  done
  echo "fal_result: fetch failed (last HTTP $code)" >&2; return 1
}

fal_price() { # <endpoint> → "unit_price unit"
  local auth r; auth=$(_fal_auth) || return 1
  r=$(curl -s --max-time 15 -H "$auth" "$FAL_PRICING?endpoint_id=$1")
  jq -r '.prices[0] | "\(.unit_price) \(.unit)"' <<<"$r" 2>/dev/null | grep -v '^null' || echo "? ?"
}

fal_cost_log() { # <endpoint> <request_id> <req.json>
  local ep="$1" rid="$2" req="$3" log="${FAL_COST_LOG:-./costs.jsonl}" price unit dur est
  read -r price unit <<<"$(fal_price "$ep")"
  dur=$(jq -r '.duration // .seconds_total // empty' "$req" 2>/dev/null | tr -d 's')
  est=$(awk -v p="$price" -v u="$unit" -v d="$dur" 'BEGIN{ if(p=="?"){print "null"; exit}
        if(u=="seconds" && d!=""){printf "%.3f", p*d} else if(u~/^(audios|units|requests)$/){printf "%.3f", p} else {print "null"} }')
  jq -nc --arg ts "$(date -u +%FT%TZ)" --arg ep "$ep" --arg rid "$rid" --arg dur "$dur" --arg p "$price" --arg u "$unit" --argjson est "$est" \
     '{ts:$ts,endpoint:$ep,request_id:$rid,duration:($dur|if .=="" then null else . end),unit_price:($p|tonumber? // null),unit:$u,est_usd:$est}' >> "$log"
  if [ "$est" != "null" ]; then echo "cost: ~\$$est ($ep, $dur s) → $log" >&2
  else echo "cost: $ep is priced per $unit ($price) — amount cannot be derived, see the fal dashboard; logged in $log" >&2; fi
  return 0   # a cost line that cannot be estimated must never fail a successful run
}

fal_run() { # <endpoint> <req.json> <out.json> [max_s]
  local ep="$1" req="$2" out="$3" max="${4:-1800}" urls su ru rid
  urls=$(fal_submit "$ep" "$req") || return 1
  su=$(sed -n 1p <<<"$urls"); ru=$(sed -n 2p <<<"$urls"); rid="${ru##*/}"
  echo "fal_run: $ep request $rid — waiting (max ${max}s)" >&2
  fal_wait "$su" "$max" || { echo "  cancel: fal.sh cancel $ep $rid" >&2; return 1; }
  fal_result "$ru" "$out" || return 1
  fal_cost_log "$ep" "$rid" "$req"
}

fal_cancel() { # <endpoint> <request_id>  (pkill on the poller does NOT stop the job — this does)
  local auth base; auth=$(_fal_auth) || return 1
  base=$(cut -d/ -f1-2 <<<"$1")   # result/cancel path = base-model path (models.md)
  curl -s --max-time 30 -X PUT -H "$auth" "$FAL_QUEUE/$base/requests/$2/cancel"; echo
}

fal_delete() { # <file_url> — delete an uploaded/generated file at fal (permission assets:write)
  local auth; auth=$(_fal_auth) || return 1
  curl -s --max-time 30 -XPOST "https://rest.fal.ai/storage/files/delete" -H "$auth" -H "content-type: application/json" \
    -d "$(jq -n --arg u "$1" '{file_url:$u}')"; echo
}

fal_costs() { # [costs.jsonl]
  local log="${1:-${FAL_COST_LOG:-./costs.jsonl}}"
  [ -f "$log" ] || { echo "no $log"; return 1; }
  jq -rs 'group_by(.endpoint) | map({ep:.[0].endpoint, n:length, usd:(map(.est_usd // 0)|add), unk:(map(select(.est_usd==null))|length)})
          | (.[] | "\(.n|tostring|.+"×") \(.ep)  ~$\(.usd*1000|round/1000)\(if .unk>0 then "  (\(.unk) without estimate: priced per token/unit — fal dashboard)" else "" end)"),
            "total ~$\(map(.usd)|add*1000|round/1000) (\(map(.n)|add) calls, \(map(.unk)|add) without estimate)"' "$log"
}

# ── command mode ──────────────────────────────────────────────────────────────
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  cmd="${1:-}"; shift || true
  case "$cmd" in
    key) fal_key;; upload) fal_upload "$@";; submit) fal_submit "$@";; wait) fal_wait "$@";;
    result) fal_result "$@";; run) fal_run "$@";; cancel) fal_cancel "$@";; price) fal_price "$@";; costs) fal_costs "$@";;
    delete) fal_delete "$@";;
    *) sed -n '2,24p' "$0"; exit 2;;
  esac
fi
