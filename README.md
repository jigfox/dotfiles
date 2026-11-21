# My dotfiles

This will setup a new computer with my preferred configuration with [`mise bootstrap`][bootstrap] ([mise-en-place][mise]): Homebrew packages and apps, macOS settings, dotfiles, the login shell and the tools that are required in multiple versions depending on project. Secrets live in [fnox][fnox], encrypted with [age][age] in this (public) repository.

## Environments

What a machine gets depends on the *environments* it selects. [mise/config.toml](./mise/config.toml) is the base every machine has, each environment adds `mise/config.<name>.toml` on top:

| environment | adds |
| --- | --- |
| `personal` | the Zen profile `private` |
| `inovex` | the company git identity, Slack, the Zen profile `inovex` |
| `customer-a` | everything for one customer: git identity, openconnect, the Zen profile `customer`, and a private repo with the work sandbox, `mise.toml` and ssh key |

A machine can select several. The selection is per machine, in `~/.config/mise/miserc.local.toml`, which is not in git. Each environment file declares the fnox secrets it needs under `[bootstrap.secrets]`, so a machine without `customer-a` never reads the customer's data.

Neutral names (`customer-a`) are what is public. The real customer is only in the encrypted values and in a private repo: bootstrap clones it (URL in the fnox secret `CUSTOMER_A_REPO`) to `~/.local/share/dotfiles-customer-a` and runs its `setup`, which links its files into place. A machine can give the environment a local alias (see step 2).

## Setup

The age key has to come first, because nothing secret can be decrypted without it. The order matters.

1. **Get the age key.** Open the Passwords app, find the entry `dotfiles age key` and copy it. Then:

   ```sh
   mkdir -p ~/.config/fnox && (umask 077; pbpaste > ~/.config/fnox/age.txt) && pbcopy </dev/null
   ```

   It is the key of the recipient `age1zf8cfg0hrzz6k3hfp3jeuttud8sak8hk5qdruhaw3m9alem93scqs2c0pj` in [home/config/fnox/config.toml](./home/config/fnox/config.toml).

2. **Pick the environments of this Mac**, for example `personal,inovex,customer-a` (`personal` alone is enough for a private Mac). They are passed to the first pass in step 4 with `-E`, which saves them to `miserc.local.toml`. Do not create `~/.config/mise` yourself: step 4 links it to the checkout and refuses a directory that already holds a config.

   To give an environment a local name, edit the saved `~/.config/mise/miserc.local.toml` after step 4 (it lives in the checkout and is git-ignored):

   ```toml
   env = ["personal", "inovex", "acme"]

   [env_sets]
   acme = ["customer-a"]
   ```

   An alias only works through `env =`, not `-E`.

3. **Install mise.**

   ```sh
   curl https://mise.run | sh
   ```

4. **First pass, without secrets.** The checkout is cloned over https, so no Xcode command line tools are needed up front. This installs Homebrew, the packages (fnox included), the tools, the macOS settings and the login shell, links `~/.config/mise` to `mise/` of the checkout (`~/.local/share/mise/bootstrap-repo`) and fnox's config to `~/.config/fnox/config.toml`:

   ```sh
   ~/.local/bin/mise -E personal,inovex,customer-a bootstrap --from https://github.com/jigfox/dotfiles.git --config-dir mise --skip dotfiles,repos --save-env
   ```

