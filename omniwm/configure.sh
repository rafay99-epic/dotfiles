#!/usr/bin/env bash
# =============================================================================
# OmniWM — Pre-configure via defaults write
# =============================================================================
#
# OmniWM is GUI-configured, but settings are stored in com.barut.OmniWM plist.
# This script pre-seeds sensible defaults so OmniWM is ready after install.
#
# Run:  ./configure.sh          — apply settings
#       ./configure.sh --export — save current OmniWM settings to backup.plist
#       ./configure.sh --import — restore settings from backup.plist
#
# =============================================================================

set -euo pipefail

DOMAIN="com.barut.OmniWM"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="$SCRIPT_DIR/backup.plist"

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'
  BOLD='\033[1m'; RESET='\033[0m'
else
  GREEN=''; BLUE=''; YELLOW=''; BOLD=''; RESET=''
fi

info()    { echo -e "  ${BLUE}→${RESET}  $*"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }

# ── Export current settings ───────────────────────────────────────────────────
if [[ "${1:-}" == "--export" ]]; then
  defaults export "$DOMAIN" "$BACKUP_FILE" 2>/dev/null || {
    warn "No OmniWM settings found to export."
    exit 1
  }
  success "OmniWM settings exported to: $BACKUP_FILE"
  echo -e "  ${BLUE}Commit this file to keep your config in version control.${RESET}"
  exit 0
fi

# ── Import saved settings ────────────────────────────────────────────────────
if [[ "${1:-}" == "--import" ]]; then
  if [[ ! -f "$BACKUP_FILE" ]]; then
    warn "No backup.plist found at: $BACKUP_FILE"
    warn "Run './configure.sh --export' first to create one."
    exit 1
  fi
  defaults import "$DOMAIN" "$BACKUP_FILE" 2>/dev/null
  success "OmniWM settings restored from: $BACKUP_FILE"
  echo -e "  ${BLUE}Restart OmniWM for changes to take effect.${RESET}"
  exit 0
fi

# ── Apply default settings ───────────────────────────────────────────────────
echo ""
echo -e "${BOLD}OmniWM — Applying configuration${RESET}"
echo ""

# Borders (match AeroSpace JankyBorders style)
defaults write "$DOMAIN" "settings.bordersEnabled" -bool true
success "Borders enabled"

# Workspace bar disabled (using SketchyBar instead)
defaults write "$DOMAIN" "settings.workspaceBar.enabled" -bool false
success "Workspace bar disabled (SketchyBar handles this)"

# Focus follows mouse off (manual focus switching)
defaults write "$DOMAIN" "settings.focusFollowsMouse" -bool false
success "Focus follows mouse: off"

# Focus follows window to monitor
defaults write "$DOMAIN" "settings.focusFollowsWindowToMonitor" -bool false
success "Focus follows window to monitor: off"

echo ""
success "OmniWM configured. Open the O menu → Settings → Hotkeys to customize keybindings."
echo ""
echo -e "  ${YELLOW}Manual steps needed in OmniWM Settings:${RESET}"
echo ""
echo -e "    ${BOLD}Layout${RESET}"
echo -e "      • Set default layout to ${BOLD}Dwindle${RESET} (BSP)"
echo ""
echo -e "    ${BOLD}Gaps${RESET}"
echo -e "      • Inner gaps: 10"
echo -e "      • Outer gaps: 10"
echo -e "      • Top gap: adjust for SketchyBar (40 for external, 8 for laptop)"
echo ""
echo -e "    ${BOLD}Hotkeys (should already match)${RESET}"
echo -e "      • Option+1-9 → switch workspace"
echo -e "      • Option+Shift+1-9 → move window to workspace"
echo -e "      • Option+Arrow Keys → focus window"
echo -e "      • Option+Shift+Arrow Keys → move window"
echo -e "      • Option+Shift+B → balance sizes"
echo -e "      • Option+Return → fullscreen"
echo ""
