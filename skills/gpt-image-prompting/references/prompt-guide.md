# Image Prompt Guide (Codex route)

Reference for writing prompts for the image model behind Codex's `image_generation` tool
(today: gpt-image-2, "ChatGPT Images 2.0"; Codex picks the model and moves to newer ones such as
Images 2.5 on its own). Images are generated with the `gptimage` wrapper on the user's ChatGPT
subscription. Everything below is about the **prompt text** and the few things the Codex route
lets you control: the prompt, the input images and a shape hint.

## TL;DR
- Order: **artifact type → scene/background → subject → camera/framing/lighting → literal text → constraints.**
- Write natural-language prose, not tag lists. 1–3 sentences plus a constraint line is often enough.
- Say "photorealistic" for realism. Skip "cinematic", "ultra-detailed", "masterpiece".
- Exclusions go in the prompt itself ("No watermark. No extra text.").
- Edits: "Change only X. Keep everything else exactly the same." plus a preserve list, restated every turn.
- Quote literal text, give typography and placement, and say it appears exactly once.
- Reference inputs by index: "Image 1: …, Image 2: …", and say how they interact.
- Transparent background: end the prompt with "on a transparent background." Codex returns a real alpha
  channel; the `gpt-image-transparent` skill finishes and checks it.

---

## A. Prompt anatomy (ten fundamentals)

1. **Structure + goal.** Write in a consistent order — background/scene → subject → key details →
   constraints — and name the intended use (ad, UI mock, infographic) to set the "mode" and level of
   polish. For complex requests use short labeled segments or line breaks instead of one long paragraph.
2. **Format is flexible.** Minimal prompts, descriptive paragraphs, labeled sections and
   instruction-style prompts all work when intent and constraints are clear. For production work,
   prefer a skimmable template over clever syntax.
3. **Specificity.** Be concrete about materials, shapes, textures and the visual medium (photo,
   watercolor, 3D render). Add texture cues only when needed — film grain, textured brushstrokes,
   macro detail. For photorealism, include the word "photorealistic"; "real photograph", "taken on a
   real camera" or "iPhone photo" also help. Detailed camera specs are read loosely — use them for the
   overall look, not literal optics.
4. **Detail where it counts.** Small or dense text, labeled infographics, close-up portraits and
   identity-sensitive edits need the most precise wording. Keep everything else simple.
5. **Composition.** Specify framing/viewpoint (close-up, wide, top-down), angle (eye-level,
   low-angle) and lighting/mood (soft diffuse, golden hour, high-contrast). For layouts, name the
   placement: "logo top-right", "subject centered with negative space on the left".
6. **People, pose, action.** Describe scale, body framing, gaze and object interactions: "full body
   visible, feet included", "child-sized relative to the table", "looking down at the open book, not
   at the camera", "hands naturally gripping the handlebars".
7. **Change vs. preserve.** State exclusions and invariants explicitly: "no watermark", "no extra
   text", "no logos/trademarks", "preserve identity/geometry/layout/brand elements". For edits:
   "Change only X. Keep everything else exactly the same." Repeat the preserve list every iteration.
8. **Text in images.** Put literal copy in quotes or ALL CAPS, specify font style, size, color and
   placement, and spell tricky words letter by letter.
