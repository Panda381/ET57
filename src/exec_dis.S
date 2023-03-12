; ****************************************************************************
;
;                            Execute display
;
; ****************************************************************************

#include "include.inc"

	.text

; switches
; --- pos 0 (3)
TextDeg:
	.asciz	"Deg"
	.balign 2

TextRad:
	.asciz	"Rad"
	.balign 2

TextGrd:
	.asciz	"Grd"
	.balign 2

; --- pos 3 (4)
.global TextFix
TextFix:
	.asciz	"Fix"
	.balign 2

; --- pos 7 (2)
TextEE:
	.asciz	"EE"
	.balign 2

; --- pos 9 (3)
Text2nd:
	.asciz	"2nd"
	.balign 2

; --- pos 12 (3)
TextInv:
	.asciz	"INV"
	.balign 2

Text4spc:
	.asciz	"    "
	.balign 2

TextPgm:
	.asciz "Pgm"
	.balign 2

; --- pos 15

; operators
OperTab:
	.byte	' '		; #define OPER_NONE	0	// no arithmetics operation
	.byte	'+'		; #define OPER_PLUS	1	// +
	.byte	'-'		; #define OPER_MINUS	2	// -
	.byte	'*'		; #define OPER_MUL	3	// *
	.byte	':'		; #define OPER_DIV	4	// :
	.byte	'/'		; #define OPER_MOD	5	// backslash
	.byte	'^'		; #define OPER_POWER	6	// ^
	.byte	'V' ;CHAR_ROOT	; #define OPER_ROOT	7	// root
	.balign 2

; ----------------------------------------------------------------------------
;              Display flags (not if running or programming)
; ----------------------------------------------------------------------------
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global DispFlags
DispFlags:

; ----- must not be running

	IF_RUNNING		; program running?
	ret			; program is running

; ----- must not be programming

	IF_PROGRAM		; programming?
	ret			; programming


.global DispFlags2
DispFlags2:

#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)

; ----- not in debug mode

	IF_DEBUG		; debug mode?
	ret
#endif

; ----- push registers

	push	r24
	push	r30
	push	r31

; ----- set start position
; DESTROYS: -
	rcall	DispSetRow1	; set cursor to start of ROW1

; ----- angle unit (3 characters)
;#define UNIT_DEG	0	// degrees
;#define UNIT_RAD	1	// radians
;#define UNIT_GRAD	2	// grads
	ldd	r24,Y+DATA_UNIT		; angle unit
	ldi	r30,lo8(TextDeg)
	ldi	r31,hi8(TextDeg)
	cpi	r24,UNIT_RAD		; radians?
	brcs	1f			; deg
	ldi	r30,lo8(TextRad)
	ldi	r31,hi8(TextRad)
	breq	1f			; rad
	ldi	r30,lo8(TextGrd)
	ldi	r31,hi8(TextGrd)
; INPUT: R31:R30 = text in ROM (terminated with 0)
; DESTROYS: R31, R30, R24
1:	rcall	DispTextRom		; display text

; ----- fix decimal places (4 characters)

	ldd	r24,Y+DATA_FIX
	cpi	r24,FIX_OFF
	brne	2f

	ldi	r30,lo8(Text4spc)
	ldi	r31,hi8(Text4spc)
	rcall	DispTextRom		; display space
	rjmp	3f

2:	ldi	r30,lo8(TextFix)
	ldi	r31,hi8(TextFix)
	rcall	DispTextRom		; display text Fix

	ldd	r24,Y+DATA_FIX
	subi	r24,-'0'
	rcall	DispChar		; display fix

; ----- display EE

3:	ldi	r30,lo8(Text4spc+2)	; text 2 spaces
	ldi	r31,hi8(Text4spc+2)
	rcall	FlagTestEE		; test EE
	breq	4f			; EE not set
	ldi	r30,lo8(TextEE)
	ldi	r31,hi8(TextEE)
4:	rcall	DispTextRom		; display text EE

; ----- display 2nd

	ldi	r30,lo8(Text4spc+1)	; text 3 spaces
	ldi	r31,hi8(Text4spc+1)
	rcall	FlagTest2nd		; test 2nd
	breq	5f			; 2nd not set
	ldi	r30,lo8(Text2nd)
	ldi	r31,hi8(Text2nd)
5:	rcall	DispTextRom		; display text 2nd

