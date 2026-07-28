# `alias` is a parse-time keyword in nushell, so it cannot be guarded at
# runtime the way fish's `command -qa` checks work (see
# .config/fish/conf.d/abbr.fish). Use `def --wrapped` with a runtime check
# instead, so a missing tool degrades gracefully instead of breaking the
# command outright.

def --wrapped cat [...args] {
  if (is-installed bat) { ^bat ...$args } else { ^cat ...$args }
}

def --wrapped du [...args] {
  if (is-installed dust) { ^dust ...$args } else { ^du ...$args }
}

# Note: ls is kept as nushell's built-in for structured output
def --wrapped __eza [...args] {
  if not (is-installed eza) {
    error make --unspanned { msg: "eza is not installed" }
  }
  ^eza ...$args
}

def --wrapped lg [...args] { __eza --long --all --header --git --git-repos ...$args }
def --wrapped l [...args] { __eza --long --all --header ...$args }
def --wrapped la [...args] { __eza --all ...$args }
def --wrapped ll [...args] { __eza --long ...$args }
def --wrapped lt [...args] { __eza --long --tree ...$args }
