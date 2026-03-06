#!/bin/bash

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╭────────────────────────────────────────╮"
echo "│        Prometheus Dotfiles Setup        │"
echo "╰────────────────────────────────────────╯"
echo ""

# ── Helpers ──────────────────────────────────────────────
info()    { echo "  [→] $1"; }
success() { echo "  [✓] $1"; }
error()   { echo "  [✗] $1"; exit 1; }

confirm() {
  read -r -p "  $1 [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

link() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    info "Backing up existing $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  success "Linked $dst"
}

# ── Homebrew ─────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  success "Homebrew already installed"
fi

# ── Packages ─────────────────────────────────────────────
info "Installing packages via Homebrew..."

brew install --quiet lsd starship fastfetch jq

# AeroSpace
if ! brew list --cask nikitabobko/tap/aerospace &>/dev/null 2>&1; then
  brew tap nikitabobko/tap
  brew install --cask --quiet nikitabobko/tap/aerospace
else
  success "AeroSpace already installed"
fi

# SketchyBar
if ! command -v sketchybar &>/dev/null; then
  brew tap FelixKratz/formulae
  brew install --quiet sketchybar
  brew services start sketchybar
else
  success "SketchyBar already installed"
fi

# Sketchybar app font (for app icons in spaces)
if ! ls ~/Library/Fonts/sketchybar-app-font.ttf &>/dev/null; then
  info "Installing sketchybar-app-font..."
  curl -fsSL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf \
    -o ~/Library/Fonts/sketchybar-app-font.ttf
  success "sketchybar-app-font installed"
fi

# CodexBar (AI usage tracker)
if ! command -v codexbar &>/dev/null; then
  info "Installing CodexBar CLI..."
  brew tap steipete/tap 2>/dev/null || true
  brew install --quiet codexbar 2>/dev/null || \
    info "CodexBar not available via brew — download from https://github.com/steipete/CodexBar"
fi

success "All packages installed"
echo ""

# ── Symlinks ─────────────────────────────────────────────
info "Creating config symlinks..."

# SketchyBar — link the whole directory
if [ -d ~/.config/sketchybar ] && [ ! -L ~/.config/sketchybar ]; then
  info "Backing up existing ~/.config/sketchybar → ~/.config/sketchybar.bak"
  mv ~/.config/sketchybar ~/.config/sketchybar.bak
fi
ln -sf "$DOTFILES/sketchybar" ~/.config/sketchybar
success "Linked ~/.config/sketchybar"

# AeroSpace
link "$DOTFILES/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml

# lsd
link "$DOTFILES/lsd/config.yaml" ~/.config/lsd/config.yaml

# Starship
link "$DOTFILES/starship/starship.toml" ~/.config/starship.toml

# Fastfetch
link "$DOTFILES/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
link "$DOTFILES/fastfetch/eldritch.png"  ~/.config/fastfetch/eldritch.png

echo ""

# ── Shell setup ───────────────────────────────────────────
info "Shell setup..."
SHELL_RC=""
if [ -f ~/.zshrc ]; then SHELL_RC=~/.zshrc
elif [ -f ~/.bashrc ]; then SHELL_RC=~/.bashrc; fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q 'starship init' "$SHELL_RC"; then
    echo '' >> "$SHELL_RC"
    echo '# Starship prompt' >> "$SHELL_RC"
    echo 'eval "$(starship init zsh)"' >> "$SHELL_RC"
    success "Added Starship init to $SHELL_RC"
  else
    success "Starship already configured in $SHELL_RC"
  fi

  if ! grep -q 'alias ls=' "$SHELL_RC"; then
    echo '' >> "$SHELL_RC"
    echo '# lsd aliases' >> "$SHELL_RC"
    echo 'alias ls="lsd"' >> "$SHELL_RC"
    echo 'alias ll="lsd -la"' >> "$SHELL_RC"
    echo 'alias lt="lsd --tree"' >> "$SHELL_RC"
    success "Added lsd aliases to $SHELL_RC"
  fi
fi

echo ""

# ── SketchyBar restart ───────────────────────────────────
if command -v sketchybar &>/dev/null; then
  info "Restarting SketchyBar..."
  brew services restart sketchybar
  sketchybar --reload 2>/dev/null || true
  success "SketchyBar reloaded"
fi

echo ""
echo "╭────────────────────────────────────────╮"
echo "│              Setup complete!            │"
echo "│                                         │"
echo "│  Restart your terminal and log out      │"
echo "│  then back in for all changes to apply. │"
echo "╰────────────────────────────────────────╯"
