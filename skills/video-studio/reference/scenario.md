# Scenario and storyboard — story order and lessons per video type

**Read this before every brief, every scenario and every storyboard.** `directing.md` governs the *picture* (shot grammar,
keyframes, editing). This document governs the *story*: where you start, what the first image is, where the brand sits,
how it ends. The learning loop: tag each video before production, read the platform metrics at day 7, and promote or
demote lessons on paired tests. Primary sources are named per lesson.

## 0. How to use this

**Status of a lesson** (shown in brackets with every lesson):

| Status | Means | You do |
|---|---|---|
| `house-rule` | confirmed on our own numbers (≥ 5 paired tests, ≥ 2 brands) | always apply; deviate only with a reason in the brief |
| `signal` | 3/3 own pairs point the same way | apply by default, keep testing |
| `external-strong` | measured by others, primary source read, large sample or experiment | apply by default |
| `external` | platform advice, second-hand figure or craft rule | allowed; does not count as truth |
| `hypothesis` | prediction before a test | only via `test_slot` |

A status never changes silently: propose the change with the evidence and let a human approve it.
What you record per production (tags, `test_slot`): `taxonomy.md`.

**Working order for the writer**
1. Pick the **type** (§2–§12) and read §1 plus that type.
2. Define the **peak**: the one image someone retells afterwards. Preferably the product or its effect.
3. Choose the **telling order** (§1 S-A01). The arc stays (tension → payoff → meaning), but you may start at the payoff.
4. Write the scenario as a **beat table with seconds** (0–3 s hook … last 2 s ending) before you write a single prompt.
5. Put the **tags** in the front matter of `brief.md` (`taxonomy.md`). At most one `test_slot`.
6. Storyboard: **draw the peak keyframe first** (`storyboard-keyframes.md`). Board order ≠ edit order.

## 1. All types

- **S-A01 Open on the peak, then the how** (`external-strong`). The first image is the moment it works (the man lifts his mug and the table comes with it), only then how it came about (the crack, one drop of glue). The peak is where the action, the emotion or the click moment sits. *Storyboard:* peak keyframe first; the payoff must return to the opening, otherwise the opening feels like a trick. *Evidence:* craft rule + Zappi 2026 (n = 3,303 social ads): ending on a high point +0.46, built-up tension without resolution +0.06, montage without story −0.19. *Measure:* 3-s hold / skip rate, avg. watch %.
- **S-A02 One image you can retell, and that image is the product** (`external-strong`). Not a pretty close-up or set: an image someone describes in one sentence. *Evidence:* Zappi 2026: 2.4× chance of top 20 %, the strongest attribute in the study. *Measure:* 3-s hold; "what did you see?" with 5 people.
- **S-A03 Brand within ±2 s, in the scene, not as a floating logo** (`external-strong`). Brand colour in the grade, the product in frame, the character, a sonic logo. A logo card at second 0 costs attention. Exception for a long brand film: S-BF07. *Evidence:* System1 (early recognition +92 % awareness, logo overlay costs attention), Google 2015 (floating logo lowers viewing and recall), Zappi (colour +0.74, slogan +0.50, packshot +0.15). *Measure:* "which brand?" check.
- **S-A04 End on a high point and resolve it on screen** (`external-strong`). Write the last 2 s as their own beat (payoff, then end card), hold the strongest frame 0.5–1 s. Never fade out mid-movement or end on just a price. *Evidence:* Zappi +0.46 (1.5× top 20 %); Baumgartner 1997 (peak and end determine the judgement). *Measure:* watch-to-end.
- **S-A05 Title and image coincide, and every title is readable** (`external-strong`). A title appears on the same frame as its image and sits next to the thing it names. Reading time ≥ max(1.5 s; characters ÷ 15): `scripts/qa-check.sh --titles spec.json` checks it. With voice-over no full sentences on screen, only 2–4 key words. *Evidence:* Mayer 2017 (temporal contiguity d = 1.30, spatial d = 0.79, redundancy d = 0.87); Szarkowska (comprehension drops with fast subtitles); PLOS ONE 2024 (reading without sound takes more effort). *Measure:* gate + pause/replay peaks.
- **S-A06 Build double: titles carry everything, sound adds** (`external-strong`). LinkedIn is watched 79 % without sound, Reels 80 % with. The titles carry the whole message; the hook gets a sound moment (sfx, one spoken line, sonic logo) that fits the picture. Speech + music scores 2.0–2.1× (Meta). *Measure:* 3-s hold per channel.
- **S-A07 Show the result, not just the use** (`external-strong`). Every demo shot has a result frame (the clean floor, the full calendar, the delivered print). *Evidence:* Zappi: product with visible result +0.52 persuasion, product only in use −0.01. *Measure:* CTR, leads per video (`source=`).
- **S-A08 AI seamless, and the best AI shot carries the brand** (`external-strong`). Shots with visible AI errors (hands, faces, warped text) go; the most spectacular generated shot contains the product or the brand. *Evidence:* Kantar Link (GenAI ads): seamless > 40 % in the top for brand impact, visible AI scores lower. *Measure:* rejects in QA.
- **S-A09 One idea per video** (`external-strong`). An explanation is one mechanism of at most 4 steps; a second idea is a second video (or a series). *Evidence:* Cowan (±4 chunks in working memory); Mayer coherence d = 0.70.

