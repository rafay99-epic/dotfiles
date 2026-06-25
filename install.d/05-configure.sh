#!/usr/bin/env bash
# shellcheck disable=SC1091
# Reason for the disable above: the config loader at
# $DOTFILES/bin/lib/dotfiles-config.sh is sourced via a dynamic path at
# runtime. The path is correct, but a static checker can't follow it.
# =============================================================================
# install.d/05-configure.sh — first-run + --reconfigure wizard
# =============================================================================
#
# Writes ~/.config/dotfiles/local.env from interactive answers, then sources
# it so later install modules see the values via the shared loader at
# bin/lib/dotfiles-config.sh.
#
# Behavior:
#   - first run (no config file)           → ask every question, write file
#   - config exists, no --reconfigure flag → silently load existing file
#   - config exists, --reconfigure flag    → re-ask everything, current
#                                            values are the defaults
#
# Globals consumed (set by install.sh):
#   DOTFILES, DRY_RUN, RECONFIGURE
#
# Globals exported (after sourcing the loader):
#   CODE_DIR, GIT_USER_NAME, GIT_USER_EMAIL, HAS_NAS, NAS_HOST, NAS_USER,
#   NAS_SHARE_MEDIA, NAS_MOUNT_MEDIA, HAS_TIMEMACHINE_NAS, NAS_SHARE_TM,
#   TM_SCHEDULE_MONTHLY, ENABLE_ARCHIVE_PROJECT, ARCHIVE_AFTER_MONTHS

# ── Input helpers ────────────────────────────────────────────────────────────
# Bash-3.2-compatible (macOS default). Avoids ${var,,}, [[ … =~ ]] is fine.

# Ask a yes/no question. $2 = default ("true"|"yes"|"y" → yes; anything else → no).
# Returns 0 (success) on yes, 1 on no. Re-asks on invalid input.
ask_yn() {
  local question="$1" default="${2:-no}" hint ans
  case "$default" in
    true|TRUE|yes|YES|y|Y|1) hint="[Y/n]" ;;
    *)                       hint="[y/N]" ;;
  esac
  while true; do
    printf "  %s %s " "$question" "$hint"
    IFS= read -r ans
    [[ -z "$ans" ]] && ans="$default"
    case "$ans" in
      y|Y|yes|YES|Yes|true|TRUE|True|1)  return 0 ;;
      n|N|no|NO|No|false|FALSE|False|0)  return 1 ;;
      *) printf "    %s? answer y or n%s\n" "$YELLOW" "$RESET" ;;
    esac
  done
}

# Ask for free text. Empty input = use the default (which may itself be empty).
# Echoes the answer to stdout.
ask_text() {
  local question="$1" default="${2:-}" hint="" ans
  [[ -n "$default" ]] && hint=" ${DIM}[$default]${RESET}"
  printf "  %s%s " "$question" "$hint" >&2
  IFS= read -r ans
  [[ -z "$ans" ]] && ans="$default"
  printf '%s' "$ans"
}

# Ask for a positive integer.
ask_int() {
  local question="$1" default="${2:-1}" ans
  while true; do
    ans="$(ask_text "$question" "$default")"
    if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 )); then
      printf '%s' "$ans"
      return 0
    fi
    printf "    %s? must be a positive integer%s\n" "$YELLOW" "$RESET" >&2
  done
}

