---
name: gpt-image-transparent
description: Make images with a transparent background via Codex (ChatGPT subscription) and finish them into clean RGBA PNGs, or remove the background of an existing image. Use whenever the user asks for: a transparent background / transparante achtergrond, transparant, zonder achtergrond, geen achtergrond, achtergrond weghalen / verwijderen / wegknippen, vrijstaand, uitgeknipt, freestelling, cut-out, cutout, isolated, no background, remove background, PNG with alpha / alfakanaal, or a sticker, icon, logo or product shot meant to be placed on any background. Not for a transparent object in a scene ("een transparant glas op tafel") or a white/coloured background.
---

# gpt-image-transparent

Codex's `image_generation` returns a **real alpha channel** when the prompt asks for a
transparent background (tested: 8 of 8 images, logo, product photo, fur, a leaf with holes).
Three things need fixing afterwards, and this skill does all of them:

1. The subject is never fully opaque: its alpha sits at 250–254 instead of 255, so it is
   1–2 % see-through. The finish step snaps near-opaque alpha to 255 and near-zero haze to 0,
   and keeps the soft edges (fur, anti-aliasing) as they are.
2. Codex's matting sometimes leaves a see-through blotch inside solid material (seen on a glossy
   navy logo badge). Such an enclosed area that is nowhere fully transparent is filled; real holes
   (a mug handle, gaps between leaves) reach alpha 0 and are kept. For glass, smoke or other
   see-through materials pass `--no-fill-holes`.
3. Nobody has checked the cut-out yet. The `cutout-inspector` agent judges a preview on
   checkerboard, black and white.

Tools (Python 3 standard library only):

```bash
GEN="${CLAUDE_SKILL_DIR}/../gptimage/bin/gpt-image-2"     # the gptimage wrapper (sibling skill)
CUT="${CLAUDE_SKILL_DIR}/bin/gpt-image-cutout"            # this skill
```

If `${CLAUDE_SKILL_DIR}` is not expanded, use `bin/gpt-image-cutout` in this skill's base
directory; the gptimage wrapper is `bin/gpt-image-2` in the sibling `gptimage` skill directory.

## New image with a transparent background

1. **Prompt.** Use the user's prompt (Rule 1 of the gptimage skill). If it does not already say
   so, append exactly: ` on a transparent background.` Tell the user you added it; this is the
   only addition this skill makes. Do not add other words.
2. **Generate** the Codex original as `<name>.source.png`:
   ```bash
   mkdir -p generated-images
   python3 "$GEN" "<prompt> on a transparent background." "$PWD/generated-images/<name>.source.png"
   ```
   Codex picks the canvas size to fit the subject; `--size` is ignored for transparent output.
   Reference images work as in the gptimage skill (`@path` in the prompt, `--image`), and they must be files (Rule 2).
3. **Finish:**
   ```bash
   python3 "$CUT" "$PWD/generated-images/<name>.source.png" "$PWD/generated-images/<name>.png" [--trim]
   ```
   `auto` sees the alpha channel and runs `finish`. It writes `<name>.png`, `<name>.preview.png`
   and prints JSON stats.
4. **Inspect:** hand the output, preview and stats to the `cutout-inspector` agent (or, without
   subagents, `Read` the preview yourself with its rubric). Report its verdict to the user.
5. If the stats say `"source_has_alpha": false` (no alpha channel, or one that is opaque everywhere), Codex returned no transparency. Do not retry
   automatically. Use the fallback below, or ask the user whether to regenerate.

## Revisions (Rule 3)

Edit the **Codex original** of the latest version, not the finished file:

```bash
python3 "$GEN" "<change>. Keep the transparent background." "$PWD/generated-images/<name>-v2.source.png" \
  --edit-target "$PWD/generated-images/<name>.source.png"
python3 "$CUT" "$PWD/generated-images/<name>-v2.source.png" "$PWD/generated-images/<name>-v2.png"
```

Tested: edits of a transparent original stay transparent, with the same canvas size.

## Background removal for an image without alpha (fallback)

```bash
python3 "$CUT" <image> "$PWD/generated-images/<name>.png"                  # auto -> chroma
python3 "$CUT" <image> "$PWD/generated-images/<name>.png" --method vision  # macOS 14+
```

- **chroma** measures the background colour on the image border.
  - With a saturated key (green, magenta, blue), every key-coloured pixel goes, holes included, and the edges are unmixed and despilled.
  - With a white or grey background, only background connected to the border goes, so white parts inside the subject stay. Add `--holes` to also clear enclosed gaps (a mug handle).
  - A background that is not flat stops with exit 4.
- **vision** uses Apple Vision's foreground mask (macOS 14+, compiles `vision-mask.swift` once with `swiftc` from the Xcode Command Line Tools). Use it for busy backgrounds and photos. Exit 5 when it is unavailable or finds no subject.
- If neither works, offer to regenerate the subject on a transparent background, or put it on a flat chroma background with an edit, after the user agrees.

## Options

| Option | Meaning |
|---|---|
| `--method auto\|finish\|chroma\|vision` | See above; `auto` = finish when the source has alpha, else chroma. |
| `--trim [PAD]` | Crop to the subject plus PAD px (default 8). |
| `--opaque-from N` / `--clear-below N` | Alpha snapping thresholds (default 245 / 4). |
| `--key`, `--tolerance`, `--softness`, `--holes`, `--no-despill` | chroma tuning. |
| `--despill` | vision: unmix the border colour from soft edges (off by default; only for a roughly one-colour background). |
| `--no-fill-holes` | Keep enclosed half-transparent areas (glass, smoke, tinted plastic). |
| `--min-speck PX` | Remove loose specks smaller than PX (default 64; 0 = off). |
| `--overwrite` | Allow replacing an existing output; the source can never be the output. |

Exit codes: 0 ok; 2 arguments or file; 4 not usable (background not flat, `--method finish` on a source
without transparency, or nothing left); 5 vision unavailable or no subject found.

## Notes

- The finished PNG has no C2PA provenance metadata (it is re-encoded); the `.source.png` keeps it.
- Fully transparent pixels are stored as black with alpha 0, so no hidden colour is left behind.
- Glass, smoke and similar see-through materials: Codex's alpha decides; check the preview on black and white.