## 2. Brand teaser (15–30 s, awareness)

- **S-TE01 Build the teaser around one image you can retell** (`external-strong`). See S-A02. First write the sentence "you see …", only then the board.
- **S-TE02 Twist only if the answer is the product** (`external-strong`). "What is this?" is fine if the reveal is the product or the brand itself. A surprise that ends on just a logo costs brand linkage. *Evidence:* Zappi: twist reveal +0.45 (1.8×); surprise without product −0.12 brand linkage.
- **S-TE03 The "heartbeat" curve: start high, 3–4 peaks, brand at every peak** (`external`). Not the TV curve of build-up → climax → logo. *Evidence:* ABCD playbook; Facebook/MetrixLab (759 ads): the classic story had the lowest brand recall (second hand).
- **S-TE04 The brand more than once, in different places** (`external-strong`). At least 2 brand moments plus the end card. *Evidence:* Meta × Toluna: 1.8×.
- **S-TE05 A recognisable colour or line cue above the packshot** (`external-strong`). Grade every shot to 1–2 brand colours, repeat one short line. Three or more fixed brand cues is the only thing that really raises brand linkage (Zappi +0.70).
- **S-TE06 Opening: 2+ shots in the first 5 s, tight framing, a face if there are people** (`external-strong`). Shot 1 is a close-up of person or product, the first cut before 2.5 s. *Evidence:* Google/Ipsos, Google 2015.
- **S-TE07 For LinkedIn: a micro-story of ≤ 15 s, no loop** (`external-strong`). One human moment, one idea; context in the post text. *Evidence:* LinkedIn (38,000 ads): top VTR = short brand or people stories; GIFs and loops score lowest.

## 3. Promo (15–45 s, offer)

