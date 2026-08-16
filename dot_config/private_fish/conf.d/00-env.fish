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

# Only meaningful when there actually is a terminal: in a non-interactive
# shell `tty` prints "not a tty", and exporting that literal string is worse
# than leaving GPG_TTY unset. Mirrors the `[ -t 0 ]` guard in shell/path.sh.
if isatty stdin
    set -gx GPG_TTY (tty)
end
# Exported unconditionally on purpose. The socket is created by the pass-cli
# LaunchAgent at login, so a shell started early enough can legitimately run
# before it exists. ssh resolves SSH_AUTH_SOCK at connect time, so pointing at
# a path that appears moments later is correct - making the export conditional
# would leave such a shell without an agent for its entire life.
# Kept in sync with shell/path.sh, which does the same for zsh/bash.
set -gx SSH_AUTH_SOCK "$HOME/.ssh/proton-pass-agent.sock"
if status is-interactive; and not test -S "$SSH_AUTH_SOCK"
    echo "warning: Proton Pass SSH agent socket missing ($SSH_AUTH_SOCK)" >&2
    echo "         ssh and commit signing will fail. Diagnose with: dotfiles-doctor" >&2
end

if command -qa micro
    set -gx EDITOR micro
    set -gx VISUAL micro
end

# Extra PATH entries live in ~/.config/shell/extra_paths.txt. The parsing
# (comments/blank lines, $HOME and $HOMEBREW_PREFIX expansion, skipping missing
# dirs) lives exactly once, in shell/path.sh - calling it as a subprocess in
# --print-extra-paths mode avoids a second, fish-native parser that silently
# drifts from it. HOMEBREW_PREFIX is exported above, so the subprocess inherits
# it and skips its own `brew shellenv`.
set -l path_sh "$HOME/.config/shell/path.sh"
set -l extra_paths_file "$HOME/.config/shell/extra_paths.txt"
set -l path_cache "$HOME/.cache/fish/extra_paths.fish"

if test -r "$path_sh"; and test -r "$extra_paths_file"
    if not test -f "$path_cache"; or test "$extra_paths_file" -nt "$path_cache"; or test "$path_sh" -nt "$path_cache"
        mkdir -p (path dirname "$path_cache")
        echo "# Auto-generated extra paths cache" > "$path_cache"
        for dir in (sh "$path_sh" --print-extra-paths)
            echo "fish_add_path --global $dir" >> "$path_cache"
        end
    end
    source "$path_cache"
end
