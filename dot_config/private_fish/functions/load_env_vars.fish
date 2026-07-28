#!/usr/bin/env fish

function load_env_vars -d "Load variables in a .env file"
    set -l file (test -n "$argv[1]"; and echo "$argv[1]"; or echo ".env")
    if not test -f "$file"
        return 1
    end
    while read -l line
        if string match -qr '^\s*#' -- $line; or test -z (string trim -- $line)
            continue
        end
        if set -l kv (string match -r '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
            set -l name $kv[2]
            set -l val (string trim -c '"' (string trim -c "'" (string trim -- $kv[3])))
            set -gx $name $val
        end
    end < "$file"
end
