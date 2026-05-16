function gm --description "git commit -m and push"
    git commit -m "$argv[1]"; and git push
end
