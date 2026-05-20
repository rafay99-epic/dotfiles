#!/usr/bin/env bash
# =============================================================================
# Prometheus Dotfiles — install.sh
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
#  What it does:
#    1. Checks prerequisites (Xcode CLT, Homebrew, curl, git)
#    2. Core install  → shells, CLI tools, runtimes, fonts, WM, bar (auto)
#    3. Symlinks      → all dotfiles into ~/.config (always)
#    4. Optional apps → user picks which GUI/AI apps to install
#
# =============================================================================

set -Euo pipefail
IFS=$'\n\t'

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
INSTALL_APPS=false
WM_CHOICE="none"          # none | omniwm | aerospace
ERRORS=()
SKIPPED=()
LINKED=()
INSTALLED=()

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; BLUE=''; CYAN=''; BOLD=''; RESET=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo -e "  ${BLUE}→${RESET}  $*"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "  ${RED}✗${RESET}  $*"; }
heading() { echo -e "\n${BOLD}${CYAN}▸  $*${RESET}"; echo -e "  ${CYAN}$(printf '%.0s─' {1..40})${RESET}"; }
dry()     { echo -e "  ${YELLOW}(dry)${RESET} $*"; }

# ── Prompt helper ─────────────────────────────────────────────────────────────
# prompt "Question?" → returns 0 for Y, 1 for N
prompt() {
  local question="$1"
  local answer

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}(dry)${RESET} Would ask: ${BOLD}$question${RESET} → assuming Yes"
    return 0
  fi

  echo -en "\n  ${BOLD}${BLUE}?${RESET}  ${BOLD}$question${RESET} [Y/n] "
  read -r answer </dev/tty 2>/dev/null || answer="y"
  echo ""
  [[ "${answer:-y}" =~ ^[Yy]$ ]]
}

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
# Prerequisites
# =============================================================================

# ── macOS only ────────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script only supports macOS."
  exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root / sudo."
  exit 1
fi

# ── Xcode Command Line Tools ─────────────────────────────────────────────────
# Required for git, clang, make, etc. On a blank system the Xcode licence must
# be accepted and the CLT package installed before anything else works.
if ! xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools not found."
  info "Installing Xcode Command Line Tools (you may be prompted)..."
  xcode-select --install 2>/dev/null || true
  # Wait for the install to finish (GUI installer runs in background)
  echo -en "\n  ${BOLD}${BLUE}?${RESET}  ${BOLD}Press Enter after the Xcode CLT installer finishes...${RESET} "
  read -r </dev/tty 2>/dev/null || true
  if ! xcode-select -p &>/dev/null; then
    error "Xcode Command Line Tools installation failed. Please install manually:"
    error "  xcode-select --install"
    exit 1
  fi
  success "Xcode Command Line Tools installed"
else
  # Ensure the licence has been accepted
  if ! /usr/bin/xcrun clang 2>&1 | grep -q "no input files"; then
    info "Accepting Xcode licence (requires sudo)..."
    sudo xcodebuild -license accept 2>/dev/null || {
      error "Could not accept Xcode licence. Run: sudo xcodebuild -license accept"
      exit 1
    }
    success "Xcode licence accepted"
  fi
fi

# ── Verify critical commands ─────────────────────────────────────────────────
for cmd in git curl; do
  if ! command -v "$cmd" &>/dev/null; then
    error "'$cmd' is required but not found."
    error "Install Xcode CLT (xcode-select --install) and retry."
    exit 1
  fi
done

# ── Validate dotfiles directory ──────────────────────────────────────────────
if [[ ! -d "$DOTFILES" ]]; then
  error "Dotfiles directory not found: $DOTFILES"
  exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╭────────────────────────────────────────────╮${RESET}"
echo -e "${BOLD}│       Prometheus Dotfiles — Setup           │${RESET}"
echo -e "${BOLD}│       github.com/rafay99-epic               │${RESET}"
echo -e "${BOLD}╰────────────────────────────────────────────╯${RESET}"
echo ""
echo -e "  ${GREEN}✓${RESET}  Dotfile symlinks       ${CYAN}(always)${RESET}"
echo -e "  ${YELLOW}?${RESET}  Window manager         ${CYAN}(optional — OmniWM, AeroSpace, or none)${RESET}"
echo -e "  ${YELLOW}?${RESET}  Core packages & fonts  ${CYAN}(optional — one prompt)${RESET}"
echo -e "  ${YELLOW}?${RESET}  Apps                   ${CYAN}(optional — pick individually)${RESET}"
echo ""
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no changes will be made\n"

# =============================================================================
# Helpers
# =============================================================================

