; ****************************************************************************
;
;                        Calculator mantissa operations
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                       Check if mantissa is zero
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = mantissa is zero
; DESTROYS: R25, R24, R23
; ----------------------------------------------------------------------------

.global MantIsZero
MantIsZero:
	adiw	r30,1		; shift to first byte of mantissa
	ldi	r25,CMANT_BYTES	; mantissa length in bytes
	clr	r23		; accumulator

2:	ld	r24,Z+		; load one byte of mantissa
	or	r23,r24		; add byte to accumulator
	dec	r25		; loop counter
	brne	2b		; test next byte

	sbiw	r30,CNUM_BYTES	; return pointer to start of number
	cpi	r23,1		; check result, set CY of mantissa is zero
	ret

; ----------------------------------------------------------------------------
;          Add lower digit from X mantissa to lower digit of Z mantissa
; ----------------------------------------------------------------------------
; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..1
;	 R21 = lower digit of X mantissa
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25, R21
; ----------------------------------------------------------------------------

.global DigAddX
DigAddX:
	andi	r21,0x0f	; mask lower digit
	add	r23,r21		; add input carry

; DigAdd must follow

; ----------------------------------------------------------------------------
;                    Add carry 0..10 to lower digit of mantissa
; ----------------------------------------------------------------------------
; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..10
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25
; ----------------------------------------------------------------------------

.global DigAdd
DigAdd:

	; load low digit
	mov	r25,r24		; save byte
	andi	r24,0x0f	; mask lower digit of mantissa
	andi	r25,0xf0	; mask higher digit of mantissa

	; add digit
	add	r24,r23		; add carry
	clr	r23		; clear carry
	cpi	r24,10		; carry?
	brcs	2f		; no carry, save result
	subi	r24,10		; carry correction
	ldi	r23,1		; new carry

	; compose digit
2:	or	r24,r25		; compose digits
	ret

; ----------------------------------------------------------------------------
;   Subtract lower digit from X mantissa from lower digit of Z mantissa
; ----------------------------------------------------------------------------
; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..1
;	 R21 = lower digit of X mantissa
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25, R21
; ----------------------------------------------------------------------------

.global DigSubX
DigSubX:
	andi	r21,0x0f	; mask lower digit
	add	r23,r21		; add input borrow

; DigSub must follow

; ----------------------------------------------------------------------------
;               Subtract borrow 0..10 from lower digit of mantissa
; ----------------------------------------------------------------------------
; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..10
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25
; ----------------------------------------------------------------------------

.global DigSub
DigSub:
	; load low digit
	mov	r25,r24		; save byte
	andi	r24,0x0f	; mask lower digit of mantissa
	andi	r25,0xf0	; mask higher digit of mantissa

	; subtract digit
	sub	r24,r23		; subtract borrow
	ldi	r23,0		; clear borrow
	brpl	2f		; no borrow, save result
	subi	r24,-10		; borrow correction
	ldi	r23,1		; borrow

	; clompose digits
2:	or	r24,r25		; compose digits
	ret

; ----------------------------------------------------------------------------
;                  Invert mantissa - nines' complement (9 - x)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
; ----------------------------------------------------------------------------

.global MantNot
MantNot:
	; shift to first byte
	adiw	r30,1		; shift to first byte of mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

	; load digit
2:	ld	r24,Z		; load one byte of mantissa
	mov	r25,r24		; save byte
	andi	r24,0x0f	; mask lower digit of mantissa
	andi	r25,0xf0	; mask higher digit of mantissa

	; invert low digit
	ldi	r23,9
	sub	r23,r24		; nines' complement of lower digit

	; inver high digit
	ldi	r24,0x90
	sub	r24,r25		; nines' complement of higher digit

	; save digit
	or	r24,r23		; compose digits
	st	Z+,r24		; save new byte

	; next byte
	dec	r22		; decrement loop counter
	brne	2b		; next byte of mantissa
	sbiw	r30,CNUM_BYTES	; return pointer
	ret

; ----------------------------------------------------------------------------
;      Negate mantissa (negate number) - tens' complement (9 - x + 1)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
; ----------------------------------------------------------------------------

.global NumNeg
NumNeg:

.global MantNeg
MantNeg:
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	MantNot		; invert number, nines' complement

; MantInc must follow

; ----------------------------------------------------------------------------
;                      Increment mantissa (add constant 1)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R22
;	 R23 = carry 0..1
; ----------------------------------------------------------------------------

.global MantInc
MantInc:
	ldi	r23,1

; MantAddC must follow

