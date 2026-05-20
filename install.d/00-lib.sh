#!/usr/bin/env bash
# =============================================================================
# install.d/00-lib.sh — Shared helpers for install.sh + modules
# =============================================================================
#
# Sourced by install.sh after globals are defined and before any module runs.
# Provides:
#   - Color variables (RED, GREEN, YELLOW, BLUE, CYAN, BOLD, RESET)
#   - Logging:  info / success / warn / error / heading / dry
#   - prompt "Question?"           → Y/N (returns 0 for Y, 1 for N; honors $DRY_RUN)
#   - link <src> <dst>              → idempotent symlink with backup
#   - require_brew                  → exits if Homebrew is missing
#   - brew_tap <tap>                → idempotent tap
#   - brew_install <formula> [--cask] → idempotent install, populates global arrays
#   - curl_install <name> <check_cmd> <url> → install via curl|bash if check fails
#   - configure_claude_statusline   → wires Starship into ~/.claude/settings.json
#   - npm_install <name> <check_cmd> <pkg> → npm -g install if check fails
#
# Globals expected to be set by install.sh BEFORE sourcing this file:
#   DRY_RUN    (true|false)
#   ERRORS SKIPPED LINKED INSTALLED    (arrays — empty is fine)
# =============================================================================

# ── Colors ────────────────────────────────────────────────────────────────────
# ANSI-C ($'...') quoting so each variable holds the actual ESC byte.
# This way both `echo -e "$BOLD"` and `printf '%s' "$BOLD"` render correctly.
# (With plain single quotes, the variables would contain a literal "\033"
# 5-character string that only `echo -e` / `printf %b` interpret.)
if [[ -t 1 ]]; then
  RED=$'\e[0;31m'; YELLOW=$'\e[0;33m'; GREEN=$'\e[0;32m'
  BLUE=$'\e[0;34m'; CYAN=$'\e[0;36m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
  RED=''; YELLOW=''; GREEN=''; BLUE=''; CYAN=''; BOLD=''; RESET=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
info()    { echo -e "  ${BLUE}→${RESET}  $*"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "  ${RED}✗${RESET}  $*"; }
heading() { echo -e "\n${BOLD}${CYAN}▸  $*${RESET}"; echo -e "  ${CYAN}$(printf '%.0s─' {1..40})${RESET}"; }
dry()     { echo -e "  ${YELLOW}(dry)${RESET} $*"; }

# ── Prompt helper ─────────────────────────────────────────────────────────────
# prompt "Question?" → returns 0 for Y, 1 for N
#   - In dry-run: prints the question, auto-answers Yes
#   - When $YES_ALL is true (--yes flag): prints + auto-Yes (real run)
#   - Otherwise: reads y/n from /dev/tty (default Y on bare Enter)
prompt() {
  local question="$1"
  local answer

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}(dry)${RESET} Would ask: ${BOLD}$question${RESET} → assuming Yes"
    return 0
  fi

  if [[ "${YES_ALL:-false}" == true ]]; then
    echo -e "\n  ${BOLD}${BLUE}?${RESET}  ${BOLD}$question${RESET} [Y/n] ${GREEN}y${RESET}  ${CYAN}(--yes)${RESET}"
    return 0
  fi

  echo -en "\n  ${BOLD}${BLUE}?${RESET}  ${BOLD}$question${RESET} [Y/n] "
  read -r answer </dev/tty 2>/dev/null || answer="y"
  echo ""
  [[ "${answer:-y}" =~ ^[Yy]$ ]]
}

# ── Symlink helper ────────────────────────────────────────────────────────────
link() {
  local src="$1"
  local dst="$2"
  local label="${dst/#$HOME/\~}"

  if [[ ! -e "$src" ]]; then
    error "Source not found: $src"
    ERRORS+=("Missing source: $src")
    return 1
  fi

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      success "Already linked: ${label}"
      SKIPPED+=("$label (already correct)")
      return 0
    else
      error "Conflict: ${label} → ${current_target}"
      error "       Expected → ${src}"
      error "       Run: rm \"${dst}\" and re-run."
      ERRORS+=("Symlink conflict: $dst")
      return 1
    fi
  fi

  if [[ -e "$dst" ]]; then
    local backup
    backup="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up ${label} → ${backup/#$HOME/\~}"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$dst" "$backup"
    else
      dry "mv $dst $backup"
    fi
  fi

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    success "Linked: ${label}"
  else
    dry "ln -sf $src $dst"
  fi
  LINKED+=("$label")
}

# ── Brew guard ────────────────────────────────────────────────────────────────
# Ensures Homebrew is available before any brew_install / brew_tap call.
require_brew() {
  if ! command -v brew &>/dev/null; then
    error "Homebrew is not installed. Cannot continue with package installation."
    exit 1
  fi
}