# ── Symlink helper ────────────────────────────────────────────────────────────
link() {
  local src="$1"
  local dst="$2"
  local label="${dst/#$HOME/\~}"

  if [[ ! -e "$src" ]]; then
    error "Source not found: $src"
    ERRORS+=("Missing source: $src")
    return 1
  fi

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      success "Already linked: ${label}"
      SKIPPED+=("$label (already correct)")
      return 0
    else
      error "Conflict: ${label} → ${current_target}"
      error "       Expected → ${src}"
      error "       Run: rm \"${dst}\" and re-run."
      ERRORS+=("Symlink conflict: $dst")
      return 1
    fi
  fi

  if [[ -e "$dst" ]]; then
    local backup
    backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up ${label} → ${backup/#$HOME/\~}"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$dst" "$backup"
    else
      dry "mv $dst $backup"
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "Linked: ${label}"
  else
    dry "ln -sf $src $dst"
  fi
  LINKED+=("$label")
}

# ── Brew guard ────────────────────────────────────────────────────────────────
# Ensures Homebrew is available before any brew_install / brew_tap call.
require_brew() {
  if ! command -v brew &>/dev/null; then
    error "Homebrew is not installed. Cannot continue with package installation."
    exit 1
  fi
}

# ── Brew tap helper ──────────────────────────────────────────────────────────
brew_tap() {
  local tap="$1"
  require_brew
  if brew tap | grep -q "^${tap}$"; then
    return 0
  fi
  if [[ "$DRY_RUN" == false ]]; then
    info "Tapping $tap..."
    brew tap "$tap" --quiet || {
      error "Failed to tap $tap"
      ERRORS+=("brew tap $tap failed")
      return 1
    }
  else
    dry "brew tap $tap"
  fi
}

# ── Brew package helper ──────────────────────────────────────────────────────
brew_install() {
  local formula="$1"
  local flags="${2:-}"
  local name
  name="$(basename "$formula")"
  require_brew

  if [[ "$flags" == "--cask" ]]; then
    if brew list --cask "$name" &>/dev/null 2>&1; then
      success "Already installed (cask): $name"
      SKIPPED+=("$name")
      return 0
    fi
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing cask: $name"
      brew install --cask --quiet "$formula" || {
        error "Failed to install cask: $name"
        ERRORS+=("brew install --cask $formula failed")
        return 1
      }
    else
      dry "brew install --cask $formula"
    fi
  else
    if brew list "$name" &>/dev/null 2>&1; then
      success "Already installed: $name"
      SKIPPED+=("$name")
      return 0
    fi
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing: $name"
      brew install --quiet "$formula" || {
        error "Failed to install: $name"
        ERRORS+=("brew install $formula failed")
        return 1
      }
    else
      dry "brew install $formula"
    fi
  fi
  INSTALLED+=("$name")
  success "Installed: $name"
}

# ── curl installer helper ────────────────────────────────────────────────────
# curl_install "name" "check_cmd" "install_url"
curl_install() {
  local name="$1"
  local check_cmd="$2"
  local install_url="$3"

  if eval "$check_cmd" &>/dev/null; then
    success "Already installed: $name"
    SKIPPED+=("$name")
    return 0
  fi

  if [[ "$DRY_RUN" == false ]]; then
    info "Installing $name..."
    curl -fsSL "$install_url" | bash || {
      error "Failed to install $name"
      ERRORS+=("$name install failed")
      return 1
    }
    INSTALLED+=("$name")
    success "Installed: $name"
  else
    dry "curl -fsSL $install_url | bash"
  fi
}

# ── Claude Code statusline configurer ────────────────────────────────────────
# Idempotently sets ~/.claude/settings.json `statusLine` to use Starship.
# Preserves all other keys via jq merge. Skips cleanly if jq/starship missing.
configure_claude_statusline() {
  local settings_file="$HOME/.claude/settings.json"
  local desired_command="starship statusline claude-code"
  local label="Claude Code statusline"

  if ! command -v starship &>/dev/null; then
    warn "starship not installed — skipping $label config"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    warn "jq not installed — skipping $label config"
    return 0
  fi

  # Already configured the way we want?
  if [[ -f "$settings_file" ]]; then
    local current
    current="$(jq -r '.statusLine.command // ""' "$settings_file" 2>/dev/null || echo "")"
    if [[ "$current" == "$desired_command" ]]; then
      success "$label already configured"
      SKIPPED+=("$label")
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    dry "merge .statusLine into $settings_file"
    return 0
  fi

  mkdir -p "$HOME/.claude"

  local tmpfile
  tmpfile="$(mktemp)"
  if [[ -f "$settings_file" ]]; then
    if jq --arg cmd "$desired_command" \
         '.statusLine = {type: "command", command: $cmd}' \
         "$settings_file" > "$tmpfile"; then
      mv "$tmpfile" "$settings_file"
    else
      rm -f "$tmpfile"
      error "Failed to update $settings_file (invalid JSON?)"
      ERRORS+=("$label config failed")
      return 1
    fi
  else
    jq -n --arg cmd "$desired_command" \
       '{statusLine: {type: "command", command: $cmd}}' \
       > "$settings_file"
  fi
  success "$label configured"
  INSTALLED+=("$label")
}

# ── npm global install helper ────────────────────────────────────────────────
# npm_install "name" "check_cmd" "npm_package"
npm_install() {
  local name="$1"
  local check_cmd="$2"
  local package="$3"

  if eval "$check_cmd" &>/dev/null; then
    success "Already installed: $name"
    SKIPPED+=("$name")
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    warn "npm not found — cannot install $name. Install Node.js first, then run: npm install -g $package"
    return 1
  fi

  if [[ "$DRY_RUN" == false ]]; then
    info "Installing $name via npm..."
    npm install -g "$package" || {
      error "Failed to install $name"
      ERRORS+=("npm install -g $package failed")
      return 1
    }
    INSTALLED+=("$name")
    success "Installed: $name"
  else
    dry "npm install -g $package"
  fi
}

# =============================================================================
# Ask: install core packages?
# =============================================================================
if prompt "Install Homebrew and core packages?"; then
  INSTALL_APPS=true
else
  info "Skipping package installation — will only set up symlinks."
fi

# =============================================================================
# Ask: Window Manager preference
# =============================================================================
heading "Window Manager"
echo ""
echo -e "  ${CYAN}Choose a tiling window manager:${RESET}"
echo -e "    ${BOLD}1)${RESET} OmniWM  — Hyprland-style dwindle/BSP, GUI config, quake terminal"
echo -e "    ${BOLD}2)${RESET} AeroSpace — i3-style manual tiling, TOML config"
echo -e "    ${BOLD}3)${RESET} None — no window manager"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo -e "  ${YELLOW}(dry)${RESET} Would ask: Pick a tiling WM → assuming OmniWM"
  WM_CHOICE="omniwm"
else
  echo -en "  ${BOLD}${BLUE}?${RESET}  ${BOLD}Enter choice [1/2/3]:${RESET} "
  read -r _wm_input </dev/tty 2>/dev/null || _wm_input="3"
  echo ""
  case "$_wm_input" in
    1) WM_CHOICE="omniwm" ;;
    2) WM_CHOICE="aerospace" ;;
    *) WM_CHOICE="none" ;;
  esac
