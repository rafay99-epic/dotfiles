# Prometheus Dotfiles — Claude Context

## Documentation

The docs site has been **extracted into a separate repository**: `~/Code/prometheus-docs/` (Astro + Tailwind, deployed to [dotfiles.rafay99.com](https://dotfiles.rafay99.com)). This repo no longer ships the docs — there is no `docs/` directory, no `vercel.json`, no `middleware.js`.

- **Live site**: [dotfiles.rafay99.com](https://dotfiles.rafay99.com)
- **Source repo**: `~/Code/prometheus-docs/`
- **Content lives in**: `~/Code/prometheus-docs/src/content/docs/` (MDX files organised under `configuration/`, `installation/`, `installing/`, `questions/`, `reference/`)
- **Key pages**:
  - `configuration/nas.mdx` — the full NAS workflow (mount story, `nas-mount` retry layer, `archive-project`, screenshot direct-save). Note: download auto-sorting moved to the Porter app (`~/Code/porter`).
  - `configuration/backup.mdx` — Time Machine to TrueNAS deep-dive
  - `configuration/maintenance.mdx` — Brewfile, gitconfig, `bin/update`, installer modules
  - `configuration/customize.mdx` — `local.env` keys and per-machine config
  - `installation/*` — install flow + portability notes
  - `questions/*` — first-run wizard reference

**When a user asks about any config, tool, or behaviour in this repo**, the authoritative explanation lives in the prometheus-docs repo. Read the relevant `.mdx` file there before changing code here — and remember to update both this repo's code/`CLAUDE.md` *and* the matching `.mdx` page in prometheus-docs when you make a change that needs to be visible to readers.

The docs repo has its own `CLAUDE.md` for site-specific architecture (Astro, Tailwind 4, Pagefind search, OG image generation, etc.). For deployment, build, and content-style conventions of the site itself, consult that file.

## Project Overview
Dotfiles for a 14" MacBook with two external 1080p monitors (27" + 24").
- **Day**: laptop only (built-in screen)
- **Evening**: docked, lid closed, two external monitors

## Structure

```
dotfiles/
├── aerospace/
│   ├── aerospace.toml          # active config (symlinked to ~/.config/aerospace/aerospace.toml)
│   ├── laptop.toml             # profile: outer.top=8, no monitor assignments
│   └── docked.toml             # profile: outer.top=35, workspaces 1-5→main, 6-9→secondary
├── atuin/
│   └── config.toml             # shell history, local-only, Ctrl+R bound, up-arrow untouched
├── bin/
│   ├── aerospace-sync          # auto-detects monitors, copies right profile, reloads
│   ├── killport                # kill whatever's on a TCP port
│   ├── update                  # one-command updater (git pull + brew + bun + npm)
│   ├── tm-status               # Time Machine status with progress bar (--watch / --json)
│   ├── tm-backup               # manual Time Machine trigger (--watch / --stop)
│   ├── clean-node-modules      # scan $PWD for node_modules, show sizes, delete after confirm
│   ├── bigfiles                # rank largest source files (by line count); skips deps/builds; --cloc passthrough
│   ├── archive-project         # recursively scan ~/Code/, archive stale clean repos to /Volumes/media/code/archived/
│   ├── nas-mount               # retry NAS mount via Finder+Keychain; loops with backoff for the login-time race
│   └── flutter-switch          # list/switch installed Flutter SDKs by repointing ~/flutter/current symlink
├── fastfetch/                  # system info banner config
├── fish/
│   ├── config.fish
│   ├── completions/
│   └── functions/              # aerospace-sync · killport · dev · etc.
├── ghostty/                    # GPU terminal config
├── git/.gitconfig              # delta diffs · sensible defaults · aliases
├── launchd/
│   ├── com.prometheus.tm-monthly.plist       # monthly Time Machine LaunchDaemon
│   └── com.prometheus.nas-mount.plist        # NAS auto-mount retry LaunchAgent (fires nas-mount at login)
├── local.env.example                # template reference for ~/.config/dotfiles/local.env
├── bin/lib/dotfiles-config.sh        # shared loader; defines all config vars + defaults
├── lsd/                        # better-ls config
├── nas/
│   └── truenas-media.inetloc   # login-item that auto-mounts the TrueNAS share
├── omniwm/                     # alternative tiling WM (dwindle/BSP, GUI config)
├── sketchybar/                 # whole dir symlinked to ~/.config/sketchybar
├── starship/                   # prompt config
├── zsh/
│   ├── .zshrc                  # interactive shell config
│   └── .zprofile               # login shell — brew shellenv
├── Brewfile                    # core packages (always installed)
├── Brewfile.aerospace          # WM-specific (when WM=AeroSpace)
├── Brewfile.omniwm             # WM-specific (when WM=OmniWM)
├── install.sh                  # orchestrator — parses flags, picks modules, runs them in order
├── install.d/                  # installer modules — each defines module_<name>()
│   ├── 00-lib.sh               # shared helpers: colors, logging, link, brew_*, npm_install
│   ├── 01-menu.sh              # module catalog + arrow-key picker + flag parsing
│   ├── 05-configure.sh         # first-run + --reconfigure wizard; writes ~/.config/dotfiles/local.env
│   ├── 10-prereqs.sh           # always-on: macOS check, Xcode CLT, banner
│   ├── 20-homebrew.sh          # Homebrew + Brewfile + Node (nvm) + Bun + WM Brewfile
│   ├── 30-wm.sh                # Window manager picker (OmniWM/AeroSpace/none)
│   ├── 40-shells.sh            # fzf-tab and other shell plugins
│   ├── 50-apps.sh              # Optional GUI apps (Ghostty, Cursor, Claude, …)
│   ├── 60-symlinks.sh          # All `link` calls — the heart of dotfiles management
│   ├── 70-launchd.sh           # Time Machine + NAS auto-mount LaunchAgents
│   ├── 80-macos.sh             # defaults write tweaks (Dock, Finder, …)
│   └── 90-sketchybar.sh        # SketchyBar restart/stop
├── install.sh.backup           # frozen pre-modularization copy — delete once validated
├── man/
│   ├── install.1               # real groff man page with framed ASCII logo (--man flag)
│   └── archive-project.1       # man page for archive-project — same framed-logo style
└── CLAUDE.md                   # this file
```

## Key Decisions

### Local config — `~/.config/dotfiles/local.env`
Every value that's specific to a single user or machine — NAS IP and username, code-projects directory, git identity, which optional features to enable — lives in **one file outside this repo**: `~/.config/dotfiles/local.env`. It's gitignored, mode 0600, written by an interactive wizard on first install.

- **Wizard module**: `install.d/05-configure.sh`. Runs after `10-prereqs.sh`, before any other module. Asks each question in order, cascades `no` answers (e.g. `HAS_NAS=false` skips the Time Machine / archive-project questions entirely).
- **Re-run**: `./install.sh --reconfigure` re-asks every question with current values as defaults.
- **Loader**: `bin/lib/dotfiles-config.sh` — sourced by every script that needs config (currently `bin/archive-project`, `bin/nas-mount`, the install modules). Provides defaults for any value not in `local.env`, plus `is_truthy` and `dotfiles_smb_url` helpers.
- **Template reference**: `local.env.example` (committed) shows every supported key with comments. Forks read this; their actual values stay in `$HOME/.config/dotfiles/local.env`.
- **Variables exposed**: `CODE_DIR`, `GIT_USER_NAME`, `GIT_USER_EMAIL`, `HAS_NAS`, `NAS_HOST`, `NAS_USER`, `NAS_SHARE_MEDIA`, `NAS_MOUNT_MEDIA`, `HAS_TIMEMACHINE_NAS`, `NAS_SHARE_TM`, `TM_SCHEDULE_MONTHLY`, `ENABLE_ARCHIVE_PROJECT`, `ARCHIVE_AFTER_MONTHS`.
- **Module gating** — install modules check the flags and skip silently when off:
  - `60-symlinks.sh`: NAS-related bin/* links and `.inetloc` rendering gated on `HAS_NAS`; `tm-status` / `tm-backup` gated on `HAS_TIMEMACHINE_NAS`; `archive-project` link on `ENABLE_ARCHIVE_PROJECT`.
  - `70-launchd.sh`: `tm-monthly` LaunchDaemon gated on `HAS_TIMEMACHINE_NAS && TM_SCHEDULE_MONTHLY`; `nas-mount` LaunchAgent gated on `HAS_NAS`.
- **Git identity**: the wizard writes `~/.gitconfig.local` from `GIT_USER_NAME`/`GIT_USER_EMAIL`. The committed `git/.gitconfig` has an `[include]` block that picks it up — so no personal name/email is in the repo.
- **Shell aliases**: per-project shortcuts (`alias lumo=…`, etc.) live in `~/.config/dotfiles/aliases.local.{sh,fish}` — sourced by `zsh/.zshrc` and `fish/config.fish` if present. The committed shellrcs never reference user-specific projects.

### AeroSpace Dual-Config
AeroSpace has no per-monitor gap support. Two profiles solve this:
- `laptop.toml`: `outer.top = 8` (notch — macOS handles the offset)
- `docked.toml`: `outer.top = 40` (external monitors — clears SketchyBar at y=46)

`aerospace-sync` resolves the symlink target with `readlink` before writing so the symlink is never broken.

### Profile Switching
- Terminal: `dock` or `undock` (both auto-detect, same script)
- AeroSpace keybinding: `Alt+D` (uses `$HOME/.local/bin/aerospace-sync` — `exec-and-forget` runs commands through `/bin/bash -c`, so env vars expand even though it doesn't source your interactive `.zshrc`)
- Script location: `~/.local/bin/aerospace-sync` → symlink to `dotfiles/bin/aerospace-sync`

### SketchyBar
- Height: 36, margin: 10, y_offset: 0 → bar bottom at y=46
- `outer.top` on external monitors must be ≥ 46 to avoid overlap

### Tiling Layout
- `Alt+T`: horizontal tiles only (side-by-side). Vertical removed.
- `Alt+F`: toggle float/tile

### Atuin (shell history)
- Configured in `atuin/config.toml`, symlinked by `install.sh` to `~/.config/atuin/config.toml`.
- **Local-only** — `auto_sync = false`. No account, no server. To switch to sync later: `atuin register` then flip `auto_sync = true`.
- Init in both shells: `atuin init {zsh,fish} --disable-up-arrow` — Ctrl+R is replaced by Atuin's TUI; up-arrow keeps default history behaviour to avoid surprises.

### TrueNAS auto-mount
- `nas/truenas-media.inetloc.template` is a templated Internet Location plist. `install.d/60-symlinks.sh` sed-substitutes `__NAS_USER__`, `__NAS_HOST__`, `__NAS_SHARE_MEDIA__` from `~/.config/dotfiles/local.env`, writes the rendered file to `~/Library/Application Support/dotfiles/nas-media.inetloc`, and registers it as a hidden Finder Login Item via `osascript`. So the repo never ships a concrete IP; the rendered file with the real values lives entirely on the user's machine, outside the repo.
- Mount happens at every login. Credentials come from the macOS Keychain (saved on first Finder mount).
- Only runs when `HAS_NAS=true` in `local.env`. If `HAS_NAS=false` the inetloc isn't rendered, no Login Item is registered, no SMB share is mounted at boot.

**Why `mount_smbfs` from a launchd script isn't viable:**
- `/Volumes` is `drwxr-xr-x root:wheel`, so a user-context process can't `mkdir` the mountpoint. Only Finder's `autodiskmount` helper (which escalates) can.
- `mount_smbfs` doesn't read from the Keychain; called from a script it fails with `Authentication error 77` unless a password is explicitly provided.
- The Finder login item works because it routes through Finder, which has Keychain + privileged-helper access.

**Retry layer — `bin/nas-mount` + `com.prometheus.nas-mount` LaunchAgent.** The `.inetloc` Login Item fires the instant you log in, often before Wi-Fi has associated, so the mount silently fails and never retries. The retry layer fixes that without resurrecting the `mount_smbfs` approach:
- `bin/nas-mount` checks if `/Volumes/media` is already mounted (~1 ms early-out). Otherwise it calls `osascript -e 'tell application "Finder" to mount volume "smb://USER@HOST/SHARE"'` — same path the `.inetloc` uses, so the saved Keychain credential just works and we stay clear of the Auth-77 trap.
- `nas-mount` no longer kicks any downstream job. Auto-sorting moved to the Porter app, which watches folders itself and sweeps on its own `NSWorkspace.didMount` observer when the share comes up — so `nas-mount`'s only job is getting the share mounted.
- Loops up to 6 attempts × 15 s = ~90 s total budget, comfortably covering Wi-Fi + DHCP + mDNS at login. Flags: `-1` (oneshot, no retries), `-v` (echo to stdout in addition to logfile).
- Logs: `~/.nas-mount/nas-mount.log`. Exit 0 = mounted, 1 = `HAS_NAS` off / not configured, 2 = retries exhausted.
- `launchd/com.prometheus.nas-mount.plist` is a LaunchAgent with `RunAtLoad=true`, `LimitLoadToSessionType=Aqua` (Finder + Keychain require it), `KeepAlive=false` (the script's internal retry loop is the budget — we don't want launchd respawning on exit-2 and flooding the log).
- Installer wiring: `60-symlinks.sh` links `bin/nas-mount` → `~/.local/bin/nas-mount` (gated on `HAS_NAS`); `70-launchd.sh` renders the plist with `__HOME__` substitution and `launchctl load`s it (also gated on `HAS_NAS`).
- Both the `.inetloc` and the LaunchAgent run at login; whichever wins the race, the other no-ops. If the `.inetloc` is removed for some reason, the LaunchAgent alone is enough. If `osascript mount volume` exhausts its budget too, the user falls back to clicking `media` in the Finder sidebar — same recipe as before, just less often.

### Time Machine — monthly schedule, not hourly
- Destination is a SEPARATE SMB share on the NAS (`smb://<NAS_USER>@<NAS_HOST>/<NAS_SHARE_TM>`, configured per-machine in `~/.config/dotfiles/local.env`).
- Apple's default hourly schedule is **disabled** via `sudo tmutil disable`.
- Replaced with `launchd/com.prometheus.tm-monthly.plist`, installed as a **LaunchDaemon** at `/Library/LaunchDaemons/`, firing on the **1st of each month at 03:00** local time.
- `install.sh` installs the daemon idempotently (checks file hash) and runs `tmutil disable` on a fresh machine. Gated on `HAS_TIMEMACHINE_NAS=true && TM_SCHEDULE_MONTHLY=true` — otherwise neither file is touched.
- Helper commands: `tm-status` (pretty live progress), `tm-backup` (manual trigger / stop). Both in `bin/` and on `$PATH`.
- Exclusions are applied via `tmutil addexclusion -p` — see `~/Code/prometheus-docs/src/content/docs/configuration/backup.mdx` (`#exclusions`) for the full list (node_modules, gradle, android, xcode derived data, NAS mounts, etc.).
- **Full step-by-step setup** for adapting this to another machine: `~/Code/prometheus-docs/src/content/docs/configuration/backup.mdx` (`/configuration/backup`).

### Downloads auto-sort → NAS — RETIRED, moved to the Porter app
This used to be `bin/sort-downloads` + `launchd/com.prometheus.sort-downloads.plist`.
It has been **removed** and replaced by the standalone **Porter** app
(`~/Code/porter`) — a SwiftUI menu-bar app that watches one or more folders and
files each finished download onto the NAS by configurable rules.

**Why it had to leave the dotfiles/launchd world** (load-bearing — don't try to
bring it back as a script): macOS scopes SMB **write** access to the Aqua GUI
session that mounted the share. A launchd-spawned process can read `/Volumes/media`
but **cannot write to it**. Porter runs as a real login-session app, so its writes
succeed; it also dodges the launchd `WatchPaths`-goes-dead / `StartInterval`-throttle
unreliability and the `/bin/bash`-bound TCC grant that broke on every script edit.

The hard-won behaviour lives on in Porter's design: the xattr-stripping cross-volume
copy (`cp -Xp` equivalent → temp → same-volume rename → unlink), case-insensitive
destination-folder resolution, settle/partial/junk triage, collision suffixes, and
"screenshots route by name before extension." See `~/Code/porter/CLAUDE.md`.
Removed alongside the script: the `~/.local/bin/sort-downloads` symlink, the
LaunchAgent, and the `ENABLE_SORT_DOWNLOADS` / `SORT_DOWNLOADS_BACKGROUND` config keys.

For screenshots, still configure your capture tool to save directly to
`/Volumes/media/screenshots/`.

### Code archive → NAS (manual)
- `bin/archive-project` is a **user-invoked** tool (never automatic) that recursively scans `$HOME/Code/` for git repos and moves stale clean ones to `/Volumes/media/code/archived/`. Frees SSD space without losing finished work.
- **Decision logic — all three must hold for a candidate**:
  1. The directory contains a regular `.git/` (worktrees / submodules / vendored sub-repos inside another repo are skipped — a nested repo will travel with its ancestor when the ancestor is archived).
  2. The working tree is fully clean — `git status --porcelain` prints nothing. Any uncommitted change at all (staged, unstaged, or untracked) means the project is never touched. This is the user's explicit rule: half-done work doesn't count as "done."
  3. The last commit is older than `ARCHIVE_AFTER_MONTHS` months. Default `1`; tweak the constant at the top of `bin/archive-project` for permanent change, or pass `--months=N` for one-off.
- **Recursive scan via `find`**: walks `$HOME/Code/` and treats every directory containing `.git/` as a candidate, no matter how deep. Skips `node_modules` and `.git/` interiors. Org-style containers (e.g., `~/Code/MyOrg/` holding several project sub-repos) all surface individually; each is evaluated independently. Candidates are then sorted by relative path so outer projects move before inner ones — if you accept the outer, the inner candidate's source disappears and silently skips on its turn.
- **Layout preservation**: `~/Code/MyOrg/foo` archives to `/Volumes/media/code/archived/MyOrg/foo`. Container dirs (`MyOrg/`) stay on the SSD; if a container becomes empty after archive, the script *prints a note* but never `rmdir`s it (that choice stays with the user).
- **Strip-before-move** (default; disable with `--keep-deps`): nukes universally-regeneratable build output at any depth: `node_modules`, `.next`, `.nuxt`, `.svelte-kit`, `.astro`, `.turbo`, `.vite`, `.parcel-cache`, `.cache`, `Pods`, `DerivedData`, `.gradle`, `.expo`, `.expo-shared`, `.dart_tool`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`. Plus files `.flutter-plugins`, `.flutter-plugins-dependencies`. Deliberately *not* stripped: `build/`, `dist/`, `out/`, `target/`, `venv/` — too generic to delete safely by default. Run `clean-node-modules` first or pass `--keep-deps` to override.
- **Atomic move via `cp -RXp` + `rm`, not `mv`**: same reasoning as the Downloads pattern but for trees. `-X` drops xattrs (so SMB doesn't choke on `com.apple.provenance` / `com.apple.quarantine`); `-Rp` recurses and preserves mode/mtime. Source is only removed after the destination is whole. A NAS dropout mid-copy can't strand you with half a project on each side.
- **Destination collisions**: appends `-YYYYMMDD`, then `-YYYYMMDD-N`. Never overwrites.
- **Pre-flight checks**: NAS must be mounted at `/Volumes/media` (else exits with the `osascript mount volume` recipe); `$ARCHIVE_DIR` is auto-created; the threshold flag must be a positive integer.
- Logs: `~/.archive-project/archive.log` (same `~/.<tool>/` convention as `~/.nas-mount/`). Man page: `man/archive-project.1`, openable via `archive-project --man` (same `--man` plumbing as `install.sh`).

### Flutter version switching — `current` symlink + `flutter-switch`
- Multiple SDKs live under `~/flutter/<label>/flutter` (e.g. `~/flutter/3.22/flutter`, `~/flutter/3.44/flutter`). Each `<label>` is just a directory name; the real framework version is read from `bin/cache/flutter.version.json` (`frameworkVersion`), falling back to the legacy `version` file.
- `~/flutter/current` is a symlink to the active `<label>/flutter`. **PATH points at the stable `$HOME/flutter/current/bin`** (`zsh/.zshrc`, `fish/config.fish`) — never at a concrete version dir. Repointing the symlink therefore makes the chosen SDK live in **every** shell instantly, including already-open ones (the PATH entry is a fixed string; the symlink resolves fresh at each exec). No re-source needed.
- `bin/flutter-switch`: `--list` shows versions with a `*` on the active one; bare invocation opens an fzf picker (numbered-menu fallback when fzf is absent); `flutter-switch <label>` switches directly. It only does `ln -sfn` on `~/flutter/current` — nothing else is mutated.
- Was previously `$HOME/Flutter-SDK/flutter/bin` in both shellrcs, a path that no longer existed (so `flutter` was simply not found). That's been replaced by the `current`-symlink scheme above.
- Shellcheck-clean (`shellcheck -x -S style bin/flutter-switch`). Linked to `~/.local/bin/flutter-switch`.

### Cross-machine portability — no hardcoded usernames
- **Rule:** no config file in this repo may contain `/Users/<username>/` or any other absolute path that bakes in the author's environment. Use `$HOME` / `~` / `fish_add_path $HOME/...` instead.
- **Why:** the repo is cloned across multiple Macs with different usernames. A hardcoded `/Users/prometheus/...` PATH entry silently resolves to nothing on a fresh machine — the failure is invisible (the binary just isn't on `$PATH`) and painful to track down.
- **Coverage:** the rule applies to `zsh/.zshrc`, `fish/config.fish`, `aerospace/*.toml`, and any other file that gets symlinked or read at runtime. Plist `Label` strings (`com.prometheus.*`) are a personal namespace, not paths — they stay.
- **AeroSpace TOMLs:** `exec-and-forget` runs commands through `/bin/bash -c`, so `$HOME` expands correctly inside the value string. No `sed`-templating needed for these (unlike launchd plists, which use the `__HOME__` placeholder + install-time substitution).
- **`install.sh`:** uses `$HOME` and `$DOTFILES` throughout. Never assumes the repo lives at `~/dotfiles` — it resolves its own path via `${BASH_SOURCE[0]}`.
- **NAS values: same rule, different mechanism.** `NAS_HOST`, `NAS_USER`, `NAS_SHARE_*`, `GIT_USER_*` were previously hardcoded in committed files. They now live ONLY in `~/.config/dotfiles/local.env` (per-machine, gitignored). `nas/truenas-media.inetloc.template` uses `__NAS_USER__` / `__NAS_HOST__` / `__NAS_SHARE_MEDIA__` placeholders, rendered by `install.d/60-symlinks.sh` at install time. The docs repo (`~/Code/prometheus-docs/src/content/docs/configuration/{backup,nas}.mdx`) uses `<USER>` / `<NAS-IP>` text placeholders so the public site never quotes a real address.
- **Maintainer metadata (`.github/SECURITY.md`, `.github/CODE_OF_CONDUCT.md`)** still references the repo owner's contact email. That's intentional — these are GitHub "report-an-issue" files and DO need a real contact. Forks should edit them to point at the fork's maintainer.

### Script & config quality standards (CI-enforced)
Any new or modified shell script, plist, or Brewfile must pass these checks **before commit**. The same checks run on every push/PR via `.github/workflows/{shellcheck,plist-validator,brewfile-check}.yml`, and a red CI on `main` is treated as a release blocker.

- **Shell scripts** (`install.sh`, anything in `bin/`):
  ```bash
  shellcheck -x -S style install.sh bin/*
  ```
  Must exit 0. `-S style` means warnings and info-level findings also fail — not just errors. Use inline `# shellcheck disable=SCxxxx` **only** with a short comment justifying *why* the lint is wrong (e.g. tilde-as-display-label in `install.sh:930`).
- **Plists** (`launchd/*.plist`, `nas/*.inetloc`):
  ```bash
  for f in launchd/*.plist nas/*.inetloc; do plutil -lint "$f"; done
  ```
  Every file must print `OK`. `__HOME__` placeholders are fine — `plutil` only validates XML structure.
- **Brewfiles** (`Brewfile`, `Brewfile.aerospace`, `Brewfile.omniwm`):
  ```bash
  for bf in Brewfile Brewfile.aerospace Brewfile.omniwm; do brew bundle check --file="$bf" --verbose; done
  ```
  Catches renamed/removed formulae before someone re-runs `install.sh` on a fresh machine and discovers it the hard way.
- **From this point onward** — any script Claude writes for this repo must meet the bar above. Run the relevant check locally and confirm it passes before reporting the task done. Don't silence findings with `# shellcheck disable` to make CI green; either fix the code or justify the disable in the same line's comment.
- **Release notes:** Commit messages drive `git-cliff` (`cliff.toml`). Push a tag like `v0.2.0` and `.github/workflows/release.yml` runs git-cliff to group commits since the previous tag by Conventional Commits prefix (`feat:` → Features, `fix:` → Fixes, `chore:` → Maintenance, `docs:` → Docs, `refactor:` → Refactor, `ci:` → CI), then publishes a GitHub Release with that body, marked Latest. **No PRs required** — direct commits to `main` are picked up. Cut a release with `git tag v0.2.0 && git push --tags`.

### Docs are multi-page, not a SPA
Static HTML + Tailwind CDN + ~700 lines of vanilla JS in `script.js`. **No React, no build step.** The cost of a framework was assessed and rejected — the site is content, not an app. See decision rationale in conversation history (or just compare bundle sizes).

## Install

```bash
./install.sh                          # interactive arrow-key picker
./install.sh --dry-run                # preview every action, no changes
./install.sh --yes                    # run all modules, auto-Y every prompt
./install.sh --only=symlinks,macos    # run only these modules (skip picker)
./install.sh --skip=wm,homebrew       # run everything EXCEPT these
./install.sh --modules                # print available module list
./install.sh --man                    # open the man page
./install.sh --help

# CI-friendly env-var equivalent of --only:
INSTALL_MODULES=symlinks,macos ./install.sh
```

Symlinks all dotfiles. Optionally installs Homebrew + all packages. Idempotent — safe to re-run.

### Modular installer
`install.sh` is a thin orchestrator (~190 lines). Each major step lives in its own `install.d/<NN-name>.sh` file that defines one function: `module_<name>()`. The orchestrator parses flags, builds a selection set, then calls each module's function in order — gated by `should_run <name>`.

- **Selection precedence** (highest first): `--only=` → `--skip=` → `--yes` → `$INSTALL_MODULES` → interactive picker (default).
- **`--only` and `--skip` are mutually exclusive** — the orchestrator errors out if both are given.
- **Interactive picker is pure bash** — no `whiptail` / `dialog` dependency, so it works on a bare macOS install. **Arrow keys** (or `j`/`k`) move the cursor, **Space** toggles the highlighted module, **a** selects all, **n** clears, **r** resets to defaults, **Enter** confirms and runs, **q** / **Esc** quits. Footer shows a live `Selected: X/8` counter.
- **Flicker-free redraw**: the entire frame is built as one bash string and emitted in a single `printf` call. Each line ends with `\033[K` (clear-to-end-of-line) so leftover characters from the previous frame are wiped without a screen-clear flash. The color variables in `00-lib.sh` use ANSI-C quoting (`$'\e[...m'`) so both `echo -e` and `printf '%s'` render correctly.
- **bash 3.2 compatible** — uses parallel indexed arrays instead of `declare -A`, so the picker works on macOS's stock `/bin/bash` on a fresh machine before Homebrew has installed anything else.
- **`prereqs` is not in the picker** — it's the macOS / Xcode CLT / banner step that has to run before anything else can.
- `INSTALL_APPS` is **derived** from whether the `homebrew` module is in the selected set; it's not a separate top-level prompt anymore.
- New modules: drop `install.d/NN-name.sh` defining `module_name()`, append `name|<description>` to the catalog in `01-menu.sh`, and add a `should_run name && source … && module_name` block in `install.sh`. Three edits, one new file.

### Man page
`man/install.1` is a real groff man page with a framed ASCII logo at the top. Sections cover NAME, SYNOPSIS, DESCRIPTION, OPTIONS, MODULES, INTERACTIVE PICKER, EXAMPLES, ENVIRONMENT, FILES, EXIT STATUS, SEE ALSO, AUTHOR. Open it via `./install.sh --man` (uses `man <path>` on macOS BSD man with a `mandoc` fallback).

## Shells
Both zsh (`zsh/.zshrc`) and fish (`fish/config.fish`) are kept in sync.
Fish functions live in `fish/functions/` and are symlinked to `~/.config/fish/functions/`.

## Deployment
This repo is not deployed anywhere — it's pure dotfiles. The documentation site that used to live in `docs/` was moved to `~/Code/prometheus-docs/` (see the **Documentation** section at the top) and is deployed from that repo. Nothing in this repo needs CI/CD beyond the lint workflows already in `.github/workflows/`.