# ── Brew tap helper ──────────────────────────────────────────────────────────
brew_tap() {
  local tap="$1"
  require_brew
  if brew tap | grep -q "^${tap}$"; then
    return 0
  fi
  if [[ "$DRY_RUN" == false ]]; then
    info "Tapping $tap..."
    brew tap "$tap" --quiet || {
      error "Failed to tap $tap"
      ERRORS+=("brew tap $tap failed")
      return 1
    }
  else
    dry "brew tap $tap"
  fi
}

# ── Brew package helper ──────────────────────────────────────────────────────
brew_install() {
  local formula="$1"
  local flags="${2:-}"
  local name
  name="$(basename "$formula")"
  require_brew

  if [[ "$flags" == "--cask" ]]; then
    if brew list --cask "$name" &>/dev/null 2>&1; then
      success "Already installed (cask): $name"
      SKIPPED+=("$name")
      return 0
    fi
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing cask: $name"
      brew install --cask --quiet "$formula" || {
        error "Failed to install cask: $name"
        ERRORS+=("brew install --cask $formula failed")
        return 1
      }
    else
      dry "brew install --cask $formula"
    fi
  else
    if brew list "$name" &>/dev/null 2>&1; then
      success "Already installed: $name"
      SKIPPED+=("$name")
      return 0
    fi
    if [[ "$DRY_RUN" == false ]]; then
      info "Installing: $name"
      brew install --quiet "$formula" || {
        error "Failed to install: $name"
        ERRORS+=("brew install $formula failed")
        return 1
      }
    else
      dry "brew install $formula"
    fi
  fi
  INSTALLED+=("$name")
  success "Installed: $name"
}

# ── curl installer helper ────────────────────────────────────────────────────
# curl_install "name" "check_cmd" "install_url"
curl_install() {
  local name="$1"
  local check_cmd="$2"
  local install_url="$3"

  if eval "$check_cmd" &>/dev/null; then
    success "Already installed: $name"
    SKIPPED+=("$name")
    return 0
  fi

  if [[ "$DRY_RUN" == false ]]; then
    info "Installing $name..."
    curl -fsSL "$install_url" | bash || {
      error "Failed to install $name"
      ERRORS+=("$name install failed")
      return 1
    }
    INSTALLED+=("$name")
    success "Installed: $name"
  else
    dry "curl -fsSL $install_url | bash"
  fi
}

# ── Claude Code statusline configurer ────────────────────────────────────────
# Idempotently sets ~/.claude/settings.json `statusLine` to use Starship.
# Preserves all other keys via jq merge. Skips cleanly if jq/starship missing.
configure_claude_statusline() {
  local settings_file="$HOME/.claude/settings.json"
  local desired_command="starship statusline claude-code"
  local label="Claude Code statusline"

  if ! command -v starship &>/dev/null; then
    warn "starship not installed — skipping $label config"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    warn "jq not installed — skipping $label config"
    return 0
  fi

  # Already configured the way we want?
  if [[ -f "$settings_file" ]]; then
    local current
    current="$(jq -r '.statusLine.command // ""' "$settings_file" 2>/dev/null || echo "")"
    if [[ "$current" == "$desired_command" ]]; then
      success "$label already configured"
      SKIPPED+=("$label")
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    dry "merge .statusLine into $settings_file"
    return 0
  fi

  mkdir -p "$HOME/.claude"

  local tmpfile
  tmpfile="$(mktemp)"
  if [[ -f "$settings_file" ]]; then
    if jq --arg cmd "$desired_command" \
         '.statusLine = {type: "command", command: $cmd}' \
         "$settings_file" > "$tmpfile"; then
      mv "$tmpfile" "$settings_file"
    else
      rm -f "$tmpfile"
      error "Failed to update $settings_file (invalid JSON?)"
      ERRORS+=("$label config failed")
      return 1
    fi
  else
    jq -n --arg cmd "$desired_command" \
       '{statusLine: {type: "command", command: $cmd}}' \
       > "$settings_file"
  fi
  success "$label configured"
  INSTALLED+=("$label")
}

# ── npm global install helper ────────────────────────────────────────────────
# npm_install "name" "check_cmd" "npm_package"
npm_install() {
  local name="$1"
  local check_cmd="$2"
  local package="$3"

  if eval "$check_cmd" &>/dev/null; then
    success "Already installed: $name"
    SKIPPED+=("$name")
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    warn "npm not found — cannot install $name. Install Node.js first, then run: npm install -g $package"
    return 1
  fi

  if [[ "$DRY_RUN" == false ]]; then
    info "Installing $name via npm..."
    npm install -g "$package" || {
      error "Failed to install $name"
      ERRORS+=("npm install -g $package failed")
      return 1
    }
    INSTALLED+=("$name")
    success "Installed: $name"
  else
    dry "npm install -g $package"
  fi
}
