; ****************************************************************************
;
;                                  Includes
;
; ****************************************************************************

#include <avr/io.h>

#define USEDEBUG			// uncomment this to use debug mode (INV + DEBUG ON, INV - DEBUG OFF)
;#define DOTEST				// uncomment this to do some internal tests

; Divider of LCD contrast generator (used on ET-58 hardware)
;  Recommended values:
;	.byte	71	; 0: 3497 Hz
;	.byte	56	; 1: 4386 Hz
;	.byte	45	; 2: 5495 Hz
;	.byte	36	; 3: 6849 Hz
;	.byte	29	; 4: 8475 Hz
;	.byte	23	; 5: 10638 Hz
;	.byte	18	; 6: 13514 Hz
;	.byte	14	; 7: 16667 Hz
;	.byte	11	; 8: 20833 Hz
;	.byte	9	; 9: 26316 Hz
#define LCDDIV	29

#ifndef TCCR0A
#define USETIM2				// use Timer2 to control LCD PWM
#endif

#ifndef PCICR
#define USEINT0				// use INT0 wakeup
#endif

; ===== CPU class
#if defined atmega8 || defined attiny2313 || defined attiny4313
#define MCU8				// ATmega8, ATTiny2313, ATTiny4313
#elif defined atmega328p || defined atmega328 || defined atmega88 || defined atmega168 || defined atmega48
#define MCU88				// ATmega48, ATmega88, ATmega168, ATmega328, ATmega328P
#else
#error Unsupported MCU!
#endif

#ifdef MCU8	// ATmega8
#define HW_ET57				// use hardware of ET-57
#else
#define HW_ET58				// use hardware of ET-58
#endif

#if FLASHEND <= 0x2000
#define ROM8K		// use 8K ROM convention (far jump not needed)
#define call rcall
#define jmp rjmp
#endif

; ===== Float number definition
; display: 11 valid digits, 2 digits exponent
; extended registers R10..R79 (13 valid digits, 8 bytes):
;	1 byte exponent with bias 128 (range -99..+99)
;	7 bytes mantissa, 14 BCD digits from MSD to LSD, highest digit can be 0 (positive) or 9 (negative number)
; base registers R0..R9, X, LAST (15 valid digits, 9 bytes):
;	1 byte exponent with bias 128 (range -99..+99)
;	8 bytes mantissa, 16 BCD digits from MSD to LSD, highest digit can be 0 (positive) or 9 (negative number)
; calculations (17 valid digits, 10 bytes):
;	1 byte exponent with bias 128 (range -99..+99)
;	9 bytes mantissa, 18 BCD digits from MSD to LSD, highest digit can be 0 (positive) or 9 (negative number)

; exponent (1 byte)
#define EXP_BIAS	128		// exponent bias
#define EXP_ONE		EXP_BIAS	// exponent of '1'
#define EXP_ZERO	0		// exponent of zero number
#define EXP_MIN		29		// minimal exponent (= -99)
#define EXP_MAX		227		// maximal exponent (= +99)
#define EXP_OVER	(EXP_MAX+1)	// overflow exponent (= +100)
#define EXP_UNDER	(EXP_MIN-1)	// underflow exponent (= -100)

#define VMANT_BYTE	6		// number of bytes of visible mantissa (used in function NumSetOver)

; number in extended registers NUM_10..
#define RMANT_BYTES	7		// number of bytes per mantissa 6..10 (must be <= CMANT_BYTES)
#define RMANT_DIG	(RMANT_BYTES*2)	// number of digits per mantissa, including sign (=12)
#define RNUM_BYTES	(1+RMANT_BYTES) // number of bytes per number (=7)

; number in base registers NUM_0 .. NUM_9, X, LAST
#define BMANT_BYTES	8		// number of bytes per mantissa 6..10 (must be <= CMANT_BYTES)
#define BMANT_DIG	(BMANT_BYTES*2)	// number of digits per mantissa, including sign (=14)
#define BNUM_BYTES	(1+BMANT_BYTES) // number of bytes per number (=8)

; number in internal calculations (size 0..3 bytes longer than registers)
#define CMANT_BYTES	9		// number of bytes per mantissa 6..10 (must be >= RMANT_BYTES, must be >= (MANT_DIGITS+1)/2))
#define CMANT_DIG	(CMANT_BYTES*2)	// number of digits per mantissa, including sign (=16)
#define CNUM_BYTES	(1+CMANT_BYTES) // number of bytes per number (=9)

