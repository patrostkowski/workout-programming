VALIDATE ?= __VALIDATE__
ASM ?= as --64 -g
LINKER ?= ld
HOSTCC ?= cc

SOURCES := $(wildcard *.s)
C_SOURCES := $(wildcard *.c)
OBJECTS := $(SOURCES:.s=.o)

.PHONY: all run test clean

all: main

%.o: %.s
	$(ASM) -o $@ $<

ifeq ($(strip $(C_SOURCES)),)
LINK = $(LINKER) --entry=_start -o $@ $(OBJECTS)
else
# Function-mode workouts link the user's assembly against the C harness.
LINK = $(HOSTCC) -fno-pie -no-pie -Wall -Wextra -Wpedantic -o $@ $(OBJECTS) $(C_SOURCES)
endif

main: $(OBJECTS)
	$(LINK)

# A non-zero program status is the result here, not a build failure.
run: main
	@./main; printf 'exit status: %d\n' $$?

test:
	$(VALIDATE) $(CURDIR)

clean:
	rm -f $(OBJECTS) main
