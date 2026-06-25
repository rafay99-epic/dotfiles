#!/usr/bin/env bash
# =============================================================================
# Prometheus Dotfiles — install.sh (orchestrator)
# =============================================================================
#
#  Clone the repo, run this script, pick which modules to install.
#
#  Usage:
#    ./install.sh                         — interactive module picker
#    ./install.sh --dry-run               — preview everything, no changes
#    ./install.sh --yes                   — run ALL modules, auto-Y every prompt
#    ./install.sh --only=symlinks,macos   — run only these modules
#    ./install.sh --skip=wm,homebrew      — run everything EXCEPT these
#    ./install.sh --reconfigure           — re-run the config wizard (re-asks
#                                           every question, overwrites
#                                           ~/.config/dotfiles/local.env)
#    ./install.sh --modules               — print module list and exit
#    ./install.sh --man                   — open the full man page
#    ./install.sh --help                  — show this message
#
#  Env var (CI-friendly equivalent of --only):
#    INSTALL_MODULES=symlinks,macos ./install.sh
#
#  Remote one-liner (bootstraps clone + runs this script):
#    curl -fsSL https://dotfiles.rafay99.com/install.sh | bash
#
#  Layout:
#    install.sh              — this orchestrator
#    install.d/00-lib.sh     — shared helpers (colors, logging, link, brew_*…)
#    install.d/01-menu.sh    — module catalog + interactive picker
#    install.d/05-configure.sh — first-run + --reconfigure wizard (writes
#                                ~/.config/dotfiles/local.env)
#    install.d/10-prereqs.sh — macOS check, Xcode CLT, banner
#    install.d/20-homebrew.sh — Homebrew + Brewfile + Node + Bun
#    install.d/30-wm.sh      — Window manager choice (omniwm/aerospace/none)
#    install.d/40-shells.sh  — fzf-tab and other shell plugins
#    install.d/50-apps.sh    — Optional GUI apps (Ghostty, Cursor, …)
#    install.d/60-symlinks.sh — All dotfile symlinks
#    install.d/70-launchd.sh — Time Machine + NAS auto-mount LaunchAgents
#    install.d/80-macos.sh   — defaults write tweaks
#    install.d/90-sketchybar.sh — Restart SketchyBar (if applicable)
#
#  Each install.d/<NN-name>.sh defines a single function `module_<name>()`
#  that does the work. This orchestrator sources them in order and calls
#  each module IFF it's in the selected set (see `should_run` in 01-menu.sh).
#
# =============================================================================

set -Euo pipefail
IFS=$'\n\t'

# ── Global state ──────────────────────────────────────────────────────────────
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
YES_ALL=false
# shellcheck disable=SC2034
# (SC2034: RECONFIGURE *is* read — by install.d/05-configure.sh, which is
# sourced dynamically below. The static checker can't see across that boundary.)
RECONFIGURE=false         # --reconfigure → re-prompt wizard, overwrite local.env
INSTALL_APPS=false
WM_CHOICE="none"          # none | omniwm | aerospace
ERRORS=()
SKIPPED=()
LINKED=()
INSTALLED=()

# Selection mode: how the module list was chosen.
#   "menu"  — interactive picker (default when no flags given)
#   "only"  — --only=… or $INSTALL_MODULES
#   "skip"  — --skip=…
#   "yes"   — --yes (= run all)
SELECTION_MODE="menu"

# ── Shared library + module catalog ──────────────────────────────────────────
# shellcheck source=install.d/00-lib.sh
source "$DOTFILES/install.d/00-lib.sh"
# shellcheck source=install.d/01-menu.sh
source "$DOTFILES/install.d/01-menu.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
print_help() {
  sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
  print_module_list
  echo ""
}