- **S-PR01 The product in frame several times, USPs as titles** (`external-strong`). 2–3 product shots, 1–3 short USP titles (feature → benefit). *Evidence:* Meta × Toluna (DR): USP on screen 5.3×, product more than once 2.7×.
- **S-PR02 Keep the brand short: ≤ 25 % of the runtime** (`external-strong`). No long logo intro or outro; brand on the product and an end card of 1–1.5 s. *Evidence:* Meta DR 4.8×.
- **S-PR03 Order: hook → problem → product → visible result → offer** (`external-strong`). Payoff first, then the offer. Never end on just the price. *Evidence:* Zappi (full arc +0.40, list without story −0.19).
- **S-PR04 One entertaining moment before the offer** (`external-strong`). A joke, twist or satisfying moment. Pure selling converts, but costs half the awareness; a neutral video converts 27 % worse. *Evidence:* System1 × TikTok (887 ads, vendor).
- **S-PR05 A concrete call to action in text and sound, with a real reason to hurry** (`external-strong`). "Order before 1 December", not "Learn more". Only real deadlines or stock. *Evidence:* Meta 1.9×; Google/Ipsos. The button text names where you go ("See your video"), not what you spend (`external`, a maker's opinion, not measured).
- **S-PR06 Benefit as headline, price as subtitle** (`external`). "−30 %" not as the hero of every promo; constant discount campaigns make customers price-sensitive. *Evidence:* Binet & Boyd (IPA 2026, second hand).
- **S-PR07 On LinkedIn, the CTA also midway** (`external-strong`). At 40–60 % of the runtime and in the post text; many viewers click before the end. *Evidence:* LinkedIn 2021.
- **S-PR08 Titles early and short** (`external`). 5–7 words per title, the first in second 0–1. *Evidence:* TikTok/Kantar (second hand).

## 4. Social proof (20–60 s, customer story)

- **S-SP01 Never an invented customer** (**law, not a lesson**). Person, quote and result are real and used with consent. AI only builds the setting or B-roll and is labelled. *Source:* FTC rule 2024, EU Directive 2019/2161. QA: consent per video in the production folder.
- **S-SP02 The product and its result are the story, not the person** (`external-strong`). Cut "about me"; every line points to problem, product or result. *Evidence:* Yang & Zhang, *Marketing Science* 2025; Zappi: product that works 2.9×.
- **S-SP03 Before → turning point → after, with the result on screen** (`external-strong`). Three acts even in 30 s; the customer's last line is the emotional payoff. *Evidence:* Zappi: positive outcome 3.8× top 20 %, the largest effect in the report.
- **S-SP04 Open on the customer's face, mid-sentence, with the result** (`external`). Not "Hi, I'm Sam from …"; name and role in a lower third. *Evidence:* ABCD, TikTok × CreatorIQ (vendor).
- **S-SP05 The customer says the brand name themselves** (`external-strong`). One take in which the customer names the company or product, subtitled. *Evidence:* Google/Ipsos (n = 5,000).
- **S-SP06 Precise numbers in the customer's own unit** (`external`). "From 14 to 3 days", not "much faster"; the number as a heavy title. *Evidence:* Schindler & Yalch (second hand).
- **S-SP07 Keep one honest doubt** (`external-strong`). Beat 2 is the hesitation ("at first I thought it was too expensive"), then how that was resolved. *Evidence:* Spiegel Research: purchase likelihood peaks at 4.0–4.7, drops towards 5.0.
- **S-SP08 Brand cues throughout the story** (`external-strong`). Customer videos lose the brand (−0.67 brand linkage): brand colour in the lower thirds, the product recognisable in the B-roll, a brand title midway. *Evidence:* Zappi; System1.
- **S-SP09 Two versions: 15 s result for a cold audience, 45–60 s full story for a warm one** (`external-strong`). *Evidence:* LinkedIn 2021.

## 5. Explainer (30–90 s, how it works)

- **S-EX01 Every shot has a job** (`external-strong`). The storyboard gets a column "which step does this show?". Pretty but redundant shots go, or move to the hook. *Evidence:* Mayer coherence d = 0.70; "seductive details" meta-analysis (58 studies).
- **S-EX02 Name the 2–3 parts before the process** (`external-strong`). A short "cast" beat after the hook: show and name each part once. *Evidence:* pre-training d = 0.46.
- **S-EX03 Mark the structure: step number, arrow, highlight or zoom** (`external-strong`). *Evidence:* signalling d = 0.46.
- **S-EX04 Voice-over in the second person and not slow** (`external-strong`). 150–180 words per minute, silences cut. *Evidence:* personalisation d = 0.79, human voice d = 0.74; Guo 2014 (faster speech up to 2× more viewing).
- **S-EX05 Build the drawing up on screen, not card to card** (`external-strong`). Lines that draw, elements that slide in. *Evidence:* Guo 2014: drawn explanation 1.5–2× more viewing than slides.
- **S-EX06 Music bed well under the voice-over, gone at the hardest step** (`external-strong`). −18 to −24 dB, no vocals. *Evidence:* Moreno & Mayer 2000 (music lowers comprehension in explanations). Conflicts with a house-style music bed: test with a comprehension question.
- **S-EX07 Problem first for a cold audience, product first for people already comparing** (`external`, no controlled study). Reconciliation: show the product already in the problem shot.

## 6. Tips (20–35 s social, longer on YouTube)

- **S-TI01 State the number up front, 3–5 tips, with a counter on screen** (`external-strong`). More than 5 = part 2. *Evidence:* signalling; ±4 chunks working memory.
- **S-TI02 The strongest tip first, the second strongest last** (`external`). The audience only shrinks; YouTube advises moving top moments forward. *Evidence:* YouTube Help, Wistia curves.
- **S-TI03 Each tip its own title card and its own self-contained piece** (`external-strong`). Number + 2–4-word heading → one demonstration → result. *Evidence:* segmenting d = 0.70; Kim 2014 (61 % of interaction peaks at a visual change).
- **S-TI04 Show every tip, with before/after** (`external-strong`). A tip you cannot show gets cut. *Evidence:* multimedia d = 1.67; TikTok: multiple scenes +38 %.
- **S-TI05 Tip 1 is on screen within 3 s, no intro** (`external`).
- **S-TI06 End with the action as text, at least 2 s on screen** (`external`). *Evidence:* TikTok: explicit text CTA +152 % (own model).

## 7. Product spotlight (15–45 s)

- **S-SL01 Product in motion and in use, never a series of static packshots** (`external-strong`). Turning, pouring, opening, clicking, wearing. *Evidence:* Roggeveen 2015, *J. Marketing*.
- **S-SL02 Frame it so you could grab it** (`external-strong`). Handle to the right (most viewers are right-handed), a hand or spoon in frame. *Keyframe rule.* *Evidence:* Elder & Krishna 2012, *JCR* (4 studies, higher purchase intent).
- **S-SL03 One product, one distinctive claim, proven on screen** (`external-strong`). Exactly one "only we" line. *Evidence:* Stewart & Furse/Koslow (1,000+ TV ads, second hand).
- **S-SL04 Show the effect, don't describe the property** (`external-strong`). "Still white after 50 washes" in a test on screen, not "durable fabric".
- **S-SL05 5–8 shots per 30 s: hero, detail, use, context, result** (`external`). *Evidence:* TikTok +38 %.
- **S-SL06 The next main element where the eye already is** (`external-strong`). At every cut the new subject sits on the old point of focus. *Evidence:* NN/g eye tracking.
- **S-SL07 Price or offer always as a title, even with voice-over** (`external`). *Evidence:* TikTok +80 %.

## 8. Walkthrough (screen recording, 30 s–3 min)

- **S-WT01 One task per video, at most 2–3 minutes of attention** (`external-strong`). A tour is a series. *Evidence:* Guo 2014 (6.9 M sessions): tutorials are watched for 2–3 min, regardless of length.
- **S-WT02 First the end result, then the steps** (`external`). Open on the sent, paid invoice; then step 1. This is S-A01 for software.
- **S-WT03 Name the screens before the clicks** (`external-strong`). A 3–5 s card: "everything happens in two places". *Evidence:* pre-training d = 0.46.
- **S-WT04 Each step a large step card and a chapter** (`external-strong`). Viewers jump to step starts. *Evidence:* Guo 2014, Kim 2014.
- **S-WT05 Mark the click: arrow, box or zoom to 150–200 %, in sync with the word** (`external-strong`). *Evidence:* Jamet & Fernandez 2016.
- **S-WT06 Draw over the interface instead of a cursor that sits still** (`external-strong`). *Evidence:* Guo 2014 (1.5–2×).
- **S-WT07 Cut dead time: loading, typing, idle cursor** (`external`). Speed up or cut every wait over 0.5 s.
- **S-WT08 Interface text readable at phone size** (`external`). In 9:16 zoom in on the active panel, interface text ≥ 1/20 of the frame height.

## 9. Leader / sting (2–10 s)

- **S-LE01 The brand within 2 s, that is the whole job** (`external-strong`). No build-up with the logo at second 4. *Evidence:* System1 fluency, Kantar Super Bowl 2026.
- **S-LE02 In a 9:16 feed never put the leader first** (`external-strong`). Instagram measures swipes in the first 3 s. Open on content with a small brand mark in the corner; the full leader becomes the outro. In 16:9 on an owned channel or long YouTube a leader of ≤ 2 s is fine. *Measure:* skip rate with and without the leader up front (a cheap test: editing only).
- **S-LE03 Only known, unique cues, identical every time** (`external-strong`). One fixed sting per brand (same frames, sound, timing); a new brand gets 1–2 cues. *Evidence:* Romaniuk/Ehrenberg-Bass.
- **S-LE04 Every sting a sonic logo of 1–2 s** (`external`). Ipsos: sonic brands ±8.5× more often top score (second hand). The storyboard has an audio row.
- **S-LE05 No story in ≤ 6 s: cue → one pleasant image → brand** (`external-strong`). *Evidence:* System1 (not a single 6-s ad reached 5 stars).
- **S-LE06 End on the strongest frame and hold it** (`external-strong`). 0.5–1 s, no fading into nothing. *Evidence:* Baumgartner 1997.
- **S-LE07 Judge a sting only after ≥ 5 videos** (`external`). Fixed cues work through repetition; record a sting version per video (`taxonomy.md`).

## 10. Series episode

- **S-SE01 Resolve one question, open one** (`external-strong`). This episode's payoff is not sacrificed to the hook into the next. *Evidence:* Wirz 2022 (n = 133) and Hahn 2023 (±500): cliffhangers don't hurt, but they are not the engine.
- **S-SE02 Every episode is someone's episode 1** (`external`). No "last time" as the opening; the cold open is a moment from *this* episode. A recap at most as one line after the hook (s 3–6). *Measure:* skip rate episode 2+ ≈ episode 1.
- **S-SE03 A character bible before episode 1** (`external-strong`). Silhouette, clothing colours, one attribute, one catchphrase, a fixed reference sheet (`consistency.md`). The same character opens every episode. *Evidence:* System1: recurring characters up to 25 % more spontaneous brand recall.
- **S-SE04 Build a world: 2–3 fixed locations, a fixed supporting cast, an open question across the season** (`external`).
- **S-SE05 Beat table with seconds before the dialogue** (`external`). 0–3 s hook, a turn around 30 s, last 5 s an open question.
- **S-SE06 Don't judge a series on episode 1** (`external`). At least 3 episodes before go/kill; the verdict rests on watch-through (episode 1 → last) and returning viewers.

## 11. Brand film / anthem (60–90 s)

- **S-BF01 No offer, price or feature list** (`external-strong`). Rational messages go into separate short versions. Don't judge a brand film on week-1 CTR. *Evidence:* Binet & Field (996 campaigns): emotional campaigns ±2× more often strong long-term profit growth (second hand).
- **S-BF02 Success is felt emotion: a target emotion per beat** (`external-strong`). The storyboard gets an **emotion row** per shot (surprise/joy/warmth/tension, 0–5). *Evidence:* System1.
- **S-BF03 Quick surprise, then a long stretch of joy** (`external-strong`). Surprise in 0–3 s, no long negative dip before the payoff. *Evidence:* Teixeira 2012, *JMR* (rises in joy gain more than dips lose).
- **S-BF04 A glimpse of the peak up front, the full peak at 70–85 %, end on the high point** (`external-strong`). No logo wall or legal text after the musical close. This is S-A01 for the long form. *Evidence:* Baumgartner 1997.
- **S-BF05 Five acts, even in 60 s** (`external-strong`). For example 8/15/15/12/10 s. A montage of pretty shots without a protagonist fails. *Evidence:* Quesenberry & Coolsen 2014 (108 Super Bowl ads).
- **S-BF06 People doing something together in one continuous place, music with melody** (`external-strong`). No slogan cards and isolated hero shots. *Evidence:* Wood/System1 ("right-brain" features).
- **S-BF07 Brand world early, brand name late** (`external-strong`, research conflicts). Colour, character and sound from the first seconds; logo or name as the payoff at the peak or at the end. Never zero brand cues in the first 5 s. *Evidence:* Williams 2022 (product first, brand later sold better) vs fluency research.
- **S-BF08 Lock the music before the storyboard, act changes on musical phrases** (`external`). Cutting on the beat is style, not a lever: no measured effect has been found.
- **S-BF09 The arc ends higher than it starts** (`external`). A sad film ends in relief or gratitude.

## 12. Personal film (one viewer)

Never measured; only a three-question debrief with the client.

- **S-PF01 Music from the recipient's teenage years** (`external-strong`). Intake question: "which songs from their 10th–25th year matter?" Cut to the music. Music policy and licensing apply. *Evidence:* Jakubowski 2020 (n = 470; peak around age 14).
- **S-PF02 A film from parent to child: a song from the parent's youth carries both generations** (`external-strong`). *Evidence:* same.
- **S-PF03 Their name, their words, their places; address them at the turn towards the climax** (`external`).
- **S-PF04 Five acts of a life: who they are → shared history → the moment → what it meant → the wish** (`external`). One real object (photo, voice message, thing) per act.
- **S-PF05 Sadness is allowed, but the line rises at the end** (`external-strong`). Act 5 ends in warmth or gratitude, never in loss.
- **S-PF06 Have every face confirmed** (practice rule). Mark every shot REAL / AI-RECONSTRUCTION / AI-SYMBOLIC; every AI shot with a person goes past the client before animating.
- **S-PF07 Debrief: which moment touched most, did anything feel "not them", has it been rewatched or shared?** The answers go into the production report.

## 13. Conflicts between lessons (and how we settle them for now)

| Conflict | Settlement until our own numbers say otherwise |
|---|---|
| Brand early vs viewers swiping away | Brand early via cues *in the scene*; the cost is in the logo card, not in early branding |
| Peak first vs an arc with a payoff | Both: open on the peak, short arc, resolve on screen in the last 2 s |
| Music bed (house style) vs coherence (Mayer) | Explainer/walkthrough: bed well under; teaser/promo/tips: bed stays. Test with a comprehension question |
| Full subtitles vs redundancy | With voice-over 2–4 key words; full subtitles only where no sound is the norm (LinkedIn) |
| Best tip first vs best for last | Strongest first, second strongest last, weakest in the middle |
| Length | First pick the metric per type (watch-to-end for awareness, CTR for promo); there is no universal ideal length |

## 14. Self-maintenance

A new lesson comes in via a production report, research or the learning loop. Every lesson gets an id, a status, an
evidence line and a measurement signal. Without a measurement signal it is a craft rule for `directing.md` or
`commercial-craft.md`, not a lesson here. Log what you learned in `lessons.md` and bump the skill CHANGELOG.