#define RMANT_DIF	(CMANT_BYTES-RMANT_BYTES) // difference of formats of extended register (bytes, must be in range 0..3)
#define BMANT_DIF	(CMANT_BYTES-BMANT_BYTES) // difference of formats ofbase register (bytes, must be in range 0..3)

; number to display
#define MANT_DIGITS	11		// max. number of visible digits of mantissa (max. 11, max. CMANT_BYTES*2-1)

#define SIGN_THRES	0x50		// check threshold of sign byte to detect negative number
					//	    (0x50 = half between 0x00 and 0x99)

// number of user registers (base registers + extended registers)
#if RMANT_BYTES == 6
#define MEM_NUM	100
#elif RMANT_BYTES == 7
#define MEM_NUM	80
#elif RMANT_BYTES == 8
#define MEM_NUM	70
#elif RMANT_BYTES == 9
#define MEM_NUM	65
#else // RMANT_BYTES == 10
#define MEM_NUM	57
#endif

; ===== User registers

; base registers (high precission, located in BaseReg)
#define MEM_0		0		// index of register 0, N (number of entries), Dsz counter
#define MEM_1		1		// index of register 1, sum(y)
#define MEM_2		2		// index of register 2, sum(y^2)
#define MEM_3		3		// index of register 3, sum(x) ... or N (TI-58)
#define MEM_4		4		// index of register 4, sum(x^2) ... or sum(x) (TI-58)
#define MEM_5		5		// index of register 5, sum(x*y) ... or sum(x^2) (TI-58)
#define MEM_6		6		// index of register 6 ... or sum(x*y) (TI-58)
#define MEM_7		7		// index of register 7, register T
#define MEM_8		8		// index of register 8, indirect register
#define MEM_9		9		// index of register 9, indirect register 2 (INV STO*, INV RCL*, INV Exc*)

#define REG_DSZ		MEM_0		// Dsz register
#define REG_T		MEM_7		// index of register T
#define REG_IND		MEM_8		// indirect register
#define REG_IND2	MEM_9		// indirect register 2

; Stat registers
#define MEM_N		MEM_0		// N
#define MEM_SUMY	MEM_1		// sum(y)
#define MEM_SUMY2	MEM_2		// sum(y^2)
#define MEM_SUMX	MEM_3		// sum(x)
#define MEM_SUMX2	MEM_4		// sum(x^2)
#define MEM_SUMXY	MEM_5		// sum(x*y)

; extended registers (low precission, located in MemReg, INV STO, INV RCL, INV Exc)
#define MEM_10		10		// index of register 10
#define MEM_11		11		// index of register 11
#define MEM_12		12		// index of register 12
#define MEM_13		13		// index of register 13
#define MEM_14		14		// index of register 14
#define MEM_15		15		// index of register 15
#define MEM_16		16		// index of register 16
#define MEM_17		17		// index of register 17
#define MEM_18		18		// index of register 18
#define MEM_19		19		// index of register 19

#define BASE_NUM	12		// number of base registers + X + T
#define MEM_NUM2	(MEM_NUM-10)	// number of extended registers (in MemReg, without base registers)

; ===== Buffers

#define LEVEL_MAX	7			// max. arithmetics level
#define CALC_TEMP	7			// reserve in calculator stack for temporary registers
#define CALC_MAX	(LEVEL_MAX+1+CALC_TEMP)	// size of calculator stack, without system registers
#define CALC_MAX2	(CALC_MAX+4)		// corrected size of calculator stack, including TEMP 1..4, X and LAST

#define EDITBUF_SIZE	16			// size of edit buffer (to display and edit number)

#define MANT_LEN	(MANT_DIGITS+2)		// mantissa visible length (digits + sign + decimal point) (=13)
#define EXP_LEN		3			// exponent visible length (digits + sign)
#define NUM_LEN		(MANT_LEN+EXP_LEN)	// number visible length (mantissa + exponent) (=16)
#define EDITBUF_MANT	0			// mantissa first character (sign)
#define EDITBUF_EXP	(EDITBUF_MANT+MANT_LEN)	// exponent first character (sign) (=13)

