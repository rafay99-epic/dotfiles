# =============================================================================
# Prometheus Dotfiles — Brewfile  (core, always installed)
# =============================================================================
#
#  Apply:    brew bundle --file=Brewfile
#  Verify:   brew bundle check --file=Brewfile
#  Cleanup:  brew bundle cleanup --file=Brewfile --force   (DANGEROUS)
#
#  WM-specific packages live in Brewfile.omniwm / Brewfile.aerospace.
#  Optional GUI apps (Ghostty, Cursor, Claude, Spotify) are
#  prompted individually by install.sh — they're not in this Brewfile so
#  someone running `brew bundle` directly doesn't get every app forced on.
#
# =============================================================================

# ── Shells & Prompts ─────────────────────────────────────────────────────────
brew "fish"
brew "starship"
brew "fastfetch"

# ── Zsh plugins ──────────────────────────────────────────────────────────────
# fish-like input experience for zsh. fzf-tab is git-cloned by install.sh
# (no homebrew formula).
brew "zsh-autosuggestions"          # greyed-out inline suggestions
brew "zsh-syntax-highlighting"      # colour as you type
brew "zsh-history-substring-search" # Ctrl+↑/↓ fuzzy-walk history

# ── CLI Tools ───────────────────────────────────────────────────────────────
brew "bat"            # better cat with syntax highlighting
brew "eza"            # modern ls
brew "lsd"            # alternative ls with icons
brew "fzf"            # fuzzy finder
brew "zoxide"         # smart cd replacement (`cd` learns frequent dirs)
brew "thefuck"        # corrects mistyped commands
brew "jq"             # JSON processor
brew "git-delta"      # pretty git diffs (referenced by ~/.gitconfig)
brew "atuin"          # magical shell history (SQLite-backed, Ctrl+R replacement)
brew "pv"             # pipe viewer — progress bars for tar / cp / etc. (used by archive-project)
brew "zstd"           # fast compression — used by archive-project for tarballs

# ── Runtimes & Languages ────────────────────────────────────────────────────
brew "rbenv"          # Ruby version manager
brew "nvm"            # Node version manager
brew "fnm"            # fast Node manager (fish-friendly)
brew "openjdk@17"     # JDK 17

# ── Mobile / hardware ───────────────────────────────────────────────────────
brew "scrcpy"         # Android screen mirror

# ── Fonts ───────────────────────────────────────────────────────────────────
cask "font-jetbrains-mono-nerd-font"

# Note: Porter (the sort-downloads replacement) is intentionally NOT installed
# from here — manage it directly via the tap:
#   brew install rafay99-epic/apps/porter
