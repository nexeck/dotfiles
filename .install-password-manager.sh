#!/usr/bin/env sh
#
# chezmoi read-source-state pre-hook: make sure `pass-cli` exists before any
# template calls protonPass. Runs on *every* chezmoi command, so it must stay
# cheap and must exit non-zero if it cannot deliver a working pass-cli -
# otherwise chezmoi would go on to render templates with missing secrets.

set -eu

# exit immediately if password-manager-binary is already in $PATH
if command -v pass-cli >/dev/null 2>&1; then
    exit 0
fi

case "$(uname -s)" in
Darwin)
    if ! command -v brew >/dev/null 2>&1; then
        echo "pass-cli is missing and Homebrew is not installed - install Homebrew first" >&2
        exit 1
    fi
    brew install protonpass/tap/pass-cli
    ;;
*)
    echo "unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac
