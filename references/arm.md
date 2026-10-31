# AArch64 assembly workout curriculum

Use GNU assembler syntax for AArch64 (ARM64) Linux. This track is freestanding: no libc, no C runtime, and raw Linux syscalls. Pick the level at session start and keep every exercise inside its scope. Each exercise targets one main idea and optionally one adjacent concept. State the register, memory, and stack contract up front, and never write the instruction sequence for the user.

The host may be AArch64 or x86-64. On x86-64 the validator needs an AArch64 assembler, a linker that supports the target, and `qemu-aarch64` to run the result.

## Setup

Default location: `~/workouts/arm/<topic>-<YYYYMMDD-HHMM>`. The track is invoked as `asm/arm`, which resolves to the `arm` id used by the files, validator, and workout directory.

Create the scaffold with the skill's setup script:

```sh
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" asm/arm <topic>
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" --dir ~/workouts/arm/<slug> asm/arm <topic>
```

It creates the directory, `main.s`, an empty `testdata/`, and a `TASK.md` scaffold, then prints the workout directory. It never writes into an existing directory. Do not create these by hand.

Fallback when the script is unavailable:

```sh
mkdir -p ~/workouts/arm
mkdir ~/workouts/arm/<slug>
```

The validator stays in the skill at `scripts/validate-arm.sh` (default install: `~/.claude/skills/workout-programming/scripts/validate-arm.sh`). Do not copy it into the workout directory.

Start from `main.s`:

```asm
    .section .text
    .global _start

_start:
    // Scaffold stub: exits with status 1 so validation fails until the task is done.
    mov x0, #1
    mov x8, #93
    svc #0

    .section .note.GNU-stack,"",@progbits
```

Use `.global` (`.globl` also works) and the `_start` entry point. Check the toolchain before the first task.

## Toolchain

The validator picks the first available option for each step and prints what it used.

- Assembler: `aarch64-linux-gnu-as`, or `clang --target=aarch64-linux-gnu -c`.
- Linker: `aarch64-linux-gnu-ld`, or `ld.lld` (install the `lld` package), or `clang --target=aarch64-linux-gnu -fuse-ld=lld`.
- Runner: native on `aarch64`/`arm64`, otherwise `qemu-aarch64`.

On Fedora the minimal setup is `sudo dnf install lld qemu-user`, or `sudo dnf install binutils-aarch64-linux-gnu qemu-user` for the GNU cross tools. On Debian and Ubuntu use `lld qemu-user`, or `binutils-aarch64-linux-gnu qemu-user`. Run `uname -m` to confirm whether the host is native.

## Syntax and ABI

AArch64 syntax has no register sigil and no immediate sigil. `//` starts a line comment.

- Registers are 64-bit `x0` to `x30`, with 32-bit `w0` to `w30` views. Writing `wN` zeroes the upper 32 bits of `xN`.
- `x29` is the frame pointer, `x30` is the link register, `sp` is the stack pointer, `xzr` reads as zero, and `x31` means `sp` or `xzr` depending on the instruction.
- Linux syscall: number in `x8`, arguments in `x0` to `x5`, result in `x0`, `svc #0`. A failed syscall returns `-errno` in `x0`.
- AAPCS64 call: arguments in `x0` to `x7`, integer return in `x0`, and `x0`/`x1` for a 128-bit return.
- Callee-saved registers: `x19` to `x28`, plus `x29` and `x30`. The caller may use `x0` to `x18` freely.
- `sp` must stay 16-byte aligned at every instruction that reads or writes memory.
- There is no flags register to read. `cmp` sets condition codes, and `b.cond`, `csel`, and `cset` consume them.

## Test scaffold

The validator checks the program's exit status, so each exercise is a freestanding program that leaves its result in the documented place. There is no C harness on this track; a cross libc and sysroot are not required.

- Every task gets one `_start` and no `.c` file.
- The validator runs the program and compares the exit status with `EXPECT_EXIT`, default `0`.
- When the exercise produces output, ask for it through the `write` syscall and keep it short and deterministic.
- For a task whose result is a number, either print it in decimal or exit with it when it fits in 0 to 255.
- The scaffold stub exits with status 1, so the first validator run fails until the user replaces it.

## Test assets

Fixed inputs live in `testdata/` in the workout directory.

- Create the assets the examples need and list each path with its exact contents in `TASK.md`, for example `testdata/alpha.txt` with `alpha\n` and `testdata/empty.txt` with nothing.
- Keep them tiny and inspectable, and delete stale ones when you assign a new exercise.
- The program takes a path and opens it; do not hardcode fixture contents in the program.
- Skip permission fixtures. A `0000` file is still readable by root, so a permission case cannot be tested reliably.

## Doc links

Give 2 to 4 links per task and list them in `TASK.md` under `## Docs`.

- Instruction or directive: `https://sourceware.org/binutils/docs/as/`.
- Architecture: `https://developer.arm.com/documentation/ddi0487/latest/` for the Arm Architecture Reference Manual.
- Procedure call standard: `https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst`.
- Syscall: `https://man7.org/linux/man-pages/man2/<name>.2.html` for a named call such as `write`.

Offline equivalents to mention in chat: `info as`, `man 2 write`, `aarch64-linux-gnu-objdump -d main` or `llvm-objdump -d main`.

Link only what the task uses. Never fetch a link, and never link tutorials, blogs, Stack Overflow, or generated summaries.

## Code scope

