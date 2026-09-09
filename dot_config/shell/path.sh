#!/bin/sh
# Shared PATH setup, used two ways:
#   1. Sourced from ~/.zprofile (zsh) and ~/.bashrc (bash) - sets PATH,
#      HOMEBREW_* vars, and activates mise for that shell.
#   2. Run directly as `sh path.sh --print-extra-paths` (see
#      private_fish/conf.d/00-env.fish) - just prints the resolved
#      extra PATH dirs, one per line, so fish can fish_add_path them too.
#
# The actual list of extra PATH dirs lives in extra_paths.txt - edit that
# file, not this one, to add/remove entries.

_print_only=0
[ "${1:-}" = "--print-extra-paths" ] && _print_only=1

# Idempotence guard: ~/.zprofile (login shells) and ~/.zshrc (every interactive
# shell) both source this file, so a login+interactive zsh would otherwise run
# `mise activate` twice and install its hooks twice. Deliberately a plain,
# non-exported variable: child shells must still get their own activation,
# since shell hooks are not inherited through the environment.
if [ "$_print_only" = 0 ] && [ -n "${__shell_path_sh_sourced:-}" ]; then
    unset -v _print_only
    return 0 2>/dev/null || exit 0
fi
__shell_path_sh_sourced=1

# Homebrew: sets up HOMEBREW_PREFIX (used below to resolve extra_paths.txt)
# and puts brew's bin/sbin on PATH. Caches shellenv to avoid ~35ms ruby overhead
# on every interactive zsh/bash startup.
export HOMEBREW_NO_ANALYTICS=1
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    :
elif [ -x /opt/homebrew/bin/brew ]; then
    _brew_bin="/opt/homebrew/bin/brew"
    _brew_cache="$HOME/.cache/shell/brew_shellenv.sh"
    if [ ! -f "$_brew_cache" ] || [ "$_brew_bin" -nt "$_brew_cache" ]; then
        mkdir -p "$HOME/.cache/shell"
        "$_brew_bin" shellenv > "$_brew_cache"
    fi
    . "$_brew_cache"
    unset -v _brew_bin _brew_cache
fi

# Resolve extra_paths.txt (expanding a leading $HOME or $HOMEBREW_PREFIX,
# skipping comments/blank lines/missing dirs), acting on each dir as we read it:
# Resolve extra_paths.txt (expanding a leading $HOME or $HOMEBREW_PREFIX,
# skipping comments/blank lines/missing dirs), acting on each dir as we read it:
# either print it (--print-extra-paths, for fish) or accumulate it to prepend
# to PATH while preserving the top-to-bottom priority order.
_extra_path=""
_extra_path_add() {
    case ":$PATH:$_extra_path:" in
        *":$1:"*) ;;
        *) _extra_path="${_extra_path:+$_extra_path:}$1" ;;
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
                _extra_path_add "$_dir"
            fi
        fi
    done < "$_extra_paths"
fi
unset -v _extra_paths _line _dir

if [ "$_print_only" = 1 ]; then
    unset -v _print_only
    unset -f _extra_path_add
    return 0 2>/dev/null || exit 0
fi
unset -v _print_only
unset -f _extra_path_add

if [ -n "$_extra_path" ]; then
    PATH="$_extra_path:$PATH"
fi
unset -v _extra_path
export PATH

# Agent/tty env shared with fish (mirrors private_fish/conf.d/00-env.fish).
# Needed here too: git's core.sshCommand pins an identity, so SSH signing and
# auth from zsh/bash would otherwise find no agent at all.
#
# Exported unconditionally on purpose: the socket is created by the pass-cli
# LaunchAgent at login and may not exist yet when an early shell starts. ssh
# resolves SSH_AUTH_SOCK at connect time, so a path that appears moments later
# still works, whereas a conditional export would leave this shell agent-less
# permanently. Warn instead, and only when someone is there to read it.
export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"
if [ ! -S "$SSH_AUTH_SOCK" ]; then
    case $- in
        *i*)
            echo "warning: Proton Pass SSH agent socket missing ($SSH_AUTH_SOCK)" >&2
            echo "         ssh and commit signing will fail. Diagnose with: dotfiles-doctor" >&2
            ;;
    esac
fi
if [ -t 0 ]; then
    GPG_TTY=$(tty 2>/dev/null) && export GPG_TTY
fi

if command -v micro >/dev/null 2>&1; then
    export EDITOR=micro
    export VISUAL=micro
fi

# mise: activate per-shell so its shims/env hooks also work outside fish
# (fish has its own `mise activate fish` in conf.d/20-mise.fish). Interactive
# shells get the full activation incl. directory-based version switching;
# non-interactive ones only get shims, mirroring what 20-mise.fish does.
if command -v mise >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        _mise_shell=zsh
    elif [ -n "${BASH_VERSION:-}" ]; then
        _mise_shell=bash
    else
        _mise_shell=
    fi
    if [ -n "$_mise_shell" ]; then
        case $- in
            *i*) eval "$(mise activate "$_mise_shell")" ;;
            *) eval "$(mise activate "$_mise_shell" --shims)" ;;
        esac
    fi
    unset _mise_shell
fi
