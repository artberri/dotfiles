# Personal instructions

Standing preferences for every project. A project's own CLAUDE.md or
AGENTS.md wins where they disagree.

## Working with me

- Before choosing a structure, tool or approach that's hard to change later,
  propose the options with trade-offs and a recommendation, and ask.
- Don't commit, push or force-push unless I ask in this session. Never
  rewrite pushed history without asking.
- Don't touch my real home folder or system settings to test something: use
  a temporary `HOME`, a dry run, or a throwaway container. Ask first if the
  real system is the only way.

## Code style

- Indent with tabs, except where a format requires spaces (YAML) or the
  project says otherwise.
- Shell scripts: Bash that also runs on macOS's `/bin/bash` 3.2 unless the
  project says otherwise, `set -euo pipefail`, quoted variables, clean under
  ShellCheck and shfmt.
- Anything for my machines must work on macOS and Debian/Ubuntu (mind GNU vs
  BSD differences in `sed -i`, `readlink`, `date`, `stat`, `find`).

## Git

- Commits are GPG-signed. If signing fails, stop and tell me: never use
  `--no-gpg-sign` or turn signing off to get a commit through.
- Never commit with `-q`/`--quiet`: it hides git's warnings, like a guessed
  author identity.
- Before committing in a repo, check `git config user.email` is the identity
  that repo should use.
- Small, focused commits: one topic each.

## Public repositories

- Never commit secrets, tokens, private keys, internal hostnames, work-related
  identifiers, or personal data beyond my name and GitHub handle. Check the
  diff for these and for absolute paths with my username before committing.
