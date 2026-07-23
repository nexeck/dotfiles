# PATH entry for $HOMEBREW_PREFIX/opt/curl/bin lives in the shared
# dot_config/shell/extra_paths.txt (added via 00-env.fish), not here.
if command -qa curl
    set -gx CURL_HOME "~/.config/curl"
end
