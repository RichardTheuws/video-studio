#!/usr/bin/env bash
# test-titles.sh — regression test for the title template + check-titles.sh, in both formats.
#   tests/titles/pass/*.json must PASS, tests/titles/fail/*.json must FAIL (exit 1, not 2/3).
# Run after every change to templates/titles/ or check-titles.sh.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; T="$HERE/tests/titles"; bad=0; n=0
for fmt in 916 169; do
  for f in "$T"/pass/*.json; do n=$((n+1)); "$HERE/check-titles.sh" "$fmt" "$f" >/dev/null 2>&1; rc=$?
    [ "$rc" = 0 ] && echo "  ok    $fmt pass/$(basename "$f")" || { echo "  ERROR $fmt pass/$(basename "$f") exited $rc"; "$HERE/check-titles.sh" "$fmt" "$f" 2>&1 | sed 's/^/        /' | head -8; bad=1; }
  done
  for f in "$T"/fail/*.json; do n=$((n+1)); "$HERE/check-titles.sh" "$fmt" "$f" >/dev/null 2>&1; rc=$?
    [ "$rc" = 1 ] && echo "  ok    $fmt fail/$(basename "$f") caught" || { echo "  ERROR $fmt fail/$(basename "$f") exited $rc (expected 1)"; bad=1; }
  done
done
[ "$bad" = 0 ] && { echo "test-titles: $n/$n PASS"; exit 0; } || { echo "test-titles: FAIL"; exit 1; }
