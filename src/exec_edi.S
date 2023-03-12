; ****************************************************************************
;
;                            Execute edit and display
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                  Clear edit buffer (set to value '0')
; ----------------------------------------------------------------------------
; DESTROYS: R27, R26, R24
; ----------------------------------------------------------------------------

.global EditBufClear
EditBufClear:

	; clear flags
	rcall	FlagClrDP	; decimal point not entered
	rcall	FlagClrExp	; exponent not entered
	rcall	FlagClrExpDig	; clear flag 'exponent digits'
	ldi	r24,2		; 2 characters = sign and 0
	std	Y+DATA_EDITDIG,r24 ; set number of mantissa digits to 2 '+0'

	; clear edit buffer
	ldi	r26,lo8(EditBuf) ; buffer
	ldi	r27,hi8(EditBuf)
	ldi	r24,' '
1:	st	X+,r24		; write space character
	cpi	r26,lo8(EditBuf+EDITBUF_SIZE)
	brne	1b
	st	X,R_ZERO	; terminating zero

	; set digit '0'
	ldi	r24,'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP-1,r24 ; write '0' digit
	ret

; ----------------------------------------------------------------------------
;                    Shift mantissa in edit buffer left
; ----------------------------------------------------------------------------
; INPUT: R23 = new inserted charater
; OUTPUT: C flag is set if cannot move (buffer is full)
; DESTROYS: R31, R30, R25, R24
; ----------------------------------------------------------------------------

.global EditBufShiftL
EditBufShiftL:

; ----- check free space

	ldd	r24,Y+DATA_EDITDIG ; number of digits of mantissa
	cpi	r24,MANT_LEN	; check mantissa size
	brcs	1f		; space is OK
	sec			; set error flag
	ret

; ----- increase text length

1:	inc	r24		; increase text length
	std	Y+DATA_EDITDIG,r24 ; save new number of digits

; ----- start address of mantissa

	ldi	r30,lo8(EditBuf+EDITBUF_MANT)
	ldi	r31,hi8(EditBuf+EDITBUF_MANT)

; ----- shift mantissa

	ldi	r25,MANT_LEN-1	; mantissa length - 1
3:	ldd	r24,Z+1
	st	Z+,r24
	dec	r25
	brne	3b

; ----- add new character

	st	Z,r23
	clc			; clear error flag
	ret

; ----------------------------------------------------------------------------
;                    Shift mantissa in edit buffer right
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R25, R24
; ----------------------------------------------------------------------------

.global EditBufShiftR
EditBufShiftR:

; ----- decrease text length

	ldd	r24,Y+DATA_EDITDIG ; number of digits of mantissa
	dec	r24		; decrease text length
	std	Y+DATA_EDITDIG,r24 ; save new number of digits

; ----- end address of mantissa

	ldi	r30,lo8(EditBuf+EDITBUF_EXP-1)
	ldi	r31,hi8(EditBuf+EDITBUF_EXP-1)

; ----- shift text

	ldi	r25,MANT_LEN-1	; mantissa length - 1
1:	ld	r24,-Z
	std	Z+1,r24
	dec	r25
	brne	1b

; ----- save first digit

	ldi	r24,' '
	st	Z,r24		; save first digit
	ret

; ----------------------------------------------------------------------------
;                          Start edit mode
; ----------------------------------------------------------------------------
; DESTROYS: R27, R26, R25, R24, R20
; ----------------------------------------------------------------------------

.global EditStart
EditStart:
	SET_EDITON		; set edit mode flag
; DESTROYS: R27, R26, R24
	rcall	EditBufClear	; clear edit buffer
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                    Stop edit mode and validate X
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R24, R1, R0
; ----------------------------------------------------------------------------

.global EditStop
EditStop:
	SET_XVALID		; set register X valid

.global EditStopNoX
EditStopNoX:

	; if not edit mode, no operation
	IFN_EDITON		; if not edit mode
	ret			; not edit mode, no operation

	; edit mode: clear edit mode flag
	CLR_EDITON		; clear edit mode flag
	SET_XVALID		; set register X valid

	; encode number from edit buffer to register X
; CALCULATOR STACK: +1
; DESTROYS: R1, R0
	rcall	EncNum		; encode number from edit buffer to calculator stack
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcSetMemDelX	; set register X

; DESTROYS: R1, R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                Stop edit mode, validate X and display C
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R24, R1, R0
; ----------------------------------------------------------------------------

.global EditStopC
EditStopC:
	rcall	EditStop	; stop edit mode and validate X
	IFN_RUNNING		; if not running
	rjmp	DispC		; display C
	ret

; ----------------------------------------------------------------------------
;                      Restart edit of current number X
; ----------------------------------------------------------------------------

