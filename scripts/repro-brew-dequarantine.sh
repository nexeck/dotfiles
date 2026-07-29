#!/usr/bin/env bash
#
# NOT a test - this performs a REAL `brew install` and changes system state.
# It is a manual reproduction harness for the Homebrew dequarantine path:
# it installs a cask through ~/.local/bin/brew-dequarantine-watch (source:
# dot_local/bin/executable_brew-dequarantine-watch) so you can verify that
# newly installed files under /opt/homebrew/bin and /opt/homebrew/Caskroom
# get their com.apple.quarantine xattr stripped while brew runs.
#
# Only needed when debugging that machinery. For a quick, side-effect-free
# check that the watcher becomes ready and strips an xattr, use a throwaway
# file instead:
#
#   brew-dequarantine-watch -w /opt/homebrew/bin -- bash -c '
#     f=/opt/homebrew/bin/.dqtest-$$; : > "$f"
#     xattr -w com.apple.quarantine "0081;0;test;" "$f"; sleep 3
#     xattr -p com.apple.quarantine "$f" 2>/dev/null || echo CLEARED; rm -f "$f"'
#
# This intentionally does NOT use launchd, to sidestep the (still unexplained)
# issue where a launchd-spawned watchexec never receives fs events for
# /opt/homebrew/* (see /memories/repo/chezmoi-dotfiles.md).

set -euo pipefail

pkg=${1:-copilot-cli}

echo "This will run: brew install ${pkg} (via brew-dequarantine-watch)"
read -r -p "Continue? [y/N] " reply
[[ ${reply} == [yY] ]] || { echo "Aborted."; exit 0; }

brew-dequarantine-watch -w /opt/homebrew/bin -w /opt/homebrew/Caskroom -- brew install "${pkg}"
