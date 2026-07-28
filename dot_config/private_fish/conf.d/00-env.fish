set -gx HOMEBREW_NO_ANALYTICS 1
# `brew shellenv` costs ~35ms; its output only changes when brew moves, so
# cache it and re-source, regenerating only when the brew binary is newer.
set -l brew_bin
if test -x /opt/homebrew/bin/brew
    set brew_bin /opt/homebrew/bin/brew
else if test -x /usr/local/bin/brew
    set brew_bin /usr/local/bin/brew
end
if test -n "$brew_bin"
    set -l brew_cache "$HOME/.cache/fish/brew_shellenv.fish"
    if not test -f "$brew_cache"; or test "$brew_bin" -nt "$brew_cache"
        mkdir -p (path dirname "$brew_cache")
        $brew_bin shellenv fish >"$brew_cache"
    end
    source "$brew_cache"
end

set -gx GPG_TTY (tty)
set -gx SSH_AUTH_SOCK ~/.ssh/proton-pass-agent.sock

if command -qa micro
    set -gx EDITOR micro
    set -gx VISUAL micro
end

# Extra PATH entries are defined in ~/.config/shell/extra_paths.txt
# (shared with zsh/bash via dot_config/shell/path.sh).
set -l extra_paths "$HOME/.config/shell/extra_paths.txt"
if test -f "$extra_paths"
    for line in (string match -r -v '^\s*(#|$)' < "$extra_paths")
        set -l dir (string replace '$HOME' "$HOME" -- $line)
        set -l dir (string replace '$HOMEBREW_PREFIX' "$HOMEBREW_PREFIX" -- $dir)
        if test -d "$dir"
            fish_add_path --global $dir
        end
    end
end
