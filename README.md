# My dotfiles

This will setup a new computer with my preferred configuration. It is using [chezmoi][chezmoi] for dotfile management. To install tools and apps which are always used in the latest version [Homebrew][brew] is used. For tools which are required in multiple versions depending on project [mise-en-place][mise] will be used.

A list of things installed with `brew` can be found in the [Brewfile][brewfile].

`chezmoi init` asks whether the machine is used for *work* and/or *personal* stuff. Both can be true; templates check `.work` and `.personal`. Change the answers later in the `[data]` section via `chezmoi edit-config`.

A list of tools with default version installed with `mise` can found in [mise/config.toml][miseconfig].

## Setup

The age key used to decrypt secrets is stored in the macOS keychain (service `age`, account `chezmoi`). Store it once and write it to disk before the first `init`, because chezmoi needs it to decrypt files:

```sh
security add-generic-password -s age -a chezmoi -w "$(cat path/to/age-key.txt)"
mkdir -p ~/.config/age && security find-generic-password -s age -a chezmoi -w > ~/.config/age/keys.txt && chmod 600 ~/.config/age/keys.txt
```

Then install chezmoi and apply:

```sh
sh -c "$(curl -fsLs https://raw.githubusercontent.com/jigfox/dotfiles/refs/heads/main/scripts/chezmoi.sh)" -- init --apply jigfox
```

###### Licenses

[MIT][mit] for everything except the files under [private_Library/private_Fonts](./private_Library/private_Fonts).

The encrypted font files in `private_Library/private_Fonts` are [Comic Code][comic] by Toshi Omagari and they need to be purchased to be used, this is why they are encrypted.

[comic]: https://tosche.net/fonts/comic-code
[mit]: ./LICENSE
[chezmoi]: https://chezmoi.io/
[brew]: https://brew.sh
[mise]: https://mise.jdx.dev
[brewfile]: ./dot_config/brew/Brewfile.tmpl
[miseconfig]: ./dot_config/mise/config.toml
