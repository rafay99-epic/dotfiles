eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Homebrew: update manually (`brew update` / `brew upgrade`), never on every command.
export HOMEBREW_NO_AUTO_UPDATE=1   # skip the background auto-update on each brew invocation
export HOMEBREW_NO_ENV_HINTS=1     # silence the "$HOMEBREW_..." env-hint footer
