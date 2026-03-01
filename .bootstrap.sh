#!/usr/bin/env bash

set -euo pipefail

work_dir="$(mktemp -d)"

# deletes the temp directory
cleanup() {
  rm -rf "$work_dir"
  echo "Deleted temp working directory $work_dir"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    machine=darwin ;;
    *)          echo "UNKNOWN:${unameOut}" && exit 1 ;;
esac

if [ "${machine}" = "darwin" ]; then
    osx_num=$(sw_vers -productVersion | awk -F '.' '{print $1}')

    export PATH=/opt/local/bin:/opt/local/sbin:$PATH

    # Install homebrew
    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(brew shellenv)"
    fi

    # Install macports
    if ! command -v port >/dev/null 2>&1; then
        # Fetch latest MacPorts version and matching package from GitHub releases API
        macports_tag=$(curl -fsSL "https://api.github.com/repos/macports/macports-base/releases/latest" \
            | grep '"tag_name"' | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
        macports_version="${macports_tag#v}"

        # Find the asset name matching the current macOS major version
        pkg_name=$(curl -fsSL "https://api.github.com/repos/macports/macports-base/releases/latest" \
            | grep '"name"' \
            | grep "MacPorts-${macports_version}-${osx_num}-.*\.pkg\"" \
            | head -1 \
            | sed 's/.*"name": *"\(.*\)".*/\1/')

        if [ -z "${pkg_name}" ]; then
            echo "No MacPorts package found for macOS ${osx_num}" && exit 1
        fi

        pkg_url="https://github.com/macports/macports-base/releases/download/${macports_tag}/${pkg_name}"
        asc_url="${pkg_url}.asc"

        pkg_file="${work_dir}/${pkg_name}"
        asc_file="${pkg_file}.asc"

        curl -fsSL -o "${pkg_file}" "${pkg_url}"
        curl -fsSL -o "${asc_file}" "${asc_url}"

        # Verify GPG signature if gpg is available
        if command -v gpg >/dev/null 2>&1; then
            # Import MacPorts signing key if not already present
            if ! gpg --list-keys "keymaster@macports.org" >/dev/null 2>&1; then
                curl -fsSL "https://trac.macports.org/static/gpg/macports-keyring.gpg" \
                    | gpg --import
            fi
            gpg --verify "${asc_file}" "${pkg_file}"
        else
            echo "Warning: gpg not available, skipping signature verification"
        fi

        sudo installer -pkg "${pkg_file}" -target /
    fi

    if ! command -v chezmoi >/dev/null 2>&1; then
        brew install chezmoi
    fi

    if [ ! -d ~/.local/share/chezmoi ]; then
        chezmoi init --apply nexeck
        chezmoi git remote set-url origin git@github.com:nexeck/dotfiles.git
    else
        echo "Chezmoi directory exists, attempting to pull and re-init"
        chezmoi git pull
        chezmoi init --apply
    fi
fi
