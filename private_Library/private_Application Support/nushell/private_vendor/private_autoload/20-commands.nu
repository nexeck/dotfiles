# Nushell has a built-in `update` for table cells. Keep the system updater
# available under a distinct name.
def dotfiles-update [] { ^update }

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
        | each { |line| $line | str trim }
        | where { |line| $line != '' and not ($line | str starts-with '#') and ($line | str contains '=') }
        | reduce --fold {} { |line, acc|
            let parts = ($line | split row '=' --number 2)
            if ($parts | length) == 2 {
                let raw_key = ($parts | first | str trim)
                let key = ($raw_key | str replace --regex '^export\s+' '')
                let value = ($parts | last | str trim | str trim --char '"' | str trim --char "'")
                if ($key =~ '^[A-Za-z_][A-Za-z0-9_]*$') {
                    $acc | merge {($key): $value}
                } else {
                    $acc
                }
            } else {
                $acc
            }
        }
    load-env $env_vars
}
