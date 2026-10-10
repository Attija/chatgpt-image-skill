---
name: gptimage
description: Give Claude Code image generation via Codex (the image_generation tool on the user's ChatGPT subscription). Whenever the user asks for an image, a mockup, a visual reference, a diagram, a design, a logo, an avatar, an illustration, an edit of an image, or any other kind of picture, use the bundled wrapper script to generate it.
---

# gptimage

Claude Code has no native image generation tool. This skill bridges that gap with a small
wrapper that runs `codex exec`, which calls Codex's `image_generation` tool on the ChatGPT
account the user is logged in with. The image is copied to the path you specify; you then
`Read` it back into context.

**Codex is the only route.** If Codex fails, report the Codex error to the user as-is. Do
not retry automatically, do not switch to another service, and do not suggest one.

## The wrapper

```bash
python3 "${CLAUDE_SKILL_DIR}/bin/gpt-image-2" "<prompt>" <output.png> [options]
```

If `${CLAUDE_SKILL_DIR}` is not expanded in your context, use the `bin/gpt-image-2` file
inside this skill's base directory (shown when the skill loads).

| Option | Meaning |
|---|---|
| `--edit-target PATH` | The image to edit. It is sent as **Image 1**. |
| `--image PATH` | A reference image (repeatable), numbered after the edit target. |
| `@path/to/file.png` in the prompt | Also attached as a reference; the token is replaced by `Image N` in the prompt that is sent. This is the only change the wrapper makes to a prompt. |
| `--size WxH` or `auto` | Shape hint only (square / portrait / landscape). Codex picks the pixels and, with input images, usually keeps the shape of Image 1; check with `sips -g pixelWidth -g pixelHeight` when it matters. |
| `--overwrite` | Allow replacing an existing output. Without it the wrapper refuses (exit 2). |
| `--orchestrator-model` | `auto` (default: Codex picks a current model for the account, low reasoning), `account-default` (no overrides at all), or an explicit model ID the user asked for. |
| `--timeout SEC` | Default 900. |
| `--check` | Verify python3 + Codex ChatGPT login without generating. |

- Inputs must be readable `.png`, `.jpg`, `.jpeg` or `.webp` files. Output ends in `.png` (or `.jpg`/`.jpeg`).
- A generation takes 30 s to a few minutes. Set the Bash timeout to **600000 ms**, or use `run_in_background` for batches and multi-image edits.
- Success: the absolute output path on stdout. Failure: the Codex error on stderr; exit 2 = bad arguments or input files, exit 3 = Codex missing or not logged in with ChatGPT.
- If Codex used a different prompt than the one sent, the wrapper warns and writes `<output>.revised_prompt.txt`. Tell the user.

After the wrapper returns, `Read` the image back so you can check it before responding.

## Rule 1 — The prompt is authoritative, and so is delegated creative intent

- **One image or one edit:** forward the user's request unchanged. Text between quotes wins;
  without quotes, the request itself is the prompt. Do not "improve" a short prompt with
  unsolicited style, lighting, composition or detail, and do not translate it.
- **Delegated creative work** ("make five different poster designs", "give me three logo
  directions"): the user explicitly asks you to develop concepts. Write one complete,
  meaningfully different prompt per output. Every prompt keeps the shared subject,
  references, brand, literal text, aspect ratio and other constraints.
- **Job numbers live in IDs and filenames** (`poster-03.png`), never inside an image prompt.
- **Prompt engineering on request:** when the user asks for a better or engineered prompt,
  use the `gpt-image-prompting` skill or the `gpt-image-prompter` agent. Once the user
  approves that prompt, pass it verbatim.

## Rule 2 — References are files, not descriptions

- Every reference must be a readable local PNG, JPEG or WebP path that is actually passed
  to the wrapper (`--image`, `--edit-target` or `@path`).
- Never replace an unresolved reference with a text description and continue. Stop and ask
  for the file.
- Prefer `@path/to/image.png` or an explicit filesystem path. An image pasted or dragged
  into the conversation is **not** inherited by the nested `codex exec` process.
- If the host shows an exact, readable temporary path for an attachment, copy that exact
  file into `<project>/generated-images/inputs/` and use the copy. If there is no path, ask
  the user to save the image inside the project and give you the path.
- Never guess from `~/.claude/image-cache` or pick "the newest image"; that can select the
  wrong or a private file.

## Rule 3 — Revisions edit the latest result

- Every wrapper call is independent; Codex remembers nothing between calls.
- For "change the image you just made", pass the previous output as `--edit-target` and
  re-attach every reference that the change still needs (one the previous output already
  carries, such as a character it shows, is usually not needed).
- With an edit target plus extra references, the model may return a side-by-side collage of
  all inputs. When you attach references to an edit, the prompt must say which image is edited
  and what each reference is for, e.g. "Edit Image 1 … Use Image 2 only as a reference for the
  scarf's pattern." If the user's wording doesn't do that, show them the role sentence you'd add
  and get their OK (Rule 1).
- Going back to the original source is a different operation and loses the prior edit; do
  it only when the user asks for that.
- Save to `<project>/generated-images/<name>.png` unless the user names a path (create the
  folder first). Revisions get a new file: `<name>-v2.png`, `<name>-v3.png`. Never overwrite
  silently.

## Examples

```bash
W="${CLAUDE_SKILL_DIR}/bin/gpt-image-2"
mkdir -p generated-images

# text -> image
python3 "$W" "A red bicycle leaning against a white wall" "$PWD/generated-images/bicycle.png" --size 1536x1024

# reference in the prompt
python3 "$W" "Use @references/character.png as the character reference and place it in a rainy Tokyo street at night" "$PWD/generated-images/tokyo.png"

# revise the last result, keep the character reference
python3 "$W" "Make the umbrella yellow. Change nothing else." "$PWD/generated-images/tokyo-v2.png" \
  --edit-target "$PWD/generated-images/tokyo.png" --image "$PWD/references/character.png"
```

## When not to use it

- Small programmatic images (1px dots, solid placeholders, simple charts): write them with a few lines of code.
- Pixel-exact editing: use an image library.
- Transparent backgrounds are not available through Codex today. Generate on a plain, solid background and cut out afterwards.

## Model status

Codex decides which image model its `image_generation` tool uses; there is no setting to choose it. When Codex
moves to a newer image model (such as ChatGPT Images 2.5), this skill uses it automatically.

## Prerequisites (user-side)

- The `codex` CLI (`brew install codex` or `npm i -g @openai/codex`), logged in with ChatGPT:
  `codex login` → "Sign in with ChatGPT". Check with `codex login status` or `--check`.
- The ChatGPT plan must allow Codex. In Team/Business workspaces an admin may need to enable it.
- Images count toward the ChatGPT subscription's usage limits. When the limit is reached Codex returns
  an error; wait for the reset.

## Under the hood

`codex exec --json --ignore-user-config --skip-git-repo-check -s read-only` runs in a throwaway
directory with a fixed instruction: call `image_generation` exactly once with the prompt between
markers. Codex saves the image under `~/.codex/generated_images/<thread-id>/`; the wrapper reads the
matching `image_generation_end` event from `~/.codex/sessions/**/rollout-*-<thread-id>.jsonl` and copies
the file. Python 3 standard library only. Each run appears as a session in Codex's history.
