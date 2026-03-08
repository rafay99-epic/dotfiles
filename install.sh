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
    local backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
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

  # ── Shells & Prompts ────────────────────────────────────────────────────
  heading "Shells & Prompts"

  brew_install fish
  brew_install starship
  brew_install fastfetch

  # ── CLI Tools ──────────────────────────────────────────────────────────
  heading "CLI Tools"

  brew_install bat
  brew_install eza
  brew_install lsd
  brew_install fzf
  brew_install thefuck
  brew_install jq

  # ── Runtimes & Languages ──────────────────────────────────────────────
  heading "Runtimes & Languages"

  brew_install rbenv
  brew_install nvm
  brew_install fnm       # fish-native Node manager (preferred in fish)
  brew_install openjdk@17

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

  # ── Mobile ─────────────────────────────────────────────────────────────
  brew_install scrcpy    # Android screen mirror

  # ── Window Manager & Bar ───────────────────────────────────────────────
  heading "Window Manager & Bar"

  # Tiling WM — user picks one (they conflict if both run simultaneously)
  echo ""
  echo -e "  ${CYAN}Choose a tiling window manager:${RESET}"
  echo -e "    ${BOLD}1)${RESET} OmniWM  — Hyprland-style dwindle/BSP, GUI config, quake terminal"
  echo -e "    ${BOLD}2)${RESET} AeroSpace — i3-style manual tiling, TOML config"
  echo -e "    ${BOLD}3)${RESET} Skip"
  echo ""
  WM_CHOICE=""
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}(dry)${RESET} Would ask: Pick a tiling WM → assuming OmniWM"
    WM_CHOICE="1"
  else
    echo -en "  ${BOLD}${BLUE}?${RESET}  ${BOLD}Enter choice [1/2/3]:${RESET} "
    read -r WM_CHOICE </dev/tty 2>/dev/null || WM_CHOICE="1"
    echo ""
  fi

  case "$WM_CHOICE" in
    1)
      # Stop AeroSpace if running
      if pgrep -x AeroSpace &>/dev/null; then
        warn "AeroSpace is currently running."
        if prompt "Kill AeroSpace before starting OmniWM?"; then
          pkill -x AeroSpace 2>/dev/null || true
          sleep 1
          success "AeroSpace stopped"
        else
          warn "Both WMs running simultaneously will cause conflicts."
        fi
      fi
      brew_tap "BarutSRB/tap"
      brew_install omniwm --cask
      # Apply OmniWM defaults
      if [[ "$DRY_RUN" == false ]]; then
        if [[ -f "$DOTFILES/omniwm/backup.plist" ]]; then
          info "Restoring saved OmniWM config..."
          defaults import com.barut.OmniWM "$DOTFILES/omniwm/backup.plist" 2>/dev/null || true
          success "OmniWM config restored from backup"
        else
          info "Applying OmniWM defaults..."
          bash "$DOTFILES/omniwm/configure.sh"
        fi
      fi
      ;;
    2)
      # Stop OmniWM if running
      if pgrep -x OmniWM &>/dev/null; then
        warn "OmniWM is currently running."
        if prompt "Kill OmniWM before starting AeroSpace?"; then
          pkill -x OmniWM 2>/dev/null || true
          sleep 1
          success "OmniWM stopped"
        else
          warn "Both WMs running simultaneously will cause conflicts."
        fi
      fi
      brew_tap "nikitabobko/tap"
      brew_install nikitabobko/tap/aerospace --cask
      ;;
    *)
      info "Skipping tiling window manager."
      ;;
  esac

  # SketchyBar
  brew_tap "FelixKratz/formulae"
  brew_install sketchybar

  if [[ "$DRY_RUN" == false ]]; then
    if ! brew services list | grep -q "sketchybar.*started"; then
      info "Starting SketchyBar service..."
      brew services start sketchybar
    fi
  fi

  # CodexBar (AI usage tracker widget for SketchyBar)
  brew_tap "steipete/tap"
  brew_install steipete/tap/codexbar --cask

  # ── Fonts ──────────────────────────────────────────────────────────────
  heading "Fonts"

  # SF Symbols — required for SketchyBar icon glyphs (icons.sh)
  brew_install sf-symbols --cask

  # SketchyBar app font
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

  # JetBrains Mono Nerd Font
  if ls "$HOME/Library/Fonts/JetBrainsMonoNerd"* &>/dev/null 2>&1 || \
     ls "/Library/Fonts/JetBrainsMonoNerd"* &>/dev/null 2>&1; then
    success "Already installed: JetBrainsMono Nerd Font"
    SKIPPED+=("JetBrainsMono Nerd Font")
  else
    brew_install font-jetbrains-mono-nerd-font --cask || \
      warn "Could not install JetBrainsMono Nerd Font — install manually from nerdfonts.com"
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

