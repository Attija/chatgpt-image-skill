# CLAUDE.md — ChatGPT Image Skill

Claude Code plugin (and `install.sh` package) that gives Claude image generation through **Codex** on the
user's **ChatGPT subscription**. Public repo: `github.com/Attija/chatgpt-image-skill` (branch `main`), current
version in `.claude-plugin/plugin.json`.

Conventions:
- Talk to the maintainer in Dutch.
- `README.md`, `CHANGELOG.md` and commit messages are Dutch. Skill files, agent files and code comments are English.

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
| `evals/trigger-evals.json` | Trigger evals for gpt-image-transparent: one list of `{query, should_trigger}` (skill-creator trigger format). |
| `evals/run_triggers.py` | Runs them with `claude -p --plugin-dir .`. It only allows Skill/Read/Glob/Grep and stops at the first Skill call, so nothing is generated (~30 s, 7 queries × 3). |
| `install.sh` | Copies skills/agents to `~/.claude` (or `$CLAUDE_CONFIG_DIR`); backups go to `~/.claude/backups/chatgpt-image-skill/<stamp>/` (never inside `skills/`, or Claude loads duplicates). `--uninstall` removes only what it installed (marker file per skill, `ours()` signature per agent). |
| `assets/banner-v2.png` | README banner (made with this plugin). |
| `README.md` | Dutch user documentation: install, Codex login, usage, working rules, transparency, troubleshooting. |
| `CHANGELOG.md` | Dutch release notes, newest first. |

When adding a skill or agent: add it to `SKILLS`/`AGENTS` and to `ours()` in `install.sh`, to the README table
and to `CHANGELOG.md`.

## Evals

Trigger evals only check that `gpt-image-transparent` fires on the right sentences. Keep them simple:
- one short plain sentence per trigger phrase (transparante achtergrond, zonder achtergrond, uitgeknipt, achtergrond weghalen);
- a few near-miss negatives (witte achtergrond, transparant glas, andere achtergrond).

No directory per case and no long example prompts; the maintainer explicitly wants it this way.

- **Add a case:** add one line `{"query": "...", "should_trigger": true|false}` to `evals/trigger-evals.json`.
- **Run:** `python3 evals/run_triggers.py [--runs 3] [--workers 4] [--model M] [--json out.json]`. Exit 1 on a failure. A positive passes at ≥ 50 % of runs triggered, a negative at < 50 %.
- **Failure:** fix the `description:` in `skills/gpt-image-transparent/SKILL.md` (and the redirect sentence in `skills/gptimage/SKILL.md`), then rerun the whole list.
- **Optional:** the file uses skill-creator's trigger format, so skill-creator's `scripts/run_loop.py --eval-set evals/trigger-evals.json --skill-path skills/gpt-image-transparent` can tune the description automatically.
- **No `claude plugin eval` suite:** it needs a directory per case and doubles the cost with a baseline arm.

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
- The image model cannot be chosen in Codex. Our C2PA metadata only says `gpt-image`, without a version. Users in openai/codex #44369 / #43965 report that Codex still produces gpt-image 2.0 while ChatGPT Images 2.5 has been announced.

## Checks before committing

```bash
bash -n install.sh
python3 -c "import ast,sys; [ast.parse(open(f).read()) for f in sys.argv[1:]]" \
  skills/gptimage/bin/gpt-image-2 skills/gpt-image-transparent/bin/gpt-image-cutout evals/run_triggers.py
claude plugin validate . && claude plugin validate .claude-plugin/plugin.json   # 1 expected warning: CLAUDE.md is for repo work, not plugin context
python3 skills/gptimage/bin/gpt-image-2 --check            # Codex login, no image
python3 -B evals/run_triggers.py                            # trigger evals, must be all PASS (~30 s)
H=$(mktemp -d); HOME=$H ./install.sh && HOME=$H ./install.sh --uninstall   # clean install round trip
grep -riE "api[ _-]?key|OPENAI_API|/v1/|fal\.ai|flare|sunburst|\bAPI\b" --exclude-dir=.git --exclude=CLAUDE.md .   # must be empty
find . -name __pycache__ -not -path './.git/*'              # must be empty (never ship it in skills/)
```

There are no unit tests; the old `tests/` folder was removed on request. To change `gpt-image-cutout`:
- run it on a few real Codex RGBA outputs, at least a logo, a photo with fur and an object with a real hole;
- `Read` each `.preview.png`, or let `cutout-inspector` judge it;
- compare the JSON stats before and after.

Real generations use the user's ChatGPT usage limits, so keep them few. Put scratch output outside the repo, or in
the git-ignored `generated-images/`.

## Release

1. Bump `version` in `.claude-plugin/plugin.json` **and** `.claude-plugin/marketplace.json`.
2. Add a Dutch entry at the top of `CHANGELOG.md`; update `README.md` when behaviour or options change.
3. Run the checks above.
4. Commit (Dutch message) and push to `origin main`. Plugin users get it with `/plugin marketplace update chatgpt-image-skill`; script users with `git pull && ./install.sh`.
