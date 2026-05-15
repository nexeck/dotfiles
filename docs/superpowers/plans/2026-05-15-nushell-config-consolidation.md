# Nushell Config Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate Nushell configuration into the native `vendor/autoload` directory and clean up redundant initialization logic.

**Architecture:** Move manual config files to `vendor/autoload`, clean up `config.nu`, and rely on the existing `run_onchange` script for tool integrations.

**Tech Stack:** Nushell, Bash (for chezmoi script), Chezmoi.

---

### Task 1: Prepare Directory Structure

**Files:**
- Create: `private_Library/private_Application Support/nushell/private_vendor/private_autoload/`
- Delete: `private_Library/private_Application Support/nushell/autoload/` (after moving files)

- [ ] **Step 1: Create the new vendor/autoload directory**
Run: `mkdir -p "private_Library/private_Application Support/nushell/private_vendor/private_autoload/"`

- [ ] **Step 2: Move existing autoload files to the new location**
Run:
```bash
mv "private_Library/private_Application Support/nushell/autoload/00-utils.nu" "private_Library/private_Application Support/nushell/private_vendor/private_autoload/"
mv "private_Library/private_Application Support/nushell/autoload/10-aliases.nu" "private_Library/private_Application Support/nushell/private_vendor/private_autoload/"
mv "private_Library/private_Application Support/nushell/autoload/20-commands.nu" "private_Library/private_Application Support/nushell/private_vendor/private_autoload/"
```

- [ ] **Step 3: Remove the old autoload directory**
Run: `rmdir "private_Library/private_Application Support/nushell/autoload/"`

- [ ] **Step 4: Commit changes**
Run: `git add . && git commit -m "chore(nu): move config fragments to vendor/autoload"`

### Task 2: Clean up config.nu

**Files:**
- Modify: `private_Library/private_Application Support/nushell/config.nu`

- [ ] **Step 1: Strip redundant logic from config.nu**
Update the file to only contain global settings.

```nu
# config.nu
#
# See https://www.nushell.sh/book/configuration.html

$env.config.show_banner = false
```

- [ ] **Step 2: Commit changes**
Run: `git add "private_Library/private_Application Support/nushell/config.nu" && git commit -m "chore(nu): remove redundant initialization from config.nu"`

### Task 3: Verify and Apply

- [ ] **Step 1: Run chezmoi diff to verify changes**
Run: `chezmoi diff`
Expected: 
- Files moved from `~/Library/Application Support/nushell/autoload/` to `~/Library/Application Support/nushell/vendor/autoload/`.
- `config.nu` is drastically simplified.

- [ ] **Step 2: Apply changes**
Run: `chezmoi apply`

- [ ] **Step 3: Verify Nushell startup**
Run: `nu -c "is-installed starship; lg"`
Expected: No errors, output from `lg` (eza).
