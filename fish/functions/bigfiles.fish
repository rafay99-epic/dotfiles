function bigfiles --description "List the largest source files under \$PWD by line count"
    set -l script "$HOME/.local/bin/bigfiles"
    if not test -x "$script"
        echo "Error: bigfiles not found at $script" >&2
        return 1
    end
    "$script" $argv
end
