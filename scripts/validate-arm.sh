#!/usr/bin/env bash
# AArch64 assembly workout validator. Usage: validate-arm.sh [workout_dir] [sources...]
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
	sources=(*.s)
	shopt -u nullglob
fi

asm_sources=()
for src in "${sources[@]}"; do
	[ -n "$src" ] && asm_sources+=("$src")
done
sources=("${asm_sources[@]}")

if [ ${#sources[@]} -eq 0 ]; then
	printf 'FAIL  no .s source files found\n'
	exit 1
fi

host_arch=$(uname -m)

as_kind=
if command -v aarch64-linux-gnu-as >/dev/null 2>&1; then
	as_kind=cross
elif command -v clang >/dev/null 2>&1; then
	as_kind=clang
else
	printf 'FAIL  no AArch64 assembler: install binutils-aarch64-linux-gnu or clang\n'
	exit 1
fi

link_kind=
linker=
if command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
	link_kind=cross
	linker=$(command -v aarch64-linux-gnu-ld)
else
	linker=$(command -v ld.lld 2>/dev/null || true)
	if [ -z "$linker" ]; then
		for candidate in /usr/lib/llvm*/bin/ld.lld /usr/lib64/llvm*/bin/ld.lld /usr/lib64/rocm/llvm/bin/ld.lld; do
			if [ -x "$candidate" ]; then
				linker=$candidate
				break
			fi
		done
	fi
	if [ -n "$linker" ]; then
		link_kind=lld
	elif command -v clang >/dev/null 2>&1; then
		link_kind=clang
	fi
fi

if [ -z "$link_kind" ]; then
	printf 'FAIL  no AArch64 linker: install lld (Fedora: sudo dnf install lld) or binutils-aarch64-linux-gnu\n'
	exit 1
fi

if [ "$host_arch" = aarch64 ] || [ "$host_arch" = arm64 ]; then
	runner_kind=native
elif command -v qemu-aarch64 >/dev/null 2>&1; then
	runner_kind=qemu
else
	runner_kind=none
fi

printf '== toolchain ==\n'
printf 'host: %s\n' "$host_arch"
if [ "$as_kind" = cross ]; then
	printf 'assembler: aarch64-linux-gnu-as\n'
else
	printf 'assembler: clang --target=aarch64-linux-gnu\n'
fi
case $link_kind in
cross) printf 'linker: %s\n' "$linker" ;;
lld) printf 'linker: %s\n' "$linker" ;;
clang) printf 'linker: clang --target=aarch64-linux-gnu -fuse-ld=lld\n' ;;
esac
printf 'runner: %s\n' "$runner_kind"

printf '\n== assemble ==\n'
printf 'sources: %s\n' "${sources[*]}"
objects=()
for src in "${sources[@]}"; do
	obj=${src%.*}.o
	if [ "$as_kind" = cross ]; then
		aarch64-linux-gnu-as -g -o "$obj" "$src"
		code=$?
	else
		clang --target=aarch64-linux-gnu -g -c -o "$obj" "$src"
		code=$?
	fi
	if [ "$code" -eq 0 ]; then
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
case $link_kind in
cross | lld)
	"$linker" --entry=_start -o "$binary" "${objects[@]}"
	code=$?
	;;
clang)
	clang --target=aarch64-linux-gnu -fuse-ld=lld -nostdlib -static -Wl,--entry=_start -o "$binary" "${objects[@]}"
	code=$?
	;;
esac

if [ "$code" -eq 0 ]; then
	pass 'link'
else
	fail 'link'
	printf '\n== summary ==\n'
	printf 'link failed, skipping run\n'
	exit "$status"
fi

printf '\n== run ==\n'
case $runner_kind in
native)
	timeout "$run_timeout" "./$binary"
	code=$?
	;;
qemu)
	timeout "$run_timeout" qemu-aarch64 "./$binary"
	code=$?
	;;
none)
	code=skip
	warn 'no AArch64 runner: install qemu-user for qemu-aarch64'
	;;
esac

if [ "$code" != skip ]; then
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
