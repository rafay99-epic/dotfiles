# =============================================================================
# Prometheus Dotfiles — Brewfile  (core, always installed)
# =============================================================================
#
#  Apply:    brew bundle --file=Brewfile
#  Verify:   brew bundle check --file=Brewfile
#  Cleanup:  brew bundle cleanup --file=Brewfile --force   (DANGEROUS)
#
#  WM-specific packages live in Brewfile.omniwm / Brewfile.aerospace.
#  Optional GUI apps (Ghostty, Cursor, Claude, Spotify, LM Studio) are
#  prompted individually by install.sh — they're not in this Brewfile so
#  someone running `brew bundle` directly doesn't get every app forced on.
#
# =============================================================================

# ── Shells & Prompts ─────────────────────────────────────────────────────────
brew "fish"
brew "starship"
brew "fastfetch"

# ── CLI Tools ───────────────────────────────────────────────────────────────
brew "bat"            # better cat with syntax highlighting
brew "eza"            # modern ls
brew "lsd"            # alternative ls with icons
brew "fzf"            # fuzzy finder
brew "thefuck"        # corrects mistyped commands
brew "jq"             # JSON processor
brew "git-delta"      # pretty git diffs (referenced by ~/.gitconfig)

# ── Runtimes & Languages ────────────────────────────────────────────────────
brew "rbenv"          # Ruby version manager
brew "nvm"            # Node version manager
brew "fnm"            # fast Node manager (fish-friendly)
brew "openjdk@17"     # JDK 17

# ── Mobile / hardware ───────────────────────────────────────────────────────
brew "scrcpy"         # Android screen mirror

# ── Fonts ───────────────────────────────────────────────────────────────────
cask "font-jetbrains-mono-nerd-font"
