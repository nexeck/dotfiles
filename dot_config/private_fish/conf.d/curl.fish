if test -d "/opt/homebrew/opt/curl/bin"
    fish_add_path /opt/homebrew/opt/curl/bin
end

if command -qa curl
    set -gx CURL_HOME "~/.config/curl"
end
