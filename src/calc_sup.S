; ****************************************************************************
;
;                    Calculator support operations
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                  Load unsigned byte (C_BYTE)
; ----------------------------------------------------------------------------

.global CalcByte
CalcByte:

; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rcall	CalcLit		; load literal -> R24

; CalcStackB must follow

; ----------------------------------------------------------------------------
;                   Store unsigned byte into calculator stack
; ----------------------------------------------------------------------------
; INPUT: R24 = unsigned byte
; DESTROYS: R25, R24, R23, R1, R0
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcStackB
CalcStackB:

; ----- number is 0

	tst	r24		; zero?
	brne	2f
	rjmp	CalcConst0	; load constant 0

; ----- load constant 1
; OUTPUT: R31:R30 = address of new top number 1
; DESTROYS: R25
; CALCULATOR STACK: +1
2:	rcall	CalcConst1	; load constant 1

; ----- save number < 10

	cpi	r24,10
	brcc	4f		; number is >= 10
3:	std	Z+1,r24		; save number < 10
	ret

; ----- save number < 100

4:	ldi	r25,EXP_ONE+1	; exponent 10
	st	Z,r25		; store exponent
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
	call	DivB10		; divide / 10
5:	swap	r25		; swap digits
	mov	r23,r25		; save lowest digit
	std	Z+2,r25		; save low digit
	cpi	r24,10
	brcs	3b		; number is < 100

; ----- save number >= 100

	ldi	r25,EXP_ONE+2	; exponent 100
	st	Z,r25		; store exponent
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
	call	DivB10		; divide / 10
	or	r25,r23		; add lowest digit
	rjmp	5b		; save digits

; ----------------------------------------------------------------------------
;           Get unsigned byte (absolute value, rounded towards zero)
; ----------------------------------------------------------------------------
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcUnstackB
CalcUnstackB:

; ----- absolute value
; DESTROYS: R31, R30, R25..R22

	rcall	CalcAbs

; ----- result is zero
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck

; ----- delete 2nd number - set new end of stack to Z (saves SREG)

	rcall	CalcDel2	; delete 2nd number

; ----- number < 1, result is 0

	clr	r23		; result is 0
	cpi	r24,EXP_ONE	; check exponent
	brcc	2f		; number is >= 1
1:	mov	r24,r23		; result
	ret

; ----- number < 10

2:	ldd	r23,Z+1		; load highest digit
	cpi	r24,EXP_ONE+1	; number < 10 ?
	brcs	1b		; number is < 10

; ----- number < 100

3:	ldi	r25,10
	mul	r25,r23		; highest digit * 10
	ldd	r23,Z+2		; load lower digit
	andi	r23,0xf0	; mask higher digit
	swap	r23		; swap digits
	add	r23,r0		; add higher digit
	cpi	r24,EXP_ONE+2	; number >= 100 ?
	brcs	1b		; number is < 100

; ----- number < 256

4:	cpi	r24,EXP_ONE+3	; number >= 1000 ?
	brcc	5f		; number is too big
	mul	r25,r23		; highest 2 digits * 10
	ldd	r23,Z+2		; load lower 2 digits
	andi	r23,0x0f	; mask lower digit
	add	r0,r23		; add digits
	adc	r1,R_ZERO
	mov	r23,r0		; low byte
	tst	r1		; overflow?
	breq	1b		; number is < 256

; ----- number is too big, result is 255

5:	ldi	r24,255		; max. result
	ret

; ----------------------------------------------------------------------------
;                        Exchange literal pointer and Z
; ----------------------------------------------------------------------------
; INPUT/OUTPUT: R31:R30, R_LITH:R_LITL
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcLitExc
CalcLitExc:
	eor	r30,R_LITL	; R30 ^ LITL
	eor	R_LITL,r30	; R30
	eor	r30,R_LITL	; LITL

	eor	r31,R_LITH	; R31 ^ LITH
	eor	R_LITH,r31	; R31
	eor	r31,R_LITH	; LITH
	ret

; ----------------------------------------------------------------------------
;                       Load next literal
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcLit
CalcLit:
; INPUT/OUTPUT: R31:R30, R_LITH:R_LITL
; DESTROYS: -
	rcall	CalcLitExc	; exchange literal pointer and Z	
	lpm	r24,Z+		; R24 <- load next literal
; INPUT/OUTPUT: R31:R30, R_LITH:R_LITL
; DESTROYS: -
	rcall	CalcLitExc	; exchange literal pointer and Z	
	ret

