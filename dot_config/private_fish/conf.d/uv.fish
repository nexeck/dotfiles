if status is-interactive
    if command -qa uv
        __gen_completions uv (command -s uv) uv generate-shell-completion fish
    end
    if command -qa uvx
        __gen_completions uvx (command -s uvx) uvx --generate-shell-completion fish
    end
end
