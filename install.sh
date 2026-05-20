#!/usr/bin/env bash
# =============================================================================
# Prometheus Dotfiles — install.sh (orchestrator)
# =============================================================================
#
#  Clone the repo, run this script, answer the prompts. That's it.
#
#  Usage:
#    ./install.sh            — interactive install
#    ./install.sh --dry-run  — preview everything without making changes
#    ./install.sh --help     — show this message
#
#  Remote one-liner (bootstraps clone + runs this script):
#    curl -fsSL https://dotfiles.rafay99.com/install.sh | bash
#
#  Layout:
#    install.sh              — this orchestrator (~120 lines)
#    install.d/00-lib.sh     — shared helpers (colors, logging, link, brew_*…)
#    install.d/10-prereqs.sh — macOS check, Xcode CLT, banner
#    install.d/20-homebrew.sh — Homebrew + Brewfile + Node + Bun
#    install.d/30-wm.sh      — Window manager choice (omniwm/aerospace/none)
#    install.d/40-shells.sh  — fzf-tab and other shell plugins
#    install.d/50-apps.sh    — Optional GUI apps (Ghostty, Cursor, …)
#    install.d/60-symlinks.sh — All dotfile symlinks
#    install.d/70-launchd.sh — Time Machine + sort-downloads LaunchAgents
#    install.d/80-macos.sh   — defaults write tweaks
#    install.d/90-sketchybar.sh — Restart SketchyBar (if applicable)
#
#  Each install.d/<NN-name>.sh defines a single function `module_<name>()`
#  that does the work. This orchestrator sources them in order and calls
#  each module sequentially.
#
# =============================================================================

set -Euo pipefail
IFS=$'\n\t'

# ── Global state ──────────────────────────────────────────────────────────────
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
INSTALL_APPS=false
WM_CHOICE="none"          # none | omniwm | aerospace
ERRORS=()
SKIPPED=()
LINKED=()
INSTALLED=()

# ── Shared library (colors, logging, prompt, link, brew_*, npm_install, …) ───
# Defined in install.d/00-lib.sh so modules can use the same helpers.
# Must be sourced AFTER the globals above are set (they're referenced inside).
# shellcheck source=install.d/00-lib.sh
source "$DOTFILES/install.d/00-lib.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo ""
      echo "Usage: ./install.sh [--dry-run] [--help]"
      echo ""
      echo "  --dry-run   Preview all changes without making them"
      echo "  --help      Show this message"
      echo ""
      exit 0
      ;;
    *) error "Unknown argument: $arg"; exit 1 ;;
  esac
done

# =============================================================================
# Run modules in order
# =============================================================================
# 10-prereqs runs first — it does the macOS / Xcode / git checks AND prints
# the banner. After that, ask the top-level "install core packages?" question
# which gates the homebrew module. Everything else runs unconditionally for
# now (Phase 3 of the refactor will add the module-selection menu).
# shellcheck source=install.d/10-prereqs.sh
source "$DOTFILES/install.d/10-prereqs.sh"
module_prereqs

# Top-level: do you want core packages installed?
if prompt "Install Homebrew and core packages?"; then
  INSTALL_APPS=true
else
  info "Skipping package installation — will only set up symlinks."
fi

# WM choice (always asked — sets WM_CHOICE which other modules read)
# shellcheck source=install.d/30-wm.sh
source "$DOTFILES/install.d/30-wm.sh"
module_wm

# Homebrew + core packages (self-gates on INSTALL_APPS)
# shellcheck source=install.d/20-homebrew.sh
source "$DOTFILES/install.d/20-homebrew.sh"
module_homebrew

# Optional apps (per-app Y/N prompts)
# shellcheck source=install.d/50-apps.sh
source "$DOTFILES/install.d/50-apps.sh"
module_apps

# macOS preferences (defaults write)
# shellcheck source=install.d/80-macos.sh
source "$DOTFILES/install.d/80-macos.sh"
module_macos

# Symlinks (the core of dotfiles management)
# shellcheck source=install.d/60-symlinks.sh
source "$DOTFILES/install.d/60-symlinks.sh"
module_symlinks

# LaunchAgents (TM monthly + sort-downloads)
# shellcheck source=install.d/70-launchd.sh
source "$DOTFILES/install.d/70-launchd.sh"
module_launchd

# Shell plugins (fzf-tab)
# shellcheck source=install.d/40-shells.sh
source "$DOTFILES/install.d/40-shells.sh"
module_shells

# SketchyBar restart (last — needs both packages and symlinks in place)
# shellcheck source=install.d/90-sketchybar.sh
source "$DOTFILES/install.d/90-sketchybar.sh"
module_sketchybar

# =============================================================================
# Summary
# =============================================================================
heading "Summary"
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  echo -e "  ${GREEN}Installed (${#INSTALLED[@]})${RESET}"
  for item in "${INSTALLED[@]}"; do echo "    • $item"; done
  echo ""
fi

if [[ ${#LINKED[@]} -gt 0 ]]; then
  echo -e "  ${BLUE}Linked (${#LINKED[@]})${RESET}"
  for item in "${LINKED[@]}"; do echo "    • $item"; done
  echo ""
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo -e "  ${YELLOW}Already up to date (${#SKIPPED[@]})${RESET}"
  for item in "${SKIPPED[@]}"; do echo "    • $item"; done
  echo ""
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "  ${RED}Errors (${#ERRORS[@]}) — action required${RESET}"
  for item in "${ERRORS[@]}"; do echo "    • $item"; done
  echo ""
  echo -e "${RED}${BOLD}Setup completed with errors. Fix the above and re-run.${RESET}"
  exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}╭──────────────────────────────────────────────╮${RESET}"
echo -e "${GREEN}${BOLD}│          All done!  Setup complete.          │${RESET}"
echo -e "${GREEN}${BOLD}│                                              │${RESET}"
echo -e "${GREEN}${BOLD}│  Open a new terminal tab and log out/back in │${RESET}"
echo -e "${GREEN}${BOLD}│  for all changes to take effect.             │${RESET}"
echo -e "${GREEN}${BOLD}╰──────────────────────────────────────────────╯${RESET}"
echo ""
