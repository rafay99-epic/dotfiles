# Prometheus Dotfiles — Claude Context

## Documentation

Full documentation lives in two places — always consult these before making changes:

- **Live site**: [dotfiles.rafay99.com](https://dotfiles.rafay99.com) — complete reference with install guide, config explanations, keybindings, and gallery
- **Source**: `docs/index.html`, `docs/styles.css`, `docs/script.js` — the static site served at that URL

When a user asks about any config, tool, or behaviour in this repo, read `docs/index.html` first (or visit the live site) for the authoritative explanation before touching any files.

## Project Overview
Dotfiles for a 14" MacBook with two external 1080p monitors (27" + 24").
- **Day**: laptop only (built-in screen)
- **Evening**: docked, lid closed, two external monitors

## Structure

```
dotfiles/
├── aerospace/
│   ├── aerospace.toml      # active config (symlinked to ~/.config/aerospace/aerospace.toml)
│   ├── laptop.toml         # profile: outer.top=8, no monitor assignments
│   └── docked.toml         # profile: outer.top=35, workspaces 1-5→main, 6-9→secondary
├── bin/
│   └── aerospace-sync      # script: auto-detects monitors, copies right profile, reloads
├── fish/
│   ├── config.fish
│   ├── completions/
│   └── functions/
│       └── aerospace-sync.fish
├── sketchybar/             # whole dir symlinked to ~/.config/sketchybar
├── zsh/
│   └── .zshrc
├── ghostty/
├── starship/
├── fastfetch/
├── lsd/
└── install.sh              # sets up symlinks + optionally installs Homebrew packages
```

## Key Decisions

### AeroSpace Dual-Config
AeroSpace has no per-monitor gap support. Two profiles solve this:
- `laptop.toml`: `outer.top = 8` (notch — macOS handles the offset)
- `docked.toml`: `outer.top = 40` (external monitors — clears SketchyBar at y=46)

`aerospace-sync` resolves the symlink target with `readlink` before writing so the symlink is never broken.

### Profile Switching
- Terminal: `dock` or `undock` (both auto-detect, same script)
- AeroSpace keybinding: `Alt+D` (uses full path — `exec-and-forget` does not source shell)
- Script location: `~/.local/bin/aerospace-sync` → symlink to `dotfiles/bin/aerospace-sync`

### SketchyBar
- Height: 36, margin: 10, y_offset: 0 → bar bottom at y=46
- `outer.top` on external monitors must be ≥ 46 to avoid overlap

### Tiling Layout
- `Alt+T`: horizontal tiles only (side-by-side). Vertical removed.
- `Alt+F`: toggle float/tile

## Install
```bash
./install.sh             # interactive
./install.sh --dry-run   # preview only
```
Symlinks all dotfiles. Optionally installs Homebrew + all packages.

## Shells
Both zsh (`zsh/.zshrc`) and fish (`fish/config.fish`) are kept in sync.
Fish functions live in `fish/functions/` and are symlinked to `~/.config/fish/functions/`.
