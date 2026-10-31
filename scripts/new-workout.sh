#!/usr/bin/env bash
# Creates a workout directory with its scaffold.
# Usage: new-workout.sh [--dir DIR] [--base DIR] [language] [topic]
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
skill_dir=$(dirname "$script_dir")

module_name=workout
default_topic=workout
language=go
topic=$default_topic
level=TODO
explicit_dir=
base=$HOME/workouts

usage() {
	cat <<'EOF'
usage: new-workout.sh [--dir DIR] [--base DIR] [--level LEVEL] [language] [topic]

  language      go (default), c, asm/x86, or asm/arm
  topic         short topic slug for the directory name (default: workout)
  --dir DIR     exact workout directory to create instead of
                <base>/<language>/<topic>-<YYYYMMDD-HHMM>
  --base DIR    base directory (default: ~/workouts)
  --level LEVEL easy, medium, or hard, written to TASK.md

Prints the absolute workout directory on the last line. Never writes into an
existing directory. TASK.md is a scaffold with TODO markers for the coach to
fill in, and testdata/ is created empty.
EOF
}

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

language_id() {
	case $1 in
	asm/x86 | asm/x86-64) printf 'x86' ;;
	asm/arm | asm/aarch64) printf 'arm' ;;
	*) printf '%s' "$1" ;;
	esac
}

while [ $# -gt 0 ]; do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	-d | --dir)
		[ $# -ge 2 ] || die "missing value for $1"
		[ -n "$2" ] || die "empty value for $1"
		explicit_dir=$2
		shift 2
		;;
	-b | --base)
		[ $# -ge 2 ] || die "missing value for $1"
		[ -n "$2" ] || die "empty value for $1"
		base=$2
		shift 2
		;;
	-l | --level)
		[ $# -ge 2 ] || die "missing value for $1"
		case $2 in
		easy | medium | hard) level=$2 ;;
		*) die "unsupported level: $2 (expected easy, medium, or hard)" ;;
		esac
		shift 2
		;;
	-*)
		printf 'error: unknown option: %s\n\n' "$1" >&2
		usage >&2
		exit 2
		;;
	*)
		break
		;;
	esac
done

if [ $# -ge 2 ]; then
	case $(language_id "$1") in
	go | c | x86 | arm) ;;
	*) die "unsupported language: $1 (expected go, c, asm/x86, or asm/arm)" ;;
	esac
fi

case ${1:-} in
asm) die "unsupported language: asm (use asm/x86 or asm/arm)" ;;
go | c | x86 | arm | asm/x86 | asm/x86-64 | asm/arm | asm/aarch64)
	language=$(language_id "$1")
	shift
	;;
esac

if [ $# -gt 0 ]; then
	topic=$1
	shift
fi

[ $# -eq 0 ] || die "too many arguments: $*"

case $language in
go | c | x86 | arm) ;;
*) die "unsupported language: $language (expected go, c, asm/x86, or asm/arm)" ;;
esac

slug=$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')
[ -n "$slug" ] || slug=$default_topic

base=${base/#\~/$HOME}
explicit_dir=${explicit_dir/#\~/$HOME}

if [ -n "$explicit_dir" ]; then
	workout_dir=$explicit_dir
else
	workout_dir=$base/$language/$slug-$(date +%Y%m%d-%H%M)
fi

if [ -e "$workout_dir" ]; then
	die "workout directory already exists: $workout_dir"
fi

mkdir -p "$(dirname "$workout_dir")"
mkdir "$workout_dir"

created=()

case $language in
go)
	cat >"$workout_dir/main.go" <<'EOF'
package main

func main() {
}
EOF
	created+=(main.go)

	if [ ! -f "$skill_dir/assets/Makefile" ]; then
		die "missing asset: $skill_dir/assets/Makefile"
	fi
	cp "$skill_dir/assets/Makefile" "$workout_dir/Makefile"
	created+=(Makefile)

	if command -v go >/dev/null 2>&1; then
		if ! output=$(cd "$workout_dir" && go mod init "$module_name" 2>&1); then
			printf '%s\n' "$output" >&2
			die "go mod init failed in $workout_dir"
		fi
		created+=(go.mod)
	else
		printf 'note: go not found, skipped go mod init\n' >&2
	fi
	entry_file=main.go
	;;
c)
	cat >"$workout_dir/main.c" <<'EOF'
