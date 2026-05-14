function killport --description "Kill whatever process is listening on a TCP port"
    set -l script "$HOME/.local/bin/killport"
    if not test -x "$script"
        echo "Error: killport not found at $script" >&2
        return 1
    end
    "$script" $argv
end
