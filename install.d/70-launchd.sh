#!/usr/bin/env bash
# =============================================================================
# install.d/70-launchd.sh — LaunchAgents / LaunchDaemons
# =============================================================================
# Two background services:
#
#   tm-monthly       LaunchDaemon (/Library/LaunchDaemons/) — root-owned.
#                    Replaces Apple's hourly Time Machine schedule with one
#                    backup on the 1st of each month at 03:00. Also calls
#                    `sudo tmutil disable` to kill the hourly auto-backup.
#
#   sort-downloads   LaunchAgent (~/Library/LaunchAgents/) — user-scoped.
#                    Watches ~/Downloads and routes files to
#                    /Volumes/media/<Category>/. Must be a User Agent
#                    because launchd-spawned daemons cannot write through
#                    Finder-mounted SMB shares.
#
# Plist source files use __HOME__ as a placeholder; we sed-substitute $HOME
# at install time for the LaunchAgent (the LaunchDaemon doesn't need
# user-path templating).
#
# Note: screenshots are *not* handled by sort-downloads. macOS scopes SMB
# write permissions to the Aqua GUI session that performed the mount —
# launchd-spawned processes can list and read but not write. Configure your
# screenshot tool (e.g. Shottr) to save directly to /Volumes/media/screenshots/
# instead. The .inetloc login item keeps the share mounted.

module_launchd() {
  heading "LaunchAgents"

  # ── Time Machine: monthly LaunchDaemon ────────────────────────────────────
  # Replaces TM's default hourly schedule with a single backup on the 1st of
  # each month at 03:00. Disables the hourly auto-backup at the same time.
  TM_PLIST_SRC="$DOTFILES/launchd/com.prometheus.tm-monthly.plist"
  TM_PLIST_DST="/Library/LaunchDaemons/com.prometheus.tm-monthly.plist"
  if [[ -f "$TM_PLIST_SRC" ]]; then
    if [[ -f "$TM_PLIST_DST" ]] && cmp -s "$TM_PLIST_SRC" "$TM_PLIST_DST"; then
      success "Already installed: monthly Time Machine schedule"
      SKIPPED+=("tm-monthly LaunchDaemon")
    elif [[ "$DRY_RUN" == false ]]; then
      info "Installing monthly Time Machine LaunchDaemon (requires sudo)..."
      sudo cp "$TM_PLIST_SRC" "$TM_PLIST_DST" \
        && sudo chown root:wheel "$TM_PLIST_DST" \
        && sudo chmod 644 "$TM_PLIST_DST" \
        && sudo launchctl unload "$TM_PLIST_DST" 2>/dev/null; \
         sudo launchctl load "$TM_PLIST_DST" \
        && sudo tmutil disable \
        && success "Monthly Time Machine schedule installed (fires 1st of each month at 03:00)"
      INSTALLED+=("tm-monthly LaunchDaemon")
    else
      dry "install $TM_PLIST_DST + sudo tmutil disable"
    fi
  fi

  # ── Downloads auto-sort: LaunchAgent ──────────────────────────────────────
  # Watches ~/Downloads and moves new files to /Volumes/media/<Category>/.
  # User-scoped LaunchAgent — no sudo needed; daemons can't see SMB mounts.
  # Plist in the repo uses __HOME__ as a placeholder; we substitute $HOME on
  # install so the dotfiles repo stays portable.
  SD_PLIST_SRC="$DOTFILES/launchd/com.prometheus.sort-downloads.plist"
  SD_PLIST_DST="$HOME/Library/LaunchAgents/com.prometheus.sort-downloads.plist"
  if [[ -f "$SD_PLIST_SRC" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$HOME/Library/LaunchAgents"
      SD_RENDERED="$(mktemp -t sort-downloads-plist.XXXXXX)"
      sed "s|__HOME__|$HOME|g" "$SD_PLIST_SRC" > "$SD_RENDERED"
      if [[ -f "$SD_PLIST_DST" ]] && cmp -s "$SD_RENDERED" "$SD_PLIST_DST"; then
        success "Already installed: Downloads auto-sort LaunchAgent"
        SKIPPED+=("sort-downloads LaunchAgent")
        rm -f "$SD_RENDERED"
      else
        info "Installing Downloads auto-sort LaunchAgent..."
        launchctl unload "$SD_PLIST_DST" 2>/dev/null || true
        mv "$SD_RENDERED" "$SD_PLIST_DST"
        chmod 644 "$SD_PLIST_DST"
        if launchctl load "$SD_PLIST_DST"; then
          success "Downloads auto-sort LaunchAgent loaded (watches ~/Downloads)"
          INSTALLED+=("sort-downloads LaunchAgent")
        else
          error "Failed to load $SD_PLIST_DST"
        fi
      fi
    else
      dry "install $SD_PLIST_DST (templated) + launchctl load"
    fi
  fi
}