# ── Wizard body ──────────────────────────────────────────────────────────────
module_configure() {
  local cfg_path="$HOME/.config/dotfiles/local.env"
  local cfg_dir
  cfg_dir="$(dirname "$cfg_path")"

  # Fast path: config exists, not asked to reconfigure → just load it.
  # The message is yellow + multi-line so users don't keep wondering
  # "why isn't the wizard asking me anything?" — they always know the
  # wizard is being intentionally skipped and how to force it.
  if [[ -r "$cfg_path" ]] && [[ "${RECONFIGURE:-false}" != "true" ]]; then
    source "$DOTFILES/bin/lib/dotfiles-config.sh"
    echo
    echo -e "  ${YELLOW}⚙${RESET}  ${BOLD}Existing config loaded — wizard skipped.${RESET}"
    echo -e "     ${DIM}File: ${cfg_path/#$HOME/~}${RESET}"
    echo -e "     ${DIM}To re-ask every question: ${BOLD}./install.sh --reconfigure${RESET}"
    echo
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ -r "$cfg_path" ]]; then
      info "[dry-run] would re-prompt for config (--reconfigure)"
    else
      info "[dry-run] would create $cfg_path via interactive wizard"
    fi
    # Load any existing config so subsequent dry-run modules see real values.
    [[ -r "$cfg_path" ]] && source "$DOTFILES/bin/lib/dotfiles-config.sh"
    return 0
  fi

  heading "Configure your dotfiles"
  echo

  # Pre-fill defaults from existing config (if we're reconfiguring) or from
  # the loader (which gives global defaults like $HOME/Code on first run).
  if [[ -r "$cfg_path" ]]; then
    source "$DOTFILES/bin/lib/dotfiles-config.sh"
    info "Re-running setup. Your current values are the defaults — press Enter to keep them."
  else
    source "$DOTFILES/bin/lib/dotfiles-config.sh"
    info "First-time setup. I'll ask a few questions, then write your config to:"
    info "  ${CYAN}${cfg_path/#$HOME/~}${RESET}"
    info "Re-run this later with: ${BOLD}./install.sh --reconfigure${RESET}"
  fi
  echo

  # ── Code projects ─────────────────────────────────────────────────────────
  echo -e "  ${BOLD}Code projects${RESET}"
  CODE_DIR="$(ask_text "Where do you keep your code projects?" "${CODE_DIR:-$HOME/Code}")"
  echo

  # ── Git identity ──────────────────────────────────────────────────────────
  # If both env vars are unset/empty, try git's own global config as a default.
  echo -e "  ${BOLD}Git identity${RESET}"
  echo -e "  ${DIM}(used in commits — leave empty to keep whatever's in your global ~/.gitconfig)${RESET}"
  local default_name="$GIT_USER_NAME"
  local default_email="$GIT_USER_EMAIL"
  [[ -z "$default_name"  ]] && default_name="$(git config --global user.name 2>/dev/null  || echo '')"
  [[ -z "$default_email" ]] && default_email="$(git config --global user.email 2>/dev/null || echo '')"
  GIT_USER_NAME="$(ask_text  "Your name:"  "$default_name")"
  GIT_USER_EMAIL="$(ask_text "Your email:" "$default_email")"
  echo

  # ── NAS ───────────────────────────────────────────────────────────────────
  echo -e "  ${BOLD}NAS${RESET}"
  echo -e "  ${DIM}(any SMB share — TrueNAS, Synology, generic Samba)${RESET}"
  if ask_yn "Do you have a NAS to sync files to?" "$HAS_NAS"; then
    HAS_NAS=true
    NAS_HOST="$(ask_text       "NAS IP or hostname:"     "$NAS_HOST")"
    NAS_USER="$(ask_text       "NAS username:"           "$NAS_USER")"
    NAS_SHARE_MEDIA="$(ask_text "SMB share name for files:" "${NAS_SHARE_MEDIA:-media}")"
    NAS_MOUNT_MEDIA="$(ask_text "Mount point on this Mac:"  "${NAS_MOUNT_MEDIA:-/Volumes/media}")"
  else
    HAS_NAS=false
    # Force-disable every NAS-dependent feature so the file ends up consistent.
    HAS_TIMEMACHINE_NAS=false
    ENABLE_ARCHIVE_PROJECT=false
  fi
  echo

  # The rest of the wizard only asks NAS-dependent questions when HAS_NAS=true.
  if [[ "$HAS_NAS" == "true" ]]; then

    # ── Time Machine ────────────────────────────────────────────────────────
    echo -e "  ${BOLD}Time Machine on NAS${RESET}"
    echo -e "  ${DIM}(needs a SEPARATE share — Time Machine wants exclusive use)${RESET}"
    if ask_yn "Set up Time Machine backups to your NAS?" "$HAS_TIMEMACHINE_NAS"; then
      HAS_TIMEMACHINE_NAS=true
      NAS_SHARE_TM="$(ask_text "SMB share name for Time Machine:" "${NAS_SHARE_TM:-timemachine}")"
      if ask_yn "Replace Apple's hourly schedule with monthly-on-the-1st-at-03:00?" "$TM_SCHEDULE_MONTHLY"; then
        TM_SCHEDULE_MONTHLY=true
      else
        TM_SCHEDULE_MONTHLY=false
      fi
    else
      HAS_TIMEMACHINE_NAS=false
    fi
    echo

    # Auto-sorting ~/Downloads onto the NAS now lives in the Porter app
    # (~/Code/porter), not this dotfiles repo — so there's no sort-downloads
    # question here anymore.

    # ── archive-project ─────────────────────────────────────────────────────
    echo -e "  ${BOLD}archive-project${RESET}"
    echo -e "  ${DIM}(manual tool: move stale code projects from ~/Code/ to the NAS)${RESET}"
    if ask_yn "Install archive-project?" "$ENABLE_ARCHIVE_PROJECT"; then
      ENABLE_ARCHIVE_PROJECT=true
      ARCHIVE_AFTER_MONTHS="$(ask_int "Default 'old enough to archive' threshold (months):" "$ARCHIVE_AFTER_MONTHS")"
    else
      ENABLE_ARCHIVE_PROJECT=false
    fi
    echo
  fi

  # ── Write the file ─────────────────────────────────────────────────────────
  if ! mkdir -p "$cfg_dir" 2>/dev/null; then
    error "Could not create $cfg_dir — aborting"
    return 1
  fi

  # `chmod 600` because it has the NAS hostname + username and a fork of
  # this dotfiles repo might one day include secrets here. 600 = only the
  # owner can read it; no one else on the machine can.
  write_local_env "$cfg_path"
  chmod 600 "$cfg_path"

  success "Wrote ${cfg_path/#$HOME/~}"
  INSTALLED+=("local config (${cfg_path/#$HOME/~})")

  # Also write ~/.gitconfig.local if the user provided git identity. The
  # committed git/.gitconfig has an [include] line that picks this up, so
  # `git config user.name` will resolve correctly across all repos.
  write_gitconfig_local
  echo
}