; ----- display INV

	ldi	r30,lo8(Text4spc+1)	; text 3 spaces
	ldi	r31,hi8(Text4spc+1)
	rcall	FlagTestInv		; test INV
	breq	6f			; INV not set
	ldi	r30,lo8(TextInv)
	ldi	r31,hi8(TextInv)
6:	rcall	DispTextRom		; display text Inv

; ----- open arithmetics operation (1 character)
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current operation
	andi	r24,OPER_MASK	; mask operation
	ldi	r30,lo8(OperTab)
	ldi	r31,hi8(OperTab) ; table of operators
	add	r30,r24
	adc	r31,R_ZERO
	lpm	r24,Z		; load character from table

	cpi	r24,' '
	brne	8f		; operator is valid

	ldd	r30,Y+DATA_LEVEL ; current level
	tst	r30		; base level?
	breq	8f		; base level

	ldi	r24,'('		; open parenthessis
; INPUT: R24 = character or data
; DESTROYS: -
8:	rcall	DispChar

; ----- pop registers

	pop	r31
	pop	r30
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                     Display 2 digits in BIN mode
; ----------------------------------------------------------------------------
; INPUT: R24 = number
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global Disp2Dig
Disp2Dig:
	push	r24
	push	r25

; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
	rcall	DivB10		; split tens -> R22, R24
	subi	r24,-'0'	; convert 'tens' to ASCII
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display tens

	mov	r24,r25		; low digit (ones)
	subi	r24,-'0'	; convert 'ones' to ASCII
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display ones

	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                     Display 3 digits in BIN mode
; ----------------------------------------------------------------------------
; INPUT: R24 = number
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

#if 0

.global Disp3Dig
Disp3Dig:
	push	r24
	push	r25

; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
	rcall	DivB10		; split hundreds
	push	r25
	rcall	DivB10

	subi	r24,-'0'	; convert 'hundreds' to ASCII
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display hundreds

	mov	r24,r25		; low digit (tens)
	subi	r24,-'0'	; convert 'tens' to ASCII
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display ones

	pop	r24		; low digit (ones)
	subi	r24,-'0'	; convert 'ones' to ASCII
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display ones

	pop	r25
	pop	r24
	ret

#endif

; ----------------------------------------------------------------------------
;                      Display current program row
; ----------------------------------------------------------------------------
; INPUT: R24 = start cursor position
; DESTROYS: R31, R30, R27, R26, R25, R24, R1, R0
; ----------------------------------------------------------------------------
; _______INV GTO 2
; Pgm1,_12: -34 2_

DispProg2:

; ----- set cursor position
; INPUT: R24 = position 0..15, add ROW1 or ROW2
; DESTROYS: -
	rcall	DispSetPos	; set cursor position

; ----- display current program

	ldi	r30,lo8(TextPgm)
	ldi	r31,hi8(TextPgm)
	rcall	DispTextRom
	ldd	r24,Y+DATA_PROGINX
	subi	r24,-'0'
	rcall	DispChar

; ----- some spaces

	rcall	DispSpc
	rcall	DispSpc

; ----- display address (2 digits)

	ldd	r26,Y+DATA_ADDR
	ldd	r27,Y+DATA_ADDR+1
	mov	r24,r26
	ldd	r30,Y+DATA_PROGBEG
	sub	r24,r30
; INPUT: R25:R24 = number
; DESTROYS: -
	rcall	Disp2Dig	; display address
	ldi	r24,':'
	rcall	DispChar
	rcall	DispSpc

; ---- Load one byte from program
; INPUT: R27:R26 (X) = address (can be out of range)
; OUTPUT: R24 = byte (0 if invalid)
;	  R27:R26 (X+1) = new address, increased by 1 (not changed on error)
;	  CY = invalid address (R27:R26 not changed)
; DESTROYS: -
	rcall	LoadByte
	brcs	9f		; invalid address

; ----- remap to key code
; INPUT: R24 = program code CMD_*
; OUTPUT: R24 = key code KEY_* (including INV flag) (or KEY_NOP if command not found)
;	  R25 = parameter 0..9, or NOKEY 255 = no parameter
; DESTROYS: R1, R0
	rcall	CmdKey		; remap program code to key code

; ----- display INV separator

	ldi	r30,' '		; no INV flag
	cpi	r24,INV_SHIFT
	brcs	2f
	subi	r24,INV_SHIFT
	ldi	r30,'-'		; INV flag
2:	push	r24
	mov	r24,r30
	rcall	DispChar
	pop	r24

; ----- display key code
; INPUT: R24 = number
; DESTROYS: R1, R0
2:	rcall	Disp2Dig	; display 2 digits
	rcall	DispSpc

