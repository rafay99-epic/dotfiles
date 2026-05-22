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
  # ── Always-on helpers ─────────────────────────────────────────────────────
  # These don't depend on NAS or any optional feature, so they ship to
  # every machine that runs the installer.
  link "$DOTFILES/bin/update"                         "$HOME/.local/bin/update"
  link "$DOTFILES/bin/killport"                       "$HOME/.local/bin/killport"
  link "$DOTFILES/bin/clean-node-modules"             "$HOME/.local/bin/clean-node-modules"
  link "$DOTFILES/bin/bigfiles"                       "$HOME/.local/bin/bigfiles"
  if [[ "$DRY_RUN" == false ]]; then
    chmod +x \
      "$HOME/.local/bin/update" \
      "$HOME/.local/bin/killport" \
      "$HOME/.local/bin/clean-node-modules" \
      "$HOME/.local/bin/bigfiles" \
      2>/dev/null || true
  fi

  # The shared loader library that bin/* scripts source. Always linked so
  # any future bin/* tool can use it.
  link "$DOTFILES/bin/lib/dotfiles-config.sh"         "$HOME/.local/bin/lib/dotfiles-config.sh"

  # ── NAS-dependent helpers ─────────────────────────────────────────────────
  # Each one is gated by its own flag in ~/.config/dotfiles/local.env.
  # When the flag is off, the script isn't symlinked — saves PATH clutter
  # and surfaces an honest "command not found" if you try to run it.

  if is_truthy "${HAS_TIMEMACHINE_NAS:-false}"; then
    link "$DOTFILES/bin/tm-status"                    "$HOME/.local/bin/tm-status"
    link "$DOTFILES/bin/tm-backup"                    "$HOME/.local/bin/tm-backup"
    if [[ "$DRY_RUN" == false ]]; then
      chmod +x "$HOME/.local/bin/tm-status" "$HOME/.local/bin/tm-backup" 2>/dev/null || true
    fi
  fi

  if is_truthy "${ENABLE_SORT_DOWNLOADS:-false}"; then
    link "$DOTFILES/bin/sort-downloads"               "$HOME/.local/bin/sort-downloads"
    if [[ "$DRY_RUN" == false ]]; then
      chmod +x "$HOME/.local/bin/sort-downloads" 2>/dev/null || true
    fi
  fi

  if is_truthy "${ENABLE_ARCHIVE_PROJECT:-false}"; then
    link "$DOTFILES/bin/archive-project"              "$HOME/.local/bin/archive-project"
    if [[ "$DRY_RUN" == false ]]; then
      chmod +x "$HOME/.local/bin/archive-project" 2>/dev/null || true
    fi
  fi

  # ── NAS auto-mount: retry helper ──────────────────────────────────────────
  # The .inetloc Login Item below tries to mount at login but doesn't retry
  # when the network isn't ready yet. `nas-mount` is the retry layer — see
  # bin/nas-mount and install.d/70-launchd.sh for the matching LaunchAgent.
  if is_truthy "${HAS_NAS:-false}"; then
    link "$DOTFILES/bin/nas-mount"                    "$HOME/.local/bin/nas-mount"
    if [[ "$DRY_RUN" == false ]]; then
      chmod +x "$HOME/.local/bin/nas-mount" 2>/dev/null || true
    fi
  fi

  # ── NAS auto-mount: .inetloc Login Item ───────────────────────────────────
  # The Finder Login Item that mounts the SMB share at every login. Rendered
  # from nas/truenas-media.inetloc.template by sed-substituting the user's
  # NAS_USER / NAS_HOST / NAS_SHARE_MEDIA into the URL.
  #
  # The rendered file lands at ~/Library/Application Support/dotfiles/
  # (instead of the repo) so the repo never has a concrete IP in it.
  if is_truthy "${HAS_NAS:-false}" && [[ -n "${NAS_HOST:-}" && -n "${NAS_USER:-}" ]]; then
    NAS_INETLOC_SRC="$DOTFILES/nas/truenas-media.inetloc.template"
    NAS_INETLOC_DST="$HOME/Library/Application Support/dotfiles/nas-media.inetloc"
    if [[ -f "$NAS_INETLOC_SRC" ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$NAS_INETLOC_DST")"
        sed \
          -e "s|__NAS_USER__|$NAS_USER|g" \
          -e "s|__NAS_HOST__|$NAS_HOST|g" \
          -e "s|__NAS_SHARE_MEDIA__|${NAS_SHARE_MEDIA:-media}|g" \
          "$NAS_INETLOC_SRC" > "$NAS_INETLOC_DST"
        success "Rendered NAS Internet Location → ${NAS_INETLOC_DST/#$HOME/~}"
        INSTALLED+=("NAS .inetloc (rendered with your values)")

        # Idempotent Login Item: remove any stale items (by name) before
        # adding the fresh one. Catches:
        #   - a previous run's rendered file at a different path,
        #   - a broken login item left over after the .inetloc moved,
        #   - the "truenas-media.inetloc" name from the pre-refactor era.
        # Each `try` block silently absorbs the case where the name isn't
        # there to delete, so this is safe to re-run.
        osascript <<'AS' 2>/dev/null || true
tell application "System Events"
    try
        delete login item "nas-media.inetloc"
    end try
    try
        delete login item "truenas-media.inetloc"
    end try
end tell
AS
        # Register the new one. `hidden:true` is requested but macOS Sequoia
        # ignores it for non-application paths — the Login Item shows in
        # System Settings but doesn't open a window at login (because an
        # .inetloc just triggers a mount), so the UX impact is nil.
        osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$NAS_INETLOC_DST\", hidden:true}" >/dev/null 2>&1 || true
      else
        dry "render $NAS_INETLOC_SRC → $NAS_INETLOC_DST + register as Login Item"
      fi
    fi
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
