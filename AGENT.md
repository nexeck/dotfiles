# Dotfiles Repository (chezmoi)

macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/). No Linux support.

## Profiles

Two mutually exclusive profiles, set during `chezmoi init`:

- **Work** (`isWork: true`) — hostname `macbook-w`
- **Personal** (`isPersonal: true`) — hostname `macbook-p`

Profile flags are used in `.tmpl` files and `.chezmoiignore` to conditionally include configs, packages, and secrets.

## Repository Structure

```
.chezmoi.yaml.tmpl                # chezmoi config (profile prompt, work umask)
.chezmoiversion                   # Minimum chezmoi version required by these templates
.chezmoiignore                    # Profile-conditional ignores
.chezmoiremove                    # Targets to delete from $HOME (deleted/renamed entries)
.chezmoidata/
  packages.yaml                   # All packages: homebrew taps/brews/casks, macports, vscode extensions
  darwin_defaults.yaml            # macOS defaults (dock, finder, terminal)
.chezmoiscripts/                  # run_once_ and run_onchange_ scripts
  darwin/                         # macOS-specific scripts (packages, defaults, hostname, docker, sudo touch)
dot_config/
  git/                            # Git config with profile-conditional includes, Proton Pass signing
  private_fish/                   # Fish shell: config, functions, conf.d drop-ins
  shell/                          # POSIX PATH/env setup shared by zsh + bash (and read by fish)
  ...                             # starship, atuin, zed, curl
dot_local/bin/                    # Standalone scripts, shared by every shell via $PATH
private_dot_ssh/                  # SSH config, allowed_signers, public keys from Proton Pass
private_Library/                  # LaunchAgents, nushell, VS Code settings
```

## Secrets Management

**Proton Pass** — SSH keys, git signing keys, git identity (name/email). Retrieved in templates via `protonPass "pass://..."`. The `pass-cli` is auto-installed by a pre-read-source-state hook (`.install-password-manager.sh`).

Always pipe `protonPass` through `trim` — it returns values with a trailing newline, which silently corrupts line-oriented files such as `~/.ssh/allowed_signers`.

Proton Pass is the *only* secrets backend. There is deliberately no `encryption:` block and no age identity: nothing is stored encrypted at rest, so there is no key to distribute or rotate. If an `encrypted_` entry is ever genuinely needed, add the `encryption:`/`age:` config back together with a `run_once_before` script that provisions the identity.

## Package Management

All packages are defined in `.chezmoidata/packages.yaml` with this structure:

```yaml
packages:
  vscode:
    all: [] # Extensions for both profiles
    work: []
    personal: []
  darwin:
    all:
      taps: []
      brews: []
      casks: []
      ports: [] # MacPorts packages
    work:
      taps: []
      brews: []
      casks: []
      ports: [] # MacPorts packages
    personal:
      taps: []
      brews: []
      casks: []
      ports: [] # MacPorts packages
```

Packages are installed by `.chezmoiscripts/darwin/run_onchange_darwin-install-packages.sh.tmpl`.

A tap entry is either a plain string or a map with `name`, optional `url` and optional `trusted`. `trusted: true` suppresses Homebrew's third-party-tap confirmation and is opt-in per tap — never set it wholesale.

```yaml
taps:
  - some/tap # untrusted: brew will ask
  - name: protonpass/tap
    trusted: true
```

## Conventions

### chezmoi

- **File prefixes:** `dot_` → `.`, `private_` → mode 0700/0600, `exact_` → removes unmanaged files in directory.
- **Templates:** `.tmpl` suffix enables Go template rendering. Use `{{ if .isWork }}` / `{{ if .isPersonal }}` guards for profile-conditional content. A template that resolves to only whitespace is skipped entirely (useful for conditional scripts).
- **Scripts** are in `.chezmoiscripts/` and follow this naming:
  - `run_` — runs on every `chezmoi apply`
  - `run_once_` — runs once per unique content (tracked by SHA256 hash)
  - `run_onchange_` — runs only when content changes since last successful run
  - `before_` / `after_` modifier — controls execution relative to file updates (e.g. `run_once_before_`, `run_onchange_after_`)
  - Scripts execute in **alphabetical order** within each phase. Use numeric prefixes if order matters.
  - All scripts must be **idempotent**. Scripts break chezmoi's declarative model and should be used sparingly.
  - No need to set executable bit — chezmoi handles this. Always include a `#!` shebang.
- **Data files** in `.chezmoidata/` are merged into template data (accessible as e.g. `.packages`).

### Project

- **Shell:** Fish is the primary shell; zsh and bash share PATH/env setup via `dot_config/shell/path.sh`. Nushell configs also exist.
- **Editors:** `EDITOR`, `git core.editor` and `chezmoi edit` all use micro. Zed and VS Code settings are managed here too.
- **Git style:** Conventional commits (`feat:`, `fix:`, `chore:`). Changelog generated with git-cliff.
- **Shared logic:** anything needed by more than one shell belongs in `dot_local/bin/` as a plain script rather than being reimplemented per shell (e.g. `update`, `dotfiles-doctor`). Exceptions are things that must mutate the calling shell's own state, such as `load_env_vars`.
- **Health checks:** `dotfiles-doctor` is the place for runtime checks. Keep it fast (~1s) and read-only by default — never call `chezmoi status` from it, which costs ~10s because it resolves every `protonPass` lookup. Put repairs behind `--fix`.

## Common Tasks

**Add a new brew/cask/tap:** Edit `.chezmoidata/packages.yaml` under the appropriate profile section.

**Add a new dotfile:** Use `chezmoi add <file>`. Secrets must not be committed — reference them from Proton Pass in a `.tmpl` instead.

**Add a profile-conditional file:** Create the `.tmpl` file and add an ignore rule in `.chezmoiignore` for the other profile.

**Test changes:** `chezmoi diff` to preview, `chezmoi apply -n` for dry-run, `chezmoi apply` to apply.