; ----- display parameter

	ldi	r24,' '
	cpi	r25,NOKEY	; valid parameter?
	breq	4f		; no parameter
	mov	r24,r25		; parameter
	subi	r24,-'0'	; convert to ASCII code
4:	rcall	DispChar	; display code

; ----- clear rest of line
; DESTROYS: -
9:	rjmp	DispSpcClr

; ----------------------------------------------------------------------------
;           Display flags, number X or programming (not if running)
; ----------------------------------------------------------------------------
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global Disp
Disp:

; ----- display flags (not if running, not if programming)
; DESTROYS: -
	rcall	DispFlags

; ----- display X or edit buffer (not if running, not if programming)
; DESTROYS: R0

	rcall	DispEdit

; ----- display programming (only if programming)
; DESTROYS: -

; DispProg must follow

; ----------------------------------------------------------------------------
;                Display programming mode (only if programming)
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispProg
DispProg:

; ----- check programming

	IFN_PROGRAM		; programming?
	ret			; no programming

; ----- push registers

	push	r24
	push	r25
	push	r26
	push	r27
	push	r30
	push	r31

; ----- display 1st row

	; set cursor position
; DESTROYS: -
	rcall	DispSetRow1	; set cursor to start of ROW1

	; skip some spaces
	ldi	r24,5
	rcall	DispSpcPos	; skip spaces to position

; ----- prepare address

	ldd	r26,Y+DATA_ADDR
	ldd	r27,Y+DATA_ADDR+1

; ---- Load one byte from program
; INPUT: R27:R26 (X) = address (can be out of range)
; OUTPUT: R24 = byte (0 if invalid)
;	  R27:R26 (X+1) = new address, increased by 1 (not changed on error)
;	  CY = invalid address (R27:R26 not changed)
; DESTROYS: -
	rcall	LoadByte
	brcs	8f		; invalid address

; ----- remap to key code
; INPUT: R24 = program code CMD_*
; OUTPUT: R24 = key code KEY_* (including INV flag) (or KEY_NOP if command not found)
;	  R25 = parameter 0..9, or NOKEY 255 = no parameter
; DESTROYS: R1, R0
	rcall	CmdKey		; remap program code to key code

; ----- display INV flag

	cpi	r24,INV_SHIFT
	brcs	1f
	subi	r24,INV_SHIFT

	push	r24
	ldi	r30,lo8(TextInv)
	ldi	r31,hi8(TextInv)
	rcall	DispTextRom	; display text "INV"
	rcall	DispSpc		; display space
	pop	r24
	rjmp	2f

1:	push	r24
	ldi	r30,lo8(Text4spc)
	ldi	r31,hi8(Text4spc)
	rcall	DispTextRom	; display 4 spaces
	pop	r24

; ----- display name of program byte
; INPUT: R24 = code
; OUTPUT: R31:R30 = ASCIIZ text in ROM
; DESTROYS: R25
2:	push	r25
	rcall	GetDispName	; get text of key

; INPUT: R31:R30 = text in ROM (terminated with 0)
; DESTROYS: R31, R30, R24
	rcall	DispTextRom	; display text
	pop	r25

; ----- display parameter

	cpi	r25,NOKEY
	breq	8f
	rcall	DispSpc		; display space
	mov	r24,r25
	subi	r24,-'0'
	rcall	DispChar	; display parameter

; ----- clear rest of line
; DESTROYS: -
8:	rcall	DispSpcClr

; ----- display 2nd row

	ldi	r24,ROW2+0	; address of ROW2
; INPUT: R24 = start cursor position
; DESTROYS: R31, R30, R27, R26, R25, R24, R1, R0
	rcall	DispProg2	; display program

; ----- pop registers

9:	pop	r31
	pop	r30
	pop	r27
	pop	r26
	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;         Display X or edit buffer (not if running or programming)
; ----------------------------------------------------------------------------
; OUTPUT: R1 = 0
; DESTROYS: R0
; ----------------------------------------------------------------------------

.global DispEdit
DispEdit:

; ----- must not be running

	IF_RUNNING		; running?
	ret			; program is running, no display

; ----- must not be programming

	IF_PROGRAM		; programming?
	ret			; programming, no display
	
; ----- if not edit mode, decode X into edit buffer
; DESTROYS: R0

.global DispEdit2
DispEdit2:

; ----- push registers

	push	r24
	push	r25
	push	r26
	push	r27
	push	r30
	push	r31

