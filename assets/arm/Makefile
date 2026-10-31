VALIDATE ?= __VALIDATE__
ASM ?= aarch64-linux-gnu-as
LINKER ?= aarch64-linux-gnu-ld
RUNNER ?= qemu-aarch64

SOURCES := $(wildcard *.s)
OBJECTS := $(SOURCES:.s=.o)

.PHONY: all run test clean

all: main

%.o: %.s
	$(ASM) -g -o $@ $<

main: $(OBJECTS)
	$(LINKER) --entry=_start -o $@ $(OBJECTS)

# A non-zero program status is the result here, not a build failure.
# On a native AArch64 host run: make run RUNNER=
run: main
	@$(RUNNER) ./main; printf 'exit status: %d\n' $$?

test:
	$(VALIDATE) $(CURDIR)

clean:
	rm -f $(OBJECTS) main
