; ****************************************************************************
;
;                          Decode number to/from text
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                 Decode number into edit buffer EditBuf
; ----------------------------------------------------------------------------
; CALCULATOR STACK: -1
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global DecNum
DecNum:

; ----- push registers

	push	r31
	push	r30
	push	r27
	push	r26
	push	r25
	push	r24
	push	r23
	push	r22
	push	r21
	push	r20

; ----- clear restart flag

; DESTROYS: -
	rcall	FlagClrResDec	; clear restart flag

DecNumRestart:

; ----- clear edit buffer
; DESTROYS: R27, R26, R24
	rcall	EditBufClear	; clear edit buffer

; ----- get top number -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop

; ----- prepare destination buffer -> X

	ldi	r26,lo8(EditBuf+EDITBUF_MANT)
	ldi	r27,hi8(EditBuf+EDITBUF_MANT)

; ----- store sign

	ldd	r24,Z+1		; sign byte
	cpi	r24,SIGN_THRES	; check negative number (NC=negative)
	ldi	r24,' '		; character of positive number
	brcs	2f		; number is positive
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	NumNeg		; negate nuber
	ldi	r24,'-'		; character of negative number
2:	st	X+,r24		; store sign

; ----- check exponent mode

	; load signed exponent -> R24
	ld	r24,Z		; load exponent
	tst	r24		; zero number?
	breq	2f		; zero number, exponent will be 0
	subi	r24,EXP_BIAS	; change exponent to signed

	; check user exponent mode
2:	rcall	FlagTestEE	; EE exponent mode?
	brne	3f		; use exponent mode

	; check maximal exponent
	cpi	r24,MANT_DIGITS	; check max. number of digits
	brge	3f		; too much integer digits -> use exponent mode

	; check minimal exponent
	ldd	r25,Y+DATA_FIX	; fixed decimals
	cpi	r25,FIX_OFF	; is fixed mode?
	brne	DecNum2		; fixed mode, do not use exponent mode
	cpi	r24,-3		; check minimal exponent (not using fixed mode)
	brge	DecNum2		; exponent is OK, do not use exponent mode

; ----- decode exponent

	; decode sign of exponent
3:	ldi	r25,'+'		; positive
	tst	r24		; is exponent negative?
	brpl	4f		; exponent is not negative
	ldi	r25,'-'		; negative
	neg	r24		; negate exponent
4:	std	Y+DATA_EDITBUF+EDITBUF_EXP,r25 ; set sign

	; limit exponent on oveflow error
	cpi	r24,100		; max. exponent
	brcs	5f		; exponent is OK
	ldi	r24,99		; limit exponent on overflow
	rcall	FlagSetResDec	; set restart flag, do not round overflow number

	; decode digits of exponent
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
5:	call	DivB10
	subi	r24,-'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP+1,r24 ; set first digit
	subi	r25,-'0'
	std	Y+DATA_EDITBUF+EDITBUF_EXP+2,r25 ; set second digit

	rcall	FlagSetExpDig	; set exponent digits flag

	; clear exponent
	clr	r24		; clear exponent

; ----- prepare flags to decode mantissa
; R24: signed exponent (0 if exponent mode)
; R23: total number of valid digits of mantissa (without additional zeroes)
; R22: number of additional zeroes after decimal point
; R21: number of valid integer digits (=0 if first digit is 0)
; R20: number of valid decimal digits (without additional zeroes)

DecNum2:
	ldi	r22,0		; number of additional zeroes after decimal point = 0

	; R21: prepare number of integer digits = exponent + 1
	mov	r21,r24		; signed exponent
	inc	r21		; exponent + 1 = number of integer digits
	brpl	2f		; number of integer digits >= 0

	; R22: prepare number of zeroes
	mov	r22,r21		; number of zero digits after decimal point
	neg	r22		; number of zero digits (0..)
	clr	r21		; no integer digit
	cpi	r22,MANT_DIGITS-1 ; check max. number of zeroes
	brcs	2f		; number of zeroes is OK
	ldi	r22,MANT_DIGITS-1 ; limit number of zeroes

	; R20: number of valid decimal digits
2:	ldi	r20,MANT_DIGITS	; total number of digts
	sub	r20,r21		; subtract integer digits
	sub	r20,r22		; subtract additional zeroes
	tst	r21		; no integer digits?
	brne	3f		; integer is valid
	dec	r20		; subtract first '0'

	; R20, Fix: limit number of digits by Fix
