# Programming Workout: Claude Code skill

A small, language-agnostic coding coach for rebuilding programming fluency. Go is the default track; C is optional. The Go track is systems-focused for Linux: files, file descriptors, permissions, pipes, processes, signals, sockets, and standard-library syscalls.

## Install (personal skill, all projects)

Extract the archive so that this file exists:

`~/.claude/skills/workout-programming/SKILL.md`

Example from a terminal, run in the directory containing `workout-programming.zip`:

```sh
mkdir -p ~/.claude/skills
unzip workout-programming.zip -d ~/.claude/skills
```

If you already have a `workout-programming` skill, back it up before extracting; the archive may overwrite files.

Start a new Claude Code session if the command doesn't appear immediately.

## Use

```text
/workout-programming
/workout-programming medium slices
/workout-programming go
/workout-programming c pointers
```

The flow is the same for every language:

1. Run `/workout-programming`. When you do not pass them in the command, the skill asks three quick questions: language (`Go` default or `C`), level, and topic (`Anything` default, where it picks and rotates). Anything you pass is not asked again.
   - **easy:** at most 20 lines of user code, one small function or snippet; in Go, Go internals alternating with Unix basics
   - **medium:** at most 100 lines, several constructs or standard library calls; in Go, Unix internals with Go as the vehicle (descriptors, pipes, processes, signals, sockets, `/proc`)
   - **hard:** a small program over multiple files; in Go, deeper Unix internals (servers, process supervision, fd passing, epoll, inotify, mmap)
2. The skill creates a fresh workout directory under `~/workouts/<language>/` with a single entry file.
   - Go: `go mod init workout`, `main.go`, and a `Makefile` for `make test` / `make run`
   - C: `main.c`

   The directory and base scaffold come from `scripts/new-workout.sh`, which refuses an existing directory and prints the resulting path. It also creates an empty `testdata/` and a `TASK.md` scaffold with the deterministic fields filled and `TODO` markers the coach replaces with the exercise. Add `--dir` to use a path you name and `--level` to record the level in `TASK.md`.

   Go workouts also get a very small test file, normally `main_test.go`, with a table-driven test of at least 3 cases. The tests cover some cases, not the full scope, and the function stub is added so they compile. Tests for file and socket tasks use temp dirs, loopback ports, or local sockets.
   Both tracks get `testdata/` fixtures for the examples, and `TASK.md` lists each fixture with its contents plus 2 to 4 doc links (`pkg.go.dev`, `go.dev`, `man7.org`).
   Once the scaffold is written, the skill opens the workout directory in VS Code with `code <dir>` when the `code` CLI is available. It never installs the CLI.
3. Submit your code. The skill reads it, runs the validator script against the workout directory, and points at the smallest issue without giving you the solution.
4. Say `stop` or `done` when you are finished. It runs full validation once more, explains the solution, and writes `GRADE.md` with a 0-10 score, what was good, what was wrong, and how to approach the problem next time.

Each workout directory gets a `TASK.md` with the current exercise, so you can resume after clearing the conversation: run `/workout-programming resume ~/workouts/<language>/<dir>` or start in that directory and run `/workout-programming resume`. A finished session leaves `GRADE.md` in the same directory.

Ask for `hint`, `next`, `harder`, `easier`, `skip`, or `show solution` at any point. Concept questions are answered with a short explanation and the relevant standard-library symbol, not with paste-ready code.

## Validation

The validators live in the skill, in `scripts/`, and are never copied into workout directories. Point the language script at the directory:

```sh
"$CLAUDE_SKILL_DIR/scripts/validate-go.sh" ~/workouts/go/<dir>
"$CLAUDE_SKILL_DIR/scripts/validate-c.sh" ~/workouts/c/<dir>
```

The directory is optional and defaults to the current directory. Arguments after it are forwarded to `go test`, or treated as source files for C. The scripts run the full check set:

- **Go:** `gofmt -l .`, `go vet ./...`, `go test -timeout 30s ./...`, `go run .` with a timeout, and `staticcheck` when installed.
- **C:** builds with `cc -std=c17 -Wall -Wextra -Wpedantic`, runs the binary with a timeout, and builds and runs an ASan/UBSan variant.

The script prints the raw tool output plus a `PASS`/`FAIL`/`WARN`/`NOTE` summary and exits non-zero when a required check fails. `RUN_TIMEOUT=30` changes the program run timeout. Dependency and network commands ask first.

## Contents

- `SKILL.md`: shared invocation, levels, setup flow, validation loop, coaching, hint policy, wrap-up
- `references/go.md`: Go setup, test scaffold, systems curriculum, validation, concept map
- `references/c.md`: C setup, scope per level, validation, concept map and safety notes
- `scripts/new-workout.sh`: creates the workout directory, entry file, Go module, Makefile, empty `testdata/`, and the `TASK.md` scaffold
- `scripts/validate-go.sh`: Go validator, invoked with a workout directory
- `scripts/validate-c.sh`: C validator, invoked with a workout directory

The skill doesn't remember progress on its own. Use `resume` with the workout directory to continue. It writes only the scaffold, task stubs, minimal test file, and `testdata/` fixtures inside the workout directory, never the exercise solution.
