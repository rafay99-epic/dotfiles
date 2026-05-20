export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

###########################################
#            Startship Promote            #
###########################################
eval "$(starship init zsh)"


# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"


# ---- FZF -----

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# ---- zoxide (smart cd) -----
# --cmd cd rebinds the `cd` builtin to zoxide. Plain `cd foo` does fuzzy
# matching against frequent dirs; `cdi` opens an fzf picker.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi


#-------------------------------
# Use case-sensitive completion
#-------------------------------
CASE_SENSITIVE="true"

#-----------------------------------
# Use hyphen-insensitive completion.
#-----------------------------------
HYPHEN_INSENSITIVE="true"

#--------------------------------------
# Disable auto-setting terminal title.
#--------------------------------------
ISABLE_AUTO_TITLE="true"

#--------------------------------
# Enable command auto-correction.
#--------------------------------
ENABLE_CORRECTION="true"

#----------------
#Time and date
#----------------
HIST_STAMPS="dd/mm/yyyy"

#---------------
#Plug for Shell
#---------------
plugins=(
   git
   zsh-autosuggestions
   )

#--------------
#System Local
#--------------
export LANG=en_US.UTF-8

# ── nvm — lazy load ──────────────────────────────────────────────────────────
# Sourcing nvm.sh costs ~600ms on every shell start. Defer it until the first
# time `nvm`, `node`, `npm`, `npx`, `yarn`, or `pnpm` is actually invoked.
#
# Global npm tools (codex, claude-code, etc.) live in
# $NVM_DIR/versions/node/<v>/bin — we pre-add the newest installed version to
# $PATH so those binaries are findable immediately, without forcing nvm.sh to
# source. nvm itself (version switching, .nvmrc auto-use) still loads on first
# command invocation.
export NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR/versions/node" ]]; then
  # newest installed version, version-sorted (v22 wins over v18, etc.)
  _nvm_latest="$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -1)"
  if [[ -n "$_nvm_latest" && -d "$NVM_DIR/versions/node/$_nvm_latest/bin" ]]; then
    export PATH="$NVM_DIR/versions/node/$_nvm_latest/bin:$PATH"
  fi
  unset _nvm_latest
fi

_nvm_lazy_init() {
  # Drop our wrapper functions so the real commands (from nvm.sh) take over
  unset -f nvm node npm npx yarn pnpm 2>/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}
for _cmd in nvm node npm npx yarn pnpm; do
  eval "${_cmd}() { _nvm_lazy_init; ${_cmd} \"\$@\"; }"
done
unset _cmd
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# ---- Atuin (shell history) -----
# Config: ~/.config/atuin/config.toml (symlinked from dotfiles/atuin/config.toml)
# Ctrl+R → atuin TUI search. Up-arrow is left to default shell history.
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# ────────────────────────────────────────────────────────────────────────────
# Zsh plugins — fish-like input experience
# Loading order matters:
#   1. fzf-tab               (must be before any other compdef-touching plugin)
#   2. zsh-autosuggestions   (greyed inline suggestions; → or Ctrl+F to accept)
#   3. zsh-syntax-highlighting (must be sourced LAST except for substring-search)
#   4. zsh-history-substring-search (Ctrl+↑/↓ fuzzy-walk; must come after highlighting)
# ────────────────────────────────────────────────────────────────────────────