3:	ldd	r24,Y+DATA_FIX	; fixed decimals
	cpi	r24,FIX_OFF	; fix mode off?
	breq	DecNum4		; fix mode is off

	add	r20,r22		; temporary add additional zeroes
	cp	r20,r24		; check number of decimal digits
	brcs	4f		; number of decimal digits is OK
	mov	r20,r24		; limit number of decimal digits
4:	sub	r20,r22		; subtract additional zeroes

	brpl	DecNum4		; number of decimal digits is OK
	add	r22,r20		; limit number of zero digits
	clr	r20		; no decimal digits

; ----- rounding
; R23: total number of digits of mantissa (without additional zeroes)
; R22: number of additional zeroes after decimal point (0..MANT_DIGITS-1)
; R21: number of valid integer digits (=0 if first digit is 0)
; R20: number of valid decimal digits (without additional zeroes)

; ----- total number of valid digits (without zero sign)

DecNum4:
	mov	r23,r21		; integer digits
	add	r23,r20		; add decimal digits

; ----- number 0 does not round
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck	; get top number and check zero
	breq	DecNum5		; number 0

; ----- already rounded if restarting

	rcall	FlagTestResDec	; check restart flag
	brne	DecNum5		; restarting

; ----- add rounding correction

	; save exponent and set exponent to '1'
	ld	r24,Z
	push	r24
	ldi	r24,EXP_ONE
	st	Z,r24		; clear exponent to value 10^0

	; add rounding correction
	push	r23
	ldi	r24,CONST_05
	rcall	CalcConst	; add constant 0.5
	rcall	CalcTop		; get top number
	pop	r23
	neg	r23
	subi	r23,-EXP_ONE
	st	Z,r23		; set exponent
	rcall	CalcAdd		; add correction

	; return exponent
	rcall	CalcTop		; get top number
	pop	r23
	ld	r24,Z

	subi	r24,EXP_ONE
	add	r23,r24
	st	Z,r23		; return exponent	

	; return sign
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_MANT ; load sign
	cpi	r24,'-'
	brne	4f		; not negative
	rcall	NumNeg		; negate nuber

	; restart
4:	rcall	FlagSetResDec	; set restart flag
	rjmp	DecNumRestart	; restart

; ----- decode mantissa digits
; R23: total number of valid digits of mantissa (without additional zeroes)
; R22: number of additional zeroes after decimal point (0..MANT_DIGITS-1)
; R21: number of valid integer digits (=0 if first digit is 0)
; R20: number of valid decimal digits (without additional zeroes)

DecNum5:

; ----- starting decimal point if integer digits = 0

	rcall	FlagSetDP	; set decimal point flag

	tst	r21		; check number of integer digits
	brne	2f		; not starting 0
	ldi	r24,'0'		; starting with '0'
	st	X+,r24
	ldi	r24,'.'
	st	X+,r24

; ----- store initial zeroes

2:	tst	r22		; check number of zeroes
	breq	4f		; no initial zeroes

	ldi	r24,'0'
3:	st	X+,r24
	dec	r22
	brne	3b

; ----- decode digits of mantissa (and decimal point)

	; no valid digits
4:	tst	r23		; check number of valid digits
	breq	DecNum6		; no valid digits

	; prepare first byte
	adiw	r30,1		; skip exponent
	ld	r24,Z+		; load first byte

	; save even digit
5:	andi	r24,0x0f	; mask lower digt
	subi	r24,-'0'	; convert to ASCII digit
	st	X+,r24		; store digit

	; save decimal point
	dec	r21		; counter of integer digits
	brne	6f		; no decimal point
	ldi	r24,'.'
	st	X+,r24		; store decimal point

	; counter of total digits
6:	dec	r23		; counter of digits
	breq	DecNum6		; end of number

	; prepare next byte
	ld	r24,Z+		; load next byte
	mov	r25,r24

	; save odd digit
	swap	r25
	andi	r25,0x0f	; mask digit
	subi	r25,-'0'	; convert to ASCII digit
	st	X+,r25		; store digit

	; save decimal point
	dec	r21		; counter of integer digits
	brne	7f		; no decimal point
	ldi	r25,'.'
	st	X+,r25		; store decimal point

	; counter of total digits
