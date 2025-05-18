set -gx HOMEBREW_NO_ANALYTICS 1


if test -f /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

fish_add_path --global "$HOMEBREW_PREFIX/opt/libpq/bin"
fish_add_path --global "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
fish_add_path --global "$HOMEBREW_PREFIX/opt/uutils-coreutils/libexec/uubin"
fish_add_path --global "$HOMEBREW_PREFIX/opt/uutils-diffutils/libexec/uubin"
fish_add_path --global "$HOMEBREW_PREFIX/opt/uutils-findutils/libexec/uubin"
fish_add_path --global "$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin"