fi

if [[ "$WM_CHOICE" == "none" ]]; then
  info "No window manager selected — skipping all WM, bar, and WM font packages."
else
  success "Window manager: $WM_CHOICE"
fi

# ── Stop conflicting WM if the other one is running ──────────────────────────
if [[ "$WM_CHOICE" == "omniwm" ]] && pgrep -x AeroSpace &>/dev/null; then
  warn "AeroSpace is currently running."
  if prompt "Kill AeroSpace before starting OmniWM?"; then
    pkill -x AeroSpace 2>/dev/null || true
    sleep 1
    success "AeroSpace stopped"
  else
    warn "Both WMs running simultaneously will cause conflicts."
  fi
elif [[ "$WM_CHOICE" == "aerospace" ]] && pgrep -x OmniWM &>/dev/null; then
  warn "OmniWM is currently running."
  if prompt "Kill OmniWM before starting AeroSpace?"; then
    pkill -x OmniWM 2>/dev/null || true
    sleep 1
    success "OmniWM stopped"
  else
    warn "Both WMs running simultaneously will cause conflicts."
  fi
elif [[ "$WM_CHOICE" == "none" ]]; then
  # Offer to stop any running WM
  if pgrep -x AeroSpace &>/dev/null; then
    warn "AeroSpace is currently running."
    if prompt "Stop AeroSpace?"; then
      pkill -x AeroSpace 2>/dev/null || true
      sleep 1
      success "AeroSpace stopped"
    fi
  fi
  if pgrep -x OmniWM &>/dev/null; then
    warn "OmniWM is currently running."
    if prompt "Stop OmniWM?"; then
      pkill -x OmniWM 2>/dev/null || true
      sleep 1
      success "OmniWM stopped"
    fi
  fi
fi

