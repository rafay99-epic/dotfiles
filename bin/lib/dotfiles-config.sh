#!/usr/bin/env bash
# dotfiles-config.sh — sourced by every script that reads user config.
#
# Loads ~/.config/dotfiles/local.env if it exists. Applies sensible
# defaults for anything not set. Never fails or exits — callers can
# always rely on the documented variables being defined after sourcing
# this file (empty string if the user opted out of a feature).
#
# Usage from any script:
#
#   # near the top, after `set -uo pipefail`:
#   # shellcheck source=lib/dotfiles-config.sh
#   . "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/dotfiles-config.sh"
#
#   # …then refer to the variables this exposes (CODE_DIR, NAS_HOST, etc.)
#
# The config file is written by install.d/05-configure.sh on first run
# (or whenever the user passes ./install.sh --reconfigure).

# Where the user config lives. Override DOTFILES_CONFIG in the calling
# environment if you keep it elsewhere; useful for testing.
DOTFILES_CONFIG="${DOTFILES_CONFIG:-$HOME/.config/dotfiles/local.env}"

# Source the file if present. We don't error when it's missing —
# scripts should still be runnable on a fresh machine before the
# wizard has run, falling back to the defaults below.
if [[ -r "$DOTFILES_CONFIG" ]]; then
  # shellcheck disable=SC1090
  . "$DOTFILES_CONFIG"
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
# The `:=` parameter expansion sets the variable only if it's unset or
# empty. So values from local.env take precedence; defaults fill the rest.

# Code projects
: "${CODE_DIR:=$HOME/Code}"

# Git identity — empty by default. Callers that need this should check
# and prompt the user (or the install wizard will fill it in).
: "${GIT_USER_NAME:=}"
: "${GIT_USER_EMAIL:=}"

# NAS — opt-in. Everything related defaults to off.
: "${HAS_NAS:=false}"
: "${NAS_HOST:=}"
: "${NAS_USER:=}"
: "${NAS_SHARE_MEDIA:=media}"
: "${NAS_MOUNT_MEDIA:=/Volumes/media}"

# Time Machine on the NAS — also opt-in, only relevant when HAS_NAS=true.
: "${HAS_TIMEMACHINE_NAS:=false}"
: "${NAS_SHARE_TM:=timemachine}"
: "${TM_SCHEDULE_MONTHLY:=true}"

# Auto-sort ~/Downloads onto the NAS.
: "${ENABLE_SORT_DOWNLOADS:=false}"
: "${SORT_DOWNLOADS_BACKGROUND:=true}"   # true → LaunchAgent; false → manual only

# Archive-project tool.
: "${ENABLE_ARCHIVE_PROJECT:=false}"
: "${ARCHIVE_AFTER_MONTHS:=1}"

# Helper: build the canonical SMB URL for a given share, using the
# NAS_USER and NAS_HOST that were configured. Returns empty when NAS
# isn't configured. Callers should check `is_truthy "$HAS_NAS"` first.
dotfiles_smb_url() {
  local share="$1"
  if [[ -z "$NAS_HOST" || -z "$NAS_USER" ]]; then
    printf ''
    return 1
  fi
  printf 'smb://%s@%s/%s' "$NAS_USER" "$NAS_HOST" "$share"
}

# Helper: true/false test for the toggles. Accepts true/yes/y/1 (case
# insensitive). Anything else is false — including empty string. So
# `is_truthy "$HAS_NAS"` always works regardless of the user's
# spelling preference.
is_truthy() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    true|yes|y|1|on) return 0 ;;
    *)               return 1 ;;
  esac
}

# Helper: the canonical local.env path, exposed so the install wizard
# and any reporter can show it without duplicating the constant.
dotfiles_config_path() {
  printf '%s' "$DOTFILES_CONFIG"
}
