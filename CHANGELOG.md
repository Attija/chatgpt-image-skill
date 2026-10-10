# Changelog

## 1.1.1 — 2026-10-10

- Evals vereenvoudigd tot één lijst, `evals/trigger-evals.json`: 4 korte zinnen die moeten triggeren (transparante achtergrond, zonder achtergrond, uitgeknipt, achtergrond weghalen) en 3 die dat niet moeten doen.
- Runner `evals/run_triggers.py` in standaard Python: hij stopt bij de eerste skill-aanroep en maakt geen beelden. Resultaat: 7/7 in ~30 s.
- De 12 mappen voor `claude plugin eval` zijn verwijderd.
- Transparant- en prompt-skill verwijzen naar de wrapper via `${CLAUDE_SKILL_DIR}/../gptimage/bin/gpt-image-2`.

## 1.1.0 — 2026-10-10

- Nieuwe skill `gpt-image-transparent`: Codex levert met "on a transparent background." een echt alpha-kanaal (12/12 getest). Daarna volgt `gpt-image-cutout` (pure Python):
  - alpha 250–254 → 255;
  - restwaas → 0;
  - doorschijnende vlekken in vlakken dicht, echte gaten open;
  - preview op schaakbord, zwart en wit.
- Terugval voor beelden zonder alpha: chroma-key met despill (bij wit of grijs alleen de aan de rand verbonden achtergrond), of Apple Vision (`--method vision`, macOS 14+).
- Nieuwe agent `cutout-inspector` (Sonnet): keurt uitsneden met een rubriek van 7 punten, max. 2 herpogingen, PASS/FAIL.
- Fixes na de review:
  - `@pad` wordt herkend tussen aanhalingstekens, `**…**`, `<…>` en voor een gedachtestreepje; URL's met `/@user/` worden genegeerd, en een onleesbare `@…png` geeft een fout in plaats van stil te verdwijnen;
  - een `@`-bestand dat ook edit-target is, krijgt hetzelfde nummer;
  - `--size` en de JPEG-converter worden gecontroleerd vóór generatie;
  - timeout 540 s;
  - `--quality` is verwijderd;
  - een oude `.revised_prompt.txt` wordt opgeruimd.
- `gpt-image-cutout`:
  - de preview kan de bron niet meer overschrijven;
  - ongeldige getallen geven exit 2;
  - 1/2/4/16-bit-PNG's werken, interlaced via sips;
  - `source_has_alpha` betekent echte transparantie;
  - Vision houdt rekening met EXIF-rotatie, en despill staat bij Vision standaard uit (`--despill`).
- `CLAUDE.md` met de opbouw, de harde regels en de controles, zodat een nieuwe Claude Code-sessie alles snel vindt.
- `gptimage`, de prompt-skill en `gpt-image-prompter` verwijzen bij transparantie naar de nieuwe skill.

## 1.0.0 — 2026-10-10

- Eerste publieke versie: Claude Code-plugin én `install.sh`.
- `gptimage`-skill met de Codex-wrapper `gpt-image-2`:
  - orchestrator-model `auto` / `account-default` / expliciet ID (geen vast model meer);
  - `@pad`-referenties in de prompt, `--edit-target` voor revisies, `--overwrite`-bescherming, `--check`;
  - `.jpg`-uitvoer via `sips` of ImageMagick.
- `gpt-image-prompting`-skill en `gpt-image-prompter`-agent (Sonnet), volledig Codex-gericht.
- Werkregels: prompt is leidend, referenties zijn bestanden, revisies bewerken het laatste resultaat.
