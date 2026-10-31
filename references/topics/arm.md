# AArch64 topic areas

## Areas

- `Registers and arithmetic`: `x`/`w` views, data movement, integer and bitwise operations.
- `Control flow and stack`: `cmp`, `b.cond`, `cbz`, loops, `stp`/`ldp`, `sp`.
- `Functions and the ABI`: `bl`/`ret`, frames, AAPCS64 registers, calling C.
- `Linux syscalls and memory`: `svc #0`, `write`, `read`, `openat`, buffers, `argv`, `mmap`.

## Easy

One main idea, at most 20 lines of user code.

### Registers and arithmetic

- 64-bit and 32-bit register views
- `mov`, `movz`, and `movk`
- `add`, `sub`, `neg` with immediates
- `and`, `orr`, `eor`
- `lsl`, `lsr`, `asr`
- `cmp`, `cset`, and `csel`

### Control flow

- `b` and `b.cond`
- `cbz` and `cbnz`
- Counted loops with `subs` and `b.ne`
- `stp` and `ldp` with `sp`
- `adr` and nearby labels

### Data and syscalls

- `ldr` and `str` with offset addressing
- Byte and halfword access with `ldrb`, `strb`, `ldrh`, `strh`
- The `exit` syscall with `svc #0`
- A fixed string with the `write` syscall

## Medium

Areas added at this level. Medium includes every easy topic.

### Functions and the ABI

- `bl` and `ret`
- Saving and restoring `x30`
- AAPCS64 argument and return registers
- Callee-saved registers `x19` to `x28`
- Stack frames with `stp x29, x30` and `ldp x29, x30`
- 16-byte stack alignment
- Local buffers on the stack
- Calling a C function from assembly

### Widths and arithmetic

- Byte, halfword, word, and doubleword access
- `ldrsb`, `ldrsh`, `ldrsw`, and zero extension
- `mul`, `madd`, `msub`
- `sdiv`, `udiv`, and remainder via `msub`
- Addressing modes: offset, pre-index, post-index
- Register offsets scaled by element size

### Syscalls and buffers

- `openat`, `read`, `write`, `close`
- Syscall error returns in `x0`
- Byte loops over a buffer
- `adrp` plus `add :lo12:` for symbol addresses
- `argc` and `argv` on the stack at `_start`
- Reading and writing a stack buffer
- Multiple functions in one file

## Hard

Areas added at this level. Hard includes every easy and medium topic.

### System utilities

- Multi-file programs with `.global`
- `strlen`, `strcmp`, `memcpy`, `memset` from scratch
- Decimal and hexadecimal conversion
- `cat`, `wc`, and `hexdump` style utilities
- Output buffering with `write`
- `brk` or `mmap` allocation
- Mixed C and assembly programs
- Syscall error handling and exit status propagation
