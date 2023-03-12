##########################
# On command line use:
#   make all = compile project
#   make clean = clean project
##########################
# Project definitions

# project name
PROJECT = eram100

# target platform
TRGT = avr-

# target CPU
MCU = atmega8

# CPU frequency
F_CPU = 8000000

# list of C source files
SRC = main.c

# list of ASM source files
ASRC =

# optimisation level
OPT = -Os

# tools
CC = $(TRGT)gcc
LN = $(TRGT)gcc
OC = $(TRGT)objcopy
AS = $(TRGT)gcc -x assembler-with-cpp
HEX = $(OC) -O ihex
BIN = $(OC) -O binary
LST = $(TRGT)objdump -d -S -m avr

# flags
CCFLAGS = $(OPT) -Wall -std=gnu99 -gstabs -mmcu=$(MCU) -c $(CDEF) -D F_CPU=$(F_CPU)
LNFLAGS = -mmcu=$(MCU)
OCFLAGS = -j .text -j .data
ASFLAGS = -mmcu=$(MCU) -nostartfiles -g -D F_CPU=$(F_CPU) -Wa,-amhls=$(<:.s=.lst)


##########################
# Makefile rules

OBJS = $(ASRC:.s=.o) $(SRC:.c=.o)

all: $(OBJS) $(PROJECT).elf $(PROJECT).hex $(PROJECT).bin $(PROJECT).lst

%.o : %.c
	$(CC) -c $(CCFLAGS) $< -o $@

%elf: $(OBJS)
	$(LN) $(LNFLAGS) -o $@ $(OBJS)
  
%hex: %elf
	$(HEX) $< $@

%bin: %elf
	$(BIN) $< $@

%lst: %elf
	$(LST) $< > $@

clean:
	-rm -f $(OBJS)
	-rm -f $(PROJECT).elf
	-rm -f $(PROJECT).map
	-rm -f $(PROJECT).hex
	-rm -f $(PROJECT).bin
	-rm -f $(PROJECT).lst
	-rm -f $(SRC:.c=.c.bak)
	-rm -f $(SRC:.c=.lst)
	-rm -f $(ASRC:.s=.bak)
	-rm -f $(ASRC:.s=.lst)