7:	dec	r23		; counter of digits
	brne	5b		; next digit

; ----- delete ending zeroes

DecNum6:
	ldd	r24,Y+DATA_FIX	; fixed decimals
	cpi	r24,FIX_OFF	; fix mode off?
	brne	DecNum7		; fix mode is on, do not redice ending zeroes

	; delete zeroes of decimal part
1:	ld	r24,-X		; load previous character
	cpi	r24,'0'
	brne	2f		; not zero
	ldi	r24,' '
	st	X,r24		; substitute it with space
	rjmp	1b		; next digit

2:	adiw	r26,1		; return pointer behind last valid digit

; ----- shift number right

DecNum7:
	mov	r24,r26		; end of text
	subi	r24,lo8(EditBuf+EDITBUF_MANT) ; length of mantissa
	std	Y+DATA_EDITDIG,r24 ; save length of mantissa

	; offset to shift
	ldi	r25,MANT_LEN	; max. length of mantissa
	sub	r25,r24		; offset to shift
	breq	DecNum8		; no shift needed

	; shift text
	ldi	r30,lo8(EditBuf+EDITBUF_EXP)
	ldi	r31,hi8(EditBuf+EDITBUF_EXP)
2:	ld	r25,-X
	st	-Z,r25
	dec	r24
	brne	2b

	; clear old characters
	ldi	r24,' '
3:	st	-Z,r24
	cpi	r30,lo8(EditBuf+EDITBUF_MANT)
	brne	3b

; ----- delete top number
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
DecNum8:
	rcall	CalcDel		; delete number

; ----- pop registers

	pop	r20
	pop	r21
	pop	r22
	pop	r23
	pop	r24
	pop	r25
	pop	r26
	pop	r27
	pop	r30
	pop	r31
	ret

; ----------------------------------------------------------------------------
;            Encode number from edit buffer to calculator stack
; ----------------------------------------------------------------------------
; CALCULATOR STACK: +1
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global EncNum
EncNum:

; ----- push registers

	push	r20
	push	r21
	push	r22
	push	r23
	push	r24
	push	r25
	push	r26
	push	r27
	push	r30
	push	r31

; ----- create new number
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0		; clear number Z

; ----- prepare to load digits of mantissa (X editbuf, R21 exponent, R22 increment exponent)

	ldd	r25,Y+DATA_EDITDIG ; mantissa length
	ldi	r26,lo8(EditBuf+EDITBUF_EXP) ; end of mantissa + 1
	ldi	r27,hi8(EditBuf+EDITBUF_EXP)
	sub	r26,r25		; start of mantissa in edit buffer
	sbc	r27,R_ZERO

; ----- load sign character -> R20

	ld	r20,X+		; load sign with character -> R20 (' ' or '-')

; ----- shift exponent
; R20: sign character ' ' or '-'
; R21: exponent with bias
; R22: exponent increment
; R23: ... temporary
; R24: character
; R25: mantissa length counter
; R27:R26: destination pointer to edit buffer
; R31:R30: source pointer to the number

	ldi	r21,EXP_ONE-2	; prepare exponent 0.01
	ldi	r22,1		; exponent increment = +1
1:	inc	r21		; shift exponent
				;	1st pass: 0.01 -> 0.1
				;	'.': 0.1 -> 1
	dec	r22		; shift exponent increment
				;	1st pass: +1 -> 0
				;	'.': 0 -> -1
2:	add	r21,r22		; shift exponent
				;	1st pass: 0.1 -> 0.1
				;	1st zero '0.': 0.1 -> 0.1
				;	'.': 1 -> 0.1
				;	2nd zero '0.0': 0.1 -> 0.01
				;	3rd zero '0.0': 0.01 -> 0.001
	dec	r25		; decrement mantissa length
	breq	EncNum4		; no other character (result number will be 0, no valid digits entered)

; ----- skip initial zeroes

	ld	r24,X+		; load one character
	cpi	r24,'0'		; zero?
	breq	2b		; add zero
	cpi	r24,'.'		; decimal point?
	breq	1b		; decimal point, shift exponent increment
	sbiw	r26,1		; return X pointer

; no '0' before decimal point (1.234): R22 exp. increment = 0, R21 exponent = 0.1
; '0' before decimal point, no other '0' (0.1234): R22 exp. increment = -1, R21 exponent = 0.1
; '0' after decimal point (0.01234): R22 exp. increment = -1, R21 exponent = 0.01
; 2nd '0' after decimal point (0.001234): R22 exp. increment = -1, R21 exponent = 0.001

