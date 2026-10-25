# C workout curriculum

Use portable C17. Pick the level at session start and keep every exercise inside its scope. Make memory ownership, input capacities, and expected behavior explicit. Each exercise targets one main idea and optionally one adjacent concept. Exercises must not require unsafe operations or non-standard functions. Use short prototypes and small illustrative inputs, not completed implementations.

## Setup

Default location: `~/workouts/c/<topic>-<YYYYMMDD-HHMM>`.

Create the scaffold with the skill's setup script:

```sh
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" c <topic>
"$CLAUDE_SKILL_DIR/scripts/new-workout.sh" --dir ~/workouts/c/<slug> c <topic>
```

It creates the directory, `main.c`, an empty `testdata/`, and a `TASK.md` scaffold, then prints the workout directory. It never writes into an existing directory. Do not create these by hand.

Fallback when the script is unavailable:

```sh
mkdir -p ~/workouts/c
mkdir ~/workouts/c/<slug>
```

The validator stays in the skill at `scripts/validate-c.sh` (default install: `~/.claude/skills/workout-programming/scripts/validate-c.sh`). Do not copy it into the workout directory.

Start from the entry file the script wrote:

```c
#include <stdio.h>

int main(void) {
    return 0;
}
```

Easy and medium stay in `main.c`. Hard may add files and must name the source files to pass to the validator. For a long medium or hard task, prepopulate `main.c` with the includes, structs, and function prototypes, and leave the logic to the user. Check the toolchain with `cc --version`.

## Test assets

Fixed inputs live in `testdata/` in the workout directory.

- Create the assets the examples need and list each path with its exact contents in `TASK.md`, for example `testdata/alpha.txt` with `alpha\n`, `testdata/blank-first.txt` with `\nrest`, and `testdata/empty.txt` with nothing.
- Keep them tiny and inspectable, and delete stale ones when you assign a new exercise.
- The program takes a path and opens it; do not hardcode fixture contents in the program.
- Skip permission fixtures. A `0000` file is still readable by root, so a permission case cannot be tested reliably.

## Doc links

Give 2 to 4 links per task and list them in `TASK.md` under `## Docs`.

- Standard library function: `https://man7.org/linux/man-pages/man3/<name>.3.html`, for example `https://man7.org/linux/man-pages/man3/strlen.3.html`.
- System call: `https://man7.org/linux/man-pages/man2/<name>.2.html`, for example `https://man7.org/linux/man-pages/man2/read.2.html`.
- Language and library: `https://en.cppreference.com/w/c`.
- Offline equivalent to mention in chat: `man 3 strlen` or `man 2 read`.

Link only what the task uses. Never fetch a link, and never link tutorials, blogs, Stack Overflow, or generated summaries.

## Code scope

- **Easy:** at most 20 lines of user code in `main.c`, one main construct. A single function or snippet.
- **Medium:** at most 100 lines of user code, usually in `main.c`, optionally one extra file. Several constructs, structs, or library calls.
- **Hard:** a small program spread over multiple files. Name the files and pass them to the validator. Use several standard library headers.

## Validation

Run the skill's validator against the workout directory:

```sh
"$CLAUDE_SKILL_DIR/scripts/validate-c.sh" ~/workouts/c/<slug>
"$CLAUDE_SKILL_DIR/scripts/validate-c.sh" ~/workouts/c/<slug> main.c helper.c
```

The directory is optional and defaults to the current directory. Remaining arguments are treated as source files; without them every `.c` file is compiled. The script runs, in order:

- `cc -std=c17 -Wall -Wextra -Wpedantic -o main <sources>`.
- `./main` with a 10 second timeout. A timeout is reported as a `NOTE`, not a failure. Override it with `RUN_TIMEOUT=30`.
- A sanitizer build with `-fsanitize=address,undefined -g`, run under the same timeout. A sanitizer build failure is reported as a `NOTE`, because the toolchain may lack ASan or UBSan support.

It prints the raw tool output and a summary, and exits non-zero when a required check fails. Report exact tool messages. Never silence warnings with `-w`. Do not run the individual commands yourself, and do not copy the script into the workout directory. `clang-format` and `clang-tidy` are optional and not part of the script; skip them unless the user asks.

## Easy: syntax recall (max 20 lines)

- Types, initialization, integer arithmetic
- `for`, `while`, `do ... while`
- `if`, `switch`, boolean-like conditions
- Fixed-size arrays, indexes and bounds
- Functions and output parameters
- Character arrays, `strlen`, NUL termination
- Simple pointers, `&` and `*`

Example themes: sum an array; find an element index; count a specified character; swap two integers using pointers; find the length of a C string without `strlen`.

## Medium: memory and representations (max 100 lines)

- Pointer arithmetic within array bounds
- Array decay vs pointers; `sizeof` pitfalls
- Strings with destination buffer capacity
- `struct`, nested data and field access
- `const` correctness
- `malloc`, `calloc`, `realloc`, `free`; failure handling
- In-place array algorithms

Example themes: bounded string copy; reverse an array in place; grow an integer buffer safely; filter struct records.

## Hard: small compositions

- Dynamic arrays with documented ownership
- Singly linked lists with cleanup
- `stdio` file reading and error handling
- Small parsers with explicit input lengths
- Multi-function utilities with clear contracts

Example themes: tokenize a line into caller-provided storage; implement a growable array; parse simple numeric fields.

## Accuracy and safety checks

- Explicitly define lengths, capacities, allocation responsibilities, and valid ranges.
- Require sufficient space for the terminating `\0` in C strings.
- Avoid relying on undefined behavior or compiler-specific extensions.
- Never recommend `gets`; prefer bounds-checked approaches.
- Prefer compile-time warnings and sanitizers over guessing at memory behavior.
- If an easy or medium task grows past its line budget, move the task up a level instead of bending the scope.
