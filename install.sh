#!/usr/bin/env bash
# =============================================================================
# Prometheus Dotfiles — install.sh
# =============================================================================
# Usage:
#   ./install.sh              — full install
#   ./install.sh --dry-run    — preview what would happen, no changes made
#   ./install.sh --help       — show usage
# =============================================================================

set -Euo pipefail
IFS=$'\n\t'

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
ERRORS=()
SKIPPED=()
LINKED=()
INSTALLED=()

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; BLUE=''; BOLD=''; RESET=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo -e "  ${BLUE}→${RESET}  $*"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "  ${RED}✗${RESET}  $*"; }
heading() { echo -e "\n${BOLD}$*${RESET}"; }
dry()     { echo -e "  ${YELLOW}(dry)${RESET} $*"; }

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: ./install.sh [--dry-run] [--help]"
      echo ""
      echo "  --dry-run   Preview all changes without making them"
      echo "  --help      Show this message"
      exit 0
      ;;
    *) error "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ── Guards ────────────────────────────────────────────────────────────────────
# macOS only
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script only supports macOS."
  exit 1
fi

# Must NOT be run as root
if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root / sudo."
  exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╭────────────────────────────────────────╮${RESET}"
echo -e "${BOLD}│        Prometheus Dotfiles Setup        │${RESET}"
echo -e "${BOLD}│        github.com/rafay99-epic          │${RESET}"
echo -e "${BOLD}╰────────────────────────────────────────╯${RESET}"
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no changes will be made"
echo ""

# ── Symlink helper ────────────────────────────────────────────────────────────
# link <src> <dst>
#   - dst is already a symlink to src   → skip (already correct)
#   - dst is a symlink to something else → error, tell user to remove it
#   - dst is a real file/directory       → back up with timestamp, then link
#   - dst does not exist                 → create symlink
link() {
  local src="$1"
  local dst="$2"
  local label="${dst/#$HOME/\~}"

  # Source must exist
  if [[ ! -e "$src" ]]; then
    error "Source not found: $src"
    ERRORS+=("Missing source: $src")
    return 1
  fi

  # Already a correct symlink — nothing to do
  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      success "Already linked: ${label}"
      SKIPPED+=("$label (already correct)")
      return 0
    else
      error "Conflict: ${label} is a symlink → ${current_target}"
      error "       Expected  → ${src}"
      error "       Run: rm \"${dst}\" and re-run this script."
      ERRORS+=("Symlink conflict: $dst → $current_target (expected $src)")
      return 1
    fi
  fi

  # Real file or directory exists — back it up
  if [[ -e "$dst" ]]; then
    local backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up existing ${label} → ${backup/#$HOME/\~}"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$dst" "$backup"
    else
      dry "mv $dst $backup"
    fi
  fi

  # Create the symlink
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "Linked: ${label} → ${src/#$HOME/\~}"
  else
    dry "ln -sf $src $dst"
  fi
  LINKED+=("$label")
}

# ── Brew package helper ───────────────────────────────────────────────────────
# brew_install <formula> [--cask]
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
# 1. Homebrew
# =============================================================================
heading "1/6  Homebrew"

if ! command -v brew &>/dev/null; then
  if [[ "$DRY_RUN" == false ]]; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      error "Homebrew installation failed."
      exit 1
    }
    # Add brew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  else
    dry "Install Homebrew"
  fi
else
  success "Homebrew already installed ($(brew --version | head -1))"
fi

# =============================================================================
# 2. Packages
# =============================================================================
heading "2/6  Packages"

# Core tools
brew_install lsd
brew_install starship
brew_install fastfetch
brew_install jq

# AeroSpace (tiling WM)
if ! brew tap | grep -q "nikitabobko/tap"; then
  [[ "$DRY_RUN" == false ]] && brew tap nikitabobko/tap --quiet
fi
brew_install nikitabobko/tap/aerospace --cask

# SketchyBar
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

# Ghostty terminal
brew_install ghostty --cask