- **Easy:** at most 20 lines of user code in `main.s`, one main construct.
- **Medium:** at most 100 lines of user code, usually in `main.s`, optionally one extra `.s` file.
- **Hard:** a small program spread over multiple files. Name the files and pass them to the validator.

"User code" counts the instruction and data lines the user writes. Directives, the provided stub, and the `.note.GNU-stack` section do not count.

## Validation

Run the skill's validator against the workout directory:

```sh
"$CLAUDE_SKILL_DIR/scripts/validate-arm.sh" ~/workouts/arm/<slug>
EXPECT_EXIT=42 "$CLAUDE_SKILL_DIR/scripts/validate-arm.sh" ~/workouts/arm/<slug>
```

The directory is optional and defaults to the current directory. Remaining arguments are `.s` files; without them every `.s` file is assembled. The script runs, in order:

- The detected assembler for each `.s` file.
- The detected linker into `main`.
- `./main` natively, or through `qemu-aarch64`, with a 10 second timeout. Override it with `RUN_TIMEOUT=30`.
- A comparison of the exit status with `EXPECT_EXIT`, default `0`.

It prints the raw tool output and a summary, and exits non-zero when a required check fails. A missing runner is reported as a `WARN`, and the build result still stands. Report exact tool messages. Do not run the individual commands yourself, and do not copy the script into the workout directory.

## Easy: registers and straight-line code (max 20 lines)

- 64-bit and 32-bit register views, `mov`, `movz`, `movk`
- `add`, `sub`, `neg`, immediate operands
- `and`, `orr`, `eor`, `lsl`, `lsr`, `asr`
- `cmp`, `b.cond`, `cset`
- `cbz`, `cbnz`, and counted loops
- `stp`/`ldp` with `sp`
- `adr`, `adrp`, `ldr`, `str`
- The `exit` syscall with `svc #0` and the `write` syscall

Example themes: exit with the sum of two values; exit with the larger of two values; absolute value with `cmp` and `csel`; set a register from a comparison with `cset`; count down a register with `subs` and `b.ne`; sum an array of bytes; write a fixed string with the `write` syscall; store and reload two values with `stp`/`ldp`.

## Medium: functions, widths, and syscalls (max 100 lines)

- `bl` and `ret`, saving `x30`, nested calls
- AAPCS64 argument and return registers, caller and callee saved rules
- Stack frames with `stp x29, x30` and `ldp x29, x30`, 16-byte alignment
- Local buffers on the stack and their bounds
- Byte and halfword access with `ldrb`, `strb`, `ldrh`, `strh`, `ldrsb`, `ldrsw`
- `mul`, `madd`, `msub`, `sdiv`, `udiv`
- Addressing modes: offset, pre-index, post-index, and register scaled by element size
- `adrp` plus `add :lo12:` for symbol addresses
- `openat`, `read`, `write`, `close`, and error returns in `x0`
- Calling a C function from assembly when a C driver is provided

Example themes: `strlen`; `strcmp`; reverse a buffer in place; count a byte in a buffer; uppercase a buffer; copy a file; exit with the number of lines read; sum an array of 32-bit values; read `argc`/`argv` at `_start` and sum the numeric arguments; print a small number in decimal; call `write` with a stack buffer.

## Hard: small system utilities (multi-file)

- Program structure across `main.s` plus focused files such as `string.s`, `io.s`, or `convert.s`
- `strlen`, `strcmp`, `memcpy`, `memset` written from scratch
- Decimal and hexadecimal conversion with output through `write`
- A small utility such as `cat`, `wc`, or `hexdump`
- Mixed C and assembly, with AAPCS64 respected on both sides
- `brk` or `mmap` for a buffer larger than the stack
- Syscall error handling and exit status propagation

Example themes: `cat` that copies standard input to standard output; `wc -l` over files named in `argv`; `hexdump` of a buffer; `itoa` plus `write` for signed decimal; a C driver calling assembly string routines; a program that reads a file into an `mmap` region and exits with its line count.

## Accuracy and safety checks

- Writing `wN` zeroes the upper 32 bits of `xN`; a 32-bit operation cannot preserve the high half.
- `mov` accepts only a limited immediate; build other constants with `movz` and `movk`, one 16-bit chunk at a time.
- `cmp x0, x1` sets condition codes from `x0 - x1`; `b.eq` branches when they are equal, and `cset x2, eq` materializes the same condition.
- There is no flags register; any instruction between `cmp` and `b.cond` may replace the condition codes. Keep the branch adjacent.
- `bl` overwrites `x30`. Save `x30` in the frame before a nested call, and restore it before `ret`.
- `sp` must remain 16-byte aligned. Move it in multiples of 16, using pre-index `[sp, #-16]!` and post-index `[sp], #16` pairs.
- `stp` and `ldp` move two registers at once; use them for the `x29`/`x30` frame and for paired locals.
- A `_start` has no caller and no return address; it must call `exit` with `svc #0` and never fall through.
- The Linux syscall return is in `x0`; a failure is `-errno`, so test for a negative value, not for `-1` alone.
- Syscall numbers differ from x86-64: `read` is 63, `write` is 64, `openat` is 56, `close` is 57, `exit` is 93, `brk` is 214, `mmap` is 222.
- Use `openat` with `AT_FDCWD` (-100) rather than assuming a legacy `open` number.
- Use `adrp` plus `add :lo12:symbol` for a symbol address; `adr` reaches only nearby labels.
- Add `.note.GNU-stack` to every file so the linker does not mark the stack executable.
- If an easy or medium task grows past its line budget, move the task up a level instead of bending the scope.
