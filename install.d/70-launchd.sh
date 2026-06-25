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
#   nas-mount        LaunchAgent (~/Library/LaunchAgents/) — user-scoped.
#                    Retries mounting the NAS share at login (the .inetloc
#                    Login Item often loses the race with Wi-Fi association).
#
# Plist source files use __HOME__ as a placeholder; we sed-substitute $HOME
# at install time for the LaunchAgent (the LaunchDaemon doesn't need
# user-path templating).
#
# NOTE: auto-sorting ~/Downloads onto the NAS is no longer done here. It moved
# to the dedicated Porter app (~/Code/porter) — a GUI-session menu-bar app that
# can write to the Finder-mounted SMB share, which a launchd-spawned agent
# cannot. sort-downloads and its LaunchAgent have been retired.

module_launchd() {
  heading "LaunchAgents"

  # ── Time Machine: monthly LaunchDaemon ────────────────────────────────────
  # Gated on HAS_TIMEMACHINE_NAS + TM_SCHEDULE_MONTHLY. Without both flags
  # set, we don't touch /Library/LaunchDaemons/ — Apple's default schedule
  # (or whatever the user already has) is left alone.
  if is_truthy "${HAS_TIMEMACHINE_NAS:-false}" && is_truthy "${TM_SCHEDULE_MONTHLY:-false}"; then
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
  else
    info "Skipping Time Machine LaunchDaemon — HAS_TIMEMACHINE_NAS / TM_SCHEDULE_MONTHLY not set."
  fi

  # ── NAS auto-mount retry: LaunchAgent ─────────────────────────────────────
  # The .inetloc Login Item (installed by 60-symlinks.sh) fires at login but
  # often loses the race with Wi-Fi association on a fresh boot. This agent
  # runs `nas-mount` which retries with backoff until the share comes up.
  # Idempotent — if the .inetloc already succeeded, nas-mount exits in ~1 ms.
  if is_truthy "${HAS_NAS:-false}"; then
    NM_PLIST_SRC="$DOTFILES/launchd/com.prometheus.nas-mount.plist"
    NM_PLIST_DST="$HOME/Library/LaunchAgents/com.prometheus.nas-mount.plist"
    if [[ -f "$NM_PLIST_SRC" ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$HOME/Library/LaunchAgents"
        NM_RENDERED="$(mktemp -t nas-mount-plist.XXXXXX)"
        sed "s|__HOME__|$HOME|g" "$NM_PLIST_SRC" > "$NM_RENDERED"
        if [[ -f "$NM_PLIST_DST" ]] && cmp -s "$NM_RENDERED" "$NM_PLIST_DST"; then
          success "Already installed: NAS auto-mount retry LaunchAgent"
          SKIPPED+=("nas-mount LaunchAgent")
          rm -f "$NM_RENDERED"
        else
          info "Installing NAS auto-mount retry LaunchAgent..."
          launchctl unload "$NM_PLIST_DST" 2>/dev/null || true
          mv "$NM_RENDERED" "$NM_PLIST_DST"
          chmod 644 "$NM_PLIST_DST"
          if launchctl load "$NM_PLIST_DST"; then
            success "NAS auto-mount retry LaunchAgent loaded"
            INSTALLED+=("nas-mount LaunchAgent")
          else
            error "Failed to load $NM_PLIST_DST"
          fi
        fi
      else
        dry "install $NM_PLIST_DST (templated) + launchctl load"
      fi
    fi
  fi
}