; ----------------------------------------------------------------------------
;                       Add constant 0..10 to mantissa
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = constant 0..10 to add
; DESTROYS: R25, R24, R22
;	 R23 = carry 0..1
; ----------------------------------------------------------------------------

.global MantAddC
MantAddC:
	adiw	r30,CNUM_BYTES	; shift to last byte of mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

.global MantAddC2
MantAddC2:

; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..10
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25
2:	ld	r24,-Z		; load digit
	rcall	DigAdd		; add constant to lower digit of mantissa
	swap	r24		; swap digits
	rcall	DigAdd		; add carry
	swap	r24		; swap digits
	st	Z,r24		; save byte
	dec	r22		; decrement loop counter
	brne	2b		; next byte of mantissa
	sbiw	r30,1		; skip exponent
	ret			; here R31:R30 points again to start of the number

; ----------------------------------------------------------------------------
;                      Decrement mantissa (subtract constant 1)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R22
;	 R23 = borrow 0..1
; ----------------------------------------------------------------------------

.global MantDec
MantDec:
	ldi	r23,1

; MantSubC must follow

; ----------------------------------------------------------------------------
;                     Subtract constant 0..10 from mantissa
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = constant 0..10 to subtract
; DESTROYS: R25, R24, R22
;	 R23 = borrow 0..1
; ----------------------------------------------------------------------------

.global MantSubC
MantSubC:
	adiw	r30,CNUM_BYTES	; shift to last byte of mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..10
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25
2:	ld	r24,-Z		; load digit
	rcall	DigSub		; subtract constant from lower digit of mantissa
	swap	r24		; swap digits
	rcall	DigAdd		; subtract borrow
	swap	r24		; swap digits
	st	Z,r24		; save byte
	dec	r22		; decrement loop counter
	brne	2b		; next byte of mantissa
	sbiw	r30,1		; skip exponent
	ret			; here R31:R30 points again to start of the number

; ----------------------------------------------------------------------------
;                 Add 2 mantissas, with input carry 0
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R23, R22, R21
;	 R23 = carry 0..1
; ----------------------------------------------------------------------------

.global MantAdd0
MantAdd0:
	clr	r23		; clear input carry

; MantAdd must follow

; ----------------------------------------------------------------------------
;                       Add 2 mantissas Z <- Z + X
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
;	 R23 = input carry 0..1
; DESTROYS: R25, R24, R22, R21
;	 R23 = carry 0..1
; ----------------------------------------------------------------------------

.global MantAdd
MantAdd:
	adiw	r30,CNUM_BYTES	; shift Z to last byte of destination mantissa
	adiw	r26,CNUM_BYTES	; shift X to last byte of source mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

; INPUT: R24 = lower digit of Z mantissa
;	 R23 = carry 0..1
;	 R21 = lower digit of X mantissa
; OUTPUT: R23 = new carry 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25, R21
2:	ld	r24,-Z		; load digit
	ld	r21,-X		; load digit
	rcall	DigAddX		; add digit from X to digit from Z
	swap	r24		; swap digits
	ld	r21,X		; load digit
	swap	r21		; swap digits
	rcall	DigAddX		; add with carry
	swap	r24		; swap digits
	st	Z,r24		; save byte
	dec	r22		; decrement loop counter
	brne	2b		; next byte of mantissa
	sbiw	r30,1		; skip exponent
	sbiw	r26,1		; skip exponent
	ret			; here R31:R30 points again to start of the number

; ----------------------------------------------------------------------------
;                 Subtract 2 mantissas, with input borrow 0
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R22, R21
;	 R23 = borrow 0..1
; ----------------------------------------------------------------------------

.global MantSub0
MantSub0:
	clr	r23		; clear input borrow

; MantSub must follow

; ----------------------------------------------------------------------------
;                   Subtract 2 mantissas Z <- Z - X
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
;	 R23 = input borrow 0..1
; DESTROYS: R25, R24, R22, R21
;	 R23 = borrow 0..1
; ----------------------------------------------------------------------------

.global MantSub
MantSub:
	adiw	r30,CNUM_BYTES	; shift Z to last byte of destination mantissa
	adiw	r26,CNUM_BYTES	; shift X to last byte of source mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

; INPUT: R24 = lower digit of Z mantissa
;	 R23 = borrow 0..1
;	 R21 = lower digit of X mantissa
; OUTPUT: R23 = new borrow 0 or 1
;	  R24 = new compose digits
; DESTROYS: R25, R21
2:	ld	r24,-Z		; load digit
	ld	r21,-X		; load digit
	rcall	DigSubX		; subtract digit from X from digit from Z
	swap	r24		; swap digits
	ld	r21,X		; load digit
	swap	r21		; swap digits
	rcall	DigSubX		; subtract with borrow
	swap	r24		; swap digits
	st	Z,r24		; save byte
	dec	r22		; decrement loop counter
	brne	2b		; next byte of mantissa
	sbiw	r30,1		; skip exponent
	sbiw	r26,1		; skip exponent
	ret			; here R31:R30 points again to start of the number