; ----- load digits of mantissa
; Note: number of entered digits are always lower than real digits of mantissa, no need to check Z pointer

	adiw	r30,1		; skip exponent byte in Z
	inc	r22		; shift exponent increment (-1 -> 0 or 0 -> 1)

; no '0' before decimal point (12.34): R22 exp. increment = +1, R21 exponent = 0.1
; '0' before decimal point, no other '0' (0.1234): R22 exp. increment = 0, R21 exponent = 0.1
; '0' after decimal point (0.01234): R22 exp. increment = 0, R21 exponent = 0.01
; 2nd '0' after decimal point (0.001234): R22 exp. increment = 0, R21 exponent = 0.001

; ----- load odd digit 0x0N

	; decimal point
5:	ld	r24,X+		; load one character
	cpi	r24,'.'		; decimal point?
	brne	1f		; not decimal point
	dec	r22		; shift exponent increment (1 -> 0)
	dec	r25		; decrement mantissa length
	breq	EncNum4		; no other character

	; valid lower digit 0x0N
	ld	r24,X+		; load one character
1:	subi	r24,'0'		; convert digit to number
	ld	r23,Z		; load byte from mantissa
	andi	r23,0xf0	; mask old high nibble
	or	r24,r23		; compose digits
	st	Z+,r24		; store new digit
	add	r21,r22		; shift exponent

2:	dec	r25		; decrement mantissa length
	breq	EncNum4		; no other character

; ----- load even digit 0xN0

	; decimal point
	ld	r24,X+		; load one character
	cpi	r24,'.'		; decimal point?
	brne	3f		; not decimal point
	dec	r22		; shift exponent increment (1 -> 0)
	dec	r25		; decrement mantissa length
	breq	EncNum4		; no other character

	; valid high digit 0xN0
	ld	r24,X+		; load one character
3:	subi	r24,'0'		; convert digit to number
	swap	r24		; swap digit to high position 0xN0
	st	Z,r24		; store new digit
	add	r21,r22		; shift exponent

4:	dec	r25		; decrement mantissa length
	brne	5b		; next character

; ----- load exponent

EncNum4:
	; get top number -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop

	; exponent digits are entered?
	rcall	FlagTestExpDig	; exponent digits?
	breq	EncNum6		; no exponent

	; high digit of exponent
	ldd	r25,Y+DATA_EDITBUF+EDITBUF_EXP+1 ; high digit of exponent
	subi	r25,'0'		; convert to number
	ldi	r24,10		; multiplier
	mul	r25,r24		; higher digit * 10

	; low digit of exponent
	ldd	r24,Y+DATA_EDITBUF+EDITBUF_EXP+2 ; low digit of exponent
	subi	r24,'0'		; convert to number
	add	r24,r0		; compose both digits

	; sign of exponent
	ldd	r25,Y+DATA_EDITBUF+EDITBUF_EXP ; sign of exponent
	cpi	r25,'-'		; negative exponent?
	brne	2f
	neg	r24		; negate exponent

	; sum exponent
2:	add	r21,r24		; sum exponent

	; check overflow
	cpi	r21,EXP_MAX+1	; check max. exponent
	brcs	3f		; exponent is OK
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	NumSetOver	; set overflow
	ldi	r21,EXP_MAX	; overflow exponent

	; check underflow
3:	cpi	r21,EXP_MIN	; check min. exponent
	brcc	EncNum6		; exponent is OK
	rcall	NumSetUnder	; set underflow
	ldi	r21,EXP_MIN	; underflow exponent

; ----- set exponent and negate number

EncNum6:
	; check zero mantissa
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = mantissa is zero
; DESTROYS: R25, R24, R23
	rcall	MantIsZero	; check if result is zero
	brcc	4f		; mantissa is OK
	clr	r21		; clear exponent

	; store exponent
4:	st	Z,r21		; store exponent

	; negate result
	cpi	r20,'-'
	brne	5f		; not negative
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	NumNeg
5:

; ----- pop registers

	pop	r31
	pop	r30
	pop	r27
	pop	r26
	pop	r25
	pop	r24
	pop	r23
	pop	r22
	pop	r21
	pop	r20
	ret
