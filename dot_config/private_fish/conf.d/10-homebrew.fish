set -gx HOMEBREW_NO_ANALYTICS 1


if test -f /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -f /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end
