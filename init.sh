#!/usr/bin/env bash

set -euo pipefail

# --- Configuration & Environment ---
work_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

# Ensure newly installed tools are available immediately
export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:/opt/local/sbin:$PATH"

# --- Discovery ---
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    machine=darwin ;;
    *)          echo "Error: This script only supports macOS." && exit 1 ;;
esac

osx_major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$osx_major" -ge 11 ]; then
    osx_num="$osx_major"
else
    osx_num=$(sw_vers -productVersion | cut -d. -f1-2)
fi

echo "Detected macOS version: $osx_num"

# --- Privileges App (Work Macbook Sudo) ---
privileges_cli=""
if command -v PrivilegesCLI >/dev/null 2>&1; then
    privileges_cli="PrivilegesCLI"
elif command -v privileges >/dev/null 2>&1; then
    privileges_cli="privileges"
fi

if [ -n "$privileges_cli" ]; then
    echo "==> Requesting admin privileges via Privileges app..."
    "$privileges_cli" -a
fi

# --- Homebrew ---
echo "==> Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    brew_installer="${work_dir}/install_brew.sh"
    curl -fsSL -o "$brew_installer" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    /bin/bash "$brew_installer"
fi

# Ensure brew is active in the current session
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Install jq for robust JSON parsing
if ! command -v jq >/dev/null 2>&1; then
    echo "Installing jq..."
    brew install jq
fi

# --- MacPorts ---
echo "==> Checking MacPorts..."
if ! command -v port >/dev/null 2>&1; then
    echo "Installing MacPorts for macOS $osx_num..."

    # Get latest release data
    release_json=$(curl -fsSL "https://api.github.com/repos/macports/macports-base/releases/latest")
    macports_tag=$(printf '%s\n' "$release_json" | jq -r '.tag_name')
    macports_version="${macports_tag#v}"

    # Robust matching with jq
    pkg_name=$(printf '%s\n' "$release_json" | jq -r --arg version "$macports_version" --arg os "$osx_num" '.assets[] | select(.name | test("MacPorts-" + $version + "-" + $os + "(-[^.]*)?\\.pkg")) | .name' | head -1)

    if [[ -z "${pkg_name}" || "${pkg_name}" == "null" ]]; then
        echo "Error: No MacPorts package found for macOS ${osx_num}" && exit 1
    fi

    pkg_url="https://github.com/macports/macports-base/releases/download/${macports_tag}/${pkg_name}"
    pkg_file="${work_dir}/${pkg_name}"

    echo "Downloading ${pkg_name}..."
    curl -fsSL -o "${pkg_file}" "${pkg_url}"

    # GPG Signature Verification
    if command -v gpg >/dev/null 2>&1; then
        echo "Verifying signature..."
        curl -fsSL -o "${pkg_file}.asc" "${pkg_url}.asc"
        if ! gpg --list-keys "keymaster@macports.org" >/dev/null 2>&1; then
            curl -fsSL "https://trac.macports.org/static/gpg/macports-keyring.gpg" | gpg --import
        fi
        if ! gpg --verify "${pkg_file}.asc" "${pkg_file}"; then
            echo "Error: MacPorts GPG signature verification failed!" >&2
            exit 1
        fi
    else
        echo "Error: gpg command is required to verify MacPorts installer package." >&2
        exit 1
    fi

    echo "Running installer (requires sudo)..."
    sudo installer -pkg "${pkg_file}" -target /
fi

# --- Base Tools ---
echo "==> Installing Base Tools (mise, chezmoi, pass-cli)..."
for tool in mise chezmoi pass-cli; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Installing $tool..."
        if [ "$tool" == "pass-cli" ]; then
            brew install protonpass/tap/pass-cli
        else
            brew install "$tool"
        fi
    fi
done

# --- Proton Pass & SSH Agent ---
echo "==> Configuring Proton Pass SSH Agent..."
if ! pass-cli vault list >/dev/null 2>&1; then
    pass-cli login
else
    echo "Already logged in to Proton Pass."
fi
if ! pass-cli ssh-agent daemon status | grep -q "Status:[[:space:]]*running"; then
    pass-cli ssh-agent daemon start
else
    echo "Proton Pass SSH Agent is already running."
fi

export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"

# Wait for socket to be ready
echo "Waiting for SSH agent socket..."
for i in {1..10}; do
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo "SSH agent is ready."
        break
    fi
    sleep 0.5
done

if [ ! -S "$SSH_AUTH_SOCK" ]; then
    echo "Warning: SSH agent socket not found at $SSH_AUTH_SOCK"
fi

# --- Chezmoi ---
echo "==> Initializing Dotfiles with chezmoi..."
if [ -d "$HOME/.local/share/chezmoi" ]; then
    echo "Existing chezmoi directory found. Updating..."
    #chezmoi update --apply
else
    echo "Initializing new chezmoi repository..."
    #chezmoi init --apply --ssh nexeck
fi

echo "Done! System initialized."
