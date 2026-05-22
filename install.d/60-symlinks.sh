#!/usr/bin/env bash
# =============================================================================
# install.d/60-symlinks.sh — All dotfile symlinks
# =============================================================================
# This is the core of dotfiles management. SketchyBar is symlinked as a whole
# directory; everything else uses the per-file `link` helper from 00-lib.sh.
#
# WM-specific symlinks (AeroSpace config, wm-switch script) are gated on
# $WM_CHOICE so they don't get linked on machines without a WM.

module_symlinks() {
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
  link "$DOTFILES/zsh/.zprofile"                      "$HOME/.zprofile"
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
  link "$DOTFILES/bin/archive-project"                "$HOME/.local/bin/archive-project"
  if [[ "$DRY_RUN" == false ]]; then
    chmod +x "$HOME/.local/bin/tm-status" "$HOME/.local/bin/tm-backup" "$HOME/.local/bin/clean-node-modules" "$HOME/.local/bin/bigfiles" "$HOME/.local/bin/sort-downloads" "$HOME/.local/bin/archive-project" 2>/dev/null || true
  fi

  # Fish functions
  link "$DOTFILES/fish/functions/killport.fish"       "$HOME/.config/fish/functions/killport.fish"
  link "$DOTFILES/fish/functions/bigfiles.fish"       "$HOME/.config/fish/functions/bigfiles.fish"
  link "$DOTFILES/fish/functions/dev.fish"            "$HOME/.config/fish/functions/dev.fish"
  link "$DOTFILES/fish/functions/gm.fish"             "$HOME/.config/fish/functions/gm.fish"
  link "$DOTFILES/fish/completions/dev.fish"          "$HOME/.config/fish/completions/dev.fish"
  if [[ "$DRY_RUN" == false ]]; then
    chmod +x "$HOME/.local/bin/killport" 2>/dev/null || true
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
}
