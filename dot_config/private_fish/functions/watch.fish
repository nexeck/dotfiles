#!/usr/bin/env fish

function watch --description 'watch with fish alias support'
    if test (count $argv) -gt 0
        if command -qa viddy
            viddy --disable_auto_save --differences --interval 2 --shell fish $argv
        else if command -qa watch
            command watch -x fish -c "$argv"
        else
            echo "Neither viddy nor watch is installed."
        end
    end
end
