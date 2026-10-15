# shellcheck shell=bash
#
# Shared bash config, linked to ~/.extend.bashrc and loaded from the
# machine's own ~/.bashrc (bash/setup adds that line).

# Guard against being loaded twice (e.g. from both ~/.bashrc and
# ~/.bash_profile). Not exported, so child shells load it again.
[ -n "${_EXTEND_BASHRC_LOADED:-}" ] && return
_EXTEND_BASHRC_LOADED=1

# --- Environment (all shells) ------------------------------------------------

# Prepend a directory to PATH if it exists and isn't already there.
path_prepend() {
	[ -d "$1" ] || return 0
	case ":$PATH:" in
	*":$1:"*) ;;
	*) PATH="$1:$PATH" ;;
	esac
}

if [ "$(uname -s)" = Darwin ]; then
	# Stock /bin/bash nags about zsh being the default shell.
	export BASH_SILENCE_DEPRECATION_WARNING=1

	for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [ -x "$brew" ]; then
			eval "$("$brew" shellenv)"
			break
		fi
	done
	unset brew
fi

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
export PATH

export EDITOR="${EDITOR:-vim}"

# Everything below only applies to interactive shells.
[[ $- == *i* ]] || return

# --- History -----------------------------------------------------------------

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
# Write each command to the history file as soon as it runs, so it survives
# crashes and shows up in other terminals.
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# --- Shell options -----------------------------------------------------------

shopt -s checkwinsize cdspell
# Bash 4+ only; ignored if the stock macOS bash reads this file.
shopt -s autocd globstar checkjobs 2>/dev/null

# --- Completion --------------------------------------------------------------

if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
	. "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [ -r /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
fi

# yarn: complete root scripts, `yarn workspace <name>` and that workspace's
# scripts. Needs jq. Doesn't check for yarn itself: it's often put on PATH
# later (proto, volta, corepack) and a completion for a missing command is
# harmless.
if command -v jq >/dev/null 2>&1; then
	# ':' is a word break by default, which splits script names like engine:dev
	COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}

	_yarn_monorepo_root() {
		local dir=$PWD
		while [[ $dir != / ]]; do
			if [[ -f $dir/package.json ]] && grep -q '"workspaces"' "$dir/package.json"; then
				echo "$dir"
				return
			fi
			dir=$(dirname "$dir")
		done
	}

	# Prints "<workspace name>\t<package.json path>" per workspace
	_yarn_workspaces() {
		local root=$1 pattern manifest
		local -a manifests=()
		while IFS= read -r pattern; do
			for manifest in "$root"/$pattern/package.json; do
				[[ -f $manifest ]] && manifests+=("$manifest")
			done
		done < <(jq -r '.workspaces | if type == "array" then .[] else .packages[] end' "$root/package.json" 2>/dev/null)
		((${#manifests[@]})) && jq -r 'select(.name) | "\(.name)\t\(input_filename)"' "${manifests[@]}" 2>/dev/null
	}

	_yarn_scripts_of() {
		jq -r '.scripts // {} | keys[]' "$1" 2>/dev/null
	}

	_yarn_complete() {
		local cur=${COMP_WORDS[COMP_CWORD]} root words=""
		COMPREPLY=()
		if ((COMP_CWORD == 1)); then
			[[ -f package.json ]] && words="$(_yarn_scripts_of package.json)"
			words+=" workspace"
		elif [[ ${COMP_WORDS[1]} == workspace ]] && ((COMP_CWORD <= 3)); then
			root=$(_yarn_monorepo_root)
			[[ -n $root ]] || return
			if ((COMP_CWORD == 2)); then
				words=$(_yarn_workspaces "$root" | cut -f1)
			else
				local manifest
				manifest=$(_yarn_workspaces "$root" | awk -F'\t' -v name="${COMP_WORDS[2]}" '$1 == name { print $2 }')
				[[ -n $manifest ]] && words=$(_yarn_scripts_of "$manifest")
			fi
		else
			return
		fi
		# shellcheck disable=SC2207
		COMPREPLY=($(compgen -W "$words" -- "$cur"))
	}
	complete -o default -F _yarn_complete yarn
fi

# --- Colors ------------------------------------------------------------------

if command -v dircolors >/dev/null 2>&1; then
	if [ -r "$HOME/.dircolors" ]; then
		eval "$(dircolors -b "$HOME/.dircolors")"
	else
		eval "$(dircolors -b)"
	fi
	alias ls='ls --color=auto'
else
	# BSD ls (macOS)
	export CLICOLOR=1
fi
alias grep='grep --color=auto'

export EZA_COLORS=di=34:bd=33:cd=33:so=31:ex=32:ur=33:uw=31:ux=32:ue=32:uu=33:gu=33:lc=31:df=32:sn=32:nb=32:nk=32:nm=32:ng=32:nt=32

# --- Aliases -----------------------------------------------------------------

if command -v eza >/dev/null 2>&1; then
	alias ll='eza -alF'
else
	alias ll='ls -alF'
fi
command -v duf >/dev/null 2>&1 && alias df='duf'
alias du='du -kh'

# Git. Most of these rely on aliases defined in ~/.gitconfig
# (p, h, ci, co, st, lg), see git/gitconfig.
alias g='git'
alias rebase='git fetch && git rebase origin/master'
alias stash='git stash'
alias unstash='git stash pop 0'
alias gp='g p'
alias gu='g h'
alias guf='g h --force'
alias ga='g add .'
alias gci='g ci -m'
alias gco='g co'
alias gcob='g co -b'
alias gs='g st'
alias gl='g lg -5'

# --- Prompt ------------------------------------------------------------------

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# --- Local overrides ---------------------------------------------------------

# Hand-written, machine-specific config (aliases, work shortcuts…). Never
# committed. Unlike ~/.bashrc, installers don't touch it.
if [ -f "$HOME/.bashrc.local" ]; then . "$HOME/.bashrc.local"; fi
