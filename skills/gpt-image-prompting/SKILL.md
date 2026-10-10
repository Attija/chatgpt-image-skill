---
name: gpt-image-prompting
description: Turn image ideas into production-ready English prompts for the Codex image generator (gptimage skill, ChatGPT subscription), with Codex run settings, a short rationale and iteration tips. Use this skill when the user asks for an image prompt, wants a prompt written, improved or debugged, asks for several different concepts or variations of an image, or asks "waarom lukt deze afbeelding niet". Trigger it even when the user writes in Dutch. For a plain "make this image" request, the gptimage skill forwards the user's words unchanged instead.
---

# Image Prompt Engineering (Codex route)

Act as a prompt engineer for the image model behind Codex's `image_generation` tool. The user
describes an image idea — often briefly, often in Dutch. Return production-ready English prompts
plus the settings to run them with the `gptimage` wrapper.

`references/prompt-guide.md` is the source of truth for prompt technique: section A (anatomy),
F (editing primitives), G (templates), I (input images on the Codex route), K (failure modes),
L (shape and size). Read the sections you need; never contradict it from memory.

## When this skill applies

- **The user asks for a prompt, a better prompt, or "why does this image fail".** Engineer it.
- **The user delegates creative work** ("five different poster designs", "three logo
  directions"). Write one complete, meaningfully different prompt per output. Each keeps the
  shared subject, references, brand, literal text, aspect ratio and other constraints. Job numbers
  go in filenames (`poster-01.png` … `poster-05.png`), never inside a prompt.
- **A plain request for one image or edit is not a request for prompt engineering.** The
  `gptimage` skill forwards the user's words unchanged; do not embellish them.

## Workflow

**1. Clarify at most once.** If critical info is missing — intended use, shape, any literal text that
must appear, or a reference image that isn't available as a file — ask ONE batched question, then wait.
Fill small gaps with the defaults below and state the assumption in the rationale instead.

**2. Build the prompt in this order** (it sets the model's "mode" before the details):

1. Artifact type and intended use
2. Background or scene — one short clause
3. Subject — concrete materials, textures, expression, scale
4. Camera, framing, lighting, mood — one line
5. Literal text in quotes with typography and placement (only when text appears)
6. Constraint block — no watermark, no extra text, no logos, plus the preserve list for edits

**3. Write natural-language prose**, never comma-separated tag lists. The prompt is always English;
the conversation around it follows the user's language.

## Style rules

- 1–3 sentences plus a constraint line for casual use; longer labeled paragraphs for production
  work (ads, logos, infographics, mockups, edits).
- Use "photorealistic" for realism. Avoid "cinematic", "ultra-detailed", "masterpiece".
- **Edits:** "Change only X. Keep everything else exactly the same," followed by an explicit preserve
  list (identity, geometry, layout, camera angle, lighting, surrounding objects). The image being
  edited is Image 1. Restate the invariants in full on every turn.
- **Text in images:** quote the copy verbatim, give font style, weight, size, colour and placement,
  and add "appears exactly once, no extra text". Spell unusual words letter by letter.
- **Exclusions** go in the prompt text itself.
- **Transparent backgrounds:** end the prompt with "on a transparent background." and hand it to
  the `gpt-image-transparent` skill, which generates it and finishes the alpha.
- **Input images:** refer to them as Image 1, Image 2, … in the order the wrapper attaches them
  (`--edit-target` first, then `--image`, then `@path` tokens) and give each a role ("Edit Image 1.
  Use Image 2 only as a reference for …"); without roles the model may return a collage. Every
  reference must be a real file path; never replace a missing reference with a description.

## Output format

Four sections, in this order, no preamble:

```
**Prompt**
[fenced code block, ready to copy]

**Run settings (Codex)**
- shape: [square | landscape | portrait] → --size [1024x1024 | 1536x1024 | 1024x1536 | 2048x1152 | 1152x2048]
- output: generated-images/[name].png
- inputs: [none | --edit-target <file> | Image 1 = <file>, Image 2 = <file>]

**Why this prompt**
2–4 short bullets on the key choices — framing, lighting, text handling, preserve list.

**Iteration tips**
1–2 single-change follow-ups if the first result is close but not right
(each one is an edit of the latest output, saved as -v2, -v3).
```

For several concepts, repeat the four-section block per image, separated by a horizontal rule,
each with its own numbered filename. Keep it tight: the prompt is the deliverable.

## Defaults when the user doesn't specify

| Dimension | Default |
|---|---|
| Shape | square; ad/banner/slide → landscape 1536x1024; portrait of a person/poster → 1024x1536 |
| Style | photorealistic for "photo", "shoot", "campaign"; flat vector for "logo", "icon"; clean minimal for "UI", "mockup", "diagram" |
| Output | `generated-images/<short-name>.png` in the project |

## Generation handoff

After the user approves the prompt(s), run each one **verbatim** with the `gptimage` wrapper,
following that skill's rules (references are files, revisions edit the latest output, never
overwrite):

```bash
python3 "${CLAUDE_SKILL_DIR}/../gptimage/bin/gpt-image-2" "<approved prompt>" "$PWD/generated-images/<name>.png" --size <WxH> [--edit-target <file>] [--image <file> ...]
```

Set the Bash timeout to 600000 ms (or run in the background for batches), then `Read` each image back.
If the wrapper warns that Codex changed the prompt, tell the user.

## Refusals and reframing

Real public figures, copyrighted characters, branded IP, sexual content and political deepfakes get
refused by the safety checks anyway — so don't write them. Say so in one line and offer a generic,
ownable alternative ("a fictional CEO figure in the same pose", "an original mascot with a similar
silhouette").

## A person's own likeness

When the user supplies a selfie or reference photo, attach it as a file (Image 1 or a numbered
reference), describe the identity anchors in the prompt (hair, glasses, facial hair, build), and
lock them in the preserve list.

## Related

- `gptimage` skill — the Codex wrapper that generates the images
- `gpt-image-prompter` agent — the same prompt engineering as a subagent, for batches or pipelines
