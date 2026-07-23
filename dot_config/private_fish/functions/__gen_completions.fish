function __gen_completions --description 'Cache a command\'s fish completions to a lazily-loaded file, regenerating only when the source binary changes'
    # Usage: __gen_completions NAME REFERENCE GENERATOR...
    #   NAME       basename of the file written under completions/ (usually the command)
    #   REFERENCE  path whose mtime gates regeneration (usually `command -s NAME`)
    #   GENERATOR  command that prints a fish completion script to stdout
    #
    # Writing to completions/ lets fish auto-load the completions lazily (on
    # first TAB) instead of sourcing them on every shell startup.
    set -l name $argv[1]
    set -l reference $argv[2]
    set -l generator $argv[3..-1]

    set -l file "$__fish_config_dir/completions/$name.fish"

    # Up to date: nothing to do (this is the common, fast path).
    if test -f "$file"; and not test "$reference" -nt "$file"
        return 0
    end

    mkdir -p (path dirname "$file")
    set -l tmp (mktemp "$file.XXXXXX")
    if $generator >"$tmp" 2>/dev/null
        mv "$tmp" "$file"
    else if not test -s "$tmp"
        # Generator failed but produced no output (e.g. a tool that isn't
        # configured yet). Cache an empty marker so we stop re-probing it on
        # every startup; it self-heals once REFERENCE's mtime advances (a
        # brew/mise upgrade rewrites the binary/shim).
        mv "$tmp" "$file"
        return 1
    else
        # Failed with partial output - don't cache garbage.
        rm -f "$tmp"
        return 1
    end
end
