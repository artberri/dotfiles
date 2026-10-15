# artberri/dotfiles

[![CI](https://github.com/artberri/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/artberri/dotfiles/actions/workflows/ci.yml)

My personal configuration files ([@artberri](https://github.com/artberri)), shared across the machines I use, both **macOS** and **Linux**.

It replaces my previous, now archived, Ansible-based setup: [artberri/devenv](https://github.com/artberri/devenv).

## Goals

- **One source of truth** for shell, editor, terminal and tool configuration.
- **Cross-platform**: the same repo works on macOS and Linux, with OS-specific bits kept clearly separated.
- **Simple to bootstrap**: a fresh machine should be one clone and one command away from feeling like home.
- **Idempotent**: running the install again is always safe and only applies what changed.
- **Safe to publish**: this repo is public, so no secrets, tokens or machine-specific private data live here. Those stay in each machine's own files (`~/.bashrc.local`, `~/.gitconfig`).

## Installation

Requirements: `git`, and on macOS [Homebrew](https://brew.sh). Linux support targets **Debian and Ubuntu**; other distros get the links and config but must install packages by hand.

```bash
git clone https://github.com/artberri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

`install` is a small, dependency-free Bash script that installs the packages the configs rely on (eza, duf, jq, fzf, zoxide, starship, delta, Ghostty…) and symlinks the files in this repo into `$HOME`. Because they are symlinks, editing a config in the repo takes effect immediately. Existing files are moved to `~/.dotfiles-backup/<timestamp>/` (keeping their path relative to `$HOME`) before being replaced, and re-running it is safe.

```bash
./install              # all tools
./install bash         # only some tools
./install --dry-run    # show what would change
./install --no-packages  # skip installing packages
./install --no-setup   # skip setup hooks
```

### Packages

Packages come from **Homebrew** on macOS and **apt** on Debian/Ubuntu, and only missing ones are installed, so re-running is quick and doesn't ask for `sudo` when there's nothing to do. Some tools only exist in recent releases' apt repositories:

| Package | Debian | Ubuntu |
|---|---|---|
| jq, duf, bash-completion | 12+ | 22.04+ |
| eza, git-delta | 13+ | 24.04+ |
| starship | 13+ | 25.10+ |
| ghostty | — | 26.04+ |

Where apt doesn't have it, starship is installed with its [official installer](https://starship.rs) into `~/.local/bin`. eza and delta are skipped with a warning: the shell config falls back to plain `ls`, but git diffs need delta. Ghostty is skipped with a pointer to [its Linux install options](https://ghostty.org/docs/install/binary#linux) (community builds aren't installed automatically); its config is linked anyway and applies once it's installed.

### Ghostty

[Ghostty](https://ghostty.org) is the terminal on every machine. `./install ghostty` installs it (Homebrew cask on macOS, apt on Ubuntu 26.04+), links its config and theme into `~/.config/ghostty/`, and installs FiraCode Nerd Font if no installed font provides it (Homebrew cask on macOS, the official [Nerd Fonts](https://www.nerdfonts.com) release into `~/.local/share/fonts` on Linux).

On macOS, `~/Library/Application Support/com.mitchellh.ghostty/config` is loaded after the shared config, so it can hold per-machine overrides.

### Bash everywhere

Bash is the shell on every machine, macOS included. `./install bash` links the shared config to `~/.extend.bashrc` and adds a line to `~/.bashrc` that loads it. On macOS it also makes Homebrew's up-to-date bash your login shell (the system `/bin/bash` is stuck at 3.2) and adds it to `/etc/shells`. It asks for your password for `sudo` and `chsh`.

## Layout

One folder per tool. Each folder has a `links` file listing what to symlink where and/or a `packages` file listing what it needs installed, plus optionally a `setup` script for anything else (changing the shell…). Tools without config, like `gh` or `ripgrep`, live in `cli/`, which only has `packages`.

```text
bash/
  links          # "<source> <target relative to $HOME> [macos|linux]" per line
  packages       # optional: "<brew name> [apt=<name>|apt=-] [cmd=<command>]" per line
  extend.bashrc
  setup          # optional
git/
  ...
install
```

## Testing

CI runs on every push and weekly: ShellCheck and shfmt, then `./install` **twice** on Ubuntu 24.04/26.04, Debian 12/13, Fedora (the unsupported-distro path) and macOS. It fails if the second run changes anything or if the shell config prints errors in any bash on the system (including macOS's `/bin/bash` 3.2).

To run a Linux check locally (it changes the container, never your machine):

```bash
docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 sh /src/test/container.sh
```

## Updating

```bash
cd ~/.dotfiles
git pull
./install
```

## Machine-specific config

Some files belong to each machine and are **never** symlinked: `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig` and `~/.ssh/config`. Tool installers (nvm, bun, gcloud, `gh auth setup-git`…) love to append to them, and those changes shouldn't end up as noise in this repo. Anything personal, secret or specific to one machine goes there too.

The shared config is loaded alongside them instead:

| Shared (this repo) | Machine-owned | How it's loaded |
|---|---|---|
| `~/.extend.bashrc` | `~/.bashrc` | `./install bash` appends a line to `~/.bashrc` that sources it |
| `~/.config/git/config` | `~/.gitconfig` | Git reads both; `~/.gitconfig` wins |
| `~/.ssh/dotfiles.conf` | `~/.ssh/config` | `./install ssh` appends an `Include` at the end; host entries above it win. Hosts never go in this repo |
| `~/.inputrc` | `~/.inputrc.local` | `~/.inputrc` includes it last |

Your own hand-written, machine-specific shell config (aliases, work shortcuts, completions) goes in **`~/.bashrc.local`**. `~/.extend.bashrc` loads it at the end, so it can override anything shared. It is never committed, and unlike `~/.bashrc` no installer writes to it.

For example, a `~/.gitconfig` that sets a different identity per directory:

```gitconfig
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig.work
[includeIf "gitdir:~/personal/"]
	path = ~/.gitconfig.personal
# This repo too, or its commits get an address git makes up from the
# hostname (user@host.local), which ends up public on GitHub.
[includeIf "gitdir:~/.dotfiles/"]
	path = ~/.gitconfig.personal
```

### Commit signing on a new machine

Commits are signed with GPG, one key per identity. Signing is switched on in each identity file, not in the shared config, so a machine (or folder) without keys still commits normally.

1. **Get the keys onto the machine.** Find a key's ID with `gpg --list-secret-keys --keyid-format long` (the part after `ed25519/` or `rsa4096/`).
   - *Reuse an existing key*: on the old machine run `gpg --export-secret-keys --armor <KEY_ID> > key.asc`, move the file over something private (AirDrop, a USB stick; not email or a synced folder), then on the new one run `gpg --import key.asc`, mark it as yours with `gpg --edit-key <KEY_ID>` → `trust` → `5` → `quit`, and delete `key.asc` on both.
   - *Or create a new one*: `gpg --full-generate-key` (ECC/ed25519, the email of that identity), then add `gpg --armor --export <KEY_ID>` to GitHub under *Settings → SSH and GPG keys → New GPG key*. The email must be a verified email of that GitHub account, or GitHub shows the commit as *Unverified*.
2. **Run `./install`.** It installs GnuPG and, on macOS, `pinentry-mac`, a passphrase dialog that also works for commits made from editors.
3. **Point each identity at its key** in its identity file (e.g. `~/.gitconfig.personal`):

   ```gitconfig
   [user]
   	email = you@example.com
   	signingkey = <KEY_ID>
   [commit]
   	gpgsign = true
   ```

4. **Check it** in a repo of that identity (this one, for the personal identity):

   ```bash
   git commit --allow-empty -m "Test signing"   # asks for the passphrase
   git log --show-signature -1                  # should say "Good signature"
   git reset --soft HEAD~1                      # drop the test commit
   ```

   On macOS, tick *Save in Keychain* in the passphrase dialog so it doesn't ask again.

Key IDs, emails and identity files never go in this repo.

## Inspiration and resources

- [dotfiles.github.io](https://dotfiles.github.io/) and its [inspiration](https://dotfiles.github.io/inspiration/) list
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [artberri/devenv](https://github.com/artberri/devenv), my previous setup

## License

[0BSD](LICENSE). Take anything you find useful, no attribution required.