#define PROGSTACK_NUM	8			// max. level of program stack

; ===== System registers
; - registers in RegMem
#define REG_X		31		// index of register X
#define REG_LAST	30		// index of register LAST
#define REG_SYS_BASE	REG_LAST	// base index
#define REG_SYS_SHIFT	(BASE_NUM-2-REG_SYS_BASE) // offset to recalculate to RegMem index

; - registers in CalcStack
#define TEMP_1		29		// index of register TEMP 1
#define TEMP_2		28		// index of register TEMP 2
#define TEMP_3		27		// index of register TEMP 3
#define TEMP_4		26		// index of register TEMP 4
#define REG_TEMP_BASE	TEMP_4		// base index
#define REG_TEMP_SHIFT	(CALC_MAX-REG_TEMP_BASE) // offset to recalculate to CalcStack index

; ===== LCD display

#define LCD_ROWNUM	2			// number of rows of LCD display
#define LCD_COLNUM	16			// number of columns of LCD display
#define ROW1		0			// address of 1st row
#define ROW2		0x40			// address of 2nd row

#define CHAR_NUM	8			// number of custom characters

; ===== Arithmetics operations

; code of arithmetics operation (3 bits)
#define OPER_NONE	0	// no arithmetics operation

#define OPER_PLUS	1	// +
#define OPER_MINUS	2	// -

#define OPER_MUL	3	// *
#define OPER_DIV	4	// :
#define OPER_MOD	5	// backslash

#define OPER_POWER	6	// ^
#define OPER_ROOT	7	// root

#define OPER_MASK	7	// mask of code of arithmetics operation

; level of current arithmetics operation (2 bits)
#define LEVEL_NONE	(0<<3)	// no level
#define LEVEL_PLUSMINUS	(1<<3)	// + -
#define LEVEL_MULDIV	(2<<3)	// * : backslash
#define LEVEL_POWER	(3<<3)	// ^ root

#define LEVEL_MASK	(3<<3)	// mask of level of arithmetics operation

; level of lower arithmetics operation (2 bits)
#define LOWER_NONE	(0<<5)	// no level
#define LOWER_PLUSMINUS	(1<<5)	// + -
#define LOWER_MULDIV	(2<<5)	// * :
#define LOWER_POWER	(3<<5)	// ^ root

#define LOWER_MASK	(3<<5)	// mask of level of arithmetics operation

; ===== Bit constants

#define	B0	0x1
#define	B1	0x2
#define	B2	0x4
#define	B3	0x8
#define	B4	0x10
#define	B5	0x20
#define	B6	0x40
#define	B7	0x80
#define	B8	0x100
#define	B9	0x200
#define	B10	0x400
#define	B11	0x800
#define	B12	0x1000
#define	B13	0x2000
#define	B14	0x4000
#define	B15	0x8000

#define BIT(pos) (1<<(pos))

; ===== Memory

; RAM address and size
#ifdef MCU8
#define RAM_BEG		0x0060	// SRAM begin
#else
#define RAM_BEG		0x0100	// SRAM begin
#endif
#define RAM_END		(RAMEND+1) // SRAM end + 1
#define RAM_SIZE	(RAM_END-RAM_BEG) // SRAM size
#define STACK		RAMEND // end of stack in RAM (= last byte)

; ROM address and  size
#define ROM_BEG		0x0000	// ROM begin
#define ROM_END		(FLASHEND+1) // ROM end + 1
#define ROM_SIZE	(ROM_END-ROM_BEG) // ROM size

; FLASH address and size
#define EEPROM_BEG	0x0000	// EEPROM begin
#define EEPROM_END	(E2END+1) // EEPROM end + 1
#define EEPROM_SIZE	(EEPROM_END-EEPROM_BEG)	// EEPROM size

; ==== EEPROM

#define PROG_SIZE	50	// number of program steps per one program
#define PROG_NUM	10	// number of program slots (total 500 bytes)

#define CFG_LCD		(EEPROM_END-1) // (1) LCD contrast (ET-58 hardware)
#define CFG_SEED	(CFG_LCD-RNUM_BYTES) // (RNUM_BYTES) random number generator

; ===== User keyboard codes

#include "inc_key.inc"

; ===== Internal program code

#include "inc_cmd.inc"

; ===== Calculator macro literals

