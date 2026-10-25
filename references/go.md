# Go workout curriculum

Use standard Go and the standard library. Pick the level at session start and keep every exercise inside its scope. Each exercise targets one main idea and optionally one adjacent concept. Give correct, copyable function signatures; never implementation bodies beyond TODO placeholders.

This track is systems-oriented and assumes Linux. Easy tasks alternate Go internals with Linux basics; medium and hard mix Linux internals in Go with concurrent Go where the task fits: files, file descriptors, permissions, pipes, processes, signals, sockets, `/proc`, goroutines, channels, and `select`. Use the `syscall` package for Linux-specific exercises. Say in the task that the exercise is Linux-only, and do not add `golang.org/x/sys/unix` or any other dependency.

## Setup

Default location: `~/workouts/go/<topic>-<YYYYMMDD-HHMM>`.

Create the scaffold with the skill's setup script:

```sh
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" go <topic>
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" --dir ~/workouts/go/<slug> go <topic>
```

It creates the directory, `main.go`, `go.mod` from `go mod init workout`, a copy of `assets/Makefile`, an empty `testdata/`, and a `TASK.md` scaffold, then prints the workout directory. It never writes into an existing directory. Do not create these by hand.

Fallback when the script is unavailable:

```sh
mkdir -p ~/workouts/go
mkdir ~/workouts/go/<slug>
cd ~/workouts/go/<slug>
go mod init workout
```

The validator stays in the skill at `scripts/validate-go.sh` (default install: `~/.claude/skills/workout-programming/scripts/validate-go.sh`). Do not copy it into the workout directory.

The module gives the editor and Go tooling a consistent context. It uses a local name, adds no dependencies, and produces no build artifacts by itself.

The copied `Makefile` is part of the script's scaffold, so `make test` runs `go test -v ./` and `make run` runs `go run .`. Do not edit it per exercise.

Start from the entry file the script wrote:

```go
package main

func main() {
}
```

Easy and medium stay in `main.go`. Hard may add files in the same module. For a long medium or hard task, prepopulate `main.go` with the imports, `flag` parsing, wiring, and typed stubs with `panic("TODO")` bodies, and leave the logic to the user. Every exercise also gets a minimal test file, normally `main_test.go` (see Test scaffold). Keep every file in `package main` unless the task explicitly names a small internal package. Check the toolchain with `go version`, and confirm `go env GOOS` reports `linux` before a Linux-only task.

## Test scaffold

Every Go exercise gets a very small test file, normally `main_test.go`, using only `testing`. It is a partial specification, not a full test suite.

- Write one table-driven test function for the function named in the task. Use at least 3 cases: one typical case, one empty or zero case, and one simple edge case. Those 3 cases are the minimum.
- Use a `tests := []struct{...}` table and `t.Run` per case. Split a case into its own test function only when it needs different setup.
- Deliberately leave at least one meaningful case untested. The tests should catch obvious mistakes, not cover the full scope.
- Do not test helpers the user has not written, and never put the implementation in the test file.
- Add the required function signature to the file the task names, with a `panic("TODO")` body, so the test file compiles before the user starts.
- Give each exercise a distinct function name so stubs do not collide in the shared package.
- Choose tasks around a callable function; avoid exercises that only print output.
- Keep the test file as short as the task allows, roughly 30 to 50 lines for easy and medium tasks, with no external packages and no nontrivial helpers.
- Compute every expected value by hand. Never invent a result.
- Overwrite the test file when you assign a new exercise, and write it to the file instead of pasting it into chat.
- Treat the tests as the exercise contract. If the user edits or deletes them, review the change instead of accepting it silently.
- Read fixed inputs from `testdata/`; use `t.TempDir()` only when a case must create, mutate, or delete the file.

For system tasks:

- Use `t.TempDir()` for files, directories, and Unix socket paths.
- For TCP, listen on `127.0.0.1:0`, read the port from `listener.Addr()`, and close the listener and connections.
- Test `/proc` and `/sys` parsers with fixture strings or temp files, not host values.
- Never require root, a fixed port, external network access, or global process state. Set socket deadlines so a broken implementation fails instead of hanging.

