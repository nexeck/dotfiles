# env.nu
#
# Installed by:
# version = "0.109.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.

$env.HOMEBREW_NO_ANALYTICS = "1"
$env.SSH_AUTH_SOCK = $"($env.HOME)/.ssh/proton-pass-agent.sock"

let path_sh = $"($env.HOME)/.config/shell/path.sh"
let extra_paths = if ($path_sh | path exists) {
    ^sh $path_sh --print-extra-paths | lines
} else {
    []
}
let managed_paths = [
    $"($env.HOME)/.local/share/mise/shims"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
] | where { |path| $path | path exists }

$env.PATH = ($managed_paths ++ $extra_paths ++ $env.PATH | uniq)
