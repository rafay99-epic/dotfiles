#!/usr/bin/env bash
# =============================================================================
# install.d/80-macos.sh — macOS Preferences via `defaults write`
# =============================================================================
# Two layers:
#   1. Required tweaks — applied unconditionally (menu bar auto-hide for WMs,
#      login items for the chosen WM)
#   2. Optional tweaks — Y/N prompts for Dock, Finder, Trackpad, Screenshots,
#      Mission Control, Menu Bar Clock, Office telemetry, Battery percentage
#
# Process restarts (Dock, Finder, SystemUIServer) happen at the end based on
# which tweaks actually changed.

module_macos() {
  heading "macOS Preferences"

  # ── Required tweaks (always applied) ──────────────────────────────────────
  info "Applying required macOS preferences..."

  # Auto-hide the menu bar (needed for SketchyBar — only when a WM is active)
  if [[ "$WM_CHOICE" != "none" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write NSGlobalDomain _HIHideMenuBar -bool true
      success "Menu bar auto-hide enabled"
    else
      dry "defaults write NSGlobalDomain _HIHideMenuBar -bool true"
    fi
  fi

  # Launch tiling WM at login — only for the chosen WM
  if [[ "$WM_CHOICE" == "omniwm" && -d "/Applications/OmniWM.app" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      # Remove AeroSpace from login items if present
      osascript -e 'tell application "System Events" to delete every login item whose name is "AeroSpace"' 2>/dev/null || true
      osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/OmniWM.app", hidden:true}' 2>/dev/null || true
      success "OmniWM added to login items (AeroSpace removed)"
    else
      dry "Add OmniWM.app to login items, remove AeroSpace"
    fi
  elif [[ "$WM_CHOICE" == "aerospace" && -d "/Applications/AeroSpace.app" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      # Remove OmniWM from login items if present
      osascript -e 'tell application "System Events" to delete every login item whose name is "OmniWM"' 2>/dev/null || true
      osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/AeroSpace.app", hidden:true}' 2>/dev/null || true
      success "AeroSpace added to login items (OmniWM removed)"
    else
      dry "Add AeroSpace.app to login items, remove OmniWM"
    fi
  elif [[ "$WM_CHOICE" == "none" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      # Remove both WMs from login items
      osascript -e 'tell application "System Events" to delete every login item whose name is "AeroSpace"' 2>/dev/null || true
      osascript -e 'tell application "System Events" to delete every login item whose name is "OmniWM"' 2>/dev/null || true
      info "Removed WMs from login items (no WM selected)"
    else
      dry "Remove AeroSpace and OmniWM from login items"
    fi
  fi

  # ── Optional tweaks (user picks) ──────────────────────────────────────────
  echo ""
  echo -e "  ${CYAN}Optional system tweaks:${RESET}"
  echo ""

  # Track changes that need specific process restarts
  NEEDS_DOCK_RESTART=false
  NEEDS_FINDER_RESTART=false
  NEEDS_SYSTEMUI_RESTART=false

  # ── Dock ────────────────────────────────────────────────────────────────
  if prompt "Remove Dock auto-hide delay (instant Dock appear/disappear)?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.dock autohide-delay -float 0
      success "Dock auto-hide delay removed"
      INSTALLED+=("macos: no dock delay")
    else
      dry "defaults write com.apple.dock autohide-delay -float 0"
    fi
    NEEDS_DOCK_RESTART=true
  fi

  # ── Finder ──────────────────────────────────────────────────────────────
  if prompt "Apply Finder tweaks (path bar, status bar, hidden files, list view, open to home)?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.finder ShowPathbar -bool true
      defaults write com.apple.finder ShowStatusBar -bool true
      defaults write com.apple.finder AppleShowAllFiles -bool true
      defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      # Default view → list (Nlsv=list, icnv=icon, clmv=column, glyv=gallery)
      defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
      # New windows open to home folder (PfHm=home, PfDe=desktop, PfLo=custom path)
      defaults write com.apple.finder NewWindowTarget -string "PfHm"
      defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
      success "Finder: path bar, status bar, hidden files, full path, list view, home folder"
      INSTALLED+=("macos: finder tweaks")
    else
      dry "defaults write com.apple.finder ShowPathbar/ShowStatusBar/AppleShowAllFiles/FXShowPosixPathInTitle/FXPreferredViewStyle/NewWindowTarget"
    fi
    NEEDS_FINDER_RESTART=true
  fi

  # ── Trackpad ────────────────────────────────────────────────────────────
  if prompt "Enable tap-to-click on trackpad?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
      defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
      defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
      success "Trackpad tap-to-click enabled"
      INSTALLED+=("macos: tap to click")
    else
      dry "defaults write trackpad Clicking -bool true"
    fi
  fi

  # ── Screenshots ─────────────────────────────────────────────────────────
  if prompt "Configure screenshots (PNG, no shadow, save to ~/Pictures/Screenshots)?"; then
    SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$SCREENSHOT_DIR"
      defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
      defaults write com.apple.screencapture type -string png
      defaults write com.apple.screencapture disable-shadow -bool true
      success "Screenshots: PNG format, no shadow, saved to ~/Pictures/Screenshots"
      INSTALLED+=("macos: screenshot config")
    else
      dry "mkdir -p $SCREENSHOT_DIR"
      dry "defaults write com.apple.screencapture location/type/disable-shadow"
    fi
    NEEDS_SYSTEMUI_RESTART=true
  fi

  # ── Mission Control ─────────────────────────────────────────────────────
  if prompt "Prevent Mission Control from auto-rearranging Spaces?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.dock mru-spaces -bool false
      success "Mission Control: Spaces will not auto-rearrange"
      INSTALLED+=("macos: fixed spaces order")
    else
      dry "defaults write com.apple.dock mru-spaces -bool false"
    fi
    NEEDS_DOCK_RESTART=true
  fi

  # ── Menu Bar Clock ──────────────────────────────────────────────────────
  if prompt "Show seconds in menu bar clock?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.menuextra.clock ShowSeconds -bool true
      success "Menu bar clock: seconds enabled"
      INSTALLED+=("macos: clock seconds")
    else
      dry "defaults write com.apple.menuextra.clock ShowSeconds -bool true"
    fi
    NEEDS_SYSTEMUI_RESTART=true
  fi

  # ── Microsoft Office telemetry ──────────────────────────────────────────
  if prompt "Disable Microsoft Office telemetry (Word, Excel, PowerPoint, Outlook, OneNote, AutoUpdate, Office365 Service)?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.microsoft.Word              SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.Excel             SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.Powerpoint        SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.Outlook           SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.onenote.mac       SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.autoupdate2       SendAllTelemetryEnabled -bool FALSE
      defaults write com.microsoft.Office365ServiceV2 SendAllTelemetryEnabled -bool FALSE
      success "Microsoft Office telemetry disabled (7 bundles)"
      INSTALLED+=("macos: office telemetry off")
    else
      dry "defaults write com.microsoft.{Word,Excel,Powerpoint,Outlook,onenote.mac,autoupdate2,Office365ServiceV2} SendAllTelemetryEnabled -bool FALSE"
    fi
  fi

  # ── Battery ─────────────────────────────────────────────────────────────
  if prompt "Show battery percentage in menu bar?"; then
    if [[ "$DRY_RUN" == false ]]; then
      defaults write com.apple.controlcenter BatteryShowPercentage -bool true
      success "Battery percentage visible in menu bar"
      INSTALLED+=("macos: battery percentage")
    else
      dry "defaults write com.apple.controlcenter BatteryShowPercentage -bool true"
    fi
    NEEDS_SYSTEMUI_RESTART=true
  fi

  # ── Manual tweaks reminder ──────────────────────────────────────────────
  # These settings cannot be scripted via defaults write / pmset — GUI only.
  echo ""
  echo -e "  ${YELLOW}The following tweaks must be set manually in System Settings:${RESET}"
  echo ""
  echo -e "    ${BOLD}Displays${RESET}"
  echo -e "      • Disable True Tone → Displays → uncheck True Tone"
  echo ""
  echo -e "    ${BOLD}Keyboard${RESET}"
  echo -e "      • Adjust keyboard brightness in low light → Keyboard → toggle on"
  echo -e "      • Turn keyboard backlight off after inactivity → Keyboard → set to 15 seconds"
  echo ""
  echo -e "    ${BOLD}Battery${RESET}"
  echo -e "      • Optimize video streaming while on battery → Battery → toggle on"
  echo ""

  # ── Restart affected processes ──────────────────────────────────────────
  if [[ "$DRY_RUN" == false ]]; then
    if [[ "$NEEDS_DOCK_RESTART" == true ]]; then
      killall Dock 2>/dev/null || true
      info "Dock restarted"
    fi
    if [[ "$NEEDS_FINDER_RESTART" == true ]]; then
      killall Finder 2>/dev/null || true
      info "Finder restarted"
    fi
    if [[ "$NEEDS_SYSTEMUI_RESTART" == true ]]; then
      killall SystemUIServer 2>/dev/null || true
      info "SystemUIServer restarted"
    fi
  fi
}