ONLY_CSV=""
SKIP_CSV=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=true ;;
    --yes|-y)         YES_ALL=true; SELECTION_MODE="yes" ;;
    --reconfigure)    RECONFIGURE=true ;;
    --modules)        print_module_list; exit 0 ;;
    --only=*)         ONLY_CSV="${arg#--only=}"; SELECTION_MODE="only" ;;
    --skip=*)         SKIP_CSV="${arg#--skip=}"; SELECTION_MODE="skip" ;;
    --man)
      if [[ ! -r "$DOTFILES/man/install.1" ]]; then
        error "Man page not found at $DOTFILES/man/install.1"
        exit 1
      fi
      # macOS's BSD `man` accepts an absolute path directly — no `-l` flag
      # needed (and not supported). On Linux, `man` also accepts a path
      # argument as of recent versions, so this form is portable. Fall back
      # to `mandoc` (always on macOS) if `man` rejects the file for any reason.
      if ! exec man "$DOTFILES/man/install.1" 2>/dev/null; then
        exec mandoc "$DOTFILES/man/install.1" | ${PAGER:-less -R}
      fi
      ;;
    --help|-h)        print_help; exit 0 ;;
    *) error "Unknown argument: $arg"; echo "Try: ./install.sh --help" >&2; exit 1 ;;
  esac
done

# Env-var equivalent of --only — only honored when no other selection flag set.
if [[ -n "${INSTALL_MODULES:-}" && "$SELECTION_MODE" == "menu" ]]; then
  ONLY_CSV="$INSTALL_MODULES"
  SELECTION_MODE="only"
fi

# --only and --skip are mutually exclusive
if [[ -n "$ONLY_CSV" && -n "$SKIP_CSV" ]]; then
  error "--only and --skip are mutually exclusive"
  exit 1
fi

# ── Prereqs (always run, never optional) ──────────────────────────────────────
# shellcheck source=install.d/10-prereqs.sh
source "$DOTFILES/install.d/10-prereqs.sh"
module_prereqs

# ── Configure (always run — fast no-op if config exists and not --reconfigure)
# The wizard writes ~/.config/dotfiles/local.env on first install (or when
# --reconfigure is passed). Later modules read it via bin/lib/dotfiles-config.sh
# to gate themselves on $HAS_NAS, $HAS_TIMEMACHINE_NAS, etc.
# shellcheck source=install.d/05-configure.sh
source "$DOTFILES/install.d/05-configure.sh"
module_configure

# ── Resolve module selection ─────────────────────────────────────────────────
case "$SELECTION_MODE" in
  only)
    set_selection_from_csv "$ONLY_CSV"
    info "Selected (--only): $(selected_summary)"
    ;;
  skip)
    apply_skip_csv "$SKIP_CSV"
    info "Selected (--skip): $(selected_summary)"
    ;;
  yes)
    select_all
    info "Selected (--yes): $(selected_summary)"
    ;;
  menu|*)
    interactive_module_menu
    ;;
esac

# INSTALL_APPS is derived from whether the homebrew module was picked.
# 50-apps and 90-sketchybar both read it.
if should_run homebrew; then
  INSTALL_APPS=true
fi

# =============================================================================
# Run modules in display order — each gated on should_run
# =============================================================================
# Module order is the same as the catalog in 01-menu.sh, EXCEPT for two
# real-world dependencies that pin a different ordering:
#   - wm runs before homebrew (so WM_CHOICE is set when Brewfile.<wm> needs it)
#   - sketchybar runs last (needs both packages and symlinks in place)

if should_run wm; then
  # shellcheck source=install.d/30-wm.sh
  source "$DOTFILES/install.d/30-wm.sh"
  module_wm
fi

if should_run homebrew; then
  # shellcheck source=install.d/20-homebrew.sh
  source "$DOTFILES/install.d/20-homebrew.sh"
  module_homebrew
fi

if should_run apps; then
  # shellcheck source=install.d/50-apps.sh
  source "$DOTFILES/install.d/50-apps.sh"
  module_apps
fi

if should_run macos; then
  # shellcheck source=install.d/80-macos.sh
  source "$DOTFILES/install.d/80-macos.sh"
  module_macos
fi

if should_run symlinks; then
  # shellcheck source=install.d/60-symlinks.sh
  source "$DOTFILES/install.d/60-symlinks.sh"
  module_symlinks
fi

if should_run launchd; then
  # shellcheck source=install.d/70-launchd.sh
  source "$DOTFILES/install.d/70-launchd.sh"
  module_launchd
fi

if should_run shells; then
  # shellcheck source=install.d/40-shells.sh
  source "$DOTFILES/install.d/40-shells.sh"
  module_shells
fi

if should_run sketchybar; then
  # shellcheck source=install.d/90-sketchybar.sh
  source "$DOTFILES/install.d/90-sketchybar.sh"
  module_sketchybar
fi

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
