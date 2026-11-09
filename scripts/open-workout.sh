#!/usr/bin/env bash
# Opens a workout directory in the user's editor.
# Usage: open-workout.sh <workout dir>
set -euo pipefail

# Editors that can open a directory; the rest start with an empty buffer in the right cwd.
dir_editors="vi vim nvim nvi hx helix emacs"
plain_editors="nano micro ed editor sensible-editor kak kakoune"

usage() {
	cat <<'EOF'
usage: open-workout.sh <workout dir>

Opens the workout directory in WORKOUT_PROGRAMMING_EDITOR. When it is unset or
empty, nothing is opened.

GUI editors are launched. Terminal editors are never launched; the command to
run in your own shell is printed instead.
EOF
}

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

case ${1:-} in
-h | --help)
	usage
	exit 0
	;;
"")
	usage >&2
	exit 2
	;;
esac

dir=$1
[ $# -eq 1 ] || die "too many arguments: $*"
[ -d "$dir" ] || die "workout directory not found: $dir"
dir=$(cd "$dir" && pwd)

editor=${WORKOUT_PROGRAMMING_EDITOR:-}
if [ -z "$editor" ]; then
	printf 'note: WORKOUT_PROGRAMMING_EDITOR is unset, not opening an editor; open %s yourself\n' "$dir"
	exit 0
fi

read -r -a editor_cmd <<<"$editor"
editor_name=${editor_cmd[0]##*/}

if ! command -v "${editor_cmd[0]}" >/dev/null 2>&1; then
	printf 'note: editor not found: %s, open %s yourself\n' "${editor_cmd[0]}" "$dir"
	exit 0
fi

is_terminal=0
for name in $dir_editors $plain_editors; do
	[ "$editor_name" = "$name" ] && is_terminal=1
done

if [ $is_terminal -eq 1 ]; then
	printf 'terminal editor: run this in your own shell\n'
	for name in $plain_editors; do
		if [ "$editor_name" = "$name" ]; then
			printf '  cd %q && %s\n' "$dir" "$editor"
			exit 0
		fi
	done
	printf '  cd %q && %s .\n' "$dir" "$editor"
	exit 0
fi

"${editor_cmd[@]}" "$dir" </dev/null >/dev/null 2>&1 ||
	die "failed to open $dir with $editor_name"
printf 'opened %s with %s\n' "$dir" "$editor_name"
