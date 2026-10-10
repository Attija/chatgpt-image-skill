# Evals

Trigger-evals voor de plugin. Ze controleren of de juiste skill of agent laadt, niet of er een beeld gemaakt wordt.

```bash
claude plugin eval . --runs 3 -j 4 --no-publish
```

- `pos-*`: de skill `gpt-image-transparent` moet laden (transparant, zonder achtergrond, vrijstaand, achtergrond weghalen, sticker, cutout, alfakanaal).
- `neg-*`: gewone beeldverzoeken. Daar moet `gptimage` laden en `gpt-image-transparent` niet, ook niet bij "witte achtergrond" of "transparant glas".
- `agent-cutout-inspector`: het keuren van een uitsnede moet naar de agent `cutout-inspector` gaan.
