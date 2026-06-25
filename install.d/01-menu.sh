#!/usr/bin/env bash
# =============================================================================
# install.d/01-menu.sh — Module catalog, selection state, interactive picker
# =============================================================================
# Pure bash (3.2-compatible — no associative arrays). Parallel indexed arrays
# track each module's name, description, and selected/unselected state.
#
# Exports for the orchestrator:
#   MODULES_AVAILABLE_NAMES        — list of module short names
#   MODULES_AVAILABLE_DESC         — parallel list of descriptions
#   MODULES_SELECTED               — parallel list of "1"/"0"
#   should_run <name>              — returns 0 iff that module is selected
#   set_selection_from_csv <csv>   — overwrite selection from "a,b,c"
#   apply_skip_csv <csv>           — turn off the named modules
#   select_all                     — turn everything on
#   interactive_module_menu        — show the picker (mutates state)
#   print_module_list              — for --help and error messages

# ── Catalog ──────────────────────────────────────────────────────────────────
# Order here = display order in the menu = run order in the orchestrator.
MODULES_AVAILABLE_NAMES=(
  symlinks
  homebrew
  wm
  apps
  macos
  launchd
  shells
  sketchybar
)

MODULES_AVAILABLE_DESC=(
  "Dotfile symlinks (~/.zshrc, ~/.config/*, ~/.local/bin/*)"
  "Homebrew + Brewfile + Node (LTS via nvm) + Bun"
  "Window manager — OmniWM / AeroSpace / none"
  "Optional GUI apps (Ghostty, Cursor, Claude, Spotify, …)"
  "macOS preferences (Dock, Finder, screenshots, telemetry, …)"
  "LaunchAgents — Time Machine + NAS auto-mount"
  "Shell plugins (fzf-tab)"
  "SketchyBar restart (auto-skips when WM is none)"
)

# Default selection: only symlinks is pre-checked.
# (We re-initialize this in interactive_module_menu so successive runs are clean.)
MODULES_SELECTED=(1 0 0 0 0 0 0 0)

# ── Internal helpers ─────────────────────────────────────────────────────────
_module_count() {
  echo "${#MODULES_AVAILABLE_NAMES[@]}"
}

