// video-studio — title layer (HyperFrames, variant A: transparent overlay on top of the ffmpeg montage).
// One source for 9:16 and 16:9: the entry (916/ or 169/) only sets the size; per-format layout lives in titles.css.
// Content + timing come from the `spec` variable (JSON), written by the montage from its measured xfade offsets.
// Never copy times by hand. Recipe: reference/titles-hyperframes.md in this skill.
//
// spec = { "duration": s, "brand": { optional, tokens from titles.css :root },
//         "fontFaces": [ { "family": "…", "file": "X.ttf", "weight": 700 } ] (optional), "items": [
//   { "kind": "plate", "in": s, "out": s, "text": "…", "small": false, "glow": s },        // title plate
//   { "kind": "pair",  "in": s, "out": s, "typed": "…", "knew": "…", "labels": ["A","B"] }, // two-part plate
//   { "kind": "card",  "in": s, "out": s, "kicker": "…", "head": "…", "panel": "…",          // full-frame paper card
//     "typewriter": 3.4, "counter": "words", "foot": ["…", "…"] } ] }
// Text is plain text (it gets escaped). Markup: *word* = accent (<b>), \n = line break.
// `in`/`out` are absolute seconds; `out` = the moment the element is fully gone.
window.buildTitles = function () {
  const root = document.getElementById("root");
  const W = +root.dataset.width, H = +root.dataset.height;
  root.classList.add(W > H ? "landscape" : "portrait");

  const v = (window.__hyperframes && window.__hyperframes.getVariables()) || {};
  const spec = JSON.parse(v.spec);
  // brand: { "teal": "#…", "amber": "#…", "paper": "#…", "plate": "rgba(…)", "font-head": "…", … } → CSS variables
  for (const [k, val] of Object.entries(spec.brand || {})) root.style.setProperty(`--${k}`, val);
  // custom brand fonts: files are copied into fonts/ by render-titles.sh (FONTS_DIR=<dir>), registered here as @font-face
  for (const f of spec.fontFaces || []) { const ff = new FontFace(f.family, `url("fonts/${f.file}")`, { weight: String(f.weight || "400") }); document.fonts.add(ff); ff.load(); }
  const glow = getComputedStyle(root).getPropertyValue("--glow").trim();   // GSAP does not interpolate var()

  const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const fmt = (s) => esc(s).replace(/\*([^*]+)\*/g, "<b>$1</b>").replace(/\n/g, "<br>");
  // every word gets its own span so the words can rise in; <b>…</b> stays intact
  const words = (s) => fmt(s).split(/(<br>|\s+)/).map(w => (w === "<br>" || /^\s*$/.test(w)) ? w : `<span class="w">${w}</span>`).join("");
  const el = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; };

  const tl = gsap.timeline({ paused: true });

  spec.items.forEach((it, i) => {
    const id = `i${i}`;
    if (it.kind === "plate" || it.kind === "pair") {
      const p = el("div", `plate ${id}`);
      if (it.kind === "plate") p.append(el("p", `title${it.small ? " small" : ""}`, words(it.text)));
      else {
        const [la, lb] = it.labels || ["YOU TYPED", "IT KNEW"];
        p.append(el("div", "kicker", esc(la)), el("p", "quote", `“${fmt(it.typed)}”`), el("hr"),
                 el("div", "kicker", esc(lb)), el("p", "title small", words(it.knew)));
      }
      root.append(p);
      const sel = `.${id}`, f = it.fade ?? 0.25;
      tl.set(sel, { opacity: 0 }, 0)
        .fromTo(sel, { opacity: 0, y: 18 }, { opacity: 1, y: 0, duration: f, ease: "power2.out" }, it.in)
        .from(`${sel} .w`, { opacity: 0, y: 14, duration: 0.3, stagger: Math.min(0.035, 0.9 / p.querySelectorAll(".w").length), ease: "power2.out" }, it.in + 0.05)
        .to(sel, { opacity: 0, duration: f, ease: "none" }, it.out - f);
      // escalation: the accent word glows at a chosen moment (e.g. when the picture 'switches on')
      if (it.glow != null) tl.to(`${sel} b`, { color: glow, textShadow: `0 0 28px ${glow}`, duration: 0.5, ease: "power2.out" }, it.glow);
      return;
    }

    // card
    const c = el("section", `card ${id}${it.panel ? "" : " nopanel"}`);
    if (it.kicker) c.append(el("div", "kicker", esc(it.kicker)));
    if (it.head) c.append(el("h1", "head", fmt(it.head)));
    let tw = null;
    if (it.panel) {
      const panel = el("div", "panel");
      if (it.typewriter) {
        tw = it.panel.split(" ");
        panel.append(el("p", "code", '<span class="pw"><span class="cur">▌</span></span>' +
          tw.map(w => `<span class="pw">${esc(w)}<span class="cur">▌</span></span> `).join("")));
      } else panel.append(el("p", "code", fmt(it.panel)));
      c.append(panel);
    }
    if (tw && it.counter) c.append(el("div", "count", `<span class="n">0</span><span class="lbl">${esc(it.counter)}</span>`));
    if (it.foot) { const ft = el("div", "foot"); ft.append(el("hr", "rule"), ...it.foot.map(t => el("p", "", fmt(t)))); c.append(ft); }
    root.append(c);

    const sel = `.${id}`, f = it.fade ?? 0.4;
    tl.set(sel, { opacity: 0 }, 0)
      .to(sel, { opacity: 1, duration: f, ease: "none" }, it.in)
      .from(`${sel} .head`, { y: 30, opacity: 0, duration: 0.6, ease: "power3.out" }, it.in + 0.1)
      .to(sel, { opacity: 0, duration: f, ease: "none" }, it.out - f);
    if (tw) {
      // typewriter: word by word, the cursor follows (each word has its own absolutely positioned cursor)
      const pws = c.querySelectorAll(".pw"), curs = c.querySelectorAll(".cur"), n = c.querySelector(".n");
      const step = it.typewriter / tw.length, t0 = it.in + 0.3;
      tl.set(pws, { opacity: 0 }, 0).set(pws[0], { opacity: 1 }, 0).set(curs, { opacity: 0 }, 0).set(curs[0], { opacity: 1 }, 0);
      tw.forEach((_, k) => {
        const t = t0 + k * step;
        tl.set(pws[k + 1], { opacity: 1 }, t).set(curs[k], { opacity: 0 }, t).set(curs[k + 1], { opacity: 1 }, t);
        if (n) tl.set(n, { textContent: String(k + 1) }, t);
      });
      if (n) tl.fromTo(`${sel} .count`, { scale: 1 }, { scale: 1.08, duration: 0.15, yoyo: true, repeat: 1, transformOrigin: "left center" }, t0 + it.typewriter);
    }
  });

  tl.set({}, {}, spec.duration);   // timeline runs to the end of the film
  return tl;
};

// Font-size ladder for long (client) copy: a plate may not grow taller than MAXH; step down 4 px at a time to MIN.
// Runs after the fonts have loaded, otherwise you measure the fallback font.
window.fitTitles = function () {
  const root = document.getElementById("root");
  const MAXH = root.classList.contains("landscape") ? 860 : 1100, MIN = 36;
  root.querySelectorAll(".plate .title, .card .head").forEach((t) => {
    const box = t.closest(".plate") || t;
    const limit = t.closest(".plate") ? MAXH : MAXH * 0.5;
    let px = parseFloat(getComputedStyle(t).fontSize);
    while (box.offsetHeight > limit && px > MIN) { px -= 4; t.style.fontSize = px + "px"; }
  });
};
