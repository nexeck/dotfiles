set -gx GPG_TTY (tty)
set -gx SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock


if command -qa micro
    set -gx EDITOR micro
    set -gx VISUAL micro
end

fish_add_path --global "$HOME/.local/bin"
fish_add_path --global "/opt/local/bin"
fish_add_path --global "/opt/local/sbin"
fish_add_path --global "$HOME/.foundry/bin"
