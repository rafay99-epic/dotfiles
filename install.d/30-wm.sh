#!/usr/bin/env bash
# =============================================================================
# install.d/30-wm.sh — Window Manager choice + conflict resolution
# =============================================================================
# Asks the user to pick OmniWM, AeroSpace, or none, and stops a conflicting
# WM that's currently running (you can't sanely have both at once).
#
# Sets the global: WM_CHOICE (omniwm | aerospace | none)

module_wm() {
  heading "Window Manager"
  echo ""
  echo -e "  ${CYAN}Choose a tiling window manager:${RESET}"
  echo -e "    ${BOLD}1)${RESET} OmniWM  — Hyprland-style dwindle/BSP, GUI config, quake terminal"
  echo -e "    ${BOLD}2)${RESET} AeroSpace — i3-style manual tiling, TOML config"
  echo -e "    ${BOLD}3)${RESET} None — no window manager"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}(dry)${RESET} Would ask: Pick a tiling WM → assuming OmniWM"
    WM_CHOICE="omniwm"
  else
    echo -en "  ${BOLD}${BLUE}?${RESET}  ${BOLD}Enter choice [1/2/3]:${RESET} "
    read -r _wm_input </dev/tty 2>/dev/null || _wm_input="3"
    echo ""
    case "$_wm_input" in
      1) WM_CHOICE="omniwm" ;;
      2) WM_CHOICE="aerospace" ;;
      *) WM_CHOICE="none" ;;
    esac
  fi

  if [[ "$WM_CHOICE" == "none" ]]; then
    info "No window manager selected — skipping all WM, bar, and WM font packages."
  else
    success "Window manager: $WM_CHOICE"
  fi

  # ── Stop conflicting WM if the other one is running ────────────────────────
  if [[ "$WM_CHOICE" == "omniwm" ]] && pgrep -x AeroSpace &>/dev/null; then
    warn "AeroSpace is currently running."
    if prompt "Kill AeroSpace before starting OmniWM?"; then
      pkill -x AeroSpace 2>/dev/null || true
      sleep 1
      success "AeroSpace stopped"
    else
      warn "Both WMs running simultaneously will cause conflicts."
    fi
  elif [[ "$WM_CHOICE" == "aerospace" ]] && pgrep -x OmniWM &>/dev/null; then
    warn "OmniWM is currently running."
    if prompt "Kill OmniWM before starting AeroSpace?"; then
      pkill -x OmniWM 2>/dev/null || true
      sleep 1
      success "OmniWM stopped"
    else
      warn "Both WMs running simultaneously will cause conflicts."
    fi
  elif [[ "$WM_CHOICE" == "none" ]]; then
    # Offer to stop any running WM
    if pgrep -x AeroSpace &>/dev/null; then
      warn "AeroSpace is currently running."
      if prompt "Stop AeroSpace?"; then
        pkill -x AeroSpace 2>/dev/null || true
        sleep 1
        success "AeroSpace stopped"
      fi
    fi
    if pgrep -x OmniWM &>/dev/null; then
      warn "OmniWM is currently running."
      if prompt "Stop OmniWM?"; then
        pkill -x OmniWM 2>/dev/null || true
        sleep 1
        success "OmniWM stopped"
      fi
    fi
  fi
}