.global EditRestart
EditRestart:
	; decode number into buffer
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load number X into calculator stack
; CALCULATOR STACK: -1
; DESTROYS: all
	rcall	DecNum		; decode number

	; set flags
	SET_EDITON		; set edit mode flag

	rcall	EncNum		; encode number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemDelX	; set register X

; ----------------------------------------------------------------------------
;                           Digit (0..9)
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecDig
ExecDig:

; ----- convert key code to ASCII character -> R23

	mov	r23,r24		; key code
	subi	r23,-'0'	; conver to character

; ----- start edit mode

	push	r23
	IFN_EDITON		; if not edit mode
	rcall	EditStart	; start edit mode (DESTROYS: R27, R26, R25, R24, R20)
	pop	r23

; ----- check mode - entering mantissa or exponent
; OUTPUT: NZ = flag is set
; DESTROYS: -
	rcall	FlagTestExp	; entering exponent?
	breq	ExecDig4	; not exponent

; ===== entering exponent

; ----- start new exponent

	rcall	FlagTestExpDig	; is exponent valid?
	brne	2f		; exponent already valid
	rcall	FlagSetExpDig	; set exponent mode
	ldi	r24,' '		; positive sign
	std	Y+DATA_EDITBUF+EDITBUF_EXP,r24 ; set sign
	ldi	r24,'0'		; digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r24 ; set second '0'

; ----- enter exponent digit

2:	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP+2 ; get second exponent digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+1,r24 ; set first exponent digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r23 ; save second exponent digit
; DESTROYS: R0
	rjmp	Disp		; display all

; ===== entering mantissa

ExecDig4:

; ----- if only one '0', delete it

	ldd	r24,Y+DATA_EDITDIG ; number of digits of mantissa
	cpi	r24,2		; only 1 digit?
	brne	5f		; more digits
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP-1 ; get last digit
	cpi	r24,'0'		; zero digit?
	brne	5f
; DESTROYS: R31, R30, R25, R24
	rcall	EditBufShiftR	; shift mantissa right (to delete last '0')

; ----- reserve space for decimal point

5:	ldd	r24,Y+DATA_EDITDIG ; number of digits of mantissa
	cpi	r24,MANT_LEN-1	; last character remains
	brne	6f
	rcall	FlagTestDP	; decimal point entered?
	brne	6f		; decimal point entered OK
	ret			; reserve 1 character

; ----- add new digit to end of buffer
; INPUT: R23 = new inserted charater
; OUTPUT: C flag is set if cannot move (buffer is full)
; DESTROYS: R31, R30, R25, R24
6:	rcall	EditBufShiftL	; add new digit to end of mantissa

; ----- display new edit buffer

; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                                 EE
; ----------------------------------------------------------------------------

.global ExecEE
ExecEE:

; ----- not in edit mode - cut number and start edit mode

	IFN_EDITON		; if not edit mode
	rcall	EditRestart	; restart edit of current number X

; ----- start exponent mode

	rcall	FlagTestExpDig	; exponent digits?
	brne	4f		; exponent digits already set
	rcall	FlagSetExpDig	; set exponent digits

	ldi	r24,'+'		; sign flag
	std	Y+DATA_EDITBUF+EDITBUF_EXP,r24 ; set sign
	ldi	r24,'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP+1,r24 ; set first exponent digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r24 ; set second exponent digit

; ----- set exponent mode

; DESTROYS: -
4:	rcall	FlagSetExp	; entering exponent mode
	rcall	FlagSetEE	; set exponent mode

; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                                 INV EE
; ----------------------------------------------------------------------------

.global ExecInvEE
ExecInvEE:

; ----- end exponent mode

; DESTROYS: -
	rcall	FlagClrEE	; clear exponent mode
	SET_XVALID		; set register X valid

; DESTROYS: -
	IF_EDITON		; if edit mode
	rcall	StopExp		; stop exponent mode and clear exponent if 0

; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                Stop exponent mode (and delete exponent if 0)
; ----------------------------------------------------------------------------

StopExp:

; DESTROYS: -
	rcall	FlagClrExp	; clear exponent flag

	; check if exponent is 00
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP+1 ; get first exponent digit
	cpi	r24,'0'		; zero exponent?
	brne	1f
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP+2 ; get second exponent digit
	cpi	r24,'0'		; zero exponent?
	brne	1f

	; delete exponent
	ldi	r24,' '
	std	Y+DATA_EDITBUF+EDITBUF_EXP,r24 ; clear sign
	std	Y+DATA_EDITBUF+EDITBUF_EXP+1,r24 ; clear first exponent digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r24 ; clear second exponent digit
	rcall	FlagClrExpDig	; clear exponent digits flag

1:	ret

