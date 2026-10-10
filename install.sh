#!/usr/bin/env bash
# Installeert de ChatGPT Image Skill (gptimage + gpt-image-prompting + gpt-image-prompter)
# in je Claude Code-map. Gebruik:  ./install.sh            installeren / bijwerken
#                                 ./install.sh --uninstall  verwijderen
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS=(gptimage gpt-image-prompting)
AGENTS=(gpt-image-prompter.md)
MARKER=".installed-by-chatgpt-image-skill"
AGENT_SIGNATURE="Codex image generator (gptimage skill"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/backups/chatgpt-image-skill/$STAMP"

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }

uninstall() {
  say "ChatGPT Image Skill verwijderen uit $CLAUDE_DIR"
  for s in "${SKILLS[@]}"; do
    target="$CLAUDE_DIR/skills/$s"
    if [[ -f "$target/$MARKER" ]]; then
      rm -rf "$target"; ok "skill $s verwijderd"
    elif [[ -e "$target" ]]; then
      warn "skills/$s is niet door dit script geïnstalleerd; laat ik staan"
    fi
  done
  for a in "${AGENTS[@]}"; do
    target="$CLAUDE_DIR/agents/$a"
    if [[ -f "$target" ]] && grep -q "$AGENT_SIGNATURE" "$target"; then
      rm -f "$target"; ok "agent ${a%.md} verwijderd"
    elif [[ -e "$target" ]]; then
      warn "agents/$a is niet door dit script geïnstalleerd; laat ik staan"
    fi
  done
  if [[ -d "$CLAUDE_DIR/backups/chatgpt-image-skill" ]]; then
    say "Back-ups van eerdere versies staan nog in $CLAUDE_DIR/backups/chatgpt-image-skill/ (niet aangeraakt)."
  fi
}

backup() {
  local path="$1"
  if [[ -e "$path" ]]; then
    # buiten skills/ en agents/, anders laadt Claude Code de back-up als dubbele skill
    mkdir -p "$BACKUP_DIR/$2"
    mv "$path" "$BACKUP_DIR/$2/"
    warn "bestaande $2/$(basename "$path") verplaatst naar $BACKUP_DIR/$2/"
  fi
}

install() {
  say "ChatGPT Image Skill installeren in $CLAUDE_DIR"

  say "1. Vereisten"
  if command -v python3 >/dev/null 2>&1; then
    ok "python3 $(python3 -c 'import sys; print(sys.version.split()[0])')"
  else
    warn "python3 ontbreekt. Installeer Python 3 en draai dit script opnieuw."; exit 1
  fi
  if command -v codex >/dev/null 2>&1; then
    ok "codex $(codex --version 2>/dev/null | head -1)"
  else
    warn "codex CLI ontbreekt. Installeer met:  brew install codex   of   npm i -g @openai/codex"
    warn "De skills worden wel geïnstalleerd; beelden maken lukt pas na installatie + codex login."
  fi

  say "2. Bestanden kopiëren"
  mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"
  for s in "${SKILLS[@]}"; do
    target="$CLAUDE_DIR/skills/$s"
    if [[ -f "$target/$MARKER" ]]; then
      rm -rf "$target"          # eigen eerdere installatie: gewoon bijwerken
    else
      backup "$target" skills
    fi
    cp -R "$REPO_DIR/skills/$s" "$target"
    touch "$target/$MARKER"
    ok "skill $s"
  done
  for a in "${AGENTS[@]}"; do
    target="$CLAUDE_DIR/agents/$a"
    if [[ -f "$target" ]] && ! grep -q "$AGENT_SIGNATURE" "$target"; then
      backup "$target" agents
    fi
    cp "$REPO_DIR/agents/$a" "$target"
    ok "agent ${a%.md}"
  done
  chmod +x "$CLAUDE_DIR/skills/gptimage/bin/gpt-image-2"

  if [[ -f "$CLAUDE_DIR/plugins/installed_plugins.json" ]] \
     && grep -q '"chatgpt-image@' "$CLAUDE_DIR/plugins/installed_plugins.json"; then
    warn "De plugin chatgpt-image is óók geïnstalleerd. Kies één van beide om dubbele skills te voorkomen"
    warn "(/plugin uninstall chatgpt-image  of  ./install.sh --uninstall)."
  fi

  say "3. Codex controleren"
  if python3 "$CLAUDE_DIR/skills/gptimage/bin/gpt-image-2" --check; then
    ok "klaar om beelden te maken"
  else
    warn "Nog niet klaar: log in met  codex login  → 'Sign in with ChatGPT' en controleer met:"
    warn "  python3 \"$CLAUDE_DIR/skills/gptimage/bin/gpt-image-2\" --check"
  fi

  say ""
  say "Klaar. Start Claude Code opnieuw en vraag bijvoorbeeld: \"maak een afbeelding van een rode fiets tegen een witte muur\"."
}

case "${1:-}" in
  --uninstall) uninstall ;;
  ""|--install) install ;;
  -h|--help) sed -n '2,4p' "$0" ;;
  *) say "Onbekende optie: $1 (gebruik --uninstall of --help)"; exit 2 ;;
esac
