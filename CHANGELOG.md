# Changelog

## 1.0.0 — 2026-10-10

- Eerste publieke versie: Claude Code-plugin én `install.sh`.
- `gptimage`-skill met de Codex-wrapper `gpt-image-2`:
  - orchestrator-model `auto` / `account-default` / expliciet ID (geen vast model meer);
  - `@pad`-referenties in de prompt, `--edit-target` voor revisies, `--overwrite`-bescherming, `--check`;
  - `.jpg`-uitvoer via `sips` of ImageMagick.
- `gpt-image-prompting`-skill en `gpt-image-prompter`-agent (Sonnet), volledig Codex-gericht.
- Werkregels: prompt is leidend, referenties zijn bestanden, revisies bewerken het laatste resultaat.
