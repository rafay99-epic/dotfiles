function aerospace-sync --description "Switch AeroSpace profile based on monitor count"
    set -l script "$HOME/.local/bin/aerospace-sync"
    if not test -x "$script"
        echo "Error: aerospace-sync not found at $script" >&2
        return 1
    end
    "$script"
end
