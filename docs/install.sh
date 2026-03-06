#!/usr/bin/env bash
# =============================================================================
# Prometheus Dotfiles — Bootstrap
# curl -fsSL https://dotfiles.rafay99.com/install.sh | bash
# =============================================================================
set -e

REPO="https://github.com/rafay99-epic/dotfiles.git"
TARGET="$HOME/dotfiles"

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'
  BOLD='\033[1m'; RESET='\033[0m'
else
  GREEN=''; BLUE=''; YELLOW=''; BOLD=''; RESET=''
fi

echo ""
echo -e "${BOLD}╭──────────────────────────────────────────────╮${RESET}"
echo -e "${BOLD}│       Prometheus Dotfiles — Bootstrap         │${RESET}"
echo -e "${BOLD}│       dotfiles.rafay99.com                    │${RESET}"
echo -e "${BOLD}╰──────────────────────────────────────────────╯${RESET}"
echo ""

# ── Require git ───────────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo -e "  ${YELLOW}git not found. Install Xcode Command Line Tools first:${RESET}"
  echo -e "  xcode-select --install"
  exit 1
fi

# ── Clone or update ───────────────────────────────────────────────────────────
if [[ -d "$TARGET/.git" ]]; then
  echo -e "  ${BLUE}→${RESET}  Dotfiles already cloned — pulling latest..."
  git -C "$TARGET" pull --ff-only
else
  echo -e "  ${BLUE}→${RESET}  Cloning dotfiles into ~/dotfiles..."
  git clone "$REPO" "$TARGET"
fi

echo -e "  ${GREEN}✓${RESET}  Repo ready at ~/dotfiles"
echo ""

# ── Hand off to install.sh ────────────────────────────────────────────────────
bash "$TARGET/install.sh"