#include "inc_calc.inc"

; ===== SPI interface

#define SPIDATA_MAX	256	// max. number of data entries

#define SPICMD_SYNC	0x53	// synchro command ('S')
#define SPICMD_READ	0x52	// read command ('R')
#define SPICMD_WRITE	0x57	// write command ('W')
#define SPICMD_ERR	0x55	// invalid synchronization ('U')
#define SPICMD_ERR2	0xAA	// alternate invalid synchronization

; ===== Offsets in data area Y
; Data area pointed by Y registers (DataStart, size max. 64 bytes)

; ...general flags
#define DATA_FLAGS	0	// (u8) general flags F_*

; General flags in DATA_FLAGS (bit index):
#define F_INV		0	// INV flag
#define F_2ND		1	// 2nd flag
#define F_EE		2	// EE mode
#define F_DP		3	// decimal point entered
#define F_EXP		4	// entering exponent
#define F_SPIERR	5	// stop on SPI error
#define F_RESDEC	6	// restart DecNum function
#define F_EXPDIG	7	// exponent digits

; ...display
#define DATA_POSX	1	// (u8) display X position
; ...keyboard
#define DATA_TIME	2	// (u8) time counter, granularity 10 ms
#define DATA_KEYRAW	3	// (u8) current pressed raw key, NOKEY=no key
#define DATA_KEYCNT	4	// (u8) key press time counter
#define DATA_KEY	5	// (u8) key pressed, NOKEY=no key
#define DATA_KEYSAVE	6	// (u8) saved key, NOKEY=no key
; ...calculator
#define DATA_STKEND	7	// (u16) end of calculator stack
#define DATA_LEVEL	9	// (u8) current level of arithmetics operations
#define DATA_LAST	10	// (u8) last arithmetics operation (OPER_*)
; ...editor
#define DATA_EDITDIG	11	// (u8) number of digits of mantissa in edit mode (may be including decimal point and sign, but may be not)
#define DATA_FIX	12	// (u8) fix decimals (0..8 digits or FIX_OFF=off)
; ...program
#define DATA_UNIT	13	// (u8) angle unit UNIT_*
#define DATA_ADDR	14	// (u16) program address - edit or run, relative to program base
#define DATA_PROGINX	16	// (u8) index of current program (0=main)
#define DATA_PROGNEXT	17	// (u8) next program index (0=main)
#define DATA_PROGBEG	18	// (u16) start address of current program (= first byte)
#define DATA_PROGEND	20	// (u16) end address of current program (= last byte)
#define DATA_PROGLEVEL	22	// (u8) current index in program stack
; ...buffers
#define DATA_EDITBUF	23	// (17) DATA_EDITBUF edit buffer to edit and display number

; ===== Flags in GPIO global register

; alternative General Purpose I/O register
#ifndef GPIOR0
#define GPIOR0	TWBR	// use TWI Bit Rate Registers
;#define GPIOR0	UBRRL	// use USART Baud Rate Register LOW
#endif

#define F_EDITON	0	// edit mode is on
#define F_XVALID	1	// register X is valid
#define F_RUNNING	2	// program is running
#define F_PROGRAM	3	// programming mode
#define F_ERROR		4	// soft error
#define F_OLDTRACE	5	// old trace flag
#define F_TRACE		6	// trace program GTO

; set flag
#define SET_EDITON	sbi _SFR_IO_ADDR(GPIOR0),F_EDITON	// set 'edit mode' flag
#define SET_XVALID	sbi _SFR_IO_ADDR(GPIOR0),F_XVALID	// set 'register X is valid' flag
#define SET_RUNNING	sbi _SFR_IO_ADDR(GPIOR0),F_RUNNING	// set 'running' flag
#define SET_PROGRAM	sbi _SFR_IO_ADDR(GPIOR0),F_PROGRAM	// set 'programming' flag
#define SET_ERROR	sbi _SFR_IO_ADDR(GPIOR0),F_ERROR	// set 'soft error' flag
#define SET_OLDTRACE	sbi _SFR_IO_ADDR(GPIOR0),F_OLDTRACE	// set 'old trace' flag
#define SET_TRACE	sbi _SFR_IO_ADDR(GPIOR0),F_TRACE	// set 'trace' flag

