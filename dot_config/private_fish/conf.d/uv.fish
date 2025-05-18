if status is-interactive
    if command -qa uv
        uv generate-shell-completion fish | source
    end

    if command -qa uvx
        uvx --generate-shell-completion fish | source
    end
end
