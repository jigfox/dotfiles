# Helpers for the bootstrap scripts. Source it: . "$(dirname "$0")/lib.sh"
#
# `mise bootstrap` runs hooks and the bootstrap task on every run, so each
# script has to be a no-op when nothing changed. That is what chezmoi's
# run_onchange did; here a script stores the hash of its inputs under
# ~/.local/state/dotfiles/<name>.sha256 and skips when it still matches.

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
# the checkout (~/.config/mise is a link to <repo>/mise)
repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
age_key="$HOME/.config/fnox/age.txt"

# the hash of stdin
sha256_stdin() { shasum -a 256 | cut -d' ' -f1; }

# unchanged <name> <hash>: true when <hash> is what the last successful run stored
unchanged() { [ "$(cat "$state_dir/$1.sha256" 2>/dev/null)" = "$2" ]; }

# record <name> <hash>: call after the work succeeded
record() {
    mkdir -p "$state_dir"
    printf '%s\n' "$2" >"$state_dir/$1.sha256"
}

# Each hook runs in its own process, so load Homebrew explicitly
load_brew() {
    local brew_bin
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
    return 1
}

is_macos() { [ "$(uname -s)" = Darwin ]; }
