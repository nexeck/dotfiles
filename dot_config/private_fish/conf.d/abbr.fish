if status is-interactive
    if command -qa bat
        abbr --add cat bat
    end

    if command -qa dust
        abbr --add du dust
    end

    if command -qa eza
        abbr --add ls 'eza'
        abbr --add lg 'eza --long --all --header --git --git-repos'
        abbr --add l 'eza --long --all --header'
        abbr --add la 'eza --all'
        abbr --add ll 'eza --long'
        abbr --add lt 'eza --long --tree'
    end

    if command -qa bottom
        abbr --add top btm
        abbr --add htop btm
    end

    if command -qa viddy
        abbr --add watch viddy
    end

    if command -qa ripgrep
        abbr --add grep rg
    end
end