if prompt "Install LM Studio (local LLMs)?"; then
  if [[ "$HAS_BREW" == true ]]; then
    brew_install lm-studio --cask
  else
    warn "Homebrew not found — skipping LM Studio. Install Homebrew first."
  fi
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

# Auto-hide the menu bar (needed for SketchyBar)
if [[ "$DRY_RUN" == false ]]; then
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  success "Menu bar auto-hide enabled"
else
  dry "defaults write NSGlobalDomain _HIHideMenuBar -bool true"
fi

# Launch tiling WM at login (OmniWM preferred, falls back to AeroSpace)
if [[ -d "/Applications/OmniWM.app" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/OmniWM.app", hidden:true}' 2>/dev/null || true
    success "OmniWM added to login items"
  else
    dry "Add OmniWM.app to login items"
  fi
elif [[ -d "/Applications/AeroSpace.app" ]]; then
  if [[ "$DRY_RUN" == false ]]; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:true}' 2>/dev/null || true
    success "AeroSpace added to login items"
  else
    dry "Add AeroSpace.app to login items"
  fi
else
  warn "No tiling WM found (OmniWM or AeroSpace) — skipping login item setup"
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

# SketchyBar — whole directory symlink
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
    LINKED+=("~/.config/sketchybar")
  else
    dry "ln -sf $DOTFILES/sketchybar ~/.config/sketchybar"
  fi
fi

# Individual file symlinks
link "$DOTFILES/aerospace/aerospace.toml"           "$HOME/.config/aerospace/aerospace.toml"
link "$DOTFILES/lsd/config.yaml"                    "$HOME/.config/lsd/config.yaml"
link "$DOTFILES/starship/starship.toml"             "$HOME/.config/starship.toml"
link "$DOTFILES/fastfetch/config.jsonc"             "$HOME/.config/fastfetch/config.jsonc"
link "$DOTFILES/fastfetch/eldritch.png"             "$HOME/.config/fastfetch/eldritch.png"
link "$DOTFILES/ghostty/config"                     "$HOME/.config/ghostty/config"
link "$DOTFILES/zsh/.zshrc"                         "$HOME/.zshrc"
link "$DOTFILES/fish/config.fish"                   "$HOME/.config/fish/config.fish"
link "$DOTFILES/fish/completions/bun.fish"          "$HOME/.config/fish/completions/bun.fish"
link "$DOTFILES/fish/functions/aerospace-sync.fish" "$HOME/.config/fish/functions/aerospace-sync.fish"
link "$DOTFILES/bin/aerospace-sync"                 "$HOME/.local/bin/aerospace-sync"
link "$DOTFILES/bin/wm-switch"                      "$HOME/.local/bin/wm-switch"
if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$HOME/.local/bin/aerospace-sync" 2>/dev/null || true
  chmod +x "$HOME/.local/bin/wm-switch" 2>/dev/null || true
fi

# =============================================================================
# SketchyBar restart  (only if core packages were installed)
# =============================================================================
if [[ "$INSTALL_APPS" == true ]]; then
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
