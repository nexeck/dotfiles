set -gx GPG_TTY (tty)
set -gx SSH_AUTH_SOCK ~/.ssh/proton-pass-agent.sock

if command -qa micro
    set -gx EDITOR micro
    set -gx VISUAL micro
end

# Extra PATH entries are shared with zsh/bash by calling the same
# dot_config/shell/path.sh - edit its extra_paths.txt, not this file, to
# add/remove entries.
set -l path_script "$HOME/.config/shell/path.sh"
if test -f "$path_script"
    for dir in (sh "$path_script" --print-extra-paths)
        fish_add_path --global $dir
    end
end
