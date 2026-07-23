#!/bin/sh
# Shared PATH setup, used two ways:
#   1. Sourced from ~/.zprofile (zsh) and ~/.bashrc (bash) - sets PATH,
#      HOMEBREW_* vars, and activates mise for that shell.
#   2. Run directly as `sh path.sh --print-extra-paths` (see
#      private_fish/conf.d/10-homebrew.fish) - just prints the resolved
#      extra PATH dirs, one per line, so fish can fish_add_path them too.
#
# The actual list of extra PATH dirs lives in extra_paths.txt - edit that
# file, not this one, to add/remove entries.

# Homebrew: sets up HOMEBREW_PREFIX (used below to resolve extra_paths.txt)
# and puts brew's bin/sbin on PATH. `brew shellenv` (no shell argument)
# emits POSIX `export VAR="value"` lines that both zsh and bash (and this
# script, run under sh) can eval directly.
export HOMEBREW_NO_ANALYTICS=1
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    :
elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Resolve extra_paths.txt (expanding a leading $HOME or $HOMEBREW_PREFIX,
# skipping comments/blank lines/missing dirs), acting on each dir as we read it:
# either print it (--print-extra-paths, for fish) or prepend it to PATH.
# NOTE: deliberately not accumulated into a variable and split later -
# zsh doesn't word-split unquoted variables the way sh/bash do, so that
# approach silently produced one broken multi-line PATH entry in zsh.
_print_only=0
[ "${1:-}" = "--print-extra-paths" ] && _print_only=1

_path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_extra_paths="$HOME/.config/shell/extra_paths.txt"
if [ -r "$_extra_paths" ]; then
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in
            ''|'#'*) continue ;;
        esac
        case "$_line" in
            '$HOME'/*)
                _dir="$HOME/${_line#'$HOME/'}"
                ;;
            '$HOMEBREW_PREFIX'/*)
                [ -n "${HOMEBREW_PREFIX:-}" ] || continue
                _dir="$HOMEBREW_PREFIX/${_line#'$HOMEBREW_PREFIX/'}"
                ;;
            *)
                _dir="$_line"
                ;;
        esac
        if [ -d "$_dir" ]; then
            if [ "$_print_only" = 1 ]; then
                printf '%s\n' "$_dir"
            else
                _path_prepend "$_dir"
            fi
        fi
    done < "$_extra_paths"
fi
unset -v _extra_paths _line _dir

if [ "$_print_only" = 1 ]; then
    unset -v _print_only
    unset -f _path_prepend
    return 0 2>/dev/null || exit 0
fi
unset -v _print_only
unset -f _path_prepend
export PATH

# mise: activate per-shell so its shims/env hooks also work outside fish
# (fish has its own `mise activate fish` in conf.d/20-mise.fish).
if command -v mise >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(mise activate zsh)"
    elif [ -n "$BASH_VERSION" ]; then
        eval "$(mise activate bash)"
    fi
fi
