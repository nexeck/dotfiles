# Dotfiles Repository (chezmoi)

macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/). No Linux support.

## Profiles

Two mutually exclusive profiles, set during `chezmoi init`:

- **Work** (`isWork: true`) — hostname `macbook-w`
- **Personal** (`isPersonal: true`) — hostname `macbook-p`

Profile flags are used in `.tmpl` files and `.chezmoiignore` to conditionally include configs, packages, and secrets.

## Repository Structure

```
.bootstrap.sh                     # Initial machine setup (Homebrew, MacPorts, chezmoi)
.chezmoi.yaml.tmpl                # chezmoi config (age encryption, 1Password hook, profile prompts)
.chezmoiignore                    # Profile-conditional ignores
.chezmoidata/
  packages.yaml                   # All packages: homebrew taps/brews/casks, macports, vscode extensions
  darwin_defaults.yaml            # macOS defaults (dock, finder, terminal)
.chezmoiscripts/                  # run_once_ and run_onchange_ scripts
  darwin/                         # macOS-specific scripts (packages, defaults, hostname, docker, sudo touch)
dot_config/
  git/                            # Git config with profile-conditional includes, 1Password signing
  private_fish/                   # Fish shell: config, functions, conf.d drop-ins
  private_1Password/private_ssh/  # 1Password SSH agent config (profile-conditional vaults)
  ...                             # starship, mise, atuin, zed, curl, nushell
private_dot_ssh/                  # SSH config, allowed_signers, public keys from 1Password
private_dot_aws/                  # AWS config (age-encrypted)
```

## Secrets Management

**1Password** — SSH keys, git signing keys, git identity (name/email). Retrieved in templates via `onepasswordRead "op://vault/item/field"`. The 1Password CLI is auto-installed by a pre-read-source-state hook (`.install-password-manager.sh`).

**Age encryption** — Used for files that must exist without 1Password (AWS config, Databricks config). Encrypted files end in `.age`. The age identity key is decrypted from `key.txt.age` by a `run_once_before` script.

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

## Conventions

### chezmoi

- **File prefixes:** `dot_` → `.`, `private_` → mode 0700/0600, `encrypted_` → age-decrypted, `exact_` → removes unmanaged files in directory.
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

- **Shell:** Fish is the primary shell. Nushell configs also exist.
- **Editors:** Zed (primary), VS Code. Both configured in this repo.
- **Git style:** Conventional commits (`feat:`, `fix:`, `chore:`). Changelog generated with git-cliff.

## Common Tasks

**Add a new brew/cask/tap:** Edit `.chezmoidata/packages.yaml` under the appropriate profile section.

**Add a new dotfile:** Use `chezmoi add <file>`. For secrets, use `chezmoi add --encrypt <file>`.

**Add a profile-conditional file:** Create the `.tmpl` file and add an ignore rule in `.chezmoiignore` for the other profile.

**Test changes:** `chezmoi diff` to preview, `chezmoi apply -n` for dry-run, `chezmoi apply` to apply.
