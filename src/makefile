##########################
# On command line use:
#   make all PROJECT=project_name MCU=mcu_type F_CPU=frequency
#   make clean

##########################
# Project definitions

# target platform
TRGT = avr-

# list of C source files
SRC =

# list of ASM source files
ASRC =

ASRC += build.S
ASRC += calc.S
ASRC += calc_ari.S
ASRC += calc_ctr.S
ASRC += calc_man.S
ASRC += calc_stk.S
ASRC += calc_sup.S
ASRC += const.S
ASRC += data.S
ASRC += decnum.S
ASRC += eeprom.S
ASRC += exec.S
ASRC += exec_ari.S
ASRC += exec_dis.S
ASRC += exec_edi.S
ASRC += exec_flg.S
ASRC += exec_fnc.S
ASRC += key.S
ASRC += lcd.S
ASRC += main.S
ASRC += math.S
ASRC += prog.S
ASRC += sleep.S
ASRC += spi.S
ASRC += wait.S

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
#CCFLAGS = $(OPT) -Wall -std=gnu99 -gstabs -mrelax -mshort-calls -mmcu=$(MCU) -c $(CDEF) -D$(MCU) -D F_CPU=$(F_CPU)
LNFLAGS = -mmcu=$(MCU) -D$(MCU) -DF_CPU=$(F_CPU)
#-mrelax 
#-mshort-calls
#OCFLAGS = -j .text -j .data
#ASFLAGS = -mmcu=$(MCU) -nostartfiles -g -mrelax -mshort-calls -D$(MCU) -D F_CPU=$(F_CPU) -Wa,-amhls=$(<:.s=.lst)


##########################
# Makefile rules

OBJS = $(ASRC:.s=.o) $(SRC:.c=.o)

all: $(OBJS) $(PROJECT).elf $(PROJECT).hex $(PROJECT).bin $(PROJECT).lst

#%.o : %.c
#	$(CC) -c $(CCFLAGS) $< -o $@

%elf: $(OBJS)
	$(LN) $(LNFLAGS) -o $@ $(OBJS)
  
%hex: %elf
	$(HEX) $< $@

%bin: %elf
	$(BIN) $< $@

%lst: %elf
	$(LST) $< > $@
