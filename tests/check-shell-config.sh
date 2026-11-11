#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

cat > "$work_dir/sample.env" <<'ENV'
TOKEN="abc"
export PORT=3000
  # indented comment=value
INVALID KEY=ignored
ENV

cat > "$work_dir/check.nu" <<EOF
source "$repo_root/private_Library/private_Application Support/nushell/private_vendor/private_autoload/20-commands.nu"
load-env-vars "$work_dir/sample.env"
if \$env.TOKEN != 'abc' { error make {msg: 'quoted dotenv value failed'} }
if \$env.PORT != '3000' { error make {msg: 'export dotenv value failed'} }
if 'export PORT' in \$env { error make {msg: 'export prefix was retained in variable name'} }
if '# indented comment' in \$env { error make {msg: 'indented comment became a variable'} }
if 'INVALID KEY' in \$env { error make {msg: 'invalid variable name was accepted'} }
let result = ([[a];[1]] | update a 2 | get a | first)
if \$result != 2 { error make {msg: 'native table update failed'} }
EOF

nu --no-config-file "$work_dir/check.nu"

nu_bin="$(command -v nu)"
env PATH=/usr/bin:/bin "$nu_bin" \
    --env-config "$repo_root/private_Library/private_Application Support/nushell/env.nu" \
    -c "if '$HOME/.local/bin' not-in \$env.PATH { error make {msg: 'shared PATH setup failed'} }; if \$env.SSH_AUTH_SOCK != '$HOME/.ssh/proton-pass-agent.sock' { error make {msg: 'SSH_AUTH_SOCK setup failed'} }"

fish_output="$work_dir/fish-abbrs"
fish -ic "source '$repo_root/dot_config/private_fish/conf.d/abbr.fish'; abbr --show" > "$fish_output"

if command -v btm >/dev/null 2>&1; then
    grep -Fq 'top btm' "$fish_output"
    grep -Fq 'htop btm' "$fish_output"
fi
if command -v rg >/dev/null 2>&1; then
    grep -Fq 'grep rg' "$fish_output"
fi

echo "Shell configuration checks passed."
