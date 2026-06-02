function cdy --description "Open yazi and cd to last directory"
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)

    yazi --cwd-file="$tmp" $argv

    if test -f "$tmp"
        set -l dir (cat "$tmp")
        rm -f "$tmp"

        if test -n "$dir" -a -d "$dir"
            cd "$dir"
        end
    end
end

