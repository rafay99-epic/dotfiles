# Complete `dev` against directories under ~/Code (one level deep).
function __dev_complete_subdirs
    set -l token (commandline -ct)
    set -l base "$HOME/Code"
    for path in $base/$token*/
        # Strip the base prefix and the trailing slash for display.
        set -l rel (string replace -- "$base/" "" "$path")
        echo (string trim --right --chars=/ -- $rel)
    end
end

complete -c dev -f -a "(__dev_complete_subdirs)" -d "subdirectory of ~/Code"
