#!/bin/bash
# chezmoi needs the age key to decrypt secrets. It is stored in the
# Passwords app (synced via iCloud), which has no CLI, so paste it once.
set -euo pipefail

key_file="$HOME/.config/age/keys.txt"
[ -s "$key_file" ] && exit 0

echo "Age key missing: copy 'chezmoi age key' from the Passwords app, then press Enter."
{ read -r _ < /dev/tty; } 2>/dev/null || true

key="$(pbpaste | grep -oE 'AGE-SECRET-KEY-1[0-9A-Z]+' | head -1 || true)"
if [ -z "$key" ]; then
    echo "Clipboard does not contain an age secret key, aborting." >&2
    exit 1
fi

mkdir -p "$(dirname "$key_file")"
(umask 077 && printf '%s\n' "$key" > "$key_file")
pbcopy < /dev/null
echo "Age key written to $key_file, clipboard cleared."
