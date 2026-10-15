#!/usr/bin/env bash
#
# Run ./install twice and fail if:
# - either run fails,
# - the second run changes anything (install must be idempotent), or
# - the shell config prints errors when loaded by any bash on the system,
# - `dot doctor` reports problems right after installing, or
# - `./install --unlink` leaves links into the repo behind.
#
# Changes the real system and $HOME: only run it on a throwaway machine
# (CI runner, container).

set -euo pipefail

cd "$(dirname "$0")/.."

echo "::group::First run"
./install "$@"
echo "::endgroup::"

echo "::group::Second run"
second="$(./install "$@" 2>&1)"
printf '%s\n' "$second"
echo "::endgroup::"

# Lines install and the setup hooks print only when they change something
changes="$(printf '%s\n' "$second" |
	grep -E '^  (link|backup|install|Adding|Creating|Installing|Linking|Changing|brew install) ' || true)"
if [ -n "$changes" ]; then
	echo "::error::Second run changed something:"
	printf '%s\n' "$changes"
	exit 1
fi

# Interactive login shells, as a terminal would start them. Noise about job
# control is expected without a TTY.
shells="/bin/bash"
if [ "$(command -v bash)" != /bin/bash ]; then
	shells="$shells $(command -v bash)"
fi
status=0
for shell in $shells; do
	errors="$("$shell" -lic true 2>&1 >/dev/null |
		grep -vE 'job control|terminal process group|setpgid|Inappropriate ioctl' || true)"
	if [ -n "$errors" ]; then
		echo "::error::$shell printed errors while loading the shell config:"
		printf '%s\n' "$errors"
		status=1
	else
		echo "$shell ($("$shell" -c 'echo $BASH_VERSION')) loads the shell config cleanly"
	fi
done

# A new machine sets up its git identity after installing (README "New
# machine"); do the same with a throwaway one so doctor can check the rest.
if [ -z "$(git config user.email)" ]; then
	git config --file "$HOME/.gitconfig" user.email ci@example.invalid
fi

echo "::group::dot doctor"
if ! dot/dot doctor; then
	echo "::error::dot doctor reported problems right after installing"
	status=1
fi
echo "::endgroup::"

echo "::group::Unlink"
./install --unlink
left="$(find "$HOME" -maxdepth 4 -type l -lname "$PWD/*" 2>/dev/null || true)"
if [ -n "$left" ]; then
	echo "::error::Links into the repo left after --unlink:"
	printf '%s\n' "$left"
	status=1
fi
echo "::endgroup::"

exit "$status"