9. **Multi-image inputs.** Reference each input by index and description ("Image 1: product
   photo… Image 2: style reference…") and describe how they interact ("apply Image 2's style to
   Image 1"; "put the bird from Image 1 on the elephant in Image 2").
10. **Iterate, don't overload.** Start clean, then refine with single-change follow-ups ("make the
    lighting warmer", "remove the extra tree"). Re-specify critical details when they drift.

## B. Prompt length

Most prompts should be short: 1–3 clear sentences that say what the image is, how it should feel and
what it must accomplish, plus 1–2 lines of constraints. Production work (logos, infographics, ads,
mockups, edits) gets longer, labeled prompts with explicit preserve and exclude lists. Past ~300–500
words, returns drop and contradictions creep in.

## C. Exclusions

There is no separate "negative" field. Write exclusions as a short constraint block at the end:

> "No watermark. No extra text. No logos or trademarks. Plain background. No decorative elements."

For edits, add the preserve list in the same block.

## D. Photorealism

Prompt as if a real photo is being captured in the moment. Use photography language (lens, lighting,
framing) and ask for real texture (pores, wrinkles, fabric wear, imperfections). Avoid words that imply
studio polish or staging.

```
Create a photorealistic candid photograph of an elderly sailor standing on a small fishing boat.
He has weathered skin with visible wrinkles, pores, and sun texture, and a few faded traditional
sailor tattoos on his arms. He is calmly adjusting a net while his dog sits nearby on the deck.
Shot like a 35mm film photograph, medium close-up at eye level, using a 50mm lens. Soft coastal
daylight, shallow depth of field, subtle film grain, natural color balance. The image should feel
honest and unposed, with real skin texture, worn materials, and everyday detail. No glamorization,
no heavy retouching.
```

## E. Text in images

1. **Quote the copy verbatim:** `Billboard text (EXACT, verbatim, no extra characters): "Fresh and clean"`
2. **Typography:** font style, weight, color, alignment.
3. **Placement:** "centered", "top-left", "as a large headline".
4. **No duplication:** "The text appears exactly once and is perfectly legible. No extra text, no watermarks."

For dense or multi-line copy, use fewer lines with more spacing. Spell brand names and unusual words
letter by letter.

## F. Editing primitives

1. **Translation in images** — preserve layout and typography; change only the text.
2. **Style transfer** — anchor what stays (palette, brushwork) vs. what changes (subject).
3. **Virtual try-on** — lock identity, change only garments; realistic fit and matching lighting.
4. **Sketch → render** — preserve layout and proportions; add realistic materials and lighting.
5. **Product mockups** — clean silhouette, legible label, light polishing only.
6. **Marketing creatives with verbatim text** — quote copy exactly, demand once-only appearance.
7. **Lighting/weather change** — change only environmental conditions; preserve identity, geometry, camera angle.
8. **Object removal / swap** — one explicit change; preserve everything else.
9. **Person-in-scene compositing** — grounded photo language; lock face, body, hair, expression.
10. **Multi-image compositing** — reference inputs by index; name the transplant target and match light and perspective.
11. **Interior swap** — preserve camera angle, room lighting, floor shadows, surrounding objects.

The core incantation, repeated on every turn of an edit chain:

> "Change only [X]. Preserve [Y]. Do not alter [Z]."

## G. Templates

**G1 — Photorealistic portrait/scene**
```
Create a photorealistic [shot type] of [subject], [doing action] in [setting].
[Subject details: 2–3 sentences on appearance, texture, expression, clothing].
Shot like a [film stock / phone / mirrorless] photograph, [framing] at [eye level / low angle / overhead],
using a [lens] lens. [Lighting], shallow depth of field, [optional: film grain, natural color balance].
The image should feel [mood], with real texture, [imperfections list].
No glamorization, no heavy retouching, no watermark.
```

**G2 — Infographic / educational diagram** (landscape shape)
```
Create a [topic] diagram titled "[TITLE]" for [audience].
Show [list of items/components/steps]. Use arrows to connect [relationships].
Label: [labels list]. Make it look like [clean classroom handout / pitch slide / poster] —
white background, simple icons, clear labels, easy-to-read text.
Avoid: tiny text, extra decoration, anything that makes the diagram hard to understand.
```

**G3 — Ad / marketing creative with copy**
```
Create a polished [campaign brand] ad for [target audience].
Concept: [one-sentence concept]. Mood: [3–5 adjectives].
Scene: [composition + subjects + setting + color direction].
Render the tagline EXACTLY ONCE, clearly and legibly, integrated into the layout:
"[VERBATIM TAGLINE]"
Typography: [font style], [weight], [color], [placement].
No extra text, no watermarks, no unrelated logos.
```

**G4 — Logo** (for several directions, write one distinct prompt per direction)
```
Create an original, non-infringing logo for [brand name], a [category] brand.
Personality: [3 adjectives]. Use clean vector-like shapes, strong silhouette, balanced negative space.
Favor simplicity over detail so it reads clearly at small and large sizes.
Flat design, minimal strokes, no gradients unless essential. Plain solid background.
Deliver a single centered logo with generous padding. No watermark.
```

**G5 — UI mockup**
```
Create a realistic [mobile/desktop/web] app UI mockup for [product].
Show [screen: UI elements with hierarchy]. Include [specific features].
Practical and easy to use. White background, [accent palette], clear typography, minimal decoration.
It should look like a real, well-designed app, not a concept sketch. [Optional: inside a phone frame.]
```

**G6 — Edit (single surgical change)** — the image to edit is Image 1
```
[One-sentence change instruction to Image 1].
Do not change anything else.
Preserve identity, geometry, layout, camera angle, lighting, and surrounding objects.
Match contact shadows and color temperature to the original photo.
```

**G7 — Character-consistent series (storyboard, children's book)**
```
Step 1 — Character anchor (new image):
"Create a [style] illustration introducing a main character.
Character: [appearance + outfit + proportions + tone].
Style: [medium + palette + line treatment].
Constraints: original character, no text, no watermarks,
plain [setting] background to clearly show the character."

Step 2 — Continuation (anchor image attached as Image 1):
"Continue the story using the same character from Image 1.
Scene: [new action + setting].
Character consistency: same [outfit + facial features + proportions + color palette].
Style: [same medium + lighting + mood].
Constraints: do not redesign the character, no text, no watermarks."
```

## H. Aesthetic cues (one phrase per genre, don't stack adjectives)

- **Editorial:** "shot like an editorial fashion photograph, natural light, candid pose, magazine-quality composition."
- **Product:** "studio product photography, soft diffuse lighting, plain seamless background, subtle contact shadow, sharp focus on the product."
- **Documentary:** "shot like a 35mm documentary photograph, available light, slight grain, unposed."
- **Film still:** "film still, widescreen framing, soft key light, shallow depth of field, naturalistic color grade" — but avoid "cinematic" for honest photography; it over-stylizes.
- **Pixel art / manga / comic:** name the medium explicitly.

## I. Input images on the Codex route

- Inputs are files passed to the wrapper: `--edit-target` (always Image 1), then `--image` in order,
  then `@path` tokens from the prompt in order of appearance. The wrapper replaces each `@path` with
  `Image N`, so a prompt can say "Use @references/character.png as the character reference".
- Write the prompt with the same numbering: "Image 1: the room photo. Image 2: the sofa."
- A reference that is not a readable file is not a reference. Never describe a missing image in words
  instead.
- Every call is independent. For a revision, the previous output is the new Image 1; re-attach only
  the references the change still needs, and restate the preserve list in full.
- With several inputs, give each a role ("Edit Image 1. Use Image 2 only as a reference for …").
  Without roles the model may return a side-by-side collage of all inputs.
- With input images the output usually keeps the shape of Image 1, whatever the shape hint says.

## J. Content policy and safety

Requests are checked before generation (text and input images) and again on the output. Enforced
categories: violence, sexual content, deepfakes (political, sexual or otherwise sensitive imagery of
real people, places or events — named public figures get refused), content involving minors, and
biological/chemical risk. Outputs carry C2PA provenance metadata and an invisible watermark.

Reframe instead of fighting a refusal: "a fictional CEO figure in the same pose", "an original mascot
with a similar silhouette".

## K. Common failures and fixes

| Failure | Fix |
|---|---|
| Garbled text | Quote the text, give font/size/placement, reduce density, spell unusual words letter by letter. |
| Edit changes things you didn't ask for | Explicit preserve list; restate invariants every turn; edit the latest output, not the original. |
| Hands or anatomy wrong | Describe the action geometry ("hands naturally gripping…", "full body visible, feet included"); add "natural proportions, anatomically correct hands". |
| Faces drift across images | Attach the anchor image as a reference every time; lock "same facial features, proportions and color palette". |
| Looks "too AI" | Photography language + texture realism + "no glamorization, no heavy retouching"; drop filler words. |
| Need a transparent background | "… on a transparent background." via the `gpt-image-transparent` skill. Don't ask for a shadow or floor. |
| Output is a side-by-side collage of the inputs | Give every input a role in the prompt; drop references the edit doesn't need. |
| Layout drifts in long edit chains | Re-paste the preserve list verbatim each turn; attach the latest output as Image 1. |
| Slow generation | Simplify the prompt; fewer inputs; run batches in the background. |
| Unexpected refusal | Avoid named public figures, brand likenesses, copyrighted characters, sexual content, political imagery of real people; reframe as generic or ownable. |
| Codex changed the prompt | The wrapper writes `<output>.revised_prompt.txt`; tighten ambiguous wording and rerun. |

## L. Shape and size

The wrapper's `--size WxH` is a shape hint: square, portrait or landscape with an aspect ratio. Codex
picks the exact pixels (for example 1254x1254 for square). Useful hints:

| Use | Hint |
|---|---|
| Social post, avatar, logo, icon | `1024x1024` (square) |
| Ad, banner, hero, slide, infographic | `1536x1024` (landscape) |
| Portrait of a person, poster, story | `1024x1536` (portrait) |
| Wide banner | `2048x1152` (16:9) |
| Phone wallpaper, vertical video frame | `1152x2048` (9:16) |

Supported ratios run from 3:1 to 1:3. Check real dimensions with `sips -g pixelWidth -g pixelHeight`
and crop or resize afterwards when an exact size is required.

## M. Caveats

- No documented maximum prompt length; very long prompts invite contradictions.
- Recurring characters and brand elements can still drift between images; anchor them with reference files.
- Strict layout-sensitive placement and very small text remain the weakest areas.
- The model's knowledge has a cutoff; for recent products, people's looks or brand designs, supply a reference image.
- Generations can take up to a couple of minutes for complex prompts.
