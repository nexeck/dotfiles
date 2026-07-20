if command -qa scw; and status is-interactive; and scw --version >/dev/null 2>&1
    eval (scw autocomplete script shell=fish)
end