_module_index() {
  # Echo the array index of <name>, or return 1 if unknown.
  local name="$1" i
  for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
    if [[ "${MODULES_AVAILABLE_NAMES[$i]}" == "$name" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

_set_selection() {
  local name="$1" value="$2" idx
  if idx="$(_module_index "$name")"; then
    MODULES_SELECTED[idx]="$value"
    return 0
  fi
  return 1
}

# ── Public API ───────────────────────────────────────────────────────────────

# should_run <module-name>
# Returns 0 if the module is selected, 1 otherwise.
should_run() {
  local idx
  if idx="$(_module_index "$1")"; then
    [[ "${MODULES_SELECTED[$idx]}" == "1" ]]
    return $?
  fi
  return 1
}

select_all() {
  local i
  for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
    MODULES_SELECTED[i]=1
  done
}

select_none() {
  local i
  for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
    MODULES_SELECTED[i]=0
  done
}

# set_selection_from_csv "a,b,c"
# Clears everything first, then turns on only the listed modules.
# Exits the script if any name is unknown.
set_selection_from_csv() {
  local csv="$1" name
  select_none
  local -a names
  IFS=',' read -ra names <<< "$csv"
  local unknown=()
  for name in "${names[@]}"; do
    name="${name// /}"   # strip spaces
    [[ -z "$name" ]] && continue
    if ! _set_selection "$name" 1; then
      unknown+=("$name")
    fi
  done
  if (( ${#unknown[@]} > 0 )); then
    local list
    list="$(IFS=' '; echo "${unknown[*]}")"
    error "Unknown module(s): $list"
    print_module_list >&2
    exit 1
  fi
}

# apply_skip_csv "a,b,c"
# Starts from "everything selected", then turns off only the listed ones.
apply_skip_csv() {
  local csv="$1" name
  select_all
  local -a names
  IFS=',' read -ra names <<< "$csv"
  local unknown=()
  for name in "${names[@]}"; do
    name="${name// /}"
    [[ -z "$name" ]] && continue
    if ! _set_selection "$name" 0; then
      unknown+=("$name")
    fi
  done
  if (( ${#unknown[@]} > 0 )); then
    local list
    list="$(IFS=' '; echo "${unknown[*]}")"
    error "Unknown module(s): $list"
    print_module_list >&2
    exit 1
  fi
}

# print_module_list — used by --help and error messages
print_module_list() {
  echo ""
  echo "Available modules:"
  local i
  for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
    printf "  %-11s  %s\n" "${MODULES_AVAILABLE_NAMES[$i]}" "${MODULES_AVAILABLE_DESC[$i]}"
  done
}

# selected_summary — joins selected module names with ", " for logging
selected_summary() {
  local i out=""
  for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
    if [[ "${MODULES_SELECTED[$i]}" == "1" ]]; then
      out="${out:+$out, }${MODULES_AVAILABLE_NAMES[$i]}"
    fi
  done
  echo "${out:-(none)}"
}

# ── Interactive picker ───────────────────────────────────────────────────────
# Pure-bash arrow-key picker. Reads single keystrokes from /dev/tty and
# redraws the menu in place. The entire frame is built as a single string
# and written in one printf call — that's what makes it flicker-free: the
# terminal sees the whole new frame in one write, not 14 sequential ones.
# Each line ends with \033[K (clear-to-end-of-line) so leftover characters
# from the previous frame are wiped without a screen-clear flash.
#
# Keys:
#   ↑ / k    move cursor up
#   ↓ / j    move cursor down
#   Space    toggle the highlighted module
#   a        select all
#   n        clear all
#   r        reset to defaults (only symlinks)
#   Enter    confirm and run
#   q / Esc  quit (selects none)
interactive_module_menu() {
  # Default selection: symlinks pre-checked
  select_none
  _set_selection symlinks 1

  local cursor=0
  local count
  count="$(_module_count)"

  # Hide terminal cursor; restore on any exit path.
  printf '\033[?25l'
  trap 'printf "\033[?25h"; trap - INT EXIT; exit 130' INT
  trap 'printf "\033[?25h"' EXIT

  # Save cursor position once — every redraw restores to here, then overwrites
  # the same lines in place. NO \033[J anywhere; that's what caused the flash.
  printf '\033[s'

  local key rest
  while :; do
    # Build the entire frame as one string and emit with a single printf.
    local frame
    frame=$'\033[u\n'
    frame+="${BOLD}${CYAN}▸  Modules — pick what to install${RESET}"$'\033[K\n'
    frame+="  ${CYAN}────────────────────────────────────────${RESET}"$'\033[K\n'
    frame+=$'\n'

    local i mark name desc padded
    for i in "${!MODULES_AVAILABLE_NAMES[@]}"; do
      name="${MODULES_AVAILABLE_NAMES[i]}"
      desc="${MODULES_AVAILABLE_DESC[i]}"
      printf -v padded '%-11s' "$name"
      if [[ "${MODULES_SELECTED[i]}" == "1" ]]; then
        mark="${GREEN}x${RESET}"
      else
        mark=" "
      fi
      if (( i == cursor )); then
        frame+="  ${BOLD}${BLUE}▶${RESET}  [${mark}] ${BOLD}${padded}${RESET}  ${BOLD}—  ${desc}${RESET}"$'\033[K\n'
      else
        frame+="     [${mark}] ${padded}  —  ${desc}"$'\033[K\n'
      fi
    done

    # Count selected — shown in the footer
    local sel_count=0 j
    for j in "${!MODULES_SELECTED[@]}"; do
      [[ "${MODULES_SELECTED[j]}" == "1" ]] && sel_count=$((sel_count + 1))
    done

    frame+=$'\n'
    frame+="  ${CYAN}↑/↓ move · Space toggle · a all · n none · r reset · Enter run · q quit${RESET}"$'\033[K\n'
    frame+="  ${BOLD}Selected:${RESET} ${GREEN}${sel_count}${RESET}${BOLD}/${count}${RESET}"$'\033[K\n'

    printf '%s' "$frame"

    # Read one keystroke (silent, raw, 1 byte). Returns non-zero on EOF.
    IFS= read -rsn1 key </dev/tty 2>/dev/null || break

    case "$key" in
      $'\e')
        # Escape sequence — consume up to 2 more bytes (arrow keys are 3 bytes
        # total: ESC, '[', 'A'|'B'|'C'|'D'). Lone Esc means "quit".
        # 1-second timeout works on bash 3.2; arrow-key bursts arrive instantly
        # anyway, so the user only waits when they actually pressed Esc alone.
        rest=""
        IFS= read -rsn2 -t 1 rest </dev/tty 2>/dev/null
        case "$rest" in
          '[A'|'OA') (( cursor > 0 ))         && cursor=$((cursor - 1)) ;;
          '[B'|'OB') (( cursor < count - 1 )) && cursor=$((cursor + 1)) ;;
          '')        select_none; break ;;   # lone Esc
        esac
        ;;
      k|K)    (( cursor > 0 ))         && cursor=$((cursor - 1)) ;;
      j|J)    (( cursor < count - 1 )) && cursor=$((cursor + 1)) ;;
      ' ')
        if [[ "${MODULES_SELECTED[cursor]}" == "1" ]]; then
          MODULES_SELECTED[cursor]=0
        else
          MODULES_SELECTED[cursor]=1
        fi
        ;;
      a|A) select_all ;;
      n|N) select_none ;;
      r|R) select_none; _set_selection symlinks 1 ;;
      q|Q) select_none; break ;;
      '')  break ;;   # Enter
    esac
  done

  # Restore cursor and remove traps
  printf '\033[?25h'
  trap - INT EXIT

  echo ""
  info "Selected: $(selected_summary)"
}
