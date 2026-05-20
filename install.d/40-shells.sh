#!/usr/bin/env bash
# =============================================================================
# install.d/40-shells.sh — Shell plugins that don't live in Homebrew
# =============================================================================
# Currently just fzf-tab — there's no `brew install fzf-tab`, so we git-clone
# it into ~/.local/share/zsh/. The zsh config already knows how to source it
# from there.

module_shells() {
  # ── fzf-tab plugin (no brew formula — git clone idempotently) ─────────────
  FZF_TAB_DIR="$HOME/.local/share/zsh/fzf-tab"
  if [[ ! -d "$FZF_TAB_DIR" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$HOME/.local/share/zsh"
      git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null || true
    else
      dry "git clone --depth=1 https://github.com/Aloxaf/fzf-tab $FZF_TAB_DIR"
    fi
  fi
}