Example entry file and tests:

```go
package main

func main() {
}

func readFirstLine(path string) (string, error) {
	panic("TODO")
}
```

```go
package main

import (
	"path/filepath"
	"testing"
)

func TestReadFirstLine(t *testing.T) {
	tests := []struct {
		name  string
		asset string
		want  string
	}{
		{name: "one line", asset: "one-line.txt", want: "alpha"},
		{name: "crlf", asset: "crlf.txt", want: "alpha"},
		{name: "blank first line", asset: "blank-first-line.txt", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			path := filepath.Join("testdata", tt.asset)

			got, err := readFirstLine(path)
			if err != nil {
				t.Fatalf("readFirstLine() error: %v", err)
			}
			if got != tt.want {
				t.Fatalf("readFirstLine() = %q, want %q", got, tt.want)
			}
		})
	}
}
```

The example leaves missing files, files without a trailing newline, and very long lines untested on purpose. The test file should compile and fail before the user starts; an undefined function means the stub is missing.

## Test assets

Fixed inputs live in `testdata/` in the workout directory. The Go tool ignores that directory, so assets never enter the build.

- Create the assets the examples and the tracked tests need, and list each path with its exact contents in `TASK.md`.
- Keep them tiny and inspectable: a few bytes of UTF-8 text, one line, a short binary header. No generated blobs.
- Have read-only cases open `filepath.Join("testdata", name)`. Copy the asset into `t.TempDir()` when a case must truncate, chmod, or delete it.
- Keep one copy. The file in `testdata/` is the source for both the tests and a manual run, so do not repeat the same bytes in the test file.
- Skip permission fixtures. A `0000` file is still readable by root, so a permission case cannot be tested reliably.
- Delete stale assets when you assign a new exercise.

For the example above, the assets are `testdata/one-line.txt` with `alpha\n`, `testdata/crlf.txt` with `alpha\r\n`, and `testdata/blank-first-line.txt` with `\nalpha\n`.

## Doc links

Give 2 to 4 links per task and list them in `TASK.md` under `## Docs`.

- Symbol: `https://pkg.go.dev/<package>#<Symbol>`, for example `https://pkg.go.dev/syscall#Open` or `https://pkg.go.dev/io#EOF`.
- Package overview, when the task uses several symbols from it: `https://pkg.go.dev/<package>`.
- Language: `https://go.dev/ref/spec` or `https://go.dev/doc/effective_go`.
- Linux system call: `https://man7.org/linux/man-pages/man2/<name>.2.html` for section 2 and `https://man7.org/linux/man-pages/man3/<name>.3.html` for section 3, for example `https://man7.org/linux/man-pages/man2/read.2.html`.
- Offline equivalent to mention in chat: `go doc syscall.Read` or `man 2 open`.

Link only symbols the task actually uses, plus at most one overview page. Never fetch a link, and never link tutorials, blogs, Stack Overflow, or generated summaries.

## Code scope

- **Easy:** at most 20 lines of user code in `main.go`, one main idea. A single function or snippet, with the error checks and `defer` it needs.
- **Medium:** at most 100 lines of user code in `main.go`. Several constructs, structs, or standard library calls.
- **Hard:** a small program spread over multiple files in the same module. Name the files the task expects. Add more tests only if the exercise needs them beyond the minimal scaffold. Use several standard library packages.

The program must compile and run with `go run .` once the exercise is complete.

## Validation

Run the skill's validator against the workout directory:

```sh
"$CLAUDE_SKILL_DIR/scripts/validate-go.sh" ~/workouts/go/<slug>
"$CLAUDE_SKILL_DIR/scripts/validate-go.sh" ~/workouts/go/<slug> -race
```

The directory is optional and defaults to the current directory. Arguments after it go to `go test`. The script runs, in order:

- `gofmt -l .`, failing when any file needs formatting.
- `go vet ./...`.
- `go test -timeout 30s ./...`, forwarding extra arguments, so `-race` works.
- `go run .` with a 10 second timeout. A timeout is reported as a `NOTE`, not a failure, because servers and blocking programs are expected to keep running. Override it with `RUN_TIMEOUT=30`.
- `staticcheck ./...` only when installed; its findings are advisory.

