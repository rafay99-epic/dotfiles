#!/usr/bin/env bash
# =============================================================================
# install.d/50-apps.sh — Optional GUI apps + AI tools
# =============================================================================
# Per-app Y/N prompts. Each is independent so the user can pick exactly
# what they want. Cask installs require Homebrew; curl/npm-based installs
# work regardless.

module_apps() {
  heading "Optional Apps"
  echo ""
  echo -e "  ${CYAN}Pick which apps to install (each is optional):${RESET}"
  echo -e "  ${CYAN}Requires Homebrew for cask installs.${RESET}"
  echo ""

  # Gate optional apps behind brew availability — some use curl so they work
  # regardless, but cask installs need brew.
  HAS_BREW=false
  command -v brew &>/dev/null && HAS_BREW=true

  # ── Terminal ──────────────────────────────────────────────────────────────
  if prompt "Install Ghostty (GPU terminal emulator)?"; then
    if [[ "$HAS_BREW" == true ]]; then
      brew_install ghostty --cask
    else
      warn "Homebrew not found — skipping Ghostty. Install Homebrew first."
    fi
  fi

  # ── Editors / IDEs ───────────────────────────────────────────────────────
  if prompt "Install Cursor (AI code editor)?"; then
    if [[ "$HAS_BREW" == true ]]; then
      brew_install cursor --cask
    else
      warn "Homebrew not found — skipping Cursor. Install Homebrew first."
    fi
  fi

  # ── AI Tools ─────────────────────────────────────────────────────────────
  if prompt "Install Claude Code (terminal AI assistant)?"; then
    curl_install "claude-code" "command -v claude" "https://claude.ai/install.sh"
  fi

  if prompt "Configure Claude Code to use Starship statusline?"; then
    configure_claude_statusline
  fi

  if prompt "Install Claude Desktop (GUI app)?"; then
    if [[ "$HAS_BREW" == true ]]; then
      brew_install claude --cask
    else
      warn "Homebrew not found — skipping Claude Desktop. Install Homebrew first."
    fi
  fi

  if prompt "Install OpenAI Codex CLI (terminal AI agent)?"; then
    npm_install "codex" "command -v codex" "@openai/codex"
  fi

  # ── Media ────────────────────────────────────────────────────────────────
  if prompt "Install Spotify?"; then
    if [[ "$HAS_BREW" == true ]]; then
      brew_install spotify --cask
    else
      warn "Homebrew not found — skipping Spotify. Install Homebrew first."
    fi
  fi
}
