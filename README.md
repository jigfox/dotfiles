# My dotfiles

This will setup a new computer with my preferred configuration. It is using [chezmoi][chezmoi] for dotfile management. To install tools and apps which are always used in the latest version [Homebrew][brew] is used. For tools which are required in multiple versions depending on project [mise-en-place][mise] will be used.

A list of things installed with `brew` can be found in the [Brewfile][brewfile].

`chezmoi init` asks whether the machine is used for *work* and/or *personal* stuff. Both can be true; templates check `.work` and `.personal`. Change the answers later in the `[data]` section via `chezmoi edit-config`.

A list of tools with default version installed with `mise` can found in [mise/config.toml][miseconfig].

## Setup

Secrets are encrypted with [age][age]. The key lives in the Passwords app as `chezmoi age key` (synced via iCloud). Setup asks for it once: copy it from Passwords when prompted.

The built-in git is used for the first clone, so no Xcode command line tools are needed up front; Homebrew installs them afterwards.

```sh
sh -c "$(curl -fsLs https://raw.githubusercontent.com/jigfox/dotfiles/refs/heads/main/scripts/chezmoi.sh)" -- init --apply --use-builtin-git true jigfox
```

After setup:

- macOS asks for Accessibility permission for AeroSpace.
- App Store apps install only if this Apple ID has downloaded them before.
- Reinstall the herdr `claude-session-title` plugin.

###### Licenses

[MIT][mit] for everything except the files under [private_Library/private_Fonts](./private_Library/private_Fonts).

The encrypted font files in `private_Library/private_Fonts` are [Comic Code][comic] by Toshi Omagari and they need to be purchased to be used, this is why they are encrypted.

[comic]: https://tosche.net/fonts/comic-code
[age]: https://age-encryption.org
[mit]: ./LICENSE
[chezmoi]: https://chezmoi.io/
[brew]: https://brew.sh
[mise]: https://mise.jdx.dev
[brewfile]: ./dot_config/brew/Brewfile.tmpl
[miseconfig]: ./dot_config/mise/config.toml
