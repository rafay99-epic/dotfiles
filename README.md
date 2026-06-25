# Prometheus Dotfiles

> macOS dotfiles — Tokyo Night themed, tiling WM, GPU terminal, and shell configs for Zsh & Fish.

[![Docs](https://img.shields.io/badge/docs-dotfiles.rafay99.com-7aa2f7?style=flat-square)](https://dotfiles.rafay99.com)
![macOS](https://img.shields.io/badge/macOS-Sequoia-black?style=flat-square&logo=apple)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

**[dotfiles.rafay99.com](https://dotfiles.rafay99.com)** — full documentation, screenshots, and install reference.

## Quick Install

Paste this into your terminal — no cloning, no setup, just one command:

```bash
curl -fsSL https://dotfiles.rafay99.com/install.sh | bash
```

The script will:

1. Clone this repo into `~/dotfiles`
2. **Run the first-run config wizard** — asks a handful of questions (code dir, git identity, NAS yes/no + IP/user/share, Time Machine, archive-project) and writes your answers to `~/.config/dotfiles/local.env` (mode 0600, never committed)
3. Show the interactive module picker — pick which install modules to run (Homebrew, window manager, symlinks, LaunchAgents, macOS tweaks, …)
4. Run each selected module — modules whose feature you said "no" to in the wizard skip themselves silently

After it finishes, open a new terminal tab and log out / back in.

### After the first install

`./install.sh` is **idempotent** — re-running it loads your existing `~/.config/dotfiles/local.env` silently (one yellow line: `→ Loaded existing config — pass --reconfigure to re-ask`) and goes straight to the module picker. **It will not re-prompt the wizard questions.**

To re-prompt the wizard (after changing NAS, fixing an email typo, flipping a feature on/off):

```bash
./install.sh --reconfigure
```

Your current values are pre-filled as the defaults — press Enter through every question you don't want to change.

To inspect or edit your config by hand:

```bash
cat ~/.config/dotfiles/local.env       # see your answers
$EDITOR ~/.config/dotfiles/local.env   # edit directly
```

The committed `local.env.example` lists every supported key with comments — a reference for what you can put in your real file.

## What's Included

| Tool | Purpose |
|------|---------|
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Floating, notch-aware menu bar — Tokyo Night |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | i3-inspired tiling window manager |
| [Ghostty](https://ghostty.org) | GPU-accelerated terminal — tabs, splits, blur |
| [Starship](https://starship.rs) | Cross-shell prompt (Zsh + Fish) |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info on every shell open |
| [bat](https://github.com/sharkdp/bat) | Syntax-highlighted `cat` replacement |
| [eza](https://github.com/eza-community/eza) | Modern `ls` with icons |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — Ctrl+R, Ctrl+T |
| [thefuck](https://github.com/nvbn/thefuck) | Corrects mistyped commands |
| [lsd](https://github.com/lsd-rs/lsd) | Alternative `ls` replacement |
| [CodexBar](https://github.com/steipete/CodexBar) | AI token usage tracker in menu bar |

## How Symlinks Work

The repo **is** the source of truth. `install.sh` creates symlinks from `~/.config/*` back into this repo — every edit inside `~/dotfiles/` is instantly live, and every change is automatically tracked by git.

```
~/dotfiles/sketchybar/            <── ~/.config/sketchybar
~/dotfiles/aerospace/aerospace.toml  <── ~/.config/aerospace/aerospace.toml
~/dotfiles/ghostty/config            <── ~/.config/ghostty/config
~/dotfiles/starship/starship.toml    <── ~/.config/starship.toml
~/dotfiles/fish/config.fish          <── ~/.config/fish/config.fish
~/dotfiles/zsh/.zshrc                <── ~/.zshrc
```

## Shell Configs

Both Zsh and Fish are fully mirrored — same PATH, same aliases, same tools.

| Feature | Zsh | Fish |
|---------|-----|------|
| Prompt | `starship init zsh` | `starship init fish` |
| Node manager | nvm | fnm (`brew install fnm`) |
| Ruby | rbenv | rbenv |
| Python | conda | conda |
| Fuzzy finder | `fzf --zsh` | `fzf --fish` |
| Autocorrect | thefuck | thefuck |

**Shared aliases**

| Alias | Command |
|-------|---------|
| `ls` | `eza --icons=always` |
| `ll` | `eza --icons=always -la` |
| `lt` | `eza --icons=always --tree` |
| `cat` | `bat` |
| `cc` | `claude` |
| `gs` | `git status` |
| `g` | `git` |
| `gc` | `git clone` |
| `ga` | `git commit -a` |

## Useful Commands

```bash
# Reload SketchyBar after a config change
sketchybar --reload

# Restart SketchyBar service
brew services restart sketchybar

# Reload AeroSpace config
aerospace reload-config

# Verify all symlinks are correct
readlink ~/.config/sketchybar
readlink ~/.config/aerospace/aerospace.toml
readlink ~/.config/ghostty/config
readlink ~/.config/starship.toml
readlink ~/.config/fish/config.fish
readlink ~/.zshrc
```


## License

MIT — [rafay99-epic](https://github.com/rafay99-epic)