; ----------------------------------------------------------------------------
;  Shift mantissa right (from higher digits to lower digits), repeat sign digit
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
; ----------------------------------------------------------------------------

.global MantRightS
MantRightS:
	ldd	r23,Z+1		; load first byte of mantissa
	cpi	r23,SIGN_THRES	; check if number is negative (NC = negative)
	ldi	r23,0		; input digit of positive number
	brcs	MantRight	; number is positive
	ldi	r23,9		; input digit of negative number

; MantRight must follow

; ----------------------------------------------------------------------------
;         Shift mantissa right (from higher digits to lower digits)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = new highest digit 0..9
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
; ----------------------------------------------------------------------------

.global MantRight
MantRight:
	; prepare pointer to first digit of mantissa
	adiw	r30,1		; shift to first byte of mantissa
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

	; shift digits of one byte
2:	ld	r24,Z		; load one byte
	mov	r0,r24		; save new carry
	andi	r24,0xf0	; mask higher digit (it will become lower digit later)
	or	r24,r23		; add carry digit (it will become higher digit later)
	swap	r24		; swap digits to correct positions
	st	Z+,r24		; save new byte

	; prepare new carry
	mov	r23,r0		; new carry
	andi	r23,0x0f	; mask digit

	; loop counter
	dec	r22		; loop counter
	brne	2b		; proces next byte
	sbiw	r30,CNUM_BYTES	; return pointer to start of number
	ret

; ----------------------------------------------------------------------------
;   Shift mantissa left (from lower digits to higher digits), insert digit 0
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry highest digit 0..9
; DESTROYS: R25, R24, R22, R0
; ----------------------------------------------------------------------------

.global MantLeft0
MantLeft0:
	clr	r23		; new highest digit = 0

; MantLeft must follow

; ----------------------------------------------------------------------------
;         Shift mantissa left (from lower digits to higher digits)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = new lowest digit 0..9
; OUTPUT: R23 = carry highest digit 0..9
; DESTROYS: R25, R24, R22, R0
; ----------------------------------------------------------------------------

.global MantLeft
MantLeft:
	; prepare pointer to last digit of mantissa
	adiw	r30,CNUM_BYTES	; shift to last byte of mantissa + 1
	ldi	r22,CMANT_BYTES	; mantissa length in bytes

	; shift digits of one byte
2:	ld	r24,-Z		; load one byte
	swap	r24		; swap digits to correct positions
	mov	r0,r24		; save new carry
	andi	r24,0xf0	; mask old lower digit
	or	r24,r23		; add carry digit
	st	Z,r24		; save new byte

	; prepare new carry
	mov	r23,r0		; new carry
	andi	r23,0x0f	; mask digit

	; loop counter
	dec	r22		; loop counter
	brne	2b		; proces next byte
	sbiw	r30,1		; return pointer to start of number
MantLeft8:
	ret

; ----------------------------------------------------------------------------
;          Shift mantissa left to maximize number, correct exponent
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22, R0
; ----------------------------------------------------------------------------

.global MantLMax
MantLMax:

; ------ check if mantissa is zero
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = mantissa is zero
; DESTROYS: R25, R24, R23
	rcall	MantIsZero
	brcs	MantLMax4	; mantissa is zero

; ----- negate mantissa
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
;	  R24 = highest byte of mantissa
	rcall	NumIsNeg	; check negative number
	brcc	MantLMax2	; mantissa is not negative

; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	NumNeg		; negate number
	rcall	MantLMax2	; maximize mantissa
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rjmp	NumNeg		; negate number

; ----- check exponent underflow

MantLMax2:
	ld	r24,Z		; load exponent
	cpi	r24,EXP_MIN	; check exponent minimal value
	brcs	MantLeft8	; exponent is not valid

; ----- check if highest digit is 0

	ldd	r24,Z+1		; load highest byte of mantissa
	cpi	r24,0		; zero?
	brne	MantLeft8	; number is normalized OK

; ----- shift mantissa left
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry highest digit 0..9
; DESTROYS: R25, R24, R22, R0

3:	rcall	MantLeft0	; shift mantissa left

; ----- decrement exponent
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24

	rcall	ExpDec		; decrement exponent
	rjmp	MantLMax2	; next step

; ----- result is zero

MantLMax4:
	st	Z,R_ZERO
	ret
