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
#  What it does:
#    1. Asks if you want to install Homebrew + all applications
#    2. If yes → installs Homebrew, then every tool used by these dotfiles
#    3. Always  → symlinks all dotfiles into ~/.config
#    4. Asks about optional GUI apps (Android Studio, VS Code, Chrome, etc.)
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

# ── Guards ────────────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script only supports macOS."
  exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root / sudo."
  exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╭────────────────────────────────────────────╮${RESET}"
echo -e "${BOLD}│       Prometheus Dotfiles — Setup           │${RESET}"
echo -e "${BOLD}│       github.com/rafay99-epic               │${RESET}"
echo -e "${BOLD}╰────────────────────────────────────────────╯${RESET}"
echo ""
echo -e "  ${GREEN}✓${RESET}  Dotfile symlinks     ${CYAN}(always)${RESET}"
echo -e "  ${YELLOW}?${RESET}  Homebrew + packages  ${CYAN}(optional — you'll be asked)${RESET}"
echo -e "  ${YELLOW}?${RESET}  GUI apps             ${CYAN}(optional — asked individually)${RESET}"
echo ""
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no changes will be made\n"

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

# ── Brew package helper ───────────────────────────────────────────────────────
brew_install() {
  local formula="$1"
  local flags="${2:-}"
  local name
  name="$(basename "$formula")"

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

# =============================================================================
# Ask: install apps?
# =============================================================================
if prompt "Install Homebrew and all applications?"; then
  INSTALL_APPS=true
else
  info "Skipping app installation — will only set up symlinks."
fi

# =============================================================================
# Step 1 — Homebrew  (only if user said yes)
# =============================================================================
if [[ "$INSTALL_APPS" == true ]]; then
  heading "Homebrew"

  if ! command -v brew &>/dev/null; then
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        error "Homebrew installation failed."
        exit 1
      }
      # Add brew to PATH immediately (Apple Silicon)
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      success "Homebrew installed"
    else
      dry "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
  else
    success "Homebrew already installed ($(brew --version | head -1))"
  fi
fi