; ----- decode X into edit buffer

	IF_EDITON		; if edit mode
	rjmp	2f		; skip decode X

; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load number X into calculator stack
; CALCULATOR STACK: -1
; DESTROYS: all
	rcall	DecNum		; decode number

; ----- display debug mode

2:
#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)

	IFN_DEBUG		; if not debug mode
	rjmp	6f		; not debug mode

	rcall	DispSetRow1	; set cursor to start of ROW1
	ldi	r30,lo8(BaseReg + (REG_X+REG_SYS_SHIFT)*BNUM_BYTES + 1)
	ldi	r31,hi8(BaseReg + (REG_X+REG_SYS_SHIFT)*BNUM_BYTES + 1)
	ldi	r25,BMANT_BYTES
4:	ld	r24,Z+
	rcall	DispHexB
	dec	r25
	brne	4b
#endif

; ----- set cursor to start of row 2
	; set cursor position
; DESTROYS: -
6:	rcall	DispSetRow2	; set cursor to start of ROW2

; ----- display edit buffer (buffer is terminated by 0)
; INPUT: R31:R30 = text in RAM (terminated with 0)
; DESTROYS: R31, R30, R24
	ldi	r30,lo8(EditBuf)
	ldi	r31,hi8(EditBuf)
	rcall	DispTextRam

; ----- pop registers

	pop	r31
	pop	r30
	pop	r27
	pop	r26
	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                          display C
; ----------------------------------------------------------------------------

.global EditStopDispC
EditStopDispC:

	rcall	EditStop	; stop edit

.global DispC
DispC:

	push	r24

;------ clear 1st row
; DESTROYS: -
	rcall	DispSetRow1	; set cursor to start of ROW1
	rcall	DispSpcClr	; clear rest of line

; ----- display 'C' on 2nd row
; DESTROYS: -
	rcall	DispSetRow2	; set cursor to start of ROW2
	ldi	r24,'C'
	rcall	DispChar	; display character 'C'
	rcall	DispSpcClr	; clear rest of line

	pop	r24
	ret

; ----------------------------------------------------------------------------
;                            Indicate error
; ----------------------------------------------------------------------------
; DESTROYS: R27, R26, R25, R24
; ----------------------------------------------------------------------------

.global DispErr
DispErr:

; ----- display running flag

	IF_RUNNING		; if running
	rjmp	DispC		; display "C"

; ----- not if programming
	
	IF_PROGRAM		; programming?
	ret			; programming, no display

; ----- display flags

	rcall	DispFlags2

; ----- check time to indicate error (granularity 10 ms, blinking period 0.6 sec)

	ldd	r25,Y+DATA_TIME
	andi	r25,0x7f
	cpi	r25,64
	brcs	2f

; ----- display X or edit buffer

	rjmp	DispEdit

; ----- set cursor to start of row 2
; DESTROYS: -
2:	rcall	DispSetRow2	; set cursor to start of ROW2

; ----- display character 'F' or 'E'

	ldi	r24,'E'		; Error mark
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar

; ----- clear rest of row

; DESTROYS: -
	rjmp	DispSpcClr

; ----------------------------------------------------------------------------
;                    Display trace (holding GTO, only if running)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27, R26, R25, R24, T flag
; ----------------------------------------------------------------------------

.global DispTrace
DispTrace:

; ----- must be running (alredy tested in main)

;	IFN_RUNNING		; if not running
;	ret			; program is not running

; ----- display 'C' if was tracing and not now

	IFN_OLDTRACE		; if not old trace
	rjmp	2f		; skip if was not tracing previously
	IFN_TRACE		; if not trace
	rcall	DispC		; if not trace, display C and clear 1st row

; ----- update old trace flag

2:	SET_OLDTRACE		; set old trace flag
	IFN_TRACE		; if not trace
	CLR_OLDTRACE		; if not trace, clear old trace flag

; ----- return if not trace

	IFN_TRACE		; if not trace
	ret			; return if not trace

; ----- display program code on 1st row

#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)

	IF_DEBUG		; debug mode?
	rjmp	3f		; skip in debug mode
#endif

	ldi	r24,0+ROW1
; INPUT: R24 = start cursor position
; DESTROYS: R31, R30, R27, R26, R25, R24
	rcall	DispProg2		; display program code

; ----- display X or edit buffer on 2nd row

3:	rcall	DispEdit2		; display X or edit buffer

; ----- wait some time
; DESTROYS: R24
	rjmp	Wait500ms	; wait 500 ms
