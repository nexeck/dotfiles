# The implementation lives once in ~/.local/bin/update. nushell has a built-in
# `update` (for table cells), so without this wrapper the script would only be
# reachable as `^update`. Every other shell picks it up straight from $PATH.
def update [] { ^update }

def copilot-usage [...args: string] {
    ^copilot-usage ...$args
}

def --wrapped watch [...args: string] {
    if ($args | is-empty) { return }
    if (is-installed viddy) {
        ^viddy --disable_auto_save --differences --interval 2 ...$args
    } else {
        ^watch ...$args
    }
}

# `--env` is required: without it `load-env` would only affect this command's
# own scope and the variables would never reach the caller.
def --env load-env-vars [file: path] {
    let env_vars = open $file
        | lines
        | where { |l| not ($l | str starts-with '#') and ($l | str contains '=') }
        | reduce --fold {} { |l, acc|
            let parts = ($l | split row '=' --number 2)
            if ($parts | length) == 2 {
                $acc | merge {($parts | first | str trim): ($parts | last | str trim)}
            } else {
                $acc
            }
        }
    load-env $env_vars
}
