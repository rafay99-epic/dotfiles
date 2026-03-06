# Prometheus Dotfiles

My personal macOS dotfiles — Tokyo Night themed, minimal, and fast.

![macOS](https://img.shields.io/badge/macOS-Sequoia-black?style=flat-square&logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

## What's included

| Tool | Purpose |
|---|---|
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Custom menu bar (floating, Tokyo Night) |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager |
| [lsd](https://github.com/lsd-rs/lsd) | Modern `ls` replacement |
| [Starship](https://starship.rs) | Cross-shell prompt |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display |
| [CodexBar](https://github.com/steipete/CodexBar) | AI token usage tracker |

## Quick install

```bash
git clone https://github.com/rafay99-epic/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Then restart your terminal and log out/in.

---

## Manual setup

### Prerequisites

- macOS Ventura or later
- [Homebrew](https://brew.sh)

### 1. SketchyBar

Floating, Tokyo Night themed menu bar with:
- Workspace indicators (AeroSpace spaces)
- Front app display with icons
- Media playback
- Calendar / clock
- Volume (cyan)
- Battery (color-coded by level)
- Wi-Fi with network switcher (click to switch)
- CodexBar AI usage (Claude + Gemini)

```bash
brew tap FelixKratz/formulae
brew install sketchybar
brew services start sketchybar

# App font for space icons
curl -fsSL https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf \
  -o ~/Library/Fonts/sketchybar-app-font.ttf

# Link config
ln -sf ~/dotfiles/sketchybar ~/.config/sketchybar
sketchybar --reload
```

> **CodexBar**: Install from [github.com/steipete/CodexBar](https://github.com/steipete/CodexBar) and log in to Claude and Gemini via the menu bar app. The sketchybar widget reads live usage from the `codexbar` CLI.

### 2. AeroSpace

i3-inspired tiling window manager for macOS.

```bash
brew tap nikitabobko/tap
brew install --cask nikitabobko/tap/aerospace

mkdir -p ~/.config/aerospace
ln -sf ~/dotfiles/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
```

**Key bindings:**

| Key | Action |
|---|---|
| `Alt + H/J/K/L` | Focus window left/down/up/right |
| `Alt + Shift + H/J/K/L` | Move window |
| `Alt + 1–9` | Switch workspace |
| `Alt + Shift + 1–9` | Move window to workspace |
| `Alt + /` | Toggle tile layout |
| `Alt + ,` | Toggle accordion layout |
| `Alt + Tab` | Previous workspace |

### 3. lsd

Modern `ls` with icons and colors.

```bash
brew install lsd
mkdir -p ~/.config/lsd
ln -sf ~/dotfiles/lsd/config.yaml ~/.config/lsd/config.yaml
```

Add to your shell rc:
```bash
alias ls="lsd"
alias ll="lsd -la"
alias lt="lsd --tree"
```

### 4. Starship

Minimal, fast shell prompt.

```bash
brew install starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

Add to `~/.zshrc`:
```bash
eval "$(starship init zsh)"
```

### 5. Fastfetch

System info on terminal open.

```bash
brew install fastfetch
mkdir -p ~/.config/fastfetch
ln -sf ~/dotfiles/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
ln -sf ~/dotfiles/fastfetch/eldritch.png  ~/.config/fastfetch/eldritch.png
```

Add to `~/.zshrc`:
```bash
fastfetch
```

---

## SketchyBar color scheme

Tokyo Night Dark — all colors live in `sketchybar/colors.sh`.

| Variable | Hex | Use |
|---|---|---|
| `BAR_COLOR` | `#1a1b26` | Bar background |
| `ITEM_BG_COLOR` | `#24283b` | Item pill background |
| `ACCENT_COLOR` | `#7aa2f7` | Blue — active space, Wi-Fi |
| `PURPLE` | `#bb9af7` | Calendar icon |
| `CYAN` | `#7dcfff` | Volume icon |
| `GREEN` | `#9ece6a` | Battery full, AI usage low |
| `YELLOW` | `#e0af68` | Battery mid, AI usage mid |
| `RED` | `#f7768e` | Battery low, AI usage high |
| `WHITE` | `#a9b1d6` | Default text (foreground) |
| `SUBTEXT` | `#565f89` | Inactive spaces |

To switch color schemes, edit the active exports at the top of `sketchybar/colors.sh`.

---

## License

MIT