# Sketchybar app font
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
  dry "Download sketchybar-app-font → $FONT_PATH"
fi

# JetBrains Mono Nerd Font (for Ghostty)
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

# CodexBar (optional — AI usage tracker)
if command -v codexbar &>/dev/null; then
  success "Already installed: codexbar"
  SKIPPED+=("codexbar")
else
  warn "CodexBar not found — download from https://github.com/steipete/CodexBar"
  warn "The SketchyBar AI widget will show errors until it's installed."
fi

# =============================================================================
# 3. Symlinks  (dotfiles → ~/.config)
# =============================================================================
heading "3/6  Symlinks"

# SketchyBar — whole directory
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
    error "       Expected  → $DOTFILES/sketchybar"
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
link "$DOTFILES/aerospace/aerospace.toml"  "$HOME/.config/aerospace/aerospace.toml"
link "$DOTFILES/lsd/config.yaml"           "$HOME/.config/lsd/config.yaml"
link "$DOTFILES/starship/starship.toml"    "$HOME/.config/starship.toml"
link "$DOTFILES/fastfetch/config.jsonc"    "$HOME/.config/fastfetch/config.jsonc"
link "$DOTFILES/fastfetch/eldritch.png"    "$HOME/.config/fastfetch/eldritch.png"
link "$DOTFILES/ghostty/config"            "$HOME/.config/ghostty/config"

# =============================================================================
# 4. Shell setup
# =============================================================================
heading "4/6  Shell"

SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [[ -z "$SHELL_RC" ]]; then
  warn "No .zshrc or .bashrc found — skipping shell setup."
else
  if grep -q 'starship init' "$SHELL_RC"; then
    success "Starship already configured in $SHELL_RC"
    SKIPPED+=("starship init")
  elif [[ "$DRY_RUN" == false ]]; then
    printf '\n# Starship prompt\neval "$(starship init zsh)"\n' >> "$SHELL_RC"
    success "Added Starship init to $SHELL_RC"
    INSTALLED+=("starship init in $SHELL_RC")
  else
    dry "Add starship init to $SHELL_RC"
  fi

  if grep -q 'alias ls=' "$SHELL_RC"; then
    success "lsd aliases already in $SHELL_RC"
    SKIPPED+=("lsd aliases")
  elif [[ "$DRY_RUN" == false ]]; then
    printf '\n# lsd aliases\nalias ls="lsd"\nalias ll="lsd -la"\nalias lt="lsd --tree"\n' >> "$SHELL_RC"
    success "Added lsd aliases to $SHELL_RC"
    INSTALLED+=("lsd aliases in $SHELL_RC")
  else
    dry "Add lsd aliases to $SHELL_RC"
  fi

  if grep -q 'fastfetch' "$SHELL_RC"; then
    success "fastfetch already in $SHELL_RC"
    SKIPPED+=("fastfetch in shell")
  elif [[ "$DRY_RUN" == false ]]; then
    printf '\n# System info on shell open\nfastfetch\n' >> "$SHELL_RC"
    success "Added fastfetch to $SHELL_RC"
  else
    dry "Add fastfetch to $SHELL_RC"
  fi
fi

# =============================================================================
# 5. SketchyBar restart
# =============================================================================
heading "5/6  SketchyBar"

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

# =============================================================================
# 6. Summary
# =============================================================================
heading "6/6  Summary"
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
  echo -e "  ${YELLOW}Skipped — already up to date (${#SKIPPED[@]})${RESET}"
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

echo -e "${GREEN}${BOLD}╭────────────────────────────────────────╮${RESET}"
echo -e "${GREEN}${BOLD}│         All done! Setup complete.       │${RESET}"
echo -e "${GREEN}${BOLD}│                                         │${RESET}"
echo -e "${GREEN}${BOLD}│  Open a new terminal tab and log out    │${RESET}"
echo -e "${GREEN}${BOLD}│  then back in for all changes to apply. │${RESET}"
echo -e "${GREEN}${BOLD}╰────────────────────────────────────────╯${RESET}"