# Write git identity to ~/.gitconfig.local. Skipped silently when both
# name and email are empty (the user opted out — global config or per-repo
# overrides will be used instead).
write_gitconfig_local() {
  local gc_local="$HOME/.gitconfig.local"
  if [[ -z "$GIT_USER_NAME" && -z "$GIT_USER_EMAIL" ]]; then
    info "Skipping ~/.gitconfig.local — no git identity provided."
    return 0
  fi
  cat > "$gc_local" <<EOF
# Generated by ./install.sh on $(date '+%Y-%m-%d at %H:%M').
# This file is loaded via the [include] block in ~/.gitconfig (which is
# the committed dotfiles/git/.gitconfig). Edit by hand or re-run
# ./install.sh --reconfigure.
[user]
    name  = $GIT_USER_NAME
    email = $GIT_USER_EMAIL
EOF
  chmod 600 "$gc_local"
  success "Wrote ${gc_local/#$HOME/~}"
}

# Write the captured values to $1, with section comments matching
# local.env.example for grep-ability.
write_local_env() {
  local path="$1"
  cat > "$path" <<EOF
# =============================================================================
# Prometheus Dotfiles — local config
# =============================================================================
# Generated by ./install.sh on $(date '+%Y-%m-%d at %H:%M').
# Re-run ./install.sh --reconfigure to update, or edit by hand.
# This file is gitignored — your values stay on this machine only.
# Mode 0600 — owner-only readable.
# =============================================================================

# ─ Code projects ────────────────────────────────────────────────────────────
CODE_DIR="$CODE_DIR"

# ─ Git identity ─────────────────────────────────────────────────────────────
GIT_USER_NAME="$GIT_USER_NAME"
GIT_USER_EMAIL="$GIT_USER_EMAIL"

# ─ NAS ──────────────────────────────────────────────────────────────────────
HAS_NAS=$HAS_NAS
NAS_HOST="$NAS_HOST"
NAS_USER="$NAS_USER"
NAS_SHARE_MEDIA="$NAS_SHARE_MEDIA"
NAS_MOUNT_MEDIA="$NAS_MOUNT_MEDIA"

# ─ Time Machine on the NAS ─────────────────────────────────────────────────
HAS_TIMEMACHINE_NAS=$HAS_TIMEMACHINE_NAS
NAS_SHARE_TM="$NAS_SHARE_TM"
TM_SCHEDULE_MONTHLY=$TM_SCHEDULE_MONTHLY

# ─ archive-project ──────────────────────────────────────────────────────────
ENABLE_ARCHIVE_PROJECT=$ENABLE_ARCHIVE_PROJECT
ARCHIVE_AFTER_MONTHS=$ARCHIVE_AFTER_MONTHS
EOF
}
