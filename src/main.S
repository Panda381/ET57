; ****************************************************************************
;
;                                 Main
;
; ****************************************************************************

#include "include.inc"

	.text

#ifdef DOTEST
BadNopTxt:
	.asciz	"Bad NOP"
	.balign 2
#endif

; ----------------------------------------------------------------------------
;                   Display calculator version
; ----------------------------------------------------------------------------

.global DispBuild
DispBuild:

	rcall	DispSetRow1
	ldi	r30,lo8(Build)
	ldi	r31,hi8(Build)
	rcall	DispTextRom	; display error text
	rcall	DispSpcClr	; clear rest of the row

	rcall	Wait1s		; wait some time (1 second)

	rjmp	DispFlags	; clear 1st row

; ----------------------------------------------------------------------------
;                        Port inizialize
; ----------------------------------------------------------------------------

.global PortInit
PortInit:

#ifdef HW_ET57				// use hardware of ET-57

; ----- initialize port B
; PB0: DB5 output LOW
; PB1: DB6 output LOW
; PB2: DB7 output LOW
; PB3: MOSI output LOW
; PB4: MISO input pull-up
; PB5: SCK output
; PB6: COL2 input
; PB7: COL1 input

	ldi	r24,B4
	out	_SFR_IO_ADDR(PORTB),r24 ; set pull-ups and outputs
	ldi	r24,B0+B1+B2+B3+B5
	out	_SFR_IO_ADDR(DDRB),r24	; set outputs

; ----- initialize port C
; PC0: ROW3 input pull-up
; PC1: ROW2 input pull-up
; PC2: ROW4 input pull-up
; PC3: ROW5 input pull-up
; PC4: COL5 input
; PC5: ROW1 input pull-up

	ldi	r24,B0+B1+B2+B3+B5
	out	_SFR_IO_ADDR(PORTC),r24	; set pull-ups and outputs
	out	_SFR_IO_ADDR(DDRC),R_ZERO ; all pins are inputs

; ----- initialize port D
; PD0: ROW6 input pull-up
; PD1: ROW7 input pull-up
; PD2: COL4 input
; PD3: COL3 input
; PD4: ROW8 input pull-up
; PD5: RS output LOW
; PD6: E output LOW
; PD7: DB4 output LOW

	ldi	r24,B0+B1+B4
	out	_SFR_IO_ADDR(PORTD),r24	; set pull-ups and outputs
	ldi	r24,B5+B6+B7
	out	_SFR_IO_ADDR(DDRD),r24	; set outputs

#else

; ----- initialize port B, reset LCD display
; PB0: ROW4 input pull-up
; PB1: ROW6 input pull-up
; PB2: COL2 input
; PB3: ROW8 input pull-up
; PB4: ROW1 input pull-up
; PB5: COL3 input
; PB6: RS output LOW
; PB7: LCD output HIGH

	ldi	r24,B0+B1+B3+B4+B7
	out	_SFR_IO_ADDR(PORTB),r24	; set pull-ups and outputs
	ldi	r24,B6
	out	_SFR_IO_ADDR(DDRB),r24	; set outputs, LCD is OFF
	rcall	Wait10ms		; wait 10 ms
	ldi	r24,B6+B7
	out	_SFR_IO_ADDR(DDRB),r24	; set outputs, LCD is ON

; ----- initialize port C
; PC0: ROW9 input pull-up
; PC1: COL4 input
; PC2: ROW7 input pull-up
; PC3: COL5 input
; PC4: ROW5 input pull-up
; PC5: ROW3 input pull-up

	ldi	r24,B0+B2+B4+B5
	out	_SFR_IO_ADDR(PORTC),r24	; set pull-ups and outputs
	out	_SFR_IO_ADDR(DDRC),R_ZERO ; all pins are inputs

; ----- initialize port D
; PD0: DB7 output LOW
; PD1: DB6 output LOW
; PD2: DB5 output LOW
; PD3: DB4 output LOW
; PD4: E output LOW
; PD5: COL1 input
; PD6: VO2 output LOW (OC0A)
; PD7: ROW2 input pull-up

	ldi	r24,B7
	out	_SFR_IO_ADDR(PORTD),r24	; set pull-ups and outputs
	ldi	r24,B0+B1+B2+B3+B4+B6
	out	_SFR_IO_ADDR(DDRD),r24	; set outputs

#endif
	ret

; ----------------------------------------------------------------------------
;                         Initialize random number gerenator
; ----------------------------------------------------------------------------

RandInit:

; ----- load random seed

	ldi	r24,MEM_NUM2
	call	CalcAddrRMem	; get number address -> Z
	ldi	r26,lo8(CFG_SEED)
	ldi	r27,hi8(CFG_SEED)
	ldi	r23,RNUM_BYTES	; length
2:	rcall	EERead		; read byte from EEPROM
	st	Z+,r24
	adiw	r26,1
	dec	r23
	brne	2b

; ----- number not initialized, set to 0

	ldi	r24,MEM_NUM2
	call	CalcAddrRMem	; get number address -> Z
	ldd	r24,Z+1		; sign
	cpi	r24,0x10	; valid number?
	brcs	3f		; number is OK
	call	NumSet0		; set number 0

; ----- shift number (coefficients are used in incorrect way to ensure another path of numbers)
;   Seed = (Seed*2531011 + 214013) mod 4294967296

3:	call	Calc
	.byte	C_GETSEED		; load seed (s)
	.byte	C_CONST(CONST_RANDC)	; load addition (s*a,c)
	.byte	C_MUL			; multiply (s*a)
	.byte	C_CONST(CONST_RANDA)	; load multiplier (s,a)
	.byte	C_ADD			; add (s*a+c)
	.byte	C_CONST(CONST_RANDM)	; load modulus (s*a+c,m)
	.byte	C_MOD			; modulus (s)
	.byte	C_SETSEED		; save seed (s)
	.byte	C_DEL			; delete
	.byte	C_END		; end
	.balign 2		; align

