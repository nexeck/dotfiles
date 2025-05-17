#!/usr/bin/env sh

set -e # -e: exit on error

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

work_dir="$(mktemp -d)"

MACPORTS_VERSION=2.10.7

# deletes the temp directory
function cleanup {
  rm -rf "$work_dir"
  echo "Deleted temp working directory $work_dir"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    machine=darwin;;
    *)          echo "UNKNOWN:${unameOut}" && exit 1;;
esac

if [ "${machine}" = "darwin" ]; then
    osx_num=$(sw_vers -productVersion | awk -F '[.]' '{print $1}')
    case "${osx_num}" in
        14) osx_code_name=Sonoma ;;
        15) osx_code_name=Sequoia ;;
        *)  echo "UNKNOWN:${osx_num}" && exit 1;;
    esac

    export PATH=/opt/local/bin:/opt/local/sbin:$PATH

    if ! xcode-select -p 1>/dev/null; then
      xcode-select --install
    fi

    # Install macports
    if [ ! "$(command -v port)" ]; then
        cd "${work_dir}"
        pkg_file=$(curl -sSL -f -O "https://github.com/macports/macports-base/releases/download/v${MACPORTS_VERSION}/MacPorts-${MACPORTS_VERSION}-${osx_num}-${osx_code_name}.pkg" -w %{filename_effective})
        sudo installer -pkg "${pkg_file}" -target /
        cd -
    fi
    # Install homebrew
    if [ ! "$(command -v brew)" ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if [ ! "$(command -v chezmoi)" ]; then
        brew install chezmoi
    fi

    if [ ! -d ~/.local/share/chezmoi ]; then
        chezmoi init --apply nexeck
        chezmoi git remote set-url origin git@github.com:nexeck/dotfiles.git
    else
      echo "Chezmoi directory exists, attempt to pull and re-init"
      chezmoi git pull
      chezmoi init --apply
    fi
fi
