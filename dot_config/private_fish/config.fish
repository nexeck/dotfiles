# Disable greeting message. `-g` rather than `-U`: a universal variable is
# persisted in fish_variables and would only need to be set once, so setting it
# on every startup just rewrites state that already exists.
set -g fish_greeting ''