5. **Second pass, with secrets.** This clones the repos (neovim, and over ssh the private repos of customer environments: the `prepare-ssh` hook writes the ssh key from fnox first and checks GitHub's host key), deploys the dotfiles, including the templates and the files fnox holds (ssh keys), then runs the setup steps (downloads, fonts, fish plugins, Zen profiles):

   ```sh
   cd ~/.local/share/mise/bootstrap-repo && mise trust && mise run apply
   ```

   `mise run apply` is `fnox exec -- mise bootstrap --skip-dirty` (a checkout with local changes, like neovim's lock file, is left alone). Afterwards switch the remote of the checkout to ssh: `git remote set-url origin git@github.com:jigfox/dotfiles.git`.

6. **Restore the tracked files** (the nono profiles, see [Tracked files](#tracked-files)) from their private history repo:

   ```sh
   mise bootstrap --adopt git@github.com:jigfox/dotfiles-history.git
   ```

After setup:

- macOS asks for Accessibility permission for AeroSpace.
- App Store apps install only if this Apple ID has downloaded them before.
- Reinstall the herdr `claude-session-title` plugin.
- Open a new shell, the login shell changed to fish.

## Day to day

```sh
cd ~/.local/share/mise/bootstrap-repo
mise run apply                                  # apply everything
fnox exec -- mise bootstrap --dry-run           # preview
fnox exec -- mise bootstrap secrets status      # are all secrets there?
fnox exec -- mise bootstrap --only dotfiles     # just the dotfiles
```

Dotfiles are links into the checkout (`home/`) or, where a value is secret or per machine, rendered [Tera][tera] templates (`templates/`). `mise bootstrap` runs its hooks and the `bootstrap` task on every run, so every script in `mise/scripts` is a no-op when nothing changed: it keeps the hash of its input in `~/.local/state/dotfiles/` (what chezmoi's `run_onchange` did).

### Secrets

All secrets are in [home/config/fnox/config.toml](./home/config/fnox/config.toml), age-encrypted. fnox accepts `[files]` only in its global config, so this file is linked to `~/.config/fnox/config.toml`; then, with the age key in place:

```sh
fnox set --global NAME                    # a text secret (prompts for the value)
fnox set --global --file ~/.ssh/config    # a file, deployed by a `mode = "fnox"` dotfile
fnox get NAME
```

Fonts (Comic Code, licensed) are binary: they stay `.age` files in `secrets/`, encrypted to the same recipient (`age -e -a -r <recipient>`), and bootstrap steps decrypt them.

### Tracked files

Files that their app rewrites (the nono profiles: a rewrite replaced the link with a real file) are not in this repo but `mode = "track"` entries: they stay plain files in place, and the watcher service `mise-history` (a LaunchAgent) saves every change to a local git history and syncs it with the private repo [jigfox/dotfiles-history](https://github.com/jigfox/dotfiles-history). They are encrypted to the fnox recipient (`settings.age.key_file` points mise at the fnox key), so customer profiles can live there too, as variants of their environment.

```sh
mise dot status                 # watcher, last push and pull
mise dot history --path <file>  # saved versions
mise dot rollback <file> --to <checkpoint>
mise dot track <file> --encrypt # then move the entry it adds into mise/config.toml
```

### Sandboxed agents

`claude`, `codex` and `opencode` run in a [nono](https://github.com/always-further/nono) sandbox under the roots `~/src/<host>/` that have one. A root is a directory whose `mise.toml` is a link to the generic [home/config/work/mise.toml](./home/config/work/mise.toml) (also deployed to `~/.config/work/mise.toml`): it keeps everything the agents and tools write (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `GRADLE_USER_HOME`, kubeconfig, AWS, npm, ...) in the root, starts a Colima VM per root for Docker (`mise/scripts/colima-agent`, via the enter and leave hooks) and puts `~/.config/work/bin` first in PATH. There `claude`, `codex` and `opencode` are links to [mise/scripts/agent](./mise/scripts/agent), so tools that exec an agent get the sandbox too. The script takes the rest from the root's `mise.local.toml` (a link as well, it overrides `mise.toml`):

| variable | meaning |
| --- | --- |
| `AGENT_NONO_PROFILE` | nono profile to run in, required |
| `AGENT_MCP` | MCP servers that run outside the sandbox, one `name=command` per line, optional |
| `AGENT_IGNORED_CONFIG` | mise configs the agent must not load, becomes `MISE_IGNORED_CONFIG_PATHS`, optional |

Secrets of a root go in a `fnox.toml` next to it (the enter hook runs `fnox activate`). A credential the agent needs is handed over by the nono profile (`env_credentials`, e.g. `"env://ANTHROPIC_API_KEY": "ANTHROPIC_API_KEY"`), not by the script. The profiles are tracked files: `agent-claude-core` is the base of all of them, `github` is the one of `~/src/github.com`.

To add a root: link the generic `mise.toml` and a `mise.local.toml` with at least `AGENT_NONO_PROFILE` into it (a `[dotfiles]` entry here, or the `setup` of a private repo), and track a nono profile of that name (extend `agent-claude-core`, grant the root's path).

### Adding a customer

1. Create a private repo for the customer's files with an executable `setup` that links them into place (see the one of `customer-a`; it can name the customer freely). For a sandboxed root (see above) it links the generic `~/.config/work/mise.toml` as `<root>/mise.toml` and the customer's part as `<root>/mise.local.toml` (tools, hosts, `AGENT_*`).
2. Copy `mise/config.customer-a.toml` to `mise/config.customer-b.toml` and give every secret a `CUSTOMER_B_` name, the clone path `~/.local/share/dotfiles-customer-b`. Keep this repo neutral: the real name, hosts and users only go into fnox and the private repo.
3. Store the values: `fnox set --global CUSTOMER_B_REPO` (the private repo's ssh URL), `CUSTOMER_B_GITLAB_HOST`, `CUSTOMER_B_GIT_EMAIL`.
4. Copy the templates the file refers to (`templates/git/customer-a.gitconfig.tera`, `templates/git/env-customer-a.inc.tera`), and add an `[include]` of `env-customer-b.inc` to `templates/gitconfig.tera`.
5. Select it on a machine: `env = [..., "customer-b"]` in its `miserc.local.toml`, or behind a local alias in `[env_sets]`.

## Layout

| path | what |
| --- | --- |
| `mise.toml` | tasks of this checkout (`apply`), not deployed |
| `mise/` | becomes `~/.config/mise`: `config.toml` (base), `config.<env>.toml`, `scripts/` |
| `home/` | plain files, linked into place by `[dotfiles]` (`home/config/work` the generic agent root, `home/src` files of `~/src/...` roots) |
| `templates/` | Tera templates, rendered into place |
| `externals.toml` | downloads with sha256, fetched by `mise/scripts/fetch-externals` |
| `secrets/` | age blobs: Comic Code fonts |

[Renovate](renovate.json) keeps the tools in `mise/config*.toml` and the downloads in `externals.toml` up to date; the `validate` workflow fixes the checksums on its branches.

###### Licenses

[MIT][mit] for everything except the files under [secrets/fonts](./secrets/fonts).

The encrypted font files in `secrets/fonts` are [Comic Code][comic] by Toshi Omagari and they need to be purchased to be used, this is why they are encrypted.

[comic]: https://tosche.net/fonts/comic-code
[age]: https://age-encryption.org
[fnox]: https://fnox.jdx.dev
[mit]: ./LICENSE
[mise]: https://mise.jdx.dev
[bootstrap]: https://mise.jdx.dev/bootstrap.html
[tera]: https://mise.jdx.dev/templates.html
