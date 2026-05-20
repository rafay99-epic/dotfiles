#!/usr/bin/env bash
# =============================================================================
# install.d/20-homebrew.sh — Core packages: Homebrew + Brewfile + WM packages
# =============================================================================
# Self-gates on INSTALL_APPS. Installs:
#   - Homebrew itself (if missing)
#   - Brewfile (core packages: fish, starship, eza, fzf, atuin, …)
#   - Node.js LTS via nvm
#   - Bun via the official installer
#   - Brewfile.<WM_CHOICE> when a WM is selected (omniwm / aerospace)
#   - SketchyBar app font (via curl, no Homebrew formula)
#   - fish registration in /etc/shells

module_homebrew() {
  [[ "$INSTALL_APPS" == true ]] || return 0

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
}
