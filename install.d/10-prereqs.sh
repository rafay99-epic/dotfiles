#!/usr/bin/env bash
# =============================================================================
# install.d/10-prereqs.sh — Prerequisites (always runs, never optional)
# =============================================================================
# macOS check · root-user refusal · Xcode CLT · git/curl · dotfiles dir · banner

module_prereqs() {
  # ── macOS only ────────────────────────────────────────────────────────────
  if [[ "$(uname)" != "Darwin" ]]; then
    error "This script only supports macOS."
    exit 1
  fi

  if [[ "$EUID" -eq 0 ]]; then
    error "Do not run this script as root / sudo."
    exit 1
  fi

  # ── Xcode Command Line Tools ─────────────────────────────────────────────
  # Required for git, clang, make, etc. On a blank system the Xcode licence
  # must be accepted and the CLT package installed before anything else works.
  if ! xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools not found."
    info "Installing Xcode Command Line Tools (you may be prompted)..."
    xcode-select --install 2>/dev/null || true
    # Wait for the install to finish (GUI installer runs in background)
    echo -en "\n  ${BOLD}${BLUE}?${RESET}  ${BOLD}Press Enter after the Xcode CLT installer finishes...${RESET} "
    read -r </dev/tty 2>/dev/null || true
    if ! xcode-select -p &>/dev/null; then
      error "Xcode Command Line Tools installation failed. Please install manually:"
      error "  xcode-select --install"
      exit 1
    fi
    success "Xcode Command Line Tools installed"
  else
    # Ensure the licence has been accepted
    if ! /usr/bin/xcrun clang 2>&1 | grep -q "no input files"; then
      if [[ "$DRY_RUN" == true ]]; then
        dry "sudo xcodebuild -license accept"
      else
        info "Accepting Xcode licence (requires sudo)..."
        sudo xcodebuild -license accept 2>/dev/null || {
          error "Could not accept Xcode licence. Run: sudo xcodebuild -license accept"
          exit 1
        }
        success "Xcode licence accepted"
      fi
    fi
  fi

  # ── Verify critical commands ─────────────────────────────────────────────
  for cmd in git curl; do
    if ! command -v "$cmd" &>/dev/null; then
      error "'$cmd' is required but not found."
      error "Install Xcode CLT (xcode-select --install) and retry."
      exit 1
    fi
  done

  # ── Validate dotfiles directory ──────────────────────────────────────────
  if [[ ! -d "$DOTFILES" ]]; then
    error "Dotfiles directory not found: $DOTFILES"
    exit 1
  fi

  # ── Banner ────────────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}╭────────────────────────────────────────────╮${RESET}"
  echo -e "${BOLD}│       Prometheus Dotfiles — Setup           │${RESET}"
  echo -e "${BOLD}│       github.com/rafay99-epic               │${RESET}"
  echo -e "${BOLD}╰────────────────────────────────────────────╯${RESET}"
  echo ""
  echo -e "  ${GREEN}✓${RESET}  Dotfile symlinks       ${CYAN}(always)${RESET}"
  echo -e "  ${YELLOW}?${RESET}  Window manager         ${CYAN}(optional — OmniWM, AeroSpace, or none)${RESET}"
  echo -e "  ${YELLOW}?${RESET}  Core packages & fonts  ${CYAN}(optional — one prompt)${RESET}"
  echo -e "  ${YELLOW}?${RESET}  Apps                   ${CYAN}(optional — pick individually)${RESET}"
  echo ""
  [[ "$DRY_RUN" == true ]] && warn "DRY RUN — no changes will be made\n"
}
