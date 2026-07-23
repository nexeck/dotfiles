#!/usr/bin/env bash
#
# Manual test script: runs a real `brew install` through the shared
# dequarantine-watch helper (dot_local/bin/executable_dequarantine-watch,
# deployed to ~/.local/bin/dequarantine-watch) so we can verify newly
# installed files under /opt/homebrew/bin and /opt/homebrew/Caskroom get
# their com.apple.quarantine xattr stripped automatically while brew runs.
#
# This intentionally does NOT use launchd, to sidestep the (still
# unexplained) issue where a launchd-spawned watchexec never receives fs
# events for /opt/homebrew/* (see /memories/repo/chezmoi-dotfiles.md).

set -euo pipefail

echo "Running: brew install copilot-cli (via dequarantine-watch)"
dequarantine-watch -w /opt/homebrew/bin -w /opt/homebrew/Caskroom -- brew install copilot-cli
