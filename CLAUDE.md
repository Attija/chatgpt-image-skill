# CLAUDE.md — ChatGPT Image Skill

Claude Code plugin (and `install.sh` package) that gives Claude image generation through **Codex** on the
user's **ChatGPT subscription**. Public repo: `github.com/Attija/chatgpt-image-skill`. README for users is Dutch;
skill/agent files are English.

## Hard rules

- **Codex only.** Never add, mention or suggest an external image API, API keys, endpoints, API model IDs,
  quality tiers or prices — not even as a fallback or a "not used" note. New image models arrive through
  Codex itself; describe them only as Codex status.
- **Standard library only** for all Python (`python3`, no pip). macOS extras are optional (`sips`, Apple Vision via `swiftc`).
- **Working rules** (in every skill/agent and the README):
  1. The user's prompt is forwarded verbatim; only explicitly delegated creative work ("five different
     posters") gets newly written prompts. Job numbers only in filenames. The single fixed addition is
     `on a transparent background.` in the transparent skill.
  2. References are files (PNG/JPEG/WebP paths, `@path` in the prompt), never text descriptions.
  3. A revision edits the latest result (`--edit-target`), saved as `-v2`, `-v3`; never overwrite silently.

## Layout

| Path | What |
|---|---|
| `.claude-plugin/plugin.json`, `marketplace.json` | Plugin `chatgpt-image`, marketplace `chatgpt-image-skill`. Bump `version` in **both** for a release. |
| `skills/gptimage/` | Main skill. `bin/gpt-image-2` = wrapper around `codex exec` (Python). |
| `skills/gpt-image-prompting/` | Prompt engineering skill; `references/prompt-guide.md` (sections A–M, referenced by letter from the skill and agent). |
| `skills/gpt-image-transparent/` | Transparent PNGs. `bin/gpt-image-cutout` (finish / chroma / vision), `bin/vision-mask.swift`. |
| `agents/gpt-image-prompter.md` | Sonnet subagent, prompts only (Read/Grep/Glob). |
| `agents/cutout-inspector.md` | Sonnet subagent, judges cut-outs (Read/Bash/Glob), max 2 re-runs, PASS/FAIL report. |
| `evals/` | Trigger evals (`claude plugin eval`): `pos-*` must load gpt-image-transparent, `neg-*` must load gptimage and not the transparent skill, `agent-*` checks the inspector. |
| `install.sh` | Copies skills/agents to `~/.claude` (or `$CLAUDE_CONFIG_DIR`); backups go to `~/.claude/backups/chatgpt-image-skill/<stamp>/` (never inside `skills/`, or Claude loads duplicates). `--uninstall` removes only what it installed (marker file per skill, `ours()` signature per agent). |
| `assets/banner-v2.png` | README banner (made with this plugin). |

When adding a skill or agent: add it to `SKILLS`/`AGENTS` and to `ours()` in `install.sh`, to the README table,
to `CHANGELOG.md`, and add eval cases.

## How the pieces work

**`gpt-image-2` wrapper** — `codex exec --json --ignore-user-config --skip-git-repo-check -s read-only` in a temp dir;
reads the `image_generation_end` event from `~/.codex/sessions/**/rollout-*-<thread>.jsonl` and copies `saved_path`.
- Orchestrator policy: `auto` (no `-m`, `model_reasoning_effort="low"`), `account-default` (no overrides), or an explicit ID.
- No retries or fallbacks.
- Inputs: `--edit-target` (Image 1), then `--image`, then `@path` tokens (replaced by `Image N`).
  - A token naming an already attached file reuses that file's number.
  - An `@…png` token that cannot be parsed is an error, never silently left in the prompt.
  - URLs like `…/@user/pic.png` are ignored.
  - `--size`, the paths and the JPEG converter are all validated before Codex runs.
- Refuses an existing output without `--overwrite`.
- Writes `<out>.revised_prompt.txt` if Codex changed the prompt.
- Exit 2 = arguments/files, 3 = Codex missing or not logged in.
- The default timeout is 540 s, below the 600 s Bash timeout the skill recommends.

**`gpt-image-cutout`** — own PNG reader/writer (zlib, filters 0–4; output uses the Up filter).
- `auto`: `finish` when the source has alpha, otherwise `chroma`.
- `finish`:
  - alpha ≥ 245 → 255 and ≤ 4 → 0;
  - specks < 64 px are removed;
  - `fill_false_holes` makes an enclosed see-through blotch solid when it never reaches alpha 0, while real holes stay.
- `chroma`: key from the median of the border pixels.
  - Saturated keys (green, magenta, blue): global key, then unmix and despill.
  - White or grey keys: only background connected to the border is removed (flood fill through clear background, then grow 2 px). `--holes` also clears enclosed gaps.
  - A background that is not flat gives exit 4. Exit 4 also covers `--method finish` on a source without transparency, and an empty result.
- `vision`: compiles `vision-mask.swift` to `~/.cache/gpt-image-transparent/`. Exit 5 if that is unavailable or no subject is found. The handler uses `orientation: .up` so the mask matches the stored pixels, and despill is off unless `--despill`.
- Always writes `<out>.preview.png` (checkerboard | black | white) and JSON stats on stdout.

## Known Codex behaviour (tested 2026-10-10, Codex CLI 0.137.0)

- "on a transparent background." → real RGBA. Prompts without it → RGB. Edits of a transparent source stay transparent.
- Codex's alpha for the subject is 250–254 (1–2 % see-through), and its matting can leave blotches in glossy flat areas. That is why `finish` exists.
- `--size` is only a hint: it is ignored for transparent output, and with input images the result keeps the shape of Image 1.
- An edit target plus extra references can come back as a side-by-side collage unless the prompt gives each image a role.
- The image model cannot be chosen in Codex. C2PA metadata says `gpt-image`; the outputs are still from the 2.0 generation.

## Checks before committing

```bash
bash -n install.sh
python3 -m py_compile skills/gptimage/bin/gpt-image-2 skills/gpt-image-transparent/bin/gpt-image-cutout
claude plugin validate . && claude plugin validate .claude-plugin/plugin.json   # 1 expected warning: CLAUDE.md is for repo work, not plugin context
python3 skills/gptimage/bin/gpt-image-2 --check            # Codex login, no image
claude plugin eval . --runs 3 -j 4 --no-publish            # trigger evals
HOME=$(mktemp -d) ./install.sh && HOME=<same> ./install.sh --uninstall   # clean install round trip
grep -riE "api[ _-]?key|OPENAI_API|/v1/|fal\.ai|flare|sunburst|\bAPI\b" --exclude-dir=.git --exclude=CLAUDE.md .   # must be empty
```

Real generations use the user's ChatGPT usage limits. Put scratch output outside the repo, or in a
git-ignored `generated-images/`, and keep `__pycache__` out of `skills/` (`python3 -B`).