It prints the raw tool output and a summary, and exits non-zero when a required check fails. The tests are expected to compile and fail before the user starts; a build failure means the stub is missing.

Do not run the individual commands yourself, and do not copy the script into the workout directory. Do not use `go build`; it leaves a binary named after the module in the workout directory. Do not run `go get` or `go mod tidy` without asking.

## Easy: Go and Unix basics (max 20 lines)

One small function, one main idea, usually one standard-library call or syscall. Alternate between the two lists below from task to task; a session should cover Go internals and Unix system tasks.

Go internals:

- Variables, short declarations, zero values, constants, `for`, `range`, `if`, `switch`
- Arrays vs slices; `len` and `cap`; `append` aliasing; nil vs empty slices
- Maps: initialize, lookup, comma-ok, delete; nil map writes
- Strings vs bytes vs runes; `range` over strings; `strconv`
- Functions, multiple returns, pointers, `defer`, `panic`/`recover`
- Structs, fields, methods, value vs pointer receivers
- Interfaces, `io.Reader`, `io.Writer`, `error`; `errors.Is`
- `runtime` basics: `GOOS`, `NumCPU`, `NumGoroutine`, `ReadMemStats`

Linux and system calls:

- Files and permissions: `os.Open`, `os.ReadFile`, `os.WriteFile`, `os.OpenFile`, `os.Chmod`, `defer Close`
- Streams: `bufio.Scanner`, `io.Copy`, `io.LimitReader`, `io.MultiWriter`, `os.Pipe`
- Metadata: `os.Stat`, `os.Lstat`, `FileMode`, `os.SameFile`, `os.Readlink`, `FileInfo.Sys()` with `syscall.Stat_t`
- Directories and paths: `os.ReadDir`, `os.MkdirAll`, `filepath.Join`, `filepath.Ext`
- Linux pseudo-files: read `/proc` and `/sys` values with `os.ReadFile` and parse them
- Process and environment: `os.Getpid`, `os.Getppid`, `os.Getuid`, `os.Getgid`, `os.Environ`, `os.Getenv`, `os.Hostname`, `os.Args`
- Network values: `net.ParseIP`, `net.ParseCIDR`, `net.SplitHostPort`, `net.ParseMAC`
- Sockets: `net.Dial`, `net.Listen`, `net.Conn`, TCP and Unix sockets
- Syscalls: `syscall.Open`, `syscall.Read`, `syscall.Close`, `syscall.Stat`, `syscall.Statfs`, `syscall.Getrlimit`, `syscall.Socketpair`

Example themes: read the first line of a file; copy a file; print inode, size, and mode; list a directory; write a file with `0600`; print a symlink target; parse a CIDR and report the network; dial a loopback TCP listener and echo a line; echo over a Unix socket; read one byte with `syscall.Open`, `Read`, and `Close`; check whether two paths are hard links; read and parse a `/proc` value; print PID, UID, GID, and hostname; use `os.Pipe` to move bytes; use `syscall.Socketpair` to move bytes between two descriptors; read at most N bytes.

## Medium: Unix internals in Go (max 100 lines)

Unix internals first, with Go as the vehicle. Prefer tasks about descriptors, files, pipes, processes, signals, sockets, and `/proc`. Add goroutines, channels, and `select` when the work is naturally concurrent, not as a drill.

- Descriptors and low-level files: `os.File.Fd`, `os.NewFile`, `File.ReadAt`/`WriteAt`/`Seek`, `syscall.Open`/`Read`/`Close`
- Metadata and permissions: `syscall.Stat`, `syscall.Stat_t`, `os.Chmod`, `FileMode.Perm`, umask
- Buffered file I/O: `bufio.Scanner`, `bufio.Reader`, `io.ReadFull`, `io.ReadAll`, `io.LimitReader`
- Pipes: `os.Pipe`, `io.Copy` between descriptors
- Process execution: `os/exec`, `CommandContext`, `StdoutPipe`, `Wait`, `ExitError`
- Signals: `os/signal`, `signal.NotifyContext`, `syscall.SIGTERM`, `SIGHUP`
- Sockets: `net.Listen`, `net.Dial`, `net.Conn`, TCP and Unix sockets, deadlines
- Directory traversal: `filepath.WalkDir`, `os.DirFS`, `io/fs`
- `/proc` and `/sys`: read and parse fields into a struct
- Locking and binary data: `syscall.Flock`, `encoding/binary`

