#!/usr/bin/env sh

# exit immediately if password-manager-binary is already in $PATH
command -v pass-cli >/dev/null 2>&1 && exit

case "$(uname -s)" in
Darwin)
  brew install protonpass/tap/pass-cli
  ;;
*)
  echo "unsupported OS"
  exit 1
  ;;
esac
