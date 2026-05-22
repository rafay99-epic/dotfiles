# =============================================================================
# Fish Shell Config — mirrored from zsh/.zshrc
# =============================================================================

# Suppress default greeting
set fish_greeting

# ── Prompt ────────────────────────────────────────────────────────────────────
starship init fish | source

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

# Maestro
fish_add_path $HOME/.maestro/bin

# Android SDK
set -gx ANDROID_HOME $HOME/Library/Android/sdk
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools

# =============================================================================
# Runtime managers
# =============================================================================

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

# ── Atuin (shell history) ─────────────────────────────────────────────────────
# Config: ~/.config/atuin/config.toml (symlinked from dotfiles/atuin/config.toml)
# Ctrl+R → atuin TUI search. Up-arrow is left to default fish history.
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# ── rbenv shims ───────────────────────────────────────────────────────────────
# (already handled above via rbenv init)

# =============================================================================
# Aliases
# =============================================================================

# ── Git ───────────────────────────────────────────────────────────────────────
alias gs="git status"
alias g="git"
alias gc="git clone"
alias ga="git add *"
alias branch="git branch -r"

# ── Better CLI tools ──────────────────────────────────────────────────────────
alias cat="bat"

# ── eza (modern ls) ───────────────────────────────────────────────────────────
# Shared flags live in $EZA_BASE so every alias stays consistent.
#   --icons=always          nerd-font glyphs next to every entry
#   --group-directories-first   folders rise to the top
#   --classify=auto         append /, *, @ markers when piped to a TTY
#   --color=always          keep colour through pagers (bat/less -R)
#   --color-scale=all       gradient on size + age columns
#   --color-scale-mode=gradient   smooth gradient instead of fixed buckets
#   --hyperlink             OSC-8 clickable paths (Ghostty/iTerm/WezTerm)
#   --git                   show git status column in long view
#   --git-repos             show repo state on directory rows
#   --header                column headers in long view
#   --time-style=relative   "3 hours ago" instead of raw timestamps
set -gx EZA_BASE --icons=always --group-directories-first --classify=auto --color=always --color-scale=all --color-scale-mode=gradient --hyperlink

# Bigger icon → name gap so glyphs don't kiss the text.
set -gx EZA_ICON_SPACING 2

