; ****************************************************************************
;
;                           Base mathematics
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;            Divide unsigned BYTE by 10 with reminder
; ----------------------------------------------------------------------------
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
; ----------------------------------------------------------------------------

.global DivB10
DivB10:

; result will be max. 25, 5 bits, we can use (8-5)+8=11 bit result, multiply by 2048
	ldi	r25,205		; multiply by 205 = 8*256/10 round up
	mul	r25,r24		; dividend * 8 * 256 / 10
	mov	r25,r24		; save input number
	ldi	r24,10		; prepare multiplier * 10
	mov	r0,r24		; R0 <- 10
	mov	r24,r1		; dividend * 8 / 10
	lsr	r24
	lsr	r24
	lsr	r24		; dividend / 10
	mul	r24,r0		; dividend * 10
	sub	r25,r0		; get remainder
	ret