; clear flag
#define CLR_EDITON	cbi _SFR_IO_ADDR(GPIOR0),F_EDITON	// clear 'edit mode' flag
#define CLR_XVALID	cbi _SFR_IO_ADDR(GPIOR0),F_XVALID	// clear 'register X is valid' flag
#define CLR_RUNNING	cbi _SFR_IO_ADDR(GPIOR0),F_RUNNING	// clear 'running' flag
#define CLR_PROGRAM	cbi _SFR_IO_ADDR(GPIOR0),F_PROGRAM	// clear 'programming' flag
#define CLR_ERROR	cbi _SFR_IO_ADDR(GPIOR0),F_ERROR	// clear 'soft error' flag
#define CLR_OLDTRACE	cbi _SFR_IO_ADDR(GPIOR0),F_OLDTRACE	// clear 'old trace' flag
#define CLR_TRACE	cbi _SFR_IO_ADDR(GPIOR0),F_TRACE	// clear 'trace' flag

; IF = execute following instruction if flag is set (skip if clear)
#define IF_EDITON	sbic _SFR_IO_ADDR(GPIOR0),F_EDITON	// execute if 'edit mode' flag
#define IF_XVALID	sbic _SFR_IO_ADDR(GPIOR0),F_XVALID	// execute if 'register X is valid' flag
#define IF_RUNNING	sbic _SFR_IO_ADDR(GPIOR0),F_RUNNING	// execute if 'running' flag
#define IF_PROGRAM	sbic _SFR_IO_ADDR(GPIOR0),F_PROGRAM	// execute if 'programming' flag
#define IF_ERROR	sbic _SFR_IO_ADDR(GPIOR0),F_ERROR	// execute if 'soft error' flag
#define IF_OLDTRACE	sbic _SFR_IO_ADDR(GPIOR0),F_OLDTRACE	// execute if 'old trace' flag
#define IF_TRACE	sbic _SFR_IO_ADDR(GPIOR0),F_TRACE	// execute if 'trace' flag

; IFN = execute following instruction if flag is not set (skip if is set)
#define IFN_EDITON	sbis _SFR_IO_ADDR(GPIOR0),F_EDITON	// execute if not 'edit mode' flag
#define IFN_XVALID	sbis _SFR_IO_ADDR(GPIOR0),F_XVALID	// execute if not 'register X is valid' flag
#define IFN_RUNNING	sbis _SFR_IO_ADDR(GPIOR0),F_RUNNING	// execute if not 'running' flag
#define IFN_PROGRAM	sbis _SFR_IO_ADDR(GPIOR0),F_PROGRAM	// execute if not 'programming' flag
#define IFN_ERROR	sbis _SFR_IO_ADDR(GPIOR0),F_ERROR	// execute if not 'soft error' flag
#define IFN_OLDTRACE	sbis _SFR_IO_ADDR(GPIOR0),F_OLDTRACE	// execute if not 'old trace' flag
#define IFN_TRACE	sbis _SFR_IO_ADDR(GPIOR0),F_TRACE	// execute if not 'trace' flag

#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)
#define F_DEBUG		7	// debug mode
#define SET_DEBUG	sbi _SFR_IO_ADDR(GPIOR0),F_DEBUG	// set 'debug' flag
#define CLR_DEBUG	cbi _SFR_IO_ADDR(GPIOR0),F_DEBUG	// clear 'debug' flag
#define IF_DEBUG	sbic _SFR_IO_ADDR(GPIOR0),F_DEBUG	// execute if 'debug' flag
#define IFN_DEBUG	sbis _SFR_IO_ADDR(GPIOR0),F_DEBUG	// execute if not 'debug' flag
#endif

; ===== Switches

; angle unit DATA_UNIT
#define UNIT_DEG	0	// degrees
#define UNIT_RAD	1	// radians
#define UNIT_GRAD	2	// grads

#define FIX_OFF		9	// fix decimals are off

#define CLEARKEY	0xff	// code to clear program memory

; ===== Registers
; Y = reserved as pointer to data area
; R0 and R1 = temporary, result of multiplication, destroyed
#define R_ZERO	R2	// zero register

#define R_LITL	R4	// literal pointer LOW (must be LOW to R_LITH)
#define R_LITH	R5	// literal pointer HIGH (must be HIGH to R_LITL)

#define R_PARAM	R16	// calc parameter register