# =============================================================================
# Step 2 — Packages  (only if user said yes)
# =============================================================================
if [[ "$INSTALL_APPS" == true ]]; then
  heading "Packages"

  # ── Shells ───────────────────────────────────────────────────────────────
  brew_install fish
  brew_install starship
  brew_install fastfetch

  # ── Better CLI tools ─────────────────────────────────────────────────────
  brew_install bat
  brew_install eza
  brew_install lsd
  brew_install fzf
  brew_install thefuck
  brew_install jq

  # ── Runtime managers ─────────────────────────────────────────────────────
  brew_install rbenv
  brew_install nvm
  brew_install fnm       # fish-native Node manager (preferred in fish)
  brew_install bun
  brew_install openjdk@17

  # ── Mobile ───────────────────────────────────────────────────────────────
  brew_install scrcpy    # Android screen mirror

  # ── AeroSpace (tiling WM) ────────────────────────────────────────────────
  if ! brew tap | grep -q "nikitabobko/tap"; then
    [[ "$DRY_RUN" == false ]] && brew tap nikitabobko/tap --quiet
  fi
  brew_install nikitabobko/tap/aerospace --cask

  # ── SketchyBar ───────────────────────────────────────────────────────────
  if ! brew tap | grep -q "FelixKratz/formulae"; then
    [[ "$DRY_RUN" == false ]] && brew tap FelixKratz/formulae --quiet
  fi
  brew_install sketchybar

  if [[ "$DRY_RUN" == false ]]; then
    if ! brew services list | grep -q "sketchybar.*started"; then
      info "Starting SketchyBar service..."
      brew services start sketchybar
    fi
  fi

  # ── Terminal & editors ───────────────────────────────────────────────────
  brew_install ghostty --cask
  brew_install windsurf --cask

  # ── AI & dev tools ───────────────────────────────────────────────────────
  brew_install lm-studio --cask

  # Claude Code (cc alias)
  if command -v claude &>/dev/null; then
    success "Already installed: claude (Claude Code)"
    SKIPPED+=("claude")
  elif command -v npm &>/dev/null; then
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing Claude Code via npm..."
      npm install -g @anthropic-ai/claude-code || warn "Could not install Claude Code"
      INSTALLED+=("claude")
    else
      dry "npm install -g @anthropic-ai/claude-code"
    fi
  else
    warn "npm not found — Claude Code (cc alias) not installed. Install Node first."
  fi

  # ── Fonts ─────────────────────────────────────────────────────────────────
  # SketchyBar app font
  FONT_PATH="$HOME/Library/Fonts/sketchybar-app-font.ttf"
  FONT_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf"
  if [[ -f "$FONT_PATH" ]]; then
    success "Already installed: sketchybar-app-font"
    SKIPPED+=("sketchybar-app-font")
  elif [[ "$DRY_RUN" == false ]]; then
    info "Installing sketchybar-app-font..."
    curl -fsSL "$FONT_URL" -o "$FONT_PATH" || {
      error "Failed to download sketchybar-app-font"
      ERRORS+=("sketchybar-app-font download failed")
    }
    success "Installed: sketchybar-app-font"
    INSTALLED+=("sketchybar-app-font")
  else
    dry "curl sketchybar-app-font → $FONT_PATH"
  fi

  # JetBrains Mono Nerd Font
  if ls "$HOME/Library/Fonts/JetBrainsMonoNerd"* &>/dev/null 2>&1 || \
     ls "/Library/Fonts/JetBrainsMonoNerd"* &>/dev/null 2>&1; then
    success "Already installed: JetBrainsMono Nerd Font"
    SKIPPED+=("JetBrainsMono Nerd Font")
  else
    if ! brew tap | grep -q "homebrew/cask-fonts"; then
      [[ "$DRY_RUN" == false ]] && brew tap homebrew/cask-fonts --quiet 2>/dev/null || true
    fi
    brew_install font-jetbrains-mono-nerd-font --cask || \
      warn "Could not install JetBrainsMono Nerd Font — install manually from nerdfonts.com"
  fi

  # CodexBar (AI usage tracker for SketchyBar)
  if command -v codexbar &>/dev/null; then
    success "Already installed: codexbar"
    SKIPPED+=("codexbar")
  else
    warn "CodexBar not found — download from https://github.com/steipete/CodexBar"
    warn "The SketchyBar AI widget will show errors until it is installed."
  fi

  # ── Register fish in /etc/shells ─────────────────────────────────────────
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
# Step 3 — Symlinks  (always — this is the core of dotfiles management)
# =============================================================================
heading "Symlinks"

# SketchyBar — whole directory symlink
if [[ -d "$HOME/.config/sketchybar" && ! -L "$HOME/.config/sketchybar" ]]; then
  local_backup="$HOME/.config/sketchybar.bak.$(date +%Y%m%d_%H%M%S)"
  warn "Backing up existing ~/.config/sketchybar → $local_backup"
  [[ "$DRY_RUN" == false ]] && mv "$HOME/.config/sketchybar" "$local_backup" || \
    dry "mv ~/.config/sketchybar $local_backup"
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
link "$DOTFILES/aerospace/aerospace.toml"      "$HOME/.config/aerospace/aerospace.toml"
link "$DOTFILES/lsd/config.yaml"               "$HOME/.config/lsd/config.yaml"
link "$DOTFILES/starship/starship.toml"        "$HOME/.config/starship.toml"
link "$DOTFILES/fastfetch/config.jsonc"        "$HOME/.config/fastfetch/config.jsonc"
link "$DOTFILES/fastfetch/eldritch.png"        "$HOME/.config/fastfetch/eldritch.png"
link "$DOTFILES/ghostty/config"                "$HOME/.config/ghostty/config"
link "$DOTFILES/zsh/.zshrc"                    "$HOME/.zshrc"
link "$DOTFILES/fish/config.fish"              "$HOME/.config/fish/config.fish"
link "$DOTFILES/fish/completions/bun.fish"     "$HOME/.config/fish/completions/bun.fish"

# =============================================================================
# Step 4 — SketchyBar restart  (only if apps were installed)
# =============================================================================
if [[ "$INSTALL_APPS" == true ]]; then
  heading "SketchyBar"

  if command -v sketchybar &>/dev/null; then
    if [[ "$DRY_RUN" == false ]]; then
      brew services restart sketchybar
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
# Step 5 — Summary
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