Go features the system work needs:

- Structs, methods, and interfaces for parsed records and pluggable sources
- Error wrapping, `errors.Is`/`errors.As`, sentinel errors
- `context.WithTimeout` and `net.Dialer.DialContext`
- One goroutine and a channel; `select` with a timeout

Example themes: grep-like line matcher over a file; walk a directory and summarize sizes; run a command and capture its exit status; TCP echo server with deadlines; Unix socket client; lock a file with `syscall.Flock`; read a binary header; signal-aware shutdown; parse `/proc` fields into a struct; copy a pipe to stdout with `io.Copy`.

## Hard: Unix system programs (multi-file)

Unix internals first, with real concurrency where the system needs it. The program structure and Go features exist to drive descriptors, processes, sockets, and files. Prefer syscall-level work over application features.

- Program structure across `main.go` plus focused files such as `server.go`, `process.go`, or `parser.go`; `flag` for a small CLI surface
- File descriptors: `os.NewFile`, `File.Fd()`, `net.FileListener`, `net.FileConn`, fd passing over Unix sockets with `Sendmsg`/`Recvmsg`
- Process supervision: `os/exec`, `CommandContext`, process groups, `SIGTERM` forwarding, `Wait` and reaping
- Signals: `signal.NotifyContext`, `SIGTERM`/`SIGINT`/`SIGHUP`, graceful shutdown
- Network servers: `net.Listener`, TCP and Unix sockets, deadlines, per-connection goroutines
- Low-level Linux: `syscall.Epoll*`, `syscall.Inotify*`, `syscall.Socket`/`Bind`/`Listen`/`Accept`, `syscall.Sendmsg`/`Recvmsg`, `syscall.Mmap`, `syscall.Flock`
- Concurrency where the system needs it: goroutines, channels, worker pools, `select`, `sync.WaitGroup`
- HTTP only as the system surface: `net/http` health endpoint, `http.Server.Shutdown`, `crypto/tls`
- Testing: table tests, `t.TempDir`, loopback listeners, `go test -race`

Example themes: TCP echo server with graceful shutdown; Unix socket daemon; inotify file watcher; process supervisor that forwards `SIGTERM`; HTTP health endpoint reporting disk and memory stats; mmap-based line counter; fd passing over a Unix socket; epoll-based echo server; TCP proxy that copies between two descriptors.

## Accuracy checks

- `syscall` is Linux-specific and frozen; say so in the task and keep `golang.org/x/sys/unix` out.
- String slicing uses byte positions and may split UTF-8 sequences.
- `range` over a string iterates runes and reports byte offsets.
- A nil slice can be appended to; a nil map cannot receive assignments.
- Close every file, pipe, socket, listener, mmap region, epoll fd, and inotify fd. Use `defer` in the right scope.
- `os.Stat` follows symlinks; `os.Lstat` does not. `os.SameFile` compares device and inode.
- File modes are affected by the process umask; check `Perm()` in tests.
- `io.Reader` can return short reads; use `io.ReadFull` or `io.ReadAll` when the full payload is required.
- TCP tests listen on `127.0.0.1:0` and use the actual address; set deadlines.
- Unix socket paths are limited to about 108 bytes; keep test paths short.
- `/proc` and `/sys` values are host-dependent; parse them instead of asserting exact values.
- Never require root or host-changing operations such as mount, reboot, `Setuid`, or signaling unrelated processes. A task may signal a child process it started.
- `os/exec` commands must be waited on; check `*exec.ExitError` for non-zero exits.
- `syscall.Flock` is advisory; close the file to release the lock.
- Define empty inputs, bounds, and whether mutation is allowed when relevant.
- If an easy or medium task grows past its line budget, move the task up a level instead of bending the scope.
