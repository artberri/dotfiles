# artberri/dotfiles

My personal configuration files ([@artberri](https://github.com/artberri)), shared across the machines I use, both **macOS** and **Linux**.

> [!NOTE]
> This repository is a work in progress. It replaces my previous, now archived, Ansible-based setup: [artberri/devenv](https://github.com/artberri/devenv).

## Goals

- **One source of truth** for shell, editor, terminal and tool configuration.
- **Cross-platform**: the same repo works on macOS and Linux, with OS-specific bits kept clearly separated.
- **Simple to bootstrap**: a fresh machine should be one clone and one command away from feeling like home.
- **Idempotent**: running the install again is always safe and only applies what changed.
- **Safe to publish**: this repo is public, so no secrets, tokens or machine-specific private data live here. Those stay in each machine's own files (`~/.bashrc.local`, `~/.gitconfig`).

## Installation

Requirements: `git`, and on macOS [Homebrew](https://brew.sh).

```bash
git clone https://github.com/artberri/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

`install` is a small, dependency-free Bash script that symlinks the files in this repo into `$HOME`. Because they are symlinks, editing a config in the repo takes effect immediately. Existing files are moved to `<file>.backup.<timestamp>` before being replaced, and re-running it is safe.

```bash
./install              # all tools
./install bash         # only some tools
./install --dry-run    # show what would change
./install --no-setup   # only create links, skip setup hooks
```

### Bash everywhere

Bash is the shell on every machine, macOS included. `./install bash` links the shared config to `~/.extend.bashrc` and adds a line to `~/.bashrc` that loads it. On macOS it also installs an up-to-date bash and bash-completion with Homebrew (the system `/bin/bash` is stuck at 3.2), adds it to `/etc/shells` and makes it your login shell. It asks for your password for `sudo` and `chsh`.

## Layout

One folder per tool. Each folder has a `links` file listing what to symlink where, and optionally a `setup` script for anything that isn't a file (installing packages, changing the shell…).

```text
bash/
  links          # "<source> <target relative to $HOME> [macos|linux]" per line
  extend.bashrc
  setup          # optional
git/
  ...
install
```

## Updating

```bash
cd ~/.dotfiles
git pull
./install
```

## Machine-specific config

Some files belong to each machine and are **never** symlinked: `~/.bashrc`, `~/.bash_profile` and `~/.gitconfig`. Tool installers (nvm, bun, gcloud, `gh auth setup-git`…) love to append to them, and those changes shouldn't end up as noise in this repo. Anything personal, secret or specific to one machine goes there too.

The shared config is loaded alongside them instead:

| Shared (this repo) | Machine-owned | How it's loaded |
|---|---|---|
| `~/.extend.bashrc` | `~/.bashrc` | `./install bash` appends a line to `~/.bashrc` that sources it |
| `~/.config/git/config` | `~/.gitconfig` | Git reads both; `~/.gitconfig` wins |

Your own hand-written, machine-specific shell config (aliases, work shortcuts, completions) goes in **`~/.bashrc.local`**. `~/.extend.bashrc` loads it at the end, so it can override anything shared. It is never committed, and unlike `~/.bashrc` no installer writes to it.

For example, a `~/.gitconfig` that sets a different email per directory:

```gitconfig
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig.work
[includeIf "gitdir:~/personal/"]
	path = ~/.gitconfig.personal
```

## Inspiration and resources

- [dotfiles.github.io](https://dotfiles.github.io/) and its [inspiration](https://dotfiles.github.io/inspiration/) list
- [webpro/awesome-dotfiles](https://github.com/webpro/awesome-dotfiles)
- [artberri/devenv](https://github.com/artberri/devenv), my previous setup

## License

[0BSD](LICENSE). Take anything you find useful, no attribution required.