; ----- save random seed

	ldi	r24,MEM_NUM2
	call	CalcAddrRMem	; get number address -> Z
	ldi	r26,lo8(CFG_SEED)
	ldi	r27,hi8(CFG_SEED)
	ldi	r23,RNUM_BYTES	; length
4:	ld	r25,Z+
	rcall	EEWrite		; write byte into EEPROM
	adiw	r26,1
	dec	r23
	brne	4b
	ret

; ----------------------------------------------------------------------------
;                      Fatal error (and stop program)
; ----------------------------------------------------------------------------

.global Fatal
Fatal:
	cli			; disable interrupts
	call	CalcInit	; inicialize calculator stack
	rcall	StopProg	; stop program

	ldi	r24,lo8(STACK)	; end of stack (= last byte of RAM)
	ldi	r25,hi8(STACK)
	out	_SFR_IO_ADDR(SPH),r25
	out	_SFR_IO_ADDR(SPL),r24

	SET_ERROR		; set error flag

	rjmp	Restart

; ----------------------------------------------------------------------------
;                    System reset, start main function
; ----------------------------------------------------------------------------

; Reset
.global main
main:

; ----- initialize global registers

	clr	R_ZERO		; register '0'
	ldi	YL,lo8(DataStart) ; data area LOW
	ldi	YH,hi8(DataStart) ; data area HIGH

; ----- initialize status register

	out	_SFR_IO_ADDR(SREG),R_ZERO

; ----- clear whole RAM memory (initialize to 0)

	ldi	r30,lo8(RAM_BEG)
	ldi	r31,hi8(RAM_BEG)
	ldi	r25,hi8(RAM_END)
1:	st	Z+,R_ZERO
	cpi	r30,lo8(RAM_END)
	cpc	r31,r25
	brne	1b

; ----- initialize stack

	ldi	r24,lo8(STACK)	; end of stack (= last byte of RAM)
	ldi	r25,hi8(STACK)
	out	_SFR_IO_ADDR(SPH),r25
	out	_SFR_IO_ADDR(SPL),r24

; ----- initialize ports

	rcall	PortInit

; ----- ET-58 hardware: system clock starts with 1 MHz (CKDIV8 is programmed), set system clock to 4 MHz

#ifdef HW_ET58				// use hardware of ET-58
	ldi	r24,BIT(CLKPCE)
#if F_CPU >= 6000000
	ldi	r25,0				; divide 8MHz /1
#else
	ldi	r25,1				; divide 8MHz /2
#endif
	sts	CLKPR,r24		; enable
	sts	CLKPR,r25
#endif

; ----- some wait

	rcall	Wait250ms

; ----- LCD initialize

	rcall	LCD_Init		; initialice LCD

; ----- initialize keyboard

	rcall	KEY_Init

; ----- initialize SPI interface

#ifdef HW_ET57				// use hardware of ET-57
	rcall	SPI_Init
#endif

; ----- default rounding

	ldi	r24,FIX_OFF
	std	Y+DATA_FIX,r24

; ----- clear edit buffer

	rcall	ExecClr

; ----- display calculator version

	rcall	DispBuild

; ----- open main program
; INPUT: R24 = program index (0=main)
; DESTROYS: R31, R30, R24, R0
	clr	r24
	rcall	OpenProg

; ----- initialize random number generator

	rcall	RandInit

; ----- restart after fatal and after wake-up

.global Restart
Restart:

; ----- enable interrupts

	sei

; ----- some internal tests

#ifdef DOTEST

	; check CMD_NOP code
#if CMD_NOP != 255
	rcall	DispSetRow1
	ldi	r30,lo8(BadNopTxt)
	ldi	r31,hi8(BadNopTxt)
	rcall	DispTextRom
2:	rjmp	2b
#endif
	
#endif

; ----- re-initialize LCD again (on short power error)

#ifdef HW_ET58				// use hardware of ET-58
	rcall	LCD_Init
	rcall	Disp
#endif

Loop:

; ----- running program: execute next command

	IFN_RUNNING		; if not running
	rjmp	4f		; not running

; ----- display trace (if running)

	rcall	DispTrace

; OUTPUT: R24 = byte (0 on error)
;	  CY = invalid address (address not changed)
; DESTROYS: -
	rcall	LoadPrg		; load byte of program
	brcs	4f		; invalid address

	; execute one key
	rcall	ExecCmd

	; check break program
	rcall	BreakKey
	rjmp	Loop

; ----- execute user key
; OUTPUT: R24 = program code 0..255 CMD_* (if NC) or key code 0..179 KEY_* (if CY) or NOKEY (if CY)
;	  CY = set if program code is not valid (returns key code or NOKEY)
; DESTROYS: R1, R0, R30, R31, R25
; NOTE: Enables interrupts
4:	rcall	GetKeyCmd
	brcs	6f		; command is not valid

	; check if programming
	IF_PROGRAM		; programming?
	rjmp	5f		; programming

	; execute program code
	rcall	ExecCmd		; execute program code
	rjmp	1f

	; programming program code
5:	rcall	ProgramCmd	; programming program code
	rjmp	1f

	; execute key code
6:	rcall	ExecKey		; execute key code

; ----- indicate error (here is not running)

1:	IFN_ERROR		; test soft error
	rjmp	Loop		; not error

	rcall	DispErr		; indicate error
	rjmp	Loop
