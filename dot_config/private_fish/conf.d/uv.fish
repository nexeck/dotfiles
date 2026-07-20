if status is-interactive
    if command -qa uv; and uv --version >/dev/null 2>&1
        uv generate-shell-completion fish | source
    end

    if command -qa uvx; and uvx --version >/dev/null 2>&1
        uvx --generate-shell-completion fish | source
    end
end
