# =============================================================================
# Fish Shell Config — mirrored from zsh/.zshrc
# =============================================================================

# Suppress default greeting (fastfetch replaces it)
set fish_greeting

# ── Prompt ────────────────────────────────────────────────────────────────────
starship init fish | source

# ── System info on open ───────────────────────────────────────────────────────
fastfetch

# ── Locale ────────────────────────────────────────────────────────────────────
set -gx LANG en_US.UTF-8

# =============================================================================
# PATH — all additions in one place
# fish_add_path prepends and deduplicates automatically
# =============================================================================

# Bun
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path $BUN_INSTALL/bin

# Rust / Cargo
fish_add_path $HOME/.cargo/bin

# Flutter SDK
fish_add_path $HOME/Flutter-SDK/flutter/bin

# Java (OpenJDK 17 via Homebrew)
fish_add_path /opt/homebrew/opt/openjdk@17/bin

# Local user bin
fish_add_path $HOME/.local/bin

# opencode
fish_add_path /Users/prometheus/.opencode/bin

# Windsurf (Codeium IDE)
fish_add_path /Users/prometheus/.codeium/windsurf/bin

# Antigravity
fish_add_path /Users/prometheus/.antigravity/antigravity/bin

# LM Studio CLI
fish_add_path /Users/prometheus/.lmstudio/bin

# zerobrew
set -gx ZEROBREW_DIR /Users/prometheus/.zerobrew
set -gx ZEROBREW_BIN /Users/prometheus/.local/bin
set -gx ZEROBREW_ROOT /opt/zerobrew
set -gx ZEROBREW_PREFIX /opt/zerobrew/prefix
set -gx PKG_CONFIG_PATH /opt/zerobrew/prefix/lib/pkgconfig $PKG_CONFIG_PATH
fish_add_path $ZEROBREW_BIN
fish_add_path $ZEROBREW_PREFIX/bin

# =============================================================================
# Runtime managers
# =============================================================================

# ── Conda ─────────────────────────────────────────────────────────────────────
if test -f /opt/anaconda3/bin/conda
    eval /opt/anaconda3/bin/conda "shell.fish" "hook" $argv | source
else if test -f /opt/anaconda3/etc/fish/conf.d/conda.fish
    source /opt/anaconda3/etc/fish/conf.d/conda.fish
else
    fish_add_path /opt/anaconda3/bin
end

# ── rbenv (Ruby) ──────────────────────────────────────────────────────────────
if command -q rbenv
    rbenv init - fish | source
end

# ── Node version manager ──────────────────────────────────────────────────────
# Option 1 — fnm (recommended, brew-installable, fish-native):
#   brew install fnm
if command -q fnm
    fnm env --use-on-cd | source
end

# Option 2 — nvm.fish (if you prefer staying with nvm):
#   nvm does not support fish natively — use the nvm.fish plugin instead:
#   fisher install jorgebucaran/nvm.fish
#   Then: nvm install lts, nvm use lts (auto-activates from .nvmrc)

# ── Bun completions ───────────────────────────────────────────────────────────
# Fish looks for completions in ~/.config/fish/completions/
# Run once to generate: bun completions fish > ~/.config/fish/completions/bun.fish

# =============================================================================
# Tools
# =============================================================================

# ── fzf (fuzzy finder) ────────────────────────────────────────────────────────
# Requires fzf >= 0.48 — provides Ctrl+R, Ctrl+T, Alt+C bindings
if command -q zoxide
    # --cmd cd rebinds `cd` to zoxide. Plain `cd foo` jumps by frequency;
    # `cdi` opens an fzf picker.
    zoxide init fish --cmd cd | source
end

if command -q fzf
    fzf --fish | source
    set -gx FZF_DEFAULT_OPTS "\
  --color=fg:#CBE0F0,bg:#011628,hl:#B388FF \
  --color=fg+:#CBE0F0,bg+:#143652,hl+:#B388FF \
  --color=info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED \
  --color=marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED"
end

# ── thefuck (command correction) ──────────────────────────────────────────────
if command -q thefuck
    thefuck --alias | source
end

# ── rbenv shims ───────────────────────────────────────────────────────────────
# (already handled above via rbenv init)

# ── Kiro IDE shell integration ─────────────────────────────────────────────────
string match -q "$TERM_PROGRAM" "kiro" && source (kiro --locate-shell-integration-path fish)

# =============================================================================
# Aliases
# =============================================================================

# ── Git ───────────────────────────────────────────────────────────────────────
alias gs="git status"
alias g="git"
alias gc="git clone"
alias ga="git commit -a"
alias branch="git branch -r"

# ── Better CLI tools ──────────────────────────────────────────────────────────
alias cat="bat"
alias ls="eza --icons=always"
alias ll="eza --icons=always -la"
alias lt="eza --icons=always --tree"

# ── Apps / shortcuts ──────────────────────────────────────────────────────────
alias cc="claude --dangerously-skip-permissions"
alias scrcpy120="scrcpy --video-codec=h265 --max-size=1920 --max-fps"

# AeroSpace profile sync
alias dock="aerospace-sync"
alias undock="aerospace-sync"

# `dev` is defined as a function in fish/functions/dev.fish (takes optional subpath args).

string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)
