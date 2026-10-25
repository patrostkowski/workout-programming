#!/usr/bin/env bash
# C workout validator. Usage: validate-c.sh [workout_dir] [sources...]
set -u

run_timeout=${RUN_TIMEOUT:-10}
workout_dir=.
binary=main
sanitized_binary=main-asan
cc_flags=(-std=c17 -Wall -Wextra -Wpedantic)
sanitizer_flags=(-fsanitize=address,undefined -g)
status=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
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
	sources=(*.c)
	shopt -u nullglob
fi

if [ ${#sources[@]} -eq 0 ]; then
	printf 'FAIL  no .c source files found\n'
	exit 1
fi

printf '== build ==\n'
printf 'sources: %s\n' "${sources[*]}"
if cc "${cc_flags[@]}" -o "$binary" "${sources[@]}"; then
	pass 'build'
else
	fail 'build'
	printf '\n== summary ==\n'
	printf 'build failed, skipping run and sanitizers\n'
	exit "$status"
fi

printf '\n== run ==\n'
timeout "$run_timeout" "./$binary"
code=$?
if [ "$code" -eq 0 ]; then
	pass 'run'
elif [ "$code" -eq 124 ]; then
	note "run timed out after ${run_timeout}s (expected for servers and blocking programs)"
else
	fail "run: exit status $code"
fi

printf '\n== sanitizers ==\n'
if cc "${cc_flags[@]}" "${sanitizer_flags[@]}" -o "$sanitized_binary" "${sources[@]}"; then
	timeout "$run_timeout" "./$sanitized_binary"
	code=$?
	if [ "$code" -eq 0 ]; then
		pass 'sanitizers'
	elif [ "$code" -eq 124 ]; then
		note "sanitized run timed out after ${run_timeout}s"
	else
		fail "sanitizers: exit status $code"
	fi
else
	note 'sanitizer build failed, toolchain may lack ASan or UBSan support'
fi

printf '\n== summary ==\n'
if [ "$status" -eq 0 ]; then
	printf 'all checks passed\n'
else
	printf 'one or more checks failed\n'
fi
exit "$status"