; ----------------------------------------------------------------------------
;                            .
; ----------------------------------------------------------------------------

.global ExecDot
ExecDot:

; ----- start edit mode

	IFN_EDITON		; if not edit mode
	rcall	EditStart	; start edit mode (DESTROYS: R27, R26, R25, R24, R20)

; ----- stop exponent mode

	rcall	FlagClrExp	; clear exponent flag

; ----- add decimal point

; OUTPUT: NZ = flag is set
; DESTROYS: -
	rcall	FlagTestDP	; check decimal point
	brne	4f		; decimal point already entered
	ldi	r23,'.'
; INPUT: R23 = new inserted charater
; OUTPUT: C flag is set if cannot move (buffer is full)
; DESTROYS: R31, R30, R25, R24
	rcall	EditBufShiftL	; add new digit to end of mantissa
	brcs	4f		; buffer is full
; DESTROYS: -
	rcall	FlagSetDP	; set dot flag

; ----- display new edit buffer

; DESTROYS: R0
4:	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                           Fix
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecFix
ExecFix:

	push	r24
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode and set X valid
	pop	r24
	rjmp	2f


.global ExecInvFix
ExecInvFix:
	; INV - turn FIX off
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode and set X valid

	ldi	r24,FIX_OFF
2:	std	Y+DATA_FIX,r24	; switch fix off
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                            +/-
; ----------------------------------------------------------------------------

.global ExecNeg
ExecNeg:

	IF_EDITON		; if edit mode
	rjmp	4f		; edit mode is set

	ldi	R_PARAM,C_NEG	; function - negate
	rjmp	ExecParFnc	; execute parameter function

	; edit mode - change sign
4:	ldi	r30,lo8(EditBuf+EDITBUF_EXP) ; exponent sign
	ldi	r31,hi8(EditBuf+EDITBUF_EXP)
	ldi	r25,'+'		; exponent plus

	; exponent mode?
; OUTPUT: NZ = flag is set
; DESTROYS: -
	rcall	FlagTestExp	; exponent mode?
	brne	6f		; exponent

	; flip sign of mantissa
	ldd	r24,Y+DATA_EDITDIG ; mantissa lenth
	sub	r30,r24		; shift to start of exponent
	sbc	r31,R_ZERO
	ldi	r25,' '		; mantissa plus

	; flip sign of exponent
6:	ld	r24,Z		; get sign
	cpi	r24,'-'		; minus?
	breq	7f		; no, plus
8:	ldi	r25,'-'		; minus
7:	st	Z,r25	 	; set new sign

; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                     Clear error flag
; ----------------------------------------------------------------------------
; DESTROYS: R27, R26, R25, R24
; ----------------------------------------------------------------------------

.global ClearErr
ClearErr:

	CLR_ERROR		; clear error flag
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                           CE (0x24)
; ----------------------------------------------------------------------------

.global ExecCe
ExecCe:

; ----- clear error flag

	IF_ERROR		; if error
	rjmp	ClearErr	; clear error

; ----- must be in edit mode

ExecCe2:
	IFN_EDITON		; if not in edit mode
	rjmp	ExecCe9		; only validate X

ExecCe4:

; ----- exponent mode - clear one digit
; OUTPUT: NZ = flag is set
; DESTROYS: -
	rcall	FlagTestExp	; entering exponent?
	breq	4f		; not exponent

; ----- shift exponent digits

	ldd	r25,Y+DATA_EDITBUF+EDITBUF_EXP+1 ; get first exponent digit
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP+2 ; get second exponent digit
	ldi	r23,'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP+1,r23 ; set first exponent digit
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r25 ; set second exponent digit

; ----- delete exponent mode if exponent is 0

	cpi	r25,'0'
	brne	2f
	cpi	r24,'0'
	brne	2f
	rcall	StopExp		; stop exponent mode, delete +0 exponent
2:	rjmp	Disp		; display all

; ----- minimal mantissa - set last digit to zero

4:	ldd	r24,Y+DATA_EDITDIG ; length of mantissa
	cpi	r24,2		; 2 last characters?
	brne	5f
	ldi	r24,'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP-1,r24 ; set last digit to zero
; DESTROYS: R0
	rjmp	Disp		; display all

; ----- delete last character

5:	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP-1 ; load last character
	cpi	r24,'.'		; deleteing decimal point?
	brne	6f		; not decimal point
	rcall	FlagClrDP	; clear decimal point flag
6:	rcall	EditBufShiftR	; shift mantissa right
; DESTROYS: R0
	rjmp	Disp		; display all

; ----- not in edit mode - only validate X (used after left parenthesis)

ExecCe9:
	SET_XVALID
ExecCe10:
; DESTROYS: R0
	rjmp	Disp		; display all

