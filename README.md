# artberri/dotfiles

My personal configuration files ([@artberri](https://github.com/artberri)), shared across the machines I use, both **macOS** and **Linux**.

> [!NOTE]
> This repository is a work in progress. It replaces my previous, now archived, Ansible-based setup: [artberri/devenv](https://github.com/artberri/devenv).

## Goals

- **One source of truth** for shell, editor, terminal and tool configuration.
- **Cross-platform**: the same repo works on macOS and Linux, with OS-specific bits kept clearly separated.
- **Simple to bootstrap**: a fresh machine should be one clone and one command away from feeling like home.
- **Idempotent**: running the install again is always safe and only applies what changed.
- **Safe to publish**: this repo is public, so no secrets, tokens or machine-specific private data live here. Those go in local, git-ignored override files.

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

Bash is the shell on every machine, macOS included. On macOS, `./install bash` installs an up-to-date bash and bash-completion with Homebrew (the system `/bin/bash` is stuck at 3.2), adds it to `/etc/shells` and makes it your login shell. It asks for your password for `sudo` and `chsh`.

## Layout

One folder per tool. Each folder has a `links` file listing what to symlink where, and optionally a `setup` script for anything that isn't a file (installing packages, changing the shell…).

```text
bash/
  links          # "<source> <target relative to $HOME> [macos|linux]" per line
  bash_profile
  bashrc
  setup          # optional
install
```

## Updating

```bash
cd ~/.dotfiles
git pull
./install
```

## Local overrides

Anything personal, secret or specific to a single machine (work email for git, API tokens, host aliases…) belongs in local files that are **not** tracked by git, for example:

- `~/.gitconfig.local`
- `~/.bashrc.local` / `~/.zshrc.local`

The tracked configs source these files when they exist. For example, a `~/.gitconfig.local` that sets a different email per directory:

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
