function dev --description "cd into ~/Code or a subdirectory beneath it"
    if test (count $argv) -eq 0
        cd "$HOME/Code"
    else
        # Join argv with spaces so `dev full stack` -> ~/Code/full stack.
        cd "$HOME/Code/$argv"
    end
end
