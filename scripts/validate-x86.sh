#!/usr/bin/env bash
# x86-64 assembly workout validator. Usage: validate-x86.sh [workout_dir] [sources...]
set -u

run_timeout=${RUN_TIMEOUT:-10}
expect_exit=${EXPECT_EXIT:-0}
workout_dir=.
binary=main
status=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
note() { printf 'NOTE  %s\n' "$1"; }

if [ $# -gt 0 ] && [ -d "$1" ]; then
	workout_dir=$1
	shift
fi

printf 'workout: %s\n\n' "$(cd "$workout_dir" && pwd)"
cd "$workout_dir" || exit 1

sources=("$@")
if [ ${#sources[@]} -eq 0 ]; then
	shopt -s nullglob
	sources=(*.s *.c)
	shopt -u nullglob
fi

asm_sources=()
c_sources=()
for src in "${sources[@]}"; do
	[ -n "$src" ] || continue
	case $src in
	*.c) c_sources+=("$src") ;;
	*) asm_sources+=("$src") ;;
	esac
done

if [ ${#asm_sources[@]} -eq 0 ]; then
	printf 'FAIL  no .s source files found\n'
	exit 1
fi

printf '== assemble ==\n'
printf 'sources: %s\n' "${asm_sources[*]}"
objects=()
for src in "${asm_sources[@]}"; do
	obj=${src%.*}.o
	if as --64 -g -o "$obj" "$src"; then
		pass "assemble $src"
		objects+=("$obj")
	else
		fail "assemble $src"
	fi
done

if [ "$status" -ne 0 ]; then
	printf '\n== summary ==\n'
	printf 'assembly failed, skipping link and run\n'
	exit "$status"
fi

printf '\n== link ==\n'
if [ ${#c_sources[@]} -gt 0 ]; then
	printf 'sources: %s and %s\n' "${objects[*]}" "${c_sources[*]}"
	if cc -fno-pie -no-pie -Wall -Wextra -Wpedantic -o "$binary" "${objects[@]}" "${c_sources[@]}"; then
		pass 'link with C harness'
	else
		fail 'link with C harness'
		printf '\n== summary ==\n'
		printf 'link failed, skipping run\n'
		exit "$status"
	fi
else
	link_out=$(ld --entry=_start -o "$binary" "${objects[@]}" 2>&1)
	link_code=$?
	printf '%s\n' "$link_out"
	if [ "$link_code" -eq 0 ]; then
		pass 'link'
		if printf '%s' "$link_out" | grep -q 'GNU-stack'; then
			note 'add .section .note.GNU-stack,"",@progbits to the source to clear the executable stack warning'
		fi
	else
		fail 'link'
		printf '\n== summary ==\n'
		printf 'link failed, skipping run\n'
		exit "$status"
	fi
fi

printf '\n== run ==\n'
host_arch=$(uname -m)
runner=()
if [ "$host_arch" = x86_64 ]; then
	runner=()
elif command -v qemu-x86_64 >/dev/null 2>&1; then
	runner=(qemu-x86_64)
else
	runner=skip
	warn "cannot run on $host_arch: install qemu-user for qemu-x86_64"
fi

if [ "${runner:-}" != skip ]; then
	timeout "$run_timeout" "${runner[@]}" "./$binary"
	code=$?
	if [ "$code" -eq 124 ]; then
		note "run timed out after ${run_timeout}s"
	elif [ "$code" -eq "$expect_exit" ]; then
		pass "run: exit status $code"
	else
		fail "run: exit status $code (expected $expect_exit)"
	fi
fi

printf '\n== summary ==\n'
if [ "$status" -ne 0 ]; then
	printf 'one or more required checks failed\n'
elif [ "$warnings" -gt 0 ]; then
	printf 'all required checks passed, %d warning(s)\n' "$warnings"
else
	printf 'all checks passed\n'
fi
exit "$status"
