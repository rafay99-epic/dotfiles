#!/usr/bin/env bash
# =============================================================================
# install.d/90-sketchybar.sh — Restart SketchyBar (or stop it) post-install
# =============================================================================
# After packages + symlinks are in place, SketchyBar needs a reload to pick
# up the new config. If no WM is selected but SketchyBar is still running
# from a previous setup, offer to stop it.

module_sketchybar() {
  if [[ "$INSTALL_APPS" == true && "$WM_CHOICE" != "none" ]]; then
    heading "SketchyBar"

    if command -v sketchybar &>/dev/null; then
      if [[ "$DRY_RUN" == false ]]; then
        brew services restart sketchybar 2>/dev/null || true
        sketchybar --reload 2>/dev/null || true
        success "SketchyBar restarted"
      else
        dry "brew services restart sketchybar && sketchybar --reload"
      fi
    else
      warn "sketchybar not found — skipping reload."
    fi
  elif [[ "$WM_CHOICE" == "none" ]] && command -v sketchybar &>/dev/null; then
    # Stop SketchyBar if running and no WM selected
    if brew services list 2>/dev/null | grep -q "sketchybar.*started"; then
      if prompt "SketchyBar is running but no WM selected. Stop it?"; then
        if [[ "$DRY_RUN" == false ]]; then
          brew services stop sketchybar 2>/dev/null || true
          success "SketchyBar stopped"
        else
          dry "brew services stop sketchybar"
        fi
      fi
    fi
  fi
}