# ── fzf-tab — replaces Tab completion with an fzf picker ─────────────────────
# Git-cloned by install.sh to ~/.local/share/zsh/fzf-tab (no brew formula).
if [[ -f "$HOME/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "$HOME/.local/share/zsh/fzf-tab/fzf-tab.plugin.zsh"

  # Disable zsh's default sort so completions stay in the order eza/git print.
  zstyle ':completion:*' menu no
  zstyle ':completion:*:git-checkout:*' sort false

  # Previews: cd uses eza tree, file ops use bat.
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=always --tree --level=2 --color=always $realpath 2>/dev/null || ls -la $realpath'
  zstyle ':fzf-tab:complete:(bat|cat|less|vim|nvim|code):*' fzf-preview 'bat --style=numbers --color=always --line-range :200 $realpath 2>/dev/null || cat $realpath'

  # Group results by header (so completions read like a labelled menu).
  zstyle ':completion:*' format '[%d]'
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':fzf-tab:*' switch-group ',' '.'
fi

# ── zsh-autosuggestions ──────────────────────────────────────────────────────
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # Subtle Tokyo-Night grey for the ghost suggestion.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
  # → and Ctrl+F accept; Ctrl+Space accepts one word.
  bindkey '^F' autosuggest-accept
  bindkey '^[[C' forward-char    # don't let → trigger accept-or-forward bug
fi

# ── zsh-syntax-highlighting (must be sourced near the end) ───────────────────
if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ── zsh-history-substring-search (must come AFTER syntax-highlighting) ───────
if [[ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  # Ctrl+↑ / Ctrl+↓ walks history filtered by what's already typed.
  bindkey '^[[1;5A' history-substring-search-up
  bindkey '^[[1;5B' history-substring-search-down
fi


# Git aliases & gm() function are defined further down (after kaku.zsh source)
# because kaku redefines ga/gc/gst etc — these win by being last.


#------------------
#Launch Claude Code 
#------------------
alias cc="claude --dangerously-skip-permissions"

alias cat="bat"

# ---- Eza (better ls) ---------------------------------------------------------
# Shared flags live in $EZA_BASE so every alias stays consistent.
#   --icons=always                glyphs next to every entry
#   --group-directories-first     folders rise to the top
#   --classify=auto               /, *, @ markers when output is a TTY
#   --color=always                keep colour through pagers (bat/less -R)
#   --color-scale=all             gradient on size + age columns
#   --color-scale-mode=gradient   smooth gradient instead of fixed buckets
#   --hyperlink                   OSC-8 clickable paths (Ghostty/iTerm/WezTerm)
export EZA_BASE="--icons=always --group-directories-first --classify=auto --color=always --color-scale=all --color-scale-mode=gradient --hyperlink"

# Bigger icon → name gap so glyphs don't kiss the text.
export EZA_ICON_SPACING=2

# Tokyo-Night-ish palette. eza uses LS_COLORS syntax; `38;2;R;G;B` is 24-bit fg.
# Reorder freely; first match wins.
export EZA_COLORS="\
di=1;38;2;122;162;247:\
ex=1;38;2;158;206;106:\
ln=38;2;125;207;255:\
or=38;2;247;118;142:\
pi=38;2;224;175;104:\
so=38;2;187;154;247:\
bd=38;2;255;158;100:\
cd=38;2;255;158;100:\
ur=38;2;224;175;104:uw=38;2;255;158;100:ux=38;2;158;206;106:ue=38;2;158;206;106:\
gr=38;2;224;175;104:gw=38;2;255;158;100:gx=38;2;158;206;106:\
tr=38;2;224;175;104:tw=38;2;255;158;100:tx=38;2;158;206;106:\
ga=38;2;158;206;106:gm=38;2;224;175;104:gd=38;2;247;118;142:gv=38;2;187;154;247:gt=38;2;125;207;255:\
xx=38;2;86;95;137:da=38;2;125;207;255:sn=38;2;224;175;104:sb=38;2;255;158;100:\
uu=38;2;187;154;247:un=38;2;86;95;137:gu=38;2;187;154;247:gn=38;2;86;95;137:\
*.md=1;38;2;187;154;247:*.markdown=1;38;2;187;154;247:*.rst=38;2;187;154;247:\
*.txt=38;2;192;202;245:*.pdf=38;2;247;118;142:\
*.json=38;2;255;158;100:*.jsonc=38;2;255;158;100:*.toml=38;2;255;158;100:\
*.yaml=38;2;255;158;100:*.yml=38;2;255;158;100:*.ini=38;2;255;158;100:\
*.conf=38;2;255;158;100:*.cfg=38;2;255;158;100:*.env=1;38;2;247;118;142:\
*.js=38;2;224;175;104:*.mjs=38;2;224;175;104:*.cjs=38;2;224;175;104:*.jsx=38;2;224;175;104:\
*.ts=38;2;125;207;255:*.tsx=38;2;125;207;255:\
*.py=38;2;125;207;255:*.rs=38;2;255;158;100:*.go=38;2;125;207;255:*.rb=38;2;247;118;142:\
*.lua=38;2;122;162;247:*.fish=38;2;158;206;106:*.sh=38;2;158;206;106:\
*.zsh=38;2;158;206;106:*.bash=38;2;158;206;106:\
*.c=38;2;125;207;255:*.h=38;2;125;207;255:*.cpp=38;2;125;207;255:\
*.swift=38;2;255;158;100:*.kt=38;2;187;154;247:*.dart=38;2;125;207;255:\
*.html=38;2;255;158;100:*.css=38;2;125;207;255:*.scss=38;2;187;154;247:\
*.vue=38;2;158;206;106:*.svelte=38;2;255;158;100:\
*.png=38;2;187;154;247:*.jpg=38;2;187;154;247:*.jpeg=38;2;187;154;247:\
*.webp=38;2;187;154;247:*.gif=38;2;187;154;247:*.svg=38;2;187;154;247:*.ico=38;2;187;154;247:\
*.mp4=1;38;2;187;154;247:*.mkv=1;38;2;187;154;247:*.mov=1;38;2;187;154;247:\
*.mp3=38;2;224;175;104:*.wav=38;2;224;175;104:*.flac=38;2;224;175;104:\
*.zip=1;38;2;247;118;142:*.tar=1;38;2;247;118;142:*.gz=1;38;2;247;118;142:\
*.tgz=1;38;2;247;118;142:*.bz2=1;38;2;247;118;142:*.xz=1;38;2;247;118;142:\
*.7z=1;38;2;247;118;142:*.rar=1;38;2;247;118;142:\
*.dmg=38;2;247;118;142:*.iso=38;2;247;118;142:\
*.lock=38;2;86;95;137:*.log=38;2;86;95;137:*.bak=38;2;86;95;137:*.tmp=38;2;86;95;137:\
.DS_Store=38;2;86;95;137:\
*Dockerfile=38;2;125;207;255:*Makefile=38;2;255;158;100:\
*README.md=1;4;38;2;158;206;106:*LICENSE=38;2;224;175;104"

# Aliases defined further down (after kaku.zsh source) so kaku's `ll`/`la`/`l`
# overrides don't clobber them.
# thefuck alias
eval $(thefuck --alias)

#-------------------
#phone recording
#-------------------

alias scrcpy120="scrcpy --video-codec=h265 --max-size=1920 --max-fps"


export PATH="$HOME/Flutter-SDK/flutter/bin:$PATH"


export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# AeroSpace profile sync
aerospace-sync() {
  local script="$HOME/.local/bin/aerospace-sync"
  [[ ! -x "$script" ]] && echo "Error: aerospace-sync not found" >&2 && return 1
  "$script"
}
alias dock='aerospace-sync'
alias undock='aerospace-sync'
# killport <port> — kills whatever is listening on a TCP port (see bin/killport)

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ ":$PATH:" != *":$HOME/.config/kaku/zsh/bin:"* ]] && export PATH="$HOME/.config/kaku/zsh/bin:$PATH" # Kaku PATH Integration
[[ -f "$HOME/.config/kaku/zsh/kaku.zsh" ]] && source "$HOME/.config/kaku/zsh/kaku.zsh" # Kaku Shell Integration
export PATH=$PATH:$HOME/.maestro/bin



# Project Keybing
# dev [subpath...] — cd into ~/Code or a subdirectory beneath it.
# Multiple args are joined with spaces, so `dev full stack` -> ~/Code/full stack.
dev() {
  if (( $# == 0 )); then
    cd "$HOME/Code"
  else
    cd "$HOME/Code/$*"
  fi
}
_dev() { _path_files -W "$HOME/Code" -/ }
compdef _dev dev
alias lumo="cd $HOME/Code/Lumo/"
alias envpilot.dev="cd $HOME/Code/ENV_Connect/"
alias tudo_tech_lab="cd $HOME/Code/TudoNumTechLab/"

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools

# ── Git aliases ──────────────────────────────────────────────────────────────
# After kaku.zsh source — kaku defines ga/gc/gst, we override here.
alias gs="git status"
alias g="git"
alias gc="git clone"
alias ga="git add *"
alias branch="git branch -r"
gm() { git commit -m "$1" && git push }

# ── eza aliases ──────────────────────────────────────────────────────────────
# Defined here (not next to EZA_BASE above) because kaku.zsh redefines
# ll/la/l when it's sourced — these win by being last.
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
alias lr="eza $EZA_BASE --long --header --git --time-style=relative --sort=modified --reverse"
alias lS="eza $EZA_BASE --long --header --git --time-style=relative --sort=size --reverse"
alias lg="eza $EZA_BASE --long --header --git --git-repos --time-style=relative"
alias ld="eza $EZA_BASE --long --header --only-dirs"
