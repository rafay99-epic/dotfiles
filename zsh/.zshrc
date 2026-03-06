 export BUN_INSTALL="$HOME/.bun" 
 export PATH="$BUN_INSTALL/bin:$PATH" 
 export PATH="$HOME/.cargo/bin:$PATH"

fastfetch

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

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"


# ---- FZF -----

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"


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

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/prometheus/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions


#-----------------
# Git Aliases
#-----------------
alias gs="git status"
alias g="git"
alias gc="git clone"
alias ga="git commit -a"
alias branch="git branch -r" 


#------------------
#Launch Claude Code 
#------------------
alias cc="claude"

alias cat="bat"
# ---- Eza (better ls) -----

#alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls='eza --icons=always'
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

# opencode
export PATH=/Users/prometheus/.opencode/bin:$PATH

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/prometheus/.lmstudio/bin"
# End of LM Studio CLI section


# Added by Windsurf
export PATH="/Users/prometheus/.codeium/windsurf/bin:$PATH"

# bun completions
[ -s "/Users/prometheus/.bun/_bun" ] && source "/Users/prometheus/.bun/_bun"

# Added by Antigravity
export PATH="/Users/prometheus/.antigravity/antigravity/bin:$PATH"
# zerobrew
export ZEROBREW_DIR=/Users/prometheus/.zerobrew
export ZEROBREW_BIN=/Users/prometheus/.local/bin
export ZEROBREW_ROOT=/opt/zerobrew
export ZEROBREW_PREFIX=/opt/zerobrew/prefix
export PKG_CONFIG_PATH="/opt/zerobrew/prefix/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
_zb_path_append() {
    local argpath="$1"
    case ":${PATH}:" in
        *:"$argpath":*) ;;
        *) export PATH="$argpath:$PATH" ;;
    esac;
}
_zb_path_append $ZEROBREW_BIN
_zb_path_append $ZEROBREW_PREFIX/bin