# =============================================================================
# PART 1 — Core Packages (shells, CLI tools, runtimes, WM, bar, fonts)
# =============================================================================
if [[ "$INSTALL_APPS" == true ]]; then

  # ── Homebrew ──────────────────────────────────────────────────────────────
  heading "Homebrew"

  if ! command -v brew &>/dev/null; then
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        error "Homebrew installation failed."
        exit 1
      }
      # Add brew to PATH immediately (Apple Silicon + Intel)
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      success "Homebrew installed"
    else
      dry "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
  else
    success "Homebrew already installed ($(brew --version | head -1))"
  fi

  require_brew

  # ── Core packages (via Brewfile) ────────────────────────────────────────
  # Declarative install — see ./Brewfile for the full list.
  heading "Core Packages (Brewfile)"

  if [[ -f "$DOTFILES/Brewfile" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      info "brew bundle --file=Brewfile..."
      if brew bundle --file="$DOTFILES/Brewfile" --no-lock; then
        success "Brewfile applied"
        INSTALLED+=("Brewfile (core)")
      else
        error "brew bundle reported errors"
        ERRORS+=("brew bundle (core) failed")
      fi
    else
      dry "brew bundle --file=$DOTFILES/Brewfile"
    fi
  else
    error "Brewfile not found at $DOTFILES/Brewfile"
    ERRORS+=("missing Brewfile")
  fi

  # Node.js via nvm (LTS)
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  NVM_BREW_PREFIX="$(brew --prefix nvm 2>/dev/null || true)"
  if [[ -n "$NVM_BREW_PREFIX" && -s "${NVM_BREW_PREFIX}/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    source "${NVM_BREW_PREFIX}/nvm.sh"
  fi
  if command -v nvm &>/dev/null; then
    if nvm ls --no-colors 2>/dev/null | grep -q "lts"; then
      success "Already installed: Node.js (LTS via nvm)"
      SKIPPED+=("node-lts")
    elif [[ "$DRY_RUN" == false ]]; then
      info "Installing Node.js LTS via nvm..."
      nvm install --lts || warn "Could not install Node.js LTS via nvm"
      INSTALLED+=("node-lts")
    else
      dry "nvm install --lts"
    fi
  else
    warn "nvm not available in this shell — install Node.js LTS manually: nvm install --lts"
  fi

  # Bun (via official installer — not in Homebrew)
  curl_install "bun" "command -v bun" "https://bun.sh/install"

  # ── Window Manager & Bar (via WM-specific Brewfile) ─────────────────────
  if [[ "$WM_CHOICE" != "none" ]]; then
    heading "Window Manager & Bar"

    WM_BREWFILE="$DOTFILES/Brewfile.${WM_CHOICE}"
    if [[ -f "$WM_BREWFILE" ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        info "brew bundle --file=Brewfile.${WM_CHOICE}..."
        if brew bundle --file="$WM_BREWFILE" --no-lock; then
          success "Brewfile.${WM_CHOICE} applied"
          INSTALLED+=("Brewfile.${WM_CHOICE}")
        else
          error "brew bundle (${WM_CHOICE}) reported errors"
          ERRORS+=("brew bundle ${WM_CHOICE} failed")
        fi
      else
        dry "brew bundle --file=$WM_BREWFILE"
      fi
    else
      error "Brewfile.${WM_CHOICE} not found"
      ERRORS+=("missing Brewfile.${WM_CHOICE}")
    fi

    # OmniWM defaults import (post-install config, not a package)
    if [[ "$WM_CHOICE" == "omniwm" && "$DRY_RUN" == false ]]; then
      if [[ -f "$DOTFILES/omniwm/backup.plist" ]]; then
        info "Restoring saved OmniWM config..."
        defaults import com.barut.OmniWM "$DOTFILES/omniwm/backup.plist" 2>/dev/null || true
        success "OmniWM config restored from backup"
      else
        info "Applying OmniWM defaults..."
        bash "$DOTFILES/omniwm/configure.sh"
      fi
    fi

    # Start SketchyBar service
    if [[ "$DRY_RUN" == false ]] && command -v sketchybar &>/dev/null; then
      if ! brew services list | grep -q "sketchybar.*started"; then
        info "Starting SketchyBar service..."
        brew services start sketchybar
      fi
    fi
  else
    info "Skipping Window Manager & Bar packages (no WM selected)."
  fi

  # ── SketchyBar app font (curl — not on Homebrew) ────────────────────────
  if [[ "$WM_CHOICE" != "none" ]]; then
    FONT_DIR="$HOME/Library/Fonts"
    FONT_PATH="$FONT_DIR/sketchybar-app-font.ttf"
    FONT_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf"
    if [[ -f "$FONT_PATH" ]]; then
      success "Already installed: sketchybar-app-font"
      SKIPPED+=("sketchybar-app-font")
    elif [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$FONT_DIR"
      info "Installing sketchybar-app-font..."
      curl -fsSL "$FONT_URL" -o "$FONT_PATH" || {
        error "Failed to download sketchybar-app-font"
        ERRORS+=("sketchybar-app-font download failed")
      }
      if [[ -f "$FONT_PATH" ]]; then
        success "Installed: sketchybar-app-font"
        INSTALLED+=("sketchybar-app-font")
      fi
    else
      dry "curl sketchybar-app-font → $FONT_PATH"
    fi
  fi

  # ── Register fish in /etc/shells ───────────────────────────────────────
  if command -v fish &>/dev/null; then
    FISH_PATH="$(command -v fish)"
    if ! grep -qF "$FISH_PATH" /etc/shells; then
      if [[ "$DRY_RUN" == false ]]; then
        info "Registering fish in /etc/shells (requires sudo)..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
        success "fish registered in /etc/shells"
      else
        dry "echo $FISH_PATH | sudo tee -a /etc/shells"
      fi
    else
      success "fish already registered in /etc/shells"
    fi
  fi
fi

# =============================================================================
# PART 2 — Optional Apps (user picks individually)
# =============================================================================
heading "Optional Apps"
echo ""
echo -e "  ${CYAN}Pick which apps to install (each is optional):${RESET}"
echo -e "  ${CYAN}Requires Homebrew for cask installs.${RESET}"
echo ""

# Gate optional apps behind brew availability — some use curl so they work
# regardless, but cask installs need brew.
HAS_BREW=false
command -v brew &>/dev/null && HAS_BREW=true

# ── Terminal ──────────────────────────────────────────────────────────────
if prompt "Install Ghostty (GPU terminal emulator)?"; then
  if [[ "$HAS_BREW" == true ]]; then
    brew_install ghostty --cask
  else
    warn "Homebrew not found — skipping Ghostty. Install Homebrew first."
  fi
fi

# ── Editors / IDEs ───────────────────────────────────────────────────────
if prompt "Install Cursor (AI code editor)?"; then
  if [[ "$HAS_BREW" == true ]]; then
    brew_install cursor --cask
  else
    warn "Homebrew not found — skipping Cursor. Install Homebrew first."
  fi
fi

# ── AI Tools ─────────────────────────────────────────────────────────────
if prompt "Install Claude Code (terminal AI assistant)?"; then
  curl_install "claude-code" "command -v claude" "https://claude.ai/install.sh"
fi

if prompt "Configure Claude Code to use Starship statusline?"; then
  configure_claude_statusline
fi

if prompt "Install Claude Desktop (GUI app)?"; then
  if [[ "$HAS_BREW" == true ]]; then
    brew_install claude --cask
  else
    warn "Homebrew not found — skipping Claude Desktop. Install Homebrew first."
  fi
fi

if prompt "Install OpenAI Codex CLI (terminal AI agent)?"; then
  npm_install "codex" "command -v codex" "@openai/codex"
fi

# ── Media ────────────────────────────────────────────────────────────────
if prompt "Install Spotify?"; then
  if [[ "$HAS_BREW" == true ]]; then
    brew_install spotify --cask
  else
    warn "Homebrew not found — skipping Spotify. Install Homebrew first."
  fi
fi

# =============================================================================
# PART 3 — macOS Preferences
# =============================================================================
heading "macOS Preferences"

# ── Required tweaks (always applied) ─────────────────────────────────────────
info "Applying required macOS preferences..."

# Auto-hide the menu bar (needed for SketchyBar — only when a WM is active)
if [[ "$WM_CHOICE" != "none" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write NSGlobalDomain _HIHideMenuBar -bool true
    success "Menu bar auto-hide enabled"
  else
    dry "defaults write NSGlobalDomain _HIHideMenuBar -bool true"
  fi
fi

# Launch tiling WM at login — only for the chosen WM
if [[ "$WM_CHOICE" == "omniwm" && -d "/Applications/OmniWM.app" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    # Remove AeroSpace from login items if present
    osascript -e 'tell application "System Events" to delete every login item whose name is "AeroSpace"' 2>/dev/null || true
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/OmniWM.app", hidden:true}' 2>/dev/null || true
    success "OmniWM added to login items (AeroSpace removed)"
  else
    dry "Add OmniWM.app to login items, remove AeroSpace"
  fi
elif [[ "$WM_CHOICE" == "aerospace" && -d "/Applications/AeroSpace.app" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    # Remove OmniWM from login items if present
    osascript -e 'tell application "System Events" to delete every login item whose name is "OmniWM"' 2>/dev/null || true
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:true}' 2>/dev/null || true
    success "AeroSpace added to login items (OmniWM removed)"
  else
    dry "Add AeroSpace.app to login items, remove OmniWM"
  fi
elif [[ "$WM_CHOICE" == "none" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    # Remove both WMs from login items
    osascript -e 'tell application "System Events" to delete every login item whose name is "AeroSpace"' 2>/dev/null || true
    osascript -e 'tell application "System Events" to delete every login item whose name is "OmniWM"' 2>/dev/null || true
    info "Removed WMs from login items (no WM selected)"
  else
    dry "Remove AeroSpace and OmniWM from login items"
  fi
fi

# ── Optional tweaks (user picks) ────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}Optional system tweaks:${RESET}"
echo ""

# Track changes that need specific process restarts
NEEDS_DOCK_RESTART=false
NEEDS_FINDER_RESTART=false
NEEDS_SYSTEMUI_RESTART=false

# ── Dock ──────────────────────────────────────────────────────────────────
if prompt "Remove Dock auto-hide delay (instant Dock appear/disappear)?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.dock autohide-delay -float 0
    success "Dock auto-hide delay removed"
    INSTALLED+=("macos: no dock delay")
  else
    dry "defaults write com.apple.dock autohide-delay -float 0"
  fi
  NEEDS_DOCK_RESTART=true
fi

# ── Finder ────────────────────────────────────────────────────────────────
if prompt "Apply Finder tweaks (path bar, status bar, hidden files, list view, open to home)?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    # Default view → list (Nlsv=list, icnv=icon, clmv=column, glyv=gallery)
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    # New windows open to home folder (PfHm=home, PfDe=desktop, PfLo=custom path)
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
    success "Finder: path bar, status bar, hidden files, full path, list view, home folder"
    INSTALLED+=("macos: finder tweaks")
  else
    dry "defaults write com.apple.finder ShowPathbar/ShowStatusBar/AppleShowAllFiles/FXShowPosixPathInTitle/FXPreferredViewStyle/NewWindowTarget"
  fi
  NEEDS_FINDER_RESTART=true
fi

# ── Trackpad ──────────────────────────────────────────────────────────────
if prompt "Enable tap-to-click on trackpad?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    success "Trackpad tap-to-click enabled"
    INSTALLED+=("macos: tap to click")
  else
    dry "defaults write trackpad Clicking -bool true"
  fi
fi

# ── Screenshots ───────────────────────────────────────────────────────────
if prompt "Configure screenshots (PNG, no shadow, save to ~/Pictures/Screenshots)?"; then
  SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$SCREENSHOT_DIR"
    defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
    defaults write com.apple.screencapture type -string png
    defaults write com.apple.screencapture disable-shadow -bool true
    success "Screenshots: PNG format, no shadow, saved to ~/Pictures/Screenshots"
    INSTALLED+=("macos: screenshot config")
  else
    dry "mkdir -p $SCREENSHOT_DIR"
    dry "defaults write com.apple.screencapture location/type/disable-shadow"
  fi
  NEEDS_SYSTEMUI_RESTART=true
fi

# ── Mission Control ───────────────────────────────────────────────────────
if prompt "Prevent Mission Control from auto-rearranging Spaces?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.dock mru-spaces -bool false
    success "Mission Control: Spaces will not auto-rearrange"
    INSTALLED+=("macos: fixed spaces order")
  else
    dry "defaults write com.apple.dock mru-spaces -bool false"
  fi
  NEEDS_DOCK_RESTART=true
fi

# ── Menu Bar Clock ────────────────────────────────────────────────────────
if prompt "Show seconds in menu bar clock?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.menuextra.clock ShowSeconds -bool true
    success "Menu bar clock: seconds enabled"
    INSTALLED+=("macos: clock seconds")
  else
    dry "defaults write com.apple.menuextra.clock ShowSeconds -bool true"
  fi
  NEEDS_SYSTEMUI_RESTART=true
fi

# ── Microsoft Office telemetry ────────────────────────────────────────────
if prompt "Disable Microsoft Office telemetry (Word, Excel, PowerPoint, Outlook, OneNote, AutoUpdate, Office365 Service)?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.microsoft.Word              SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.Excel             SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.Powerpoint        SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.Outlook           SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.onenote.mac       SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.autoupdate2       SendAllTelemetryEnabled -bool FALSE
    defaults write com.microsoft.Office365ServiceV2 SendAllTelemetryEnabled -bool FALSE
    success "Microsoft Office telemetry disabled (7 bundles)"
    INSTALLED+=("macos: office telemetry off")
  else
    dry "defaults write com.microsoft.{Word,Excel,Powerpoint,Outlook,onenote.mac,autoupdate2,Office365ServiceV2} SendAllTelemetryEnabled -bool FALSE"
  fi
fi

# ── Battery ───────────────────────────────────────────────────────────────
if prompt "Show battery percentage in menu bar?"; then
  if [[ "$DRY_RUN" == false ]]; then
    defaults write com.apple.controlcenter BatteryShowPercentage -bool true
    success "Battery percentage visible in menu bar"
    INSTALLED+=("macos: battery percentage")
  else
    dry "defaults write com.apple.controlcenter BatteryShowPercentage -bool true"
  fi
  NEEDS_SYSTEMUI_RESTART=true
fi

# ── Manual tweaks reminder ───────────────────────────────────────────────
# These settings cannot be scripted via defaults write / pmset — GUI only.
echo ""
echo -e "  ${YELLOW}The following tweaks must be set manually in System Settings:${RESET}"
echo ""
echo -e "    ${BOLD}Displays${RESET}"
echo -e "      • Disable True Tone → Displays → uncheck True Tone"
echo ""
echo -e "    ${BOLD}Keyboard${RESET}"
echo -e "      • Adjust keyboard brightness in low light → Keyboard → toggle on"
echo -e "      • Turn keyboard backlight off after inactivity → Keyboard → set to 15 seconds"
echo ""
echo -e "    ${BOLD}Battery${RESET}"
echo -e "      • Optimize video streaming while on battery → Battery → toggle on"
echo ""

# ── Restart affected processes ────────────────────────────────────────────
if [[ "$DRY_RUN" == false ]]; then
  if [[ "$NEEDS_DOCK_RESTART" == true ]]; then
    killall Dock 2>/dev/null || true
    info "Dock restarted"
  fi
  if [[ "$NEEDS_FINDER_RESTART" == true ]]; then
    killall Finder 2>/dev/null || true
    info "Finder restarted"
  fi
  if [[ "$NEEDS_SYSTEMUI_RESTART" == true ]]; then
    killall SystemUIServer 2>/dev/null || true
    info "SystemUIServer restarted"
  fi
fi

# =============================================================================
# Symlinks  (always — this is the core of dotfiles management)
# =============================================================================
heading "Symlinks"

# SketchyBar — whole directory symlink (only when a WM is selected)
if [[ "$WM_CHOICE" != "none" ]]; then
  if [[ -d "$HOME/.config/sketchybar" && ! -L "$HOME/.config/sketchybar" ]]; then
    local_backup="$HOME/.config/sketchybar.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up existing ~/.config/sketchybar → $local_backup"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$HOME/.config/sketchybar" "$local_backup"
    else
      dry "mv ~/.config/sketchybar $local_backup"
    fi
  elif [[ -L "$HOME/.config/sketchybar" ]]; then
    current="$(readlink "$HOME/.config/sketchybar")"
    if [[ "$current" == "$DOTFILES/sketchybar" ]]; then
      success "Already linked: ~/.config/sketchybar"
      # shellcheck disable=SC2088 # display label only, tilde is intentional
      SKIPPED+=("~/.config/sketchybar")
    else
      error "Conflict: ~/.config/sketchybar → $current"
      error "       Expected → $DOTFILES/sketchybar"
      error "       Run: rm ~/.config/sketchybar and re-run."
      ERRORS+=("Symlink conflict: ~/.config/sketchybar")
    fi
  fi

  if [[ ! -L "$HOME/.config/sketchybar" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$HOME/.config"
      ln -sf "$DOTFILES/sketchybar" "$HOME/.config/sketchybar"
      success "Linked: ~/.config/sketchybar"
      # shellcheck disable=SC2088 # display label only, tilde is intentional
      LINKED+=("~/.config/sketchybar")
    else
      dry "ln -sf $DOTFILES/sketchybar ~/.config/sketchybar"
    fi
  fi
fi

# Individual file symlinks
link "$DOTFILES/lsd/config.yaml"                    "$HOME/.config/lsd/config.yaml"
link "$DOTFILES/starship/starship.toml"             "$HOME/.config/starship.toml"
link "$DOTFILES/atuin/config.toml"                  "$HOME/.config/atuin/config.toml"
link "$DOTFILES/fastfetch/config.jsonc"             "$HOME/.config/fastfetch/config.jsonc"
link "$DOTFILES/fastfetch/eldritch.png"             "$HOME/.config/fastfetch/eldritch.png"
link "$DOTFILES/ghostty/config"                     "$HOME/.config/ghostty/config"
link "$DOTFILES/zsh/.zshrc"                         "$HOME/.zshrc"
link "$DOTFILES/fish/config.fish"                   "$HOME/.config/fish/config.fish"
link "$DOTFILES/fish/completions/bun.fish"          "$HOME/.config/fish/completions/bun.fish"
link "$DOTFILES/git/.gitconfig"                     "$HOME/.gitconfig"
link "$DOTFILES/bin/update"                         "$HOME/.local/bin/update"
if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$HOME/.local/bin/update" 2>/dev/null || true
fi
link "$DOTFILES/bin/killport"                       "$HOME/.local/bin/killport"
link "$DOTFILES/bin/tm-status"                      "$HOME/.local/bin/tm-status"
link "$DOTFILES/bin/tm-backup"                      "$HOME/.local/bin/tm-backup"
link "$DOTFILES/bin/clean-node-modules"             "$HOME/.local/bin/clean-node-modules"
link "$DOTFILES/bin/bigfiles"                       "$HOME/.local/bin/bigfiles"
link "$DOTFILES/bin/sort-downloads"                 "$HOME/.local/bin/sort-downloads"
if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$HOME/.local/bin/tm-status" "$HOME/.local/bin/tm-backup" "$HOME/.local/bin/clean-node-modules" "$HOME/.local/bin/bigfiles" "$HOME/.local/bin/sort-downloads" 2>/dev/null || true
fi

# ── Time Machine: monthly LaunchDaemon ───────────────────────────────────────
# Replaces TM's default hourly schedule with a single backup on the 1st of
# each month at 03:00. Disables the hourly auto-backup at the same time.
TM_PLIST_SRC="$DOTFILES/launchd/com.prometheus.tm-monthly.plist"
TM_PLIST_DST="/Library/LaunchDaemons/com.prometheus.tm-monthly.plist"
if [[ -f "$TM_PLIST_SRC" ]]; then
  if [[ -f "$TM_PLIST_DST" ]] && cmp -s "$TM_PLIST_SRC" "$TM_PLIST_DST"; then
    success "Already installed: monthly Time Machine schedule"
    SKIPPED+=("tm-monthly LaunchDaemon")
  elif [[ "$DRY_RUN" == false ]]; then
    info "Installing monthly Time Machine LaunchDaemon (requires sudo)..."
    sudo cp "$TM_PLIST_SRC" "$TM_PLIST_DST" \
      && sudo chown root:wheel "$TM_PLIST_DST" \
      && sudo chmod 644 "$TM_PLIST_DST" \
      && sudo launchctl unload "$TM_PLIST_DST" 2>/dev/null; \
       sudo launchctl load "$TM_PLIST_DST" \
      && sudo tmutil disable \
      && success "Monthly Time Machine schedule installed (fires 1st of each month at 03:00)"
    INSTALLED+=("tm-monthly LaunchDaemon")
  else
    dry "install $TM_PLIST_DST + sudo tmutil disable"
  fi
fi

# ── Downloads auto-sort: LaunchAgent ─────────────────────────────────────────
# Watches ~/Downloads and moves new files to /Volumes/media/<Category>/.
# User-scoped LaunchAgent — no sudo needed; daemons can't see SMB mounts.
# Plist in the repo uses __HOME__ as a placeholder; we substitute $HOME on
# install so the dotfiles repo stays portable.
SD_PLIST_SRC="$DOTFILES/launchd/com.prometheus.sort-downloads.plist"
SD_PLIST_DST="$HOME/Library/LaunchAgents/com.prometheus.sort-downloads.plist"
if [[ -f "$SD_PLIST_SRC" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    SD_RENDERED="$(mktemp -t sort-downloads-plist.XXXXXX)"
    sed "s|__HOME__|$HOME|g" "$SD_PLIST_SRC" > "$SD_RENDERED"
    if [[ -f "$SD_PLIST_DST" ]] && cmp -s "$SD_RENDERED" "$SD_PLIST_DST"; then
      success "Already installed: Downloads auto-sort LaunchAgent"
      SKIPPED+=("sort-downloads LaunchAgent")
      rm -f "$SD_RENDERED"
    else
      info "Installing Downloads auto-sort LaunchAgent..."
      launchctl unload "$SD_PLIST_DST" 2>/dev/null || true
      mv "$SD_RENDERED" "$SD_PLIST_DST"
      chmod 644 "$SD_PLIST_DST"
      if launchctl load "$SD_PLIST_DST"; then
        success "Downloads auto-sort LaunchAgent loaded (watches ~/Downloads)"
        INSTALLED+=("sort-downloads LaunchAgent")
      else
        error "Failed to load $SD_PLIST_DST"
      fi
    fi
  else
    dry "install $SD_PLIST_DST (templated) + launchctl load"
  fi
fi

link "$DOTFILES/fish/functions/killport.fish"       "$HOME/.config/fish/functions/killport.fish"
link "$DOTFILES/fish/functions/bigfiles.fish"       "$HOME/.config/fish/functions/bigfiles.fish"
link "$DOTFILES/fish/functions/dev.fish"            "$HOME/.config/fish/functions/dev.fish"
link "$DOTFILES/fish/functions/gm.fish"             "$HOME/.config/fish/functions/gm.fish"
link "$DOTFILES/fish/completions/dev.fish"          "$HOME/.config/fish/completions/dev.fish"
if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$HOME/.local/bin/killport" 2>/dev/null || true
fi

# ── fzf-tab plugin (no brew formula — git clone idempotently) ────────────────
FZF_TAB_DIR="$HOME/.local/share/zsh/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$HOME/.local/share/zsh"
    git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null || true
  else
    dry "git clone --depth=1 https://github.com/Aloxaf/fzf-tab $FZF_TAB_DIR"
  fi
fi

# WM-specific symlinks
if [[ "$WM_CHOICE" == "aerospace" ]]; then
  link "$DOTFILES/aerospace/aerospace.toml"           "$HOME/.config/aerospace/aerospace.toml"
  link "$DOTFILES/fish/functions/aerospace-sync.fish" "$HOME/.config/fish/functions/aerospace-sync.fish"
  link "$DOTFILES/bin/aerospace-sync"                 "$HOME/.local/bin/aerospace-sync"
  if [[ "$DRY_RUN" == false ]]; then
    chmod +x "$HOME/.local/bin/aerospace-sync" 2>/dev/null || true
  fi
fi

if [[ "$WM_CHOICE" != "none" ]]; then
  link "$DOTFILES/bin/wm-switch"                      "$HOME/.local/bin/wm-switch"
  if [[ "$DRY_RUN" == false ]]; then
    chmod +x "$HOME/.local/bin/wm-switch" 2>/dev/null || true
  fi
fi

# =============================================================================
# SketchyBar restart  (only if core packages were installed AND a WM is active)
# =============================================================================
if [[ "$INSTALL_APPS" == true && "$WM_CHOICE" != "none" ]]; then
  heading "SketchyBar"

  if command -v sketchybar &>/dev/null; then
    if [[ "$DRY_RUN" == false ]]; then
      brew services restart sketchybar 2>/dev/null || true
      sketchybar --reload 2>/dev/null || true
      success "SketchyBar restarted"
    else
      dry "brew services restart sketchybar && sketchybar --reload"
    fi
  else
    warn "sketchybar not found — skipping reload."
  fi
elif [[ "$WM_CHOICE" == "none" ]] && command -v sketchybar &>/dev/null; then
  # Stop SketchyBar if running and no WM selected
  if brew services list 2>/dev/null | grep -q "sketchybar.*started"; then
    if prompt "SketchyBar is running but no WM selected. Stop it?"; then
      if [[ "$DRY_RUN" == false ]]; then
        brew services stop sketchybar 2>/dev/null || true
        success "SketchyBar stopped"
      else
        dry "brew services stop sketchybar"
      fi
    fi
  fi
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
echo -e "${GREEN}${BOLD}│          All done!  Setup complete.           │${RESET}"
echo -e "${GREEN}${BOLD}│                                               │${RESET}"
echo -e "${GREEN}${BOLD}│  Open a new terminal tab and log out/back in  │${RESET}"
echo -e "${GREEN}${BOLD}│  for all changes to take effect.              │${RESET}"
echo -e "${GREEN}${BOLD}╰──────────────────────────────────────────────╯${RESET}"
echo ""
