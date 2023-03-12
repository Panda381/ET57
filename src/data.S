; ****************************************************************************
;
;                                Data
;
; ****************************************************************************

#include "include.inc"

	.data

; ===== Y data area (max. 64 bytes)

; Start of data area pointed by Y registers (to reduce program size; max. 64 bytes)
.global DataStart
	.lcomm DataStart,0

; ...general flags
.global Flags			; 0: (u8) DATA_FLAGS general flags F_*
	.lcomm Flags,1
; B0: F_INV INV flag
; B1: F_2ND 2nd flag
; B2: F_EE EE mode
; B3: F_DP decimal point entered
; B4: F_EXP entering exponent
; B5: F_SPIERR stop on SPI error
; B6: F_RESDEC restart DecNum function
; B7: F_EXPDIG exponent digits

; ...display
.global PosX			; 1: (u8) DATA_POSX display X position
	.lcomm PosX,1

; ...keyboard
.global Time			; 2: (u8) DATA_TIME time counter, granularity 10 ms
	.lcomm Time,1

.global KeyRaw			; 3: (u8) DATA_KEYRAW current pressed raw key, NOKEY=no key
	.lcomm KeyRaw,1

.global KeyCnt			; 4: (u8) DATA_KEYCNT key press time counter
	.lcomm KeyCnt,1

.global Key			; 5: (u8) DATA_KEY key pressed, NOKEY=no key
	.lcomm Key,1

.global KeySave			; 6: (u8) DATA_KEYSAVE saved key, NOKEY=no key
	.lcomm KeySave,1

; ...calculator
.global StkEnd			; 7: (u16) DATA_STKEND end of calculator stack
	.lcomm StkEnd,2

.global Level			; 9: (u8) DATA_LEVEL current level of arithmetics operations
	.lcomm Level,1

.global Last			; 10: (u8) DATA_LAST last arithmetics operation (OPER_*)
	.lcomm Last,1

; ...editor
.global EditDig			; 11: (u8) DATA_EDITDIG number of digits of mantissa in edit mode (including decimal point and sign)
	.lcomm EditDig,1

.global	Fix			; 12: (u8) DATA_FIX fix decimals (0..8 digits or FIX_OFF=off)
	.lcomm Fix,1

; ...program

.global Unit			; 13: (u8) DATA_UNIT angle unit UNIT_*
	.lcomm Unit,1

.global Addr			; 14: (u16) DATA_ADDR program address - edit or run, absolute address, can point behind the end
	.lcomm Addr,2

.global ProgInx			; 16: (u8) DATA_PROGINX index of current program (0=main)
	.lcomm ProgInx,1

.global ProgNext		; 17: (u8) DATA_PROGNEXT next program index (0=main)
	.lcomm ProgNext,1

.global ProgBeg			; 18: (u16) DATA_PROGBEG start address of current program (= first byte)
	.lcomm ProgBeg,2

.global ProgEnd			; 20: (u16) DATA_PROGEND end address of current program (= last byte)
	.lcomm ProgEnd,2

.global ProgLevel		; 22: (u8) DATA_PROGLEVEL current index in program stack (0=not running)
	.lcomm ProgLevel,1

; ===== buffers

.global EditBuf			; 23: (17) DATA_EDITBUF edit buffer to edit and display number
	.lcomm EditBuf,EDITBUF_SIZE+1

.global BaseReg			; base registers
	.lcomm BaseReg,BASE_NUM*BNUM_BYTES

.global MemReg			; extended registers (with 1 register of random seed)
	.lcomm MemReg,(MEM_NUM2+1)*RNUM_BYTES

.global CalcStack		; calculator stack (with base registers, temp. registers, X and LAST)
	.lcomm CalcStack,CALC_MAX2*(CNUM_BYTES)

.global OperStack		; stack of arithmetics operations (combination of OPER_x, LEVEL_x and LOWER_x)
	.lcomm OperStack,CALC_MAX

.global ProgStackAddr		; stack of return addresses
	.lcomm ProgStackAddr,PROGSTACK_NUM*2

.global ProgStackInx		; stack of program indices
	.lcomm ProgStackInx,PROGSTACK_NUM
