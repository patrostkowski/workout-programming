# Go topic areas

## Areas

- `Language internals`: Go basics, strings, bytes, slices, maps, interfaces, `runtime`.
- `Unix and concurrency`: files, pipes, processes, signals, sockets, `/proc`, goroutines, channels, `select`.

## Easy

One main idea, at most 20 lines of user code. Alternate between Go internals and Unix basics, so a session covers both.

### Go basics

- Variables, short declarations, zero values, constants
- `for`, `range`, `if`, `switch`
- Arrays vs slices, `len`/`cap`, `append`, nil vs empty
- Maps, comma-ok lookup, delete
- Strings, bytes, runes, `strconv`
- Functions, multiple returns, pointers, `defer`
- Structs, methods, value vs pointer receivers
- Interfaces, `error`, `errors.Is`
- `runtime` basics: `GOOS`, `NumCPU`, `NumGoroutine`, `ReadMemStats`

### Unix basics

- Files and permissions
- Directories and paths
- Symlinks and file metadata
- `/proc` and `/sys` values
- Pipes
- Environment and process IDs
- Network address parsing
- One socket connect or listen
- One small syscall

## Medium

Areas added at this level. Medium includes every easy topic. Stay on Unix internals and use Go as the vehicle; add goroutines, channels, and `select` where the task calls for them.

### Unix internals

- Descriptors and low-level file access
- Metadata and permissions
- Buffered file I/O
- Pipes
- Process execution and exit status
- Signals
- Sockets and deadlines
- Directory traversal
- `/proc` and `/sys` parsing
- File locking and binary data

### Concurrent Go

- Goroutines and channels
- Buffered vs unbuffered channels
- `select` with timeouts and cancellation
- `context.WithTimeout`
- `sync.WaitGroup`
- Producer and consumer
- Fan-in from several goroutines
- Shared state behind a mutex

## Hard

Areas added at this level. Hard includes every easy and medium topic.

### System programs

- TCP and Unix socket servers
- Process supervision and reaping
- File descriptor passing
- `epoll`
- `inotify`
- `mmap`
- Proxies and copy loops
- Graceful shutdown
- Small CLI surface with `flag`
- HTTP only as a health or admin endpoint

### Concurrent structure

- Worker pools
- Fan-in and fan-out
- Goroutine per connection
- Race-free shared state
- Shutdown through context or channels
- Rate limiting with timers and channels
- Pipeline stages connected by channels
- Coordination of several moving parts with `sync.WaitGroup` and `select`
