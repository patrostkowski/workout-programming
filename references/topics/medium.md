# Medium topics

One problem, at most 100 lines of user code. Medium includes every easy topic below, plus the medium areas. Rotate across areas so a session covers more than one of them, but a single task only needs one or two areas.

## Go: inherited from easy

Go basics:

- Variables, short declarations, zero values, constants
- `for`, `range`, `if`, `switch`
- Arrays vs slices, `len`/`cap`, `append`, nil vs empty
- Maps, comma-ok lookup, delete
- Strings, bytes, runes, `strconv`
- Functions, multiple returns, pointers, `defer`
- Structs, methods, value vs pointer receivers
- Interfaces, `error`, `errors.Is`
- `runtime` basics: `GOOS`, `NumCPU`, `NumGoroutine`, `ReadMemStats`

Unix basics:

- Files and permissions
- Directories and paths
- Symlinks and file metadata
- `/proc` and `/sys` values
- Pipes
- Environment and process IDs
- Network address parsing
- One socket connect or listen
- One small syscall

## Go: Unix internals

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

## Go: concurrent Go

- Goroutines and channels
- Buffered vs unbuffered channels
- `select` with timeouts and cancellation
- `context.WithTimeout`
- `sync.WaitGroup`
- Producer and consumer
- Fan-in from several goroutines
- Shared state behind a mutex

## C: inherited from easy

- Types, initialization, integer arithmetic
- `for`, `while`, `do ... while`
- Arrays and simple string handling
- Functions and parameters
- Simple pointers, `&` and `*`
- Small input and output routines

## C: added at medium

- Pointer arithmetic within array bounds
- Array decay and `sizeof`
- Structs and arrays of structs
- Dynamic arrays with checked sizes
- Bounded string handling
- In-place array algorithms
- Multi-function programs with clear contracts
