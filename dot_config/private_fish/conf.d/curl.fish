if set -q HOMEBREW_PREFIX; and test -d "$HOMEBREW_PREFIX/opt/curl/bin"
    fish_add_path "$HOMEBREW_PREFIX/opt/curl/bin"
end

if command -qa curl
    set -gx CURL_HOME "~/.config/curl"
end
