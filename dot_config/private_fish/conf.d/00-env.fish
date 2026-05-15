set -gx GPG_TTY (tty)
set -gx SSH_AUTH_SOCK ~/.ssh/proton-pass-agent.sock


if command -qa micro
    set -gx EDITOR micro
    set -gx VISUAL micro
end

fish_add_path --global "$HOME/.local/bin"
fish_add_path --global "/opt/local/bin"
fish_add_path --global "/opt/local/sbin"
fish_add_path --global "$HOME/.foundry/bin"
