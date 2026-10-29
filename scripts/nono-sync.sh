#!/bin/bash
# Keeps ~/.config/nono/profiles and the encrypted bundle in the source in sync.
#   save: before apply/update, bundle and commit local profile edits
#   check: fail if local profiles have edits that were not saved
#   mark: after the bundle was extracted, remember what is in sync
set -euo pipefail

source_dir="$(cd "$(dirname "$0")/.." && pwd)"
profiles="$HOME/.config/nono/profiles"
bundle="$source_dir/secrets/nono.tar.gz.age"
state="${XDG_STATE_HOME:-$HOME/.local/state}/chezmoi/nono-sync"
chezmoi="${CHEZMOI_EXECUTABLE:-chezmoi}"

tree_hash() {
    (cd "$profiles" && find . -type f ! -name .DS_Store -print0 | sort -z | xargs -0 shasum -a 256) | shasum -a 256 | cut -d' ' -f1
}
bundle_hash() {
    shasum -a 256 "$bundle" | cut -d' ' -f1
}
mark() {
    mkdir -p "$(dirname "$state")"
    printf '%s %s\n' "$(tree_hash)" "$(bundle_hash)" > "$state"
}

[ -d "$profiles" ] || exit 0

case "${1:-}" in
check)
    if [ -f "$state" ]; then
        read -r synced_tree _ < "$state"
        if [ "$(tree_hash)" != "$synced_tree" ]; then
            echo "nono profiles have unsaved edits, run: mise run nono:save" >&2
            exit 1
        fi
    fi
    ;;
mark)
    mark
    ;;
save)
    if [ ! -f "$state" ]; then
        mark
        exit 0
    fi
    read -r synced_tree synced_bundle < "$state"
    [ "$(tree_hash)" = "$synced_tree" ] && exit 0

    if [ "$(bundle_hash)" != "$synced_bundle" ]; then
        echo "nono profiles changed locally and in the source bundle; resolve by hand." >&2
        exit 1
    fi
    echo "Saving changed nono profiles..."
    COPYFILE_DISABLE=1 tar -C "$HOME" -czf - .config/nono/profiles | "$chezmoi" encrypt > "$bundle.tmp"
    mv "$bundle.tmp" "$bundle"
    git -C "$source_dir" commit -q -m "chore: update nono profiles" -- secrets/nono.tar.gz.age
    mark
    ;;
*)
    echo "usage: $0 save|check|mark" >&2
    exit 2
    ;;
esac
