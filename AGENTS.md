# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Copilot, Cursor…) working in this repository.

## What this repo is

Personal dotfiles for [@artberri](https://github.com/artberri), used on **macOS and Linux** machines. It holds configuration files plus the scripts that install them into `$HOME`. It is the successor of the archived [artberri/devenv](https://github.com/artberri/devenv) (Ansible, Ubuntu-only), so don't reintroduce Ansible unless asked.

When a task requires choosing a structure or a new tool, propose the options with trade-offs and ask before committing to one. Once decided, document it in this file.

## Decisions

- **Install tooling: our own symlink script** (`./install` at the repo root). No GNU Stow, chezmoi, Ansible or other dotfile managers. The script:
  - symlinks repo files into `$HOME` (edits in the repo are live);
  - must only need what ships with a stock macOS or Linux install (Bash 3.2-compatible, POSIX utilities);
  - handles OS differences itself (see below);
  - moves any existing target it replaces to `~/.dotfiles-backup/<timestamp>/<path relative to $HOME>` (never next to the original, where tools reading a whole folder would pick it up), and is safe to re-run.
- **Repo layout: one folder per tool.** A top-level folder is a tool when it contains a `links` file:

  ```text
  bash/
    links          # what to symlink, one entry per line
    packages       # optional, what to install, one package per line
    extend.bashrc  # config files, named without the leading dot
    setup          # optional, executable, idempotent hook run after linking
  ```

  `links` format (whitespace-separated, `#` comments, paths without spaces):

  ```text
  <source relative to the tool folder>  <target relative to $HOME>  [macos|linux]
  ```

  `packages` format (`#` comments):

  ```text
  <brew name>  [apt=<name>|apt=-]  [cmd=<command>]
  ```

  `apt=` sets the apt name when it differs (`-` = not in apt). `cmd=` skips the package if that command is already on PATH, however it was installed.

  The optional third column of `links` restricts an entry to one OS. `setup` hooks get `DOTFILES_DIR` and `DOTFILES_OS` (`macos`/`linux`) in the environment. Hooks may change system state (install packages, `chsh`), so never run them while testing unless the user asks; use `./install --no-setup` or `--dry-run`.
- **Machine-owned rc files are never symlinked.** `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig` and `~/.ssh/config` stay regular files on each machine, because tool installers write to them and those changes must not dirty this repo. Shared config lives in files they load: `~/.extend.bashrc` (sourced from `~/.bashrc`, a line added by `bash/setup`) and `~/.config/git/config` (read by git alongside `~/.gitconfig`, which wins). `~/.ssh/config` includes `~/.ssh/dotfiles.conf` at its **end** (ssh uses the first value it finds, so shared defaults must come last; host entries never go in the repo). Hand-written machine-specific shell config goes in `~/.bashrc.local`, which `extend.bashrc` sources last. Follow the same pattern for new tools: link a file the tool *includes*, not the file installers edit.
- **Packages: Homebrew on macOS, apt on Debian/Ubuntu.** No Homebrew on Linux. Other distros get a warning listing what to install by hand, and the rest of the install still runs. Homebrew names may be formulae or casks (e.g. `ghostty`). `./install` installs all tools' missing packages in one batch before linking (skip with `--no-packages`), and only runs `apt-get update` when the index is over a day old. When a package isn't in a release's apt (e.g. starship on Ubuntu 24.04), the tool's `setup` hook may fall back to the project's official installer into `~/.local/bin`, without sudo. Configs must keep working when an optional package is missing (see "Check that a command exists" below).
- **Shell: bash everywhere**, including macOS. `bash/packages` installs Homebrew's `bash` and `bash-completion@2` on macOS; `bash/setup` registers it in `/etc/shells` and makes it the login shell. `bash/extend.bashrc` must still load without errors under `/bin/bash` 3.2 (guard bash 4+ features).
- **License:** [0BSD](LICENSE).

## Hard rules

1. **This repository is public.** Never commit secrets, tokens, API keys, SSH/GPG private keys, passwords, internal hostnames, work-related identifiers or any personal data beyond what's already public (name, GitHub handle). Use placeholders; real values belong in machine-owned files (`~/.bashrc.local`, `~/.gitconfig`). If you spot a secret in a file or diff, stop and flag it.
2. **Never touch the real `$HOME` without explicit permission.** Don't run install/bootstrap scripts, create symlinks or overwrite files outside this repo unless the user asks for it. Test against a temporary `HOME` instead (e.g. `HOME="$(mktemp -d)" ./install --dry-run`). Package installs and setup hooks change the real system even with a temporary `HOME`; test those in a throwaway container (e.g. `docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 …`) as a non-root user with sudo.
3. **Never overwrite existing user files silently.** Install scripts must back up (or skip and warn about) any pre-existing file before replacing it.
4. **Keep it idempotent.** Running any install script twice must produce the same result and no errors.

## Cross-platform conventions

- Everything must work on **both macOS and Linux** unless it lives in an OS-specific location or is guarded by an OS check:

  ```bash
  case "$(uname -s)" in
    Darwin) ... ;;
    Linux)  ... ;;
  esac
  ```

- Mind GNU vs BSD differences (`sed -i`, `readlink -f`, `date`, `stat`, `find`, `grep -P`). Prefer portable flags or detect the variant.
- macOS ships Bash 3.2 at `/bin/bash`. Scripts should either stay compatible with it or explicitly require a newer shell and say so.
- Check that a command exists (`command -v foo >/dev/null 2>&1`) before configuring or calling it; a missing optional tool must not break shell startup.
- Respect XDG paths (`${XDG_CONFIG_HOME:-$HOME/.config}`) where the tool supports them.

## Shell scripts

- Start with a shebang (`#!/usr/bin/env bash` or `#!/bin/sh`) and `set -euo pipefail` for Bash scripts.
- Quote variables, use `"$HOME"` rather than `~` inside scripts, and never hard-code `/Users/<name>` or `/home/<name>`.
- Lint with [ShellCheck](https://www.shellcheck.net/) and format with [shfmt](https://github.com/mvdan/sh) when available.
- Keep shell startup fast: avoid slow commands (network calls, `brew --prefix` in loops, heavy `eval`s) in rc files; cache where possible.

## Config files

- Add a short comment explaining anything non-obvious (why a setting exists, not what it does).
- Machine- or secret-specific values belong in the machine-owned files, never in the repo.
- Don't add configs for tools the user didn't ask for.

## Workflow

- Keep changes small and focused; one topic per commit.
- Update `README.md` when installation steps, requirements or layout change, and update this file when a convention is decided.
- Before committing, review the diff for secrets and absolute personal paths.
