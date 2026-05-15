def update [] {
    if (is-installed brew) {
        ^brew update
        ^brew upgrade
    }
    if (is-installed port) {
        ^sudo port selfupdate
        ^sudo port upgrade outdated
    }
    if (is-installed tldr) {
        ^tldr --update
    }
    ^sudo softwareupdate --install --all
}

def watch [...args: string] {
    if ($args | is-empty) { return }
    if (is-installed viddy) {
        ^viddy --disable_auto_save --differences --interval 2 ...$args
    } else {
        ^watch ...$args
    }
}

def load-env-vars [file: path] {
    let env_vars = open $file
        | lines
        | where { |l| not ($l | str starts-with '#') and ($l | str contains '=') }
        | reduce --fold {} { |l, acc|
            let parts = ($l | split row '=' --max 2)
            if ($parts | length) == 2 {
                $acc | merge {($parts | first | str trim): ($parts | last | str trim)}
            } else {
                $acc
            }
        }
    load-env $env_vars
}
