# Dotfiles

Personal macOS workstation configuration, managed with [chezmoi](https://www.chezmoi.io/).

Covers shells (fish, zsh, bash, nushell), git, SSH, editors, CLI tooling, Homebrew
packages, macOS defaults and a handful of LaunchAgents. **macOS only** — there is
no Linux support, and the provisioning scripts assume Homebrew and `sudo`.

## Requirements

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh/)
- chezmoi ≥ 2.62 (enforced by `.chezmoiversion`)
- A Proton Pass account with the vault entries listed under [Secrets](#secrets)

## Fresh machine

Bootstrapping is handled by a separate repository:
[dotfiles-init](https://github.com/nexeck/dotfiles-init).

It ends up running `chezmoi init --apply`, which will:

1. Ask **"Is this a work machine?"** — this choice is stored and drives every
   profile-conditional file from then on.
2. Install `pass-cli` (Proton Pass CLI) via a pre-hook, so templates can resolve
   secrets.
3. Write the dotfiles, then run the provisioning scripts: install packages,
   apply macOS defaults, enable Touch ID for `sudo`, set the shell to fish.

Expect to be prompted: several scripts need `sudo`, and Proton Pass must be
unlocked. Setup is **not** unattended.

## Profiles

Two mutually exclusive profiles, chosen at `chezmoi init` time:

| Profile  | Flag               | Used for                                                                                             |
| -------- | ------------------ | ---------------------------------------------------------------------------------------------------- |
| Work     | `isWork: true`     | Corporate machine: work git identity, proxy CA workarounds, Homebrew dequarantine, MDM-friendly umask |
| Personal | `isPersonal: true` | Personal machine: personal git identity, macOS defaults, personal apps                               |

Profile gating happens in `.chezmoiignore` and in `.tmpl` guards. Re-run
`chezmoi init` to change the answer.

## Day-to-day

```sh
chezmoi diff                 # preview pending changes
chezmoi apply                # apply them
chezmoi apply --force <path> # re-apply one target, skipping the "changed since" prompt
chezmoi edit <file>          # edit the source of a deployed file (opens micro)
chezmoi add <file>           # start managing an existing file
update                       # upgrade Homebrew, MacPorts and tldr pages
dotfiles-doctor              # check that agent, secrets, signing and agents work
```

Packages are **not** installed by hand: add them to `.chezmoidata/packages.yaml`
and run `chezmoi apply`.

## Layout

| Path               | Contents                                                          |
| ------------------ | ----------------------------------------------------------------- |
| `.chezmoidata/`    | Data files: package lists, macOS defaults                          |
| `.chezmoiscripts/` | Provisioning scripts (`run_once_` / `run_onchange_`)               |
| `dot_config/`      | `~/.config`: fish, git, starship, atuin, curl, zed, shared shell   |
| `dot_local/bin/`   | Standalone scripts shared by every shell via `$PATH`               |
| `private_dot_ssh/` | SSH config, `allowed_signers`, public keys                         |
| `private_Library/` | LaunchAgents, nushell, VS Code settings                            |
| `scripts/`         | Manual debugging helpers — never run automatically                 |

`AGENT.md` documents the conventions in detail (naming prefixes, script phases,
where shared logic belongs). Read it before making structural changes.

## Secrets

Nothing secret is stored in this repository. Every secret is fetched from
**Proton Pass** at template-render time via `protonPass "pass://..."`:

- `pass://{Personal,Work}/GIT Config/{name,email,signingkey}`
- `pass://{Personal,Work}/SSH Key {Personal,Work}/public key`

Consequences worth knowing:

- Proton Pass must be **unlocked** for `chezmoi diff`, `status`, `cat` _and_
  `apply` — not just apply.
- SSH keys never touch disk unencrypted; authentication and commit signing go
  through the Proton Pass SSH agent (`~/.ssh/proton-pass-agent.sock`), started
  by the `com.proton.pass-cli.ssh-agent` LaunchAgent.
- Always pipe `protonPass` through `trim` — values come back with a trailing
  newline that silently corrupts line-oriented files.

## Troubleshooting

Start with `dotfiles-doctor` — it checks the SSH agent, the Proton Pass session,
commit signing, `allowed_signers` integrity, LaunchAgents and (on work machines)
the Homebrew dequarantine sudo rule, in about a second. `dotfiles-doctor --fix`
additionally restarts the SSH agent if it is unreachable.

**`chezmoi diff` fails or renders empty secrets**
Proton Pass is locked or `pass-cli` is missing. Unlock the app, then run
`pass-cli --version` to confirm.

**Commits are unsigned, or `git log --show-signature` reports a bad signature**
Check the agent: `ssh-add -l` should list your key. If the socket is stale,
restart the agent with `dotfiles-doctor --fix`, or manually:

```sh
plist=~/Library/LaunchAgents/com.proton.pass-cli.ssh-agent.plist
launchctl bootout gui/"$(id -u)" "$plist"; launchctl bootstrap gui/"$(id -u)" "$plist"
```

**A new `~/.local/bin` script isn't found**
fish caches failed command lookups. Start a new shell (`exec fish`).

**A LaunchAgent change doesn't take effect**
`chezmoi apply` writes the plist but does not reload launchd — `bootout` then
`bootstrap` it as above.

**A deleted file keeps coming back in `$HOME`**
Removing a source entry does not delete the deployed copy. Add its
destination-relative path to `.chezmoiremove`.

**Gatekeeper kills freshly installed Homebrew binaries (work machines)**
That is what `brew-dequarantine-watch` exists for. Verify
`/usr/local/libexec/dequarantine-homebrew` exists and that `watchexec` is
installed; see `scripts/repro-brew-dequarantine.sh`.

## Validating changes

There is no CI yet. Before committing, at minimum:

```sh
# every script template must render and be syntactically valid
for t in .chezmoiscripts/*.tmpl .chezmoiscripts/darwin/*.tmpl; do
    chezmoi execute-template < "$t" > /tmp/out.sh && bash -n /tmp/out.sh
done

# plists must still be well-formed
chezmoi execute-template < some.plist.tmpl > /tmp/x.plist && plutil -lint /tmp/x.plist

chezmoi status   # confirm only the intended targets changed
```

Note that `chezmoi cat` and `chezmoi apply <path>` do not work on
`.chezmoiscripts/` entries — use `chezmoi execute-template` as above.