# Tokyo-Night-ish palette. eza uses LS_COLORS syntax; `38;2;R;G;B` is 24-bit fg.
# Each line is one rule — `string join ':'` collapses them into the format eza
# wants. Reorder freely; first match wins.
set -gx EZA_COLORS (string join ':' \
    "di=1;38;2;122;162;247" \
    "ex=1;38;2;158;206;106" \
    "ln=38;2;125;207;255" \
    "or=38;2;247;118;142" \
    "pi=38;2;224;175;104" \
    "so=38;2;187;154;247" \
    "bd=38;2;255;158;100" \
    "cd=38;2;255;158;100" \
    "ur=38;2;224;175;104" \
    "uw=38;2;255;158;100" \
    "ux=38;2;158;206;106" \
    "ue=38;2;158;206;106" \
    "gr=38;2;224;175;104" \
    "gw=38;2;255;158;100" \
    "gx=38;2;158;206;106" \
    "tr=38;2;224;175;104" \
    "tw=38;2;255;158;100" \
    "tx=38;2;158;206;106" \
    "ga=38;2;158;206;106" \
    "gm=38;2;224;175;104" \
    "gd=38;2;247;118;142" \
    "gv=38;2;187;154;247" \
    "gt=38;2;125;207;255" \
    "xx=38;2;86;95;137" \
    "da=38;2;125;207;255" \
    "sn=38;2;224;175;104" \
    "sb=38;2;255;158;100" \
    "uu=38;2;187;154;247" \
    "un=38;2;86;95;137" \
    "gu=38;2;187;154;247" \
    "gn=38;2;86;95;137" \
    "*.md=1;38;2;187;154;247" \
    "*.markdown=1;38;2;187;154;247" \
    "*.rst=38;2;187;154;247" \
    "*.txt=38;2;192;202;245" \
    "*.pdf=38;2;247;118;142" \
    "*.json=38;2;255;158;100" \
    "*.jsonc=38;2;255;158;100" \
    "*.toml=38;2;255;158;100" \
    "*.yaml=38;2;255;158;100" \
    "*.yml=38;2;255;158;100" \
    "*.ini=38;2;255;158;100" \
    "*.conf=38;2;255;158;100" \
    "*.cfg=38;2;255;158;100" \
    "*.env=1;38;2;247;118;142" \
    "*.js=38;2;224;175;104" \
    "*.mjs=38;2;224;175;104" \
    "*.cjs=38;2;224;175;104" \
    "*.jsx=38;2;224;175;104" \
    "*.ts=38;2;125;207;255" \
    "*.tsx=38;2;125;207;255" \
    "*.py=38;2;125;207;255" \
    "*.rs=38;2;255;158;100" \
    "*.go=38;2;125;207;255" \
    "*.rb=38;2;247;118;142" \
    "*.lua=38;2;122;162;247" \
    "*.fish=38;2;158;206;106" \
    "*.sh=38;2;158;206;106" \
    "*.zsh=38;2;158;206;106" \
    "*.bash=38;2;158;206;106" \
    "*.c=38;2;125;207;255" \
    "*.h=38;2;125;207;255" \
    "*.cpp=38;2;125;207;255" \
    "*.swift=38;2;255;158;100" \
    "*.kt=38;2;187;154;247" \
    "*.dart=38;2;125;207;255" \
    "*.html=38;2;255;158;100" \
    "*.css=38;2;125;207;255" \
    "*.scss=38;2;187;154;247" \
    "*.vue=38;2;158;206;106" \
    "*.svelte=38;2;255;158;100" \
    "*.png=38;2;187;154;247" \
    "*.jpg=38;2;187;154;247" \
    "*.jpeg=38;2;187;154;247" \
    "*.webp=38;2;187;154;247" \
    "*.gif=38;2;187;154;247" \
    "*.svg=38;2;187;154;247" \
    "*.ico=38;2;187;154;247" \
    "*.mp4=1;38;2;187;154;247" \
    "*.mkv=1;38;2;187;154;247" \
    "*.mov=1;38;2;187;154;247" \
    "*.mp3=38;2;224;175;104" \
    "*.wav=38;2;224;175;104" \
    "*.flac=38;2;224;175;104" \
    "*.zip=1;38;2;247;118;142" \
    "*.tar=1;38;2;247;118;142" \
    "*.gz=1;38;2;247;118;142" \
    "*.tgz=1;38;2;247;118;142" \
    "*.bz2=1;38;2;247;118;142" \
    "*.xz=1;38;2;247;118;142" \
    "*.7z=1;38;2;247;118;142" \
    "*.rar=1;38;2;247;118;142" \
    "*.dmg=38;2;247;118;142" \
    "*.iso=38;2;247;118;142" \
    "*.lock=38;2;86;95;137" \
    "*.log=38;2;86;95;137" \
    "*.bak=38;2;86;95;137" \
    "*.tmp=38;2;86;95;137" \
    ".DS_Store=38;2;86;95;137" \
    "*Dockerfile=38;2;125;207;255" \
    "*Makefile=38;2;255;158;100" \
    "*README.md=1;4;38;2;158;206;106" \
    "*LICENSE=38;2;224;175;104")

# Core listings — `ls` is bound to the long view (same as `ll`).
# Plain grid is still reachable via `lG`.
alias ls="eza $EZA_BASE --long --header --git --time-style=relative"
alias ll="eza $EZA_BASE --long --header --git --time-style=relative"
alias l="eza $EZA_BASE --oneline"
alias lG="eza $EZA_BASE"
alias la="eza $EZA_BASE --long --header --git --time-style=relative --all"
alias lla="eza $EZA_BASE --long --header --git --time-style=relative --all"

# Tree views (depth-limited — unbounded trees in node_modules will ruin your day)
alias lt="eza $EZA_BASE --tree --level=2"
alias lt3="eza $EZA_BASE --tree --level=3"
alias lta="eza $EZA_BASE --tree --level=2 --all --git-ignore"
alias ltd="eza $EZA_BASE --tree --level=2 --only-dirs"

# Sorted views
alias lr="eza $EZA_BASE --long --header --git --time-style=relative --sort=modified --reverse"   # newest first
alias lS="eza $EZA_BASE --long --header --git --time-style=relative --sort=size --reverse"       # largest first
alias lg="eza $EZA_BASE --long --header --git --git-repos --time-style=relative"                 # repo-aware
alias ld="eza $EZA_BASE --long --header --only-dirs"                                              # dirs only

# ── Apps / shortcuts ──────────────────────────────────────────────────────────
alias cc="claude --dangerously-skip-permissions"
alias scrcpy120="scrcpy --video-codec=h265 --max-size=1920 --max-fps"

# AeroSpace profile sync
alias dock="aerospace-sync"
alias undock="aerospace-sync"

# `dev` is defined as a function in fish/functions/dev.fish (takes optional subpath args).
# `gm` is defined as a function in fish/functions/gm.fish (git commit -m + push).

# ── Project shortcuts ─────────────────────────────────────────────────────────
alias lumo="cd $HOME/Code/Lumo/"
alias envpilot.dev="cd $HOME/Code/ENV_Connect/"
alias tudo_tech_lab="cd $HOME/Code/TudoNumTechLab/"
alias media="cd /Volumes/media/"
