#!/usr/bin/env bash
# Go workout validator. Usage: validate-go.sh [workout_dir] [go test flags...]
set -u

run_timeout=${RUN_TIMEOUT:-10}
test_timeout=${TEST_TIMEOUT:-30s}
workout_dir=.
status=0
warnings=0

if [ $# -gt 0 ]; then
	case "$1" in
	-*) ;;
	*)
		if [ ! -d "$1" ]; then
			printf 'error: workout directory not found: %s\n' "$1" >&2
			exit 2
		fi
		workout_dir=$1
		shift
		;;
	esac
fi

printf 'workout: %s\n\n' "$(cd "$workout_dir" && pwd)"
cd "$workout_dir" || exit 1

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; status=1; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
note() { printf 'NOTE  %s\n' "$1"; }

printf '== gofmt ==\n'
unformatted=$(gofmt -l .)
if [ -z "$unformatted" ]; then
	pass 'gofmt'
else
	printf '%s\n' "$unformatted"
	fail 'gofmt: files need formatting'
fi

printf '\n== go vet ==\n'
if go vet ./...; then
	pass 'go vet'
else
	fail 'go vet'
fi

printf '\n== go test ==\n'
if go test -timeout "$test_timeout" "$@" ./...; then
	pass 'go test'
else
	fail 'go test'
fi

printf '\n== go run ==\n'
timeout "$run_timeout" go run .
code=$?
if [ "$code" -eq 0 ]; then
	pass 'go run'
elif [ "$code" -eq 124 ]; then
	note "go run timed out after ${run_timeout}s (expected for servers and blocking programs)"
else
	fail "go run: exit status $code"
fi

if command -v staticcheck >/dev/null 2>&1; then
	printf '\n== staticcheck ==\n'
	out=$(staticcheck ./... 2>&1)
	code=$?
	printf '%s\n' "$out"
	if [ "$code" -eq 0 ]; then
		pass 'staticcheck'
	elif printf '%s' "$out" | grep -qE 'internal error in importing|Staticcheck was built with'; then
		note 'staticcheck is incompatible with this Go toolchain, skipped'
	else
		warn 'staticcheck reported findings (advisory)'
	fi
else
	note 'staticcheck not installed, skipped'
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
