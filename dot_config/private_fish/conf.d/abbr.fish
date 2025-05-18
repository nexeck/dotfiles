if command -qa bat
    abbr cat bat
end

if command -qa dust
    abbr du dust
end

if command -qa eza
   	abbr -a ls 'eza'
   	abbr -a lg 'eza --long --all --header --git --git-repos'
   	abbr -a l 'eza --long --all --header'
   	abbr -a la 'eza --all'
   	abbr -a ll 'eza --long'
   	abbr -a lt 'eza --long --tree'
end