#include <stdio.h>

int main(void) {
    return 0;
}
EOF
	created+=(main.c)
	entry_file=main.c

	if ! command -v cc >/dev/null 2>&1; then
		printf 'note: cc not found, the validator needs it\n' >&2
	fi
	;;
x86)
	cat >"$workout_dir/main.s" <<'EOF'
    .section .text
    .global _start

_start:
    # Scaffold stub: exits with status 1 so validation fails until the task is done.
    mov $1, %edi
    mov $60, %eax
    syscall

    .section .note.GNU-stack,"",@progbits
EOF
	created+=(main.s)
	entry_file=main.s

	if ! command -v as >/dev/null 2>&1 || ! command -v ld >/dev/null 2>&1; then
		printf 'note: as and ld not found, the validator needs binutils\n' >&2
	fi
	;;
arm)
	cat >"$workout_dir/main.s" <<'EOF'
    .section .text
    .global _start

_start:
    // Scaffold stub: exits with status 1 so validation fails until the task is done.
    mov x0, #1
    mov x8, #93
    svc #0

    .section .note.GNU-stack,"",@progbits
EOF
	created+=(main.s)
	entry_file=main.s

	if ! command -v aarch64-linux-gnu-as >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
		printf 'note: no AArch64 assembler found, install binutils-aarch64-linux-gnu or clang\n' >&2
	fi
	if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1 && ! command -v ld.lld >/dev/null 2>&1 && ! compgen -G '/usr/lib/llvm*/bin/ld.lld' >/dev/null && ! compgen -G '/usr/lib64/llvm*/bin/ld.lld' >/dev/null && ! compgen -G '/usr/lib64/rocm/llvm/bin/ld.lld' >/dev/null && ! command -v clang >/dev/null 2>&1; then
		printf 'note: no AArch64 linker on PATH, install lld or binutils-aarch64-linux-gnu\n' >&2
	fi
	if [ "$(uname -m)" != aarch64 ] && ! command -v qemu-aarch64 >/dev/null 2>&1; then
		printf 'note: qemu-aarch64 not found, the validator can build but not run the binary\n' >&2
	fi
	;;
esac

workout_dir=$(cd "$workout_dir" && pwd)

mkdir "$workout_dir/testdata"
created+=(testdata/)

case $language in
go)
	language_name=Go
	test_file=main_test.go
	make_targets='make test, make run'
	;;
c)
	language_name=C
	test_file=none
	make_targets=none
	;;
x86)
	language_name="x86-64 assembly"
	test_file=none
	make_targets=none
	;;
arm)
	language_name="AArch64 assembly"
	test_file=none
	make_targets=none
	;;
esac

cat >"$workout_dir/TASK.md" <<'EOF'
# Workout task

- Language: __LANGUAGE__
- Level: __LEVEL__
- Workout dir: __WORKOUT_DIR__
- Entry file: __ENTRY_FILE__
- Task files: TODO
- Starting point: TODO
- Test file: __TEST_FILE__
- Test assets: TODO
- Make targets: __MAKE_TARGETS__

## Objective

TODO

## Signature

`TODO`

## Examples

- `TODO` returns `TODO`

## Docs

- TODO: TODO

## Constraints

### Behavior

- TODO: TODO

### Errors

- TODO: TODO

### Limits

- Code: at most TODO lines of user code in `__ENTRY_FILE__`
- Dependencies: standard library only

### Tests

- Covered: TODO

## Validation

- `__VALIDATE__ __WORKOUT_DIR__`
EOF

sed -i \
	-e "s|__LANGUAGE__|$language_name|g" \
	-e "s|__LEVEL__|$level|g" \
	-e "s|__WORKOUT_DIR__|$workout_dir|g" \
	-e "s|__ENTRY_FILE__|$entry_file|g" \
	-e "s|__TEST_FILE__|$test_file|g" \
	-e "s|__MAKE_TARGETS__|$make_targets|g" \
	-e "s|__VALIDATE__|$skill_dir/scripts/validate-$language.sh|g" \
	"$workout_dir/TASK.md"
created+=(TASK.md)

printf 'created: %s\n' "${created[*]}"
printf 'entry file: %s\n' "$workout_dir/$entry_file"
printf 'validate: %s/scripts/validate-%s.sh %s\n' "$skill_dir" "$language" "$workout_dir"
printf '%s\n' "$workout_dir"
