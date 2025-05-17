#!/usr/bin/env sh

# exit immediately if password-manager-binary is already in $PATH
command -v op >/dev/null 2>&1 && exit

case "$(uname -s)" in
Darwin)
  brew install 1password
  brew install 1password-cli
  ;;
*)
  echo "unsupported OS"
  exit 1
  ;;
esac
