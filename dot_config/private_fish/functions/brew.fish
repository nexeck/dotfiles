#!/usr/bin/env fish

function brew --description 'brew wrapper that dequarantines newly installed files while it runs'
    # only bother with the dequarantine watcher for subcommands that
    # actually install/link new files under $HOMEBREW_PREFIX; xattr/quarantine
    # is macOS-only, so skip entirely if the helper isn't available
    if not contains -- "$argv[1]" install reinstall upgrade bundle
        or not command -qa dequarantine-watch
        or not set -q HOMEBREW_PREFIX
        command brew $argv
        return $status
    end

    dequarantine-watch -w "$HOMEBREW_PREFIX/bin" -w "$HOMEBREW_PREFIX/Caskroom" -- brew $argv
    return $status
end
