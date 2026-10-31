# Programming Workout: Claude Code skill

A language-agnostic coding coach for rebuilding programming fluency. Go is the default track; C, x86-64 assembly, and AArch64 assembly are optional. Go workouts focus on Linux systems work: files, descriptors, pipes, processes, signals, sockets, and syscalls. Assembly workouts are freestanding, with raw Linux syscalls and no libc.

## Install

Clone into your personal skills directory so `~/.claude/skills/workout-programming/SKILL.md` exists:

```sh
mkdir -p ~/.claude/skills
git clone git@github.com:patrostkowski/workout-programming.git \
  ~/.claude/skills/workout-programming
```

The repo is private, so the machine needs SSH access to the account. Move any existing `workout-programming` folder aside first; `git clone` refuses a non-empty directory. Start a new session afterwards.

To use a terminal editor such as nvim, export it in your shell profile before starting Claude Code:

```sh
export WORKOUT_PROGRAMMING_EDITOR=nvim
```

Update with:

```sh
git -C ~/.claude/skills/workout-programming pull
```

## Use

```text
/workout-programming
/workout-programming medium slices
/workout-programming go
/workout-programming c pointers
/workout-programming asm/x86 loops
/workout-programming asm/arm syscalls medium
```

It asks for language (`Go` default, `C`, `asm/x86`, or `asm/arm`), level, and topic unless you pass them. Topic options are `Random` plus the areas declared in the language's topic file.

- **easy:** one small function, at most 20 lines
- **medium:** one problem, at most 100 lines, several constructs and some standard library
- **hard:** a small multi-file program

It then creates `~/workouts/<language>/<dir>/` via `scripts/new-workout.sh`: `TASK.md`, `testdata/` fixtures, a `Makefile` for Go and both assembly tracks, and for Go a module plus a small table-driven test. Assembly tracks start from `main.s`; there, `make run` builds and runs the program and prints its exit status, and `make test` runs the validator. It opens the directory in your editor when one is available.

Submit your code and it points at the smallest issue without giving the solution. Ask for `hint`, `next`, `harder`, `easier`, `skip`, or `show solution` at any time. Say `done` to finish, or `ready to grade` for a `GRADE.md` with a 0 to 10 score and a reference implementation.

Resume later with `/workout-programming resume ~/workouts/<language>/<dir>`; `TASK.md` holds the exercise.

## Editor

Setup opens the workout directory in `WORKOUT_PROGRAMMING_EDITOR`, then `$VISUAL`/`$EDITOR`, then the first of `code`, `code-insiders`, `codium`, `cursor`, `zed`, `subl` on `PATH`. GUI editors open directly. Terminal editors such as `nvim` cannot run inside a Claude Code session, so the skill prints the command instead:

```sh
cd ~/workouts/go/slices-20261025-1930 && nvim .
```

Run it in your own shell, save the files, and tell the coach to review. To pin an editor, export `WORKOUT_PROGRAMMING_EDITOR` in your shell profile as shown in Install.

## Validation

`scripts/` holds the validators, which are never copied into workout directories:

```sh
"$CLAUDE_SKILL_DIR/scripts/validate-go.sh" ~/workouts/go/<dir>
"$CLAUDE_SKILL_DIR/scripts/validate-c.sh" ~/workouts/c/<dir>
"$CLAUDE_SKILL_DIR/scripts/validate-x86.sh" ~/workouts/x86/<dir>
"$CLAUDE_SKILL_DIR/scripts/validate-arm.sh" ~/workouts/arm/<dir>
```

The directory defaults to the current one. Go runs `gofmt`, `go vet`, `go test`, `go run`, and `staticcheck` when installed. C builds with `cc -std=c17 -Wall -Wextra -Wpedantic`, runs the binary, and repeats with ASan/UBSan. x86-64 assembles with `as --64`, links with `ld` or a C harness, and checks the exit status; `EXPECT_EXIT=42` checks a non-zero result. AArch64 auto-detects a cross assembler or `clang`, a cross linker or `lld`, and `qemu-aarch64` on non-AArch64 hosts. Output ends in a `PASS`/`FAIL`/`WARN`/`NOTE` summary.

## Contents

- `SKILL.md`: shared flow, levels, coaching, hints, wrap-up
- `references/<language>.md`: per-language setup, scope, validation, concept map
- `references/topics/<language>.md`: areas and cumulative topics per level
- `scripts/new-workout.sh`: workout scaffold
- `assets/<language>/Makefile`: convenience Makefile copied into Go and assembly workouts
- `scripts/open-workout.sh`: opens the workout directory in the user's editor
- `scripts/validate-go.sh`, `scripts/validate-c.sh`, `scripts/validate-x86.sh`, `scripts/validate-arm.sh`: validators
