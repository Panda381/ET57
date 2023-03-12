; ****************************************************************************
;
;                        Calculator macro interpreter
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                           Random number (C_RAND)
; ----------------------------------------------------------------------------
; Microsoft C++ random number generator:
;   Seed = (Seed*214013 + 2531011) mod 4294967296
;   Random = Seed / 4294967296
;		4294967296 = 2^32

.global CalcRand
CalcRand:
	rcall	Calc

	.byte	C_GETSEED		; load seed (s)
	.byte	C_CONST(CONST_RANDA)	; load multiplier (s,a)
	.byte	C_MUL			; multiply (s*a)
	.byte	C_CONST(CONST_RANDC)	; load addition (s*a,c)
	.byte	C_ADD			; add (s*a+c)
	.byte	C_CONST(CONST_RANDM)	; load modulus (s*a+c,m)
	.byte	C_MOD			; modulus (s)
	.byte	C_SETSEED		; save seed (s)

	.byte	C_CONST(CONST_RANDM)	; load modulus (s,m)
	.byte	C_DIV			; divide (s/m))
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                           Square x^2 (C_SQR)
; ----------------------------------------------------------------------------

.global CalcSqr
CalcSqr:
; DESTROYS: R31, R30, R27..R24
; CALCULATOR STACK: +1
	rcall	CalcDup		; duplicate
; DESTROYS: all
; CALCULATOR STACK: -1
	rjmp	CalcMul		; multiplication

; ----------------------------------------------------------------------------
;                       Reciprocal value 1/x (C_REC)
; ----------------------------------------------------------------------------

.global CalcRec
CalcRec:
	rcall	CalcConst1	; load constant "1"
; DESTROYS: R31, R30, R27..R23
	rcall	CalcExc		; exchange operands
; DESTROYS: all
; CALCULATOR STACK: -1
	rjmp	CalcDiv		; divide

; ----------------------------------------------------------------------------
;                       Increment +1 (C_INC)
; ----------------------------------------------------------------------------
; DESTROYS: all
; ----------------------------------------------------------------------------

.global CalcInc
CalcInc:
	rcall	CalcConst1	; load constant "1"
; DESTROYS: all
; CALCULATOR STACK: -1
	rjmp	CalcAdd		; add 1

; ----------------------------------------------------------------------------
;                       Decrement -1 (C_DEC)
; ----------------------------------------------------------------------------
; DESTROYS: all
; ----------------------------------------------------------------------------

.global CalcDec
CalcDec:
	rcall	CalcConst1	; load constant "1"
; DESTROYS: all
; CALCULATOR STACK: -1
	rjmp	CalcSub		; sub 1

; ----------------------------------------------------------------------------
;                          Compare (C_LTEQ..C_EQU)
; ----------------------------------------------------------------------------
; INPUT: R24 = literal
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------
; Leaves 0/1 on top of calculator stack.

.global CalcCmp
CalcCmp:

; ----- get last 2 numbers -> 1st number X, 2nd number Z
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack
;	  R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop2

; ----- prepare comparison code -> R24
; <= 000, >= 001, <> 010
;  > 100,  < 101,  = 110

	subi	r24,C_LTEQ

; ----- swap operands in cases >= and <
; <= 00, <> 01
;  > 10,  = 11

	lsr	r24		; shift right
; <= xx00, <> xx01
;  > xx10,  = xx11
	brcc	1f		; skip if bit 0 is clear

; DESTROYS: R31, R30, R27..R23

	push	r24		; push comparison flags
; DESTROYS: R31, R30, R27..R23
	rcall	CalcExc		; swap two numbers on the stack
	pop	r24		; pop comparison flags

; ----- substract numbers (result leaves on top of stack)
;   top number: 0 if numbers are equal

1:	push	r24
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcSub
	pop	r24		; pop comparison flags

; ----- process result
; top number = 1st number - 2nd number
; <= 00, <> 01, > 10, = 11

; DESTROYS: R31, R30, R25, R24

	push	r24		; push comparison flags
	sbrc	r24,0		; skip if bit 0 is clear (= equal flag)
	rcall	CalcNot		; invert result number if bit 0 is set

; top number = 1st number - 2nd number = dif
; dif = 0 (numbers are equal): <= 00 (->0), <> 01 (->1), > 10 (->0), = 11 (->1)
; dif <> 0: <= 00 (dif), <> 01 (->0), > 10 (dif), = 11 (->0)

; DESTROYS: R31, R30, R27..R23, R1, R0

	rcall	CalcGr0		; greater-0, sets 1 if number was > 0, or 0 otherwise

; dif > 0: <= 00 (->1), <> 01 (->0), > 10 (->1), = 11 (->0)
; dif < 0: <= 00 (->0), <> 01 (->0), > 10 (->0), = 11 (->0)

	pop	r24		; pop comparison flags

; ----- apply a terminal NOT by bit 2 of comparison flag - inverts meaning of <= and <>

; DESTROYS: R31, R30, R25, R24

	sbrs	r24,1		; skip if bit 1 (old bit 2) is set
	rcall	CalcNot		; NOT result if bit 1 is clear

; dif = 0: <= 00 (->1), <> 01 (->0), > 10 (->0), = 11 (->1)
; dif > 0: <= 00 (->0), <> 01 (->1), > 10 (->1), = 11 (->0)
; dif < 0: <= 00 (->1), <> 01 (->1), > 10 (->0), = 11 (->0)

CalcCmp9:
	ret

; ----------------------------------------------------------------------------
;             Check if number if less than zero (C_LT0)
; ----------------------------------------------------------------------------
; Set number to 1 if number is < 0, or 0 otherwise.

.global CalcLt0
CalcLt0:

; ----- get last number on calculator stack -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop

; ----- prepare mask for check

	ldi	r24,0		; XOR mask

; ----- check sign bit

CalcLt02: ; jump here from CalcGr0
	ldd	r25,Z+1		; get sign bit (from first byte of mantissa)
	eor	r25,r24		; check sign bit

; ----- set result
	brmi	NumSet1_2	; set to 1 in case of negative number (or positive from CalcGr0)
NumSet0_2:
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rjmp	NumSet0		; set to 0

; ----------------------------------------------------------------------------
;            Check if number if greater than zero (C_GR0)
; ----------------------------------------------------------------------------
; Set number to 1 if number is > 0, or 0 otherwise.

.global CalcGr0
CalcGr0:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck
	breq	CalcCmp9	; zero number left unchanged

; ----- prepare mask for check

	ldi	r24,0x80	; negative mask
	rjmp	CalcLt02

; ----------------------------------------------------------------------------
;             Check if number if less or equ zero (C_LTEQ0)
; ----------------------------------------------------------------------------
; Set number to 1 if number is <= 0, or 0 otherwise.

.global CalcLtEq0
CalcLtEq0:
	rcall	CalcGr0		; set to 1 if number is > 0, or 0 otherwise
	rjmp	CalcNot		; inverse result

; ----------------------------------------------------------------------------
;             Check if number if greater or equ zero (C_GREQ0)
; ----------------------------------------------------------------------------
; Set number to 1 if number is >= 0, or 0 otherwise.

.global CalcGrEq0
CalcGrEq0:
	rcall	CalcLt0		; set to 1 if number is < 0, or 0 otherwise

; CalcNot must follow

; ----------------------------------------------------------------------------
;                            NOT operator (C_NOT)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R25, R24
; ----------------------------------------------------------------------------
; Returns value 0 or 1.

.global CalcNot
CalcNot:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck

; ----- set result
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25
	brne	NumSet0_2	; set to 0 in case of not zero
NumSet1_2:
	rjmp	NumSet1		; set to 1 in case of zero

; ----------------------------------------------------------------------------
;                           Unary minus, Negate (C_NEG)
; ----------------------------------------------------------------------------

.global CalcNeg
CalcNeg:

; ----- get last number
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get top number

; ----- negate number
; INPUT: R31:R30 (Z) = address of the number
CalcNeg2:
	rjmp	NumNeg

; ----------------------------------------------------------------------------
;                             Absolute value (C_ABS)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R25..R22
; ----------------------------------------------------------------------------

.global CalcAbs
CalcAbs:

; ----- get last number on calculator stack -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop


.global CalcAbsZ
CalcAbsZ:

; ----- check negative
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; check if number is negative
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	brcs	CalcNeg2	; number is negative, negate it
	ret

; ----------------------------------------------------------------------------
;                         Round down (C_FLOOR)
; ----------------------------------------------------------------------------

.global CalcFloor
CalcFloor:

; ----- get last number and check if zero -> Z, R25:R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck
	subi	r24,EXP_BIAS	; check bias
	brcc	CalcFloor2	; 1 or greater

; ----- number 0..1 becomes into 0, number -1..0 becomes into -1
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; negative?
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	brcc	NumSet0_2	; non-negative number, set to 0
	rjmp	NumSetM1	; set -1

; ----- prepare number of digits to clear

CalcFloor2:
	subi	r24,CMANT_DIG-2	; subtract max. digits from exponent
	brpl	CalcFloor9	; number is too high, always integer (no fractional part)

	neg	r24		; number of bits = CMANT_DIG-2..1

; ----- prepare number of bytes to clear

CalcFloor3:
	adiw	r30,CNUM_BYTES	; shift pointer behind end of number
	mov	r22,r24		; R22 <- number of digits
	lsr	r22		; number of digits / 2 = number of bytes
	breq	CalcFloor6	; no whole bytes

; ----- reset whole bytes to 0

CalcFloor4:
	st	-Z,R_ZERO	; set 2 digits to 0
	dec	r22		; byte counter
	brne	CalcFloor4	; next byte

; ----- reset remaining digit

CalcFloor6:
	andi	r24,1		; remaining digit
	breq	CalcFloor9	; no digit

	ld	r24,-Z
	andi	r24,0xf0	; clear one digit
	st	Z,r24

CalcFloor9:
	ret

; ----------------------------------------------------------------------------
;                       fraction (CFRAC)
; ----------------------------------------------------------------------------

.global CalcFrac
CalcFrac:

	rcall	Calc
	.byte	C_DUP		; duplicate
	.byte	C_TRUNC		; trunc x
	.byte	C_SUB		; subtract
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                Integer truncation towards zero (C_TRUNC)
; ----------------------------------------------------------------------------

.global CalcTrunc
CalcTrunc:

; ----- get last number on calculator stack -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop
; ----- number 0..1 becomes into 0, number -1..0 becomes into -1
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; negative?
	brcc	CalcFloor	; non-negative number, round as floor

; CalcCeil must follow

; ----------------------------------------------------------------------------
;                           Round up (C_CEIL)
; ----------------------------------------------------------------------------

.global CalcCeil
CalcCeil:

	rcall	CalcNeg		; negate number
	rcall	CalcFloor	; truncate negative number
	rjmp	CalcNeg		; negate number

; ----------------------------------------------------------------------------
;                           Round nearest (C_ROUND)
; ----------------------------------------------------------------------------

.global CalcRound
CalcRound:

	rcall	Calc
; offset 0
	.byte	C_CONST(CONST_05) ; load 0.5 constant (x,0.5)
	.byte	C_ADD		; add rounding correction
	.byte	C_FLOOR		; round floor
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                  Normalize angle argument (C_ARG)
; ----------------------------------------------------------------------------
; Result lies in range 0..2*PI

.global CalcArg
CalcArg:

	rcall	Calc		; (x)
	.byte	C_CONST(CONST_PI2) ; add 2*PI constant
	.byte	C_MOD2		; modulus floor
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;     Add serie member to accumulator and loop if meaningful (C_ADDLOOP)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; ----------------------------------------------------------------------------

.global CalcAddLoop
CalcAddLoop:

; ----- get 2 top numbers
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack
;	  R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop2

; ----- 1st number (accumulator) is infinity or underflow - stop iteration

	ld	r23,X		; exponent
	cpi	r23,EXP_OVER
	breq	CalcAddLoop6	; infinity
	cpi	r23,EXP_UNDER
	breq	CalcAddLoop6	; underflow

; ----- 2nd number (serie member) is zero or infinity or underflow - stop iteration
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R24 = exponent
;	 CY = exponent is not in valid range
	rcall	ExpIsValid	; check 2nd number
	brcs	CalcAddLoop6	; invalid exponent
	cpi	r24,EXP_ZERO
	breq	CalcAddLoop6	; 2nd number is zero - end iteration

; ----- compare exponents

	sbc	r23,r24		; difference of exponents
	brcs	CalcAddLoop4	; member is greater than accumulator - continue
	cpi	r23,CMANT_DIG + CMANT_DIG/6 ; check distance
	brcc	CalcAddLoop6	; member is too small, break

; ----- add numbers

CalcAddLoop4:
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcAdd		; add numbers

; ----- jump to loop begin
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
	rjmp	CalcJump

; ----- stop loop - only destroy literal with jump offset

CalcAddLoop6:
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
	rcall	CalcDel		; delete member

; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rjmp	CalcLit		; load literal -> R24

; ----------------------------------------------------------------------------
;                             Cosine (C_COS)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
; cos(x) = sin(x+PI/2)

.global CalcCos
CalcCos:

; ----- add angle PI/2

	rcall	Calc		; calculator
; offset 0
	.byte	C_TORAD		; angle to radians
	.byte	C_CONST(CONST_PI05) ; load constant PI/2
	.byte	C_ADD		; add PI/2 to angle
	.byte	C_JMP		; jump
	.byte	4		; jump to offset 9 (9-5=4)
; offset 5
	.balign 2		; align
; offset 6

; CalcSin must follow

; ----------------------------------------------------------------------------
;                             Sine (C_SIN)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
; Taylor serie xi+1 = xi * -x^2/((2*i)*(2*i+1)) ... x0 = x
; sin(x) = x/1! - x^3/3! + x^5/5! - x^7/7! + x^9/9! - ...

.global CalcSin
CalcSin:

	rcall	Calc		; calculator
; offset 0 (8): convert angle to radians
	.byte	C_TORAD		; angle to radians
; offset 1 (9): normalize angle into range 0..PI*2
	.byte	C_ARG		; normalize angle (x) (uses TEMP_1, TEMP_2)
; offset 2: normalize angle into range 0..PI (if x >= PI then x = 2*PI - x)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST(CONST_PI) ; load constant PI (x,x,PI)
	.byte	C_LT		; check if x < PI (x,1/0)
	.byte	C_SETMEM(TEMP_1) ; save 1/0 into temp 1 (0=result will be negative)
	.byte	C_JUMPT		; skip if x < PI (x)
	.byte	3		; jump to offset 11 (11-8=3)
; offset 8:
	.byte	C_CONST(CONST_PI2) ; load constant PI*2 (x,PI*2)
	.byte	C_EXC		; exchange (PI*2,x)
	.byte	C_SUB		; subtract (PI*2-x)
; offset 11: number is zero, result will be zero
	.byte	C_JUMPZ		; skip if x = 0 (x)
	.byte	37		; jump to offset 50 (50-13=37)
; offset 13: number is PI, result will be zero
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST(CONST_PI) ; load constant PI (x,x,PI)
	.byte	C_SUB		; subtract (x,x-PI)
	.byte	C_JUMPF		; jump if x = PI, result will be 0
	.byte	36		; jump to offset 54 (54-18=36)
; offset 18: prepare square -x^2 into TEMP_2
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_SQR		; square (x, x^2)
	.byte	C_NEG		; negate (x, -x^2)
	.byte	C_SETMEMDEL(TEMP_2) ; save -x^2 into TEMP_2
; offset 22: prepare factorial coefficient 1 into TEMP_3
	.byte	C_CONST1	; load constant 1 (x,1)
	.byte	C_SETMEMDEL(TEMP_3) ; save 1 into TEMP_3
; offset 24: prepare member x into TEMP_4
	.byte	C_SETMEM(TEMP_4) ; save x into TEMP 4

; ===== start of loop
; offset 25: multiply member by -x^2
	.byte	C_GETMEM(TEMP_4) ; load member (res,mem)
	.byte	C_GETMEM(TEMP_2) ; load -x^2 (res,mem,-x^2)
	.byte	C_MUL		; multiply member by -x^2 (res,mem*-x^2)
; offset 28: increment factorial coefficient
	.byte	C_GETMEM(TEMP_3) ; load factorial coefficient form TEMP_3 (res,mem2,coef)
	.byte	C_INC		; increment (res,mem2,coef+1)
	.byte	C_SETMEM(TEMP_3) ; save new factorial coefficient
; offset 31: divide member by factorial coefficient
	.byte	C_DIV		; divide (res,mem2/coef2)
; offset 32: increment factorial coefficient again
	.byte	C_GETMEM(TEMP_3) ; load factorial coefficient form TEMP_3 (res,mem3,coef2)
	.byte	C_INC		; increment (res,mem3,coef2+1)
	.byte	C_SETMEM(TEMP_3) ; save new factorial coefficient (res,mem3,coef3)
; offset 35: divide member by factorial coefficient
	.byte	C_DIV		; divide (res,mem3/coef3)
; offset 36: save new member
	.byte	C_SETMEM(TEMP_4) ; save member
; offset 37: add member to accumulator and loop if meaningful
	.byte	C_ADDLOOP	; add and loop
	.byte	-14		; jump to offset 25 (25-39=-14)

; ===== clip result to range -1..+1
; offset 39:
	.byte	C_DUP		; duplicate (res,res)
	.byte	C_CONST1	; load constant 1 (res,res,1)
	.byte	C_LT		; check if res < 1 (res,0/1)
	.byte	C_JUMPT		; skip if res < 1 (res)
	.byte	2		; skip to offset 46 (46-44=2)
; offset 44:
	.byte	C_DEL		; delete result
	.byte	C_CONST1	; load constant 1 (1)

; ====== negate result
; offset 46:
	.byte	C_GETMEM(TEMP_1) ; load memory 0 ("positive flag")
	.byte	C_JUMPT		; skip if result is positive
	.byte	1		; jump to offset 50 (50-49=1)
; offset 49
	.byte	C_NEG		; negate result
; offset 50
	.byte	C_END		; end
; offset 51
	.balign 2		; align
; offset 52
	ret

; ===== result will be 0
; offset 54:
	.byte	C_DEL		; delete x
	.byte	C_CONST0	; load constant 0
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                             Tangent (C_TAN)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
; tan(x) = sin(x)/cos(x)

.global CalcTan
CalcTan:

	rcall	Calc		; calculator (x)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_SIN		; sinus (x,sin(x))
	.byte	C_EXC		; exchange (sin(x),x)
	.byte	C_COS		; cosinus (sin(x),cos(x))
	.byte	C_DIV		; divide
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                     Arcus Sine in radians (C_ASNRAD)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3
; ----------------------------------------------------------------------------
; result is in range -PI/2..+PI/2
;  Taylor serie xi+1 = xi * (2*i-1)^2*x^2 / ((2*i)*(2*i+1)) ... x0 = x
;  arcsin(x) = x + x^3/2/3 + 3*x^5/2/4/5 + 3*5*x^7/2/4/6/7 +
;  For x > 0.75 we use alternate method via arccos: sqrt(1 - x^2)

.global CalcAsnRad
CalcAsnRad:

	rcall	Calc		; calculator (x)
; offset 0: number is zero, result will be zero
	.byte	C_JUMPZ		; jump if number is zero (x)
	.byte	55		; jump to offset 57 (57-2=55)
; offset 2: save sign (1 if number is > 0)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_GR0		; check if x > 0 (x,1/0 = S)
	.byte	C_EXC		; exchange (S,x)
; offset 5: absolute value
	.byte	C_ABS		; absolute value (S,x)
; offset 6: number > 1 is invalid
	.byte	C_DUP		; duplicate (S,x,x)
	.byte	C_CONST1	; load constant 1 (S,x,x,1)
	.byte	C_GR		; check if x > 1 (S,x,0/1)
	.byte	C_JUMPT		; jump if x > 1 (argument error) (S,x)
	.byte	49		; jump to offset 60 (60-11=49)
; offset 11: check if use alternate method (1 if not using alternate method)
; - if x > 0.75, we use sqrt(1 - x^2)
	.byte	C_DUP		; duplicate (S,x,x)
	.byte	C_CONST(CONST_075) ; constant 0.75 (S,x,x,0.75)
	.byte	C_LTEQ		; check if x <= 0.75 (S,x,0/1 = A)
	.byte	C_JUMPNZ	; jump if x <= 0.75 (S,x,A)
	.byte	6		; jump to offset 22 (22-16=6)
; offset 16: prepare alternative method - use sqrt(1 - x^2)
	.byte	C_EXC		; exchange (S,A,x)
	.byte	C_SQR		; square (S,A,x^2)
	.byte	C_DEC		; decrement (S,A,x^2-1)
	.byte	C_NEG		; negate (S,A,1 - x^2)
	.byte	C_SQRT		; square root (S,A,sqrt(1 - x^2))
	.byte	C_EXC		; exchange (S,sqrt(1 - x^2),A)
; offset 22: square -> TEMP_1
	.byte	C_EXC		; exchange (S,A,x)
	.byte	C_DUP		; duplicate (S,A,x,x)
	.byte	C_SQR		; square (S,A,x,x^2)
	.byte	C_SETMEMDEL(TEMP_1) ; save temp3 (S,A,x)
; offset 26: prepare factorial coefficient -> TEMP_2
	.byte	C_CONST1	; load constant 1 (S,A,x,1)
	.byte	C_SETMEMDEL(TEMP_2) ; save factorial coefficient (S,A,x)
; offset 28: prepare member -> TEMP_3
	.byte	C_SETMEM(TEMP_3) ; save member (S,A,x)

; ===== start of loop
; offset 29: multiply member by x^2
	.byte	C_GETMEM(TEMP_3) ; get member (S,A,res,mem)
	.byte	C_GETMEM(TEMP_1) ; get square (S,A,res,mem,x^2)
	.byte	C_MUL		; multiply (S,A,res,mem*x^2)
; offset 32: multiply member by coefficient^2
	.byte	C_GETMEM(TEMP_2) ; load factorial coefficient (S,A,res,mem*x^2,fac)
	.byte	C_MUL		; multiply (S,A,res,mem*x^2*fac)
	.byte	C_GETMEM(TEMP_2) ; load factorial coefficient (S,A,res,mem2,fac)
	.byte	C_MUL		; multiply (S,A,res,mem2*fac)
; offset 36: increment factorial coefficient
	.byte	C_GETMEM(TEMP_2) ; load factorial coefficient (S,A,res,mem3,fac)
	.byte	C_INC		; increment coefficient
	.byte	C_SETMEM(TEMP_2) ; save coefficient
; offset 39: divide nember by coefficient
	.byte	C_DIV		; divide (S,A,res,mem3/fac)
; offset 40: increment factorial coefficient
	.byte	C_GETMEM(TEMP_2) ; load factorial coefficient (S,A,res,mem4,fac)
	.byte	C_INC		; increment coefficient
	.byte	C_SETMEM(TEMP_2) ; save coefficient
; offset 43: divide nember by coefficient
	.byte	C_DIV		; divide (S,A,res,mem4/fac)
; offset 44: save member
	.byte	C_SETMEM(TEMP_3) ; save member
; offset 45: add member to accumulator and loop if meaningful
	.byte	C_ADDLOOP	; add and loop
	.byte	-18		; jump to offset 29 (29-47=-18)

; offset 47: correction for alternate method (PI/2 - y)
	.byte	C_EXC		; exchange (S,y,A)
	.byte	C_JUMPT		; jump if not alternative flag
	.byte	3		; jump to offset 53 (53-50=3)
; offset 50:
	.byte	C_NEG		; negate
	.byte	C_CONST(CONST_PI05) ; load constant PI/2
	.byte	C_ADD		; add constant PI/2
; offset 53: negate result
	.byte	C_EXC		; exchange (y,S)
	.byte	C_JUMPT		; jump if not negative
	.byte	1		; jump to offset 57 (57-56=1)
; offset 56
	.byte	C_NEG		; negate result
; offset 57
	.byte	C_END		; end
; offset 58
	.balign 2		; align
; offset 58
	ret

; offset 60: argument error (> 1)
	.byte	C_DEL		; delete x (S)
	.byte	C_CONST(CONST_PI05) ; load constant PI/2 (S,PI/2)
	.byte	C_ERROR		; set error flag
	.byte	C_JMP		; jump back
	.byte	-12		; jump to offset 53 (53-65=-12)
; offset 65
	.balign 2		; align

; ----------------------------------------------------------------------------
;                       Arcus Sine (C_ASN)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3
; ----------------------------------------------------------------------------

.global CalcAsn
CalcAsn:
	rcall	CalcAsnRad	; ascus sine in radians

; CalcFromRad must follow

; ----------------------------------------------------------------------------
;                             FromRad (C_FROMRAD)
; ----------------------------------------------------------------------------

.global CalcFromRad
CalcFromRad:
	ldd	r24,Y+DATA_UNIT	; get current angle unit
	cpi	r24,UNIT_RAD	; radians?
	breq	CalcToRad9	; angle is already in radians
	ldi	r24,CONST_180PI	; conversion to degrees
	brcs	CalcToRad4	; unit is degree
	ldi	r24,CONST_200PI	; conversion to grads
	rjmp	CalcToRad4	; conversion

; ----------------------------------------------------------------------------
;                             ToRad (C_TORAD)
; ----------------------------------------------------------------------------
;#define UNIT_DEG	0	// degrees
;#define UNIT_RAD	1	// radians
;#define UNIT_GRAD	2	// grads

.global CalcToRad
CalcToRad:
	ldd	r24,Y+DATA_UNIT	; get current angle unit
	cpi	r24,UNIT_RAD	; radians?
	breq	CalcToRad9	; angle is already in radians
	ldi	r24,CONST_PI180	; conversion from degrees
	brcs	CalcToRad4	; unit is degree
	ldi	r24,CONST_PI200	; conversion from grads
CalcToRad4:
; INPUT: R24 = index of the constant in ConstTab
; CALCULATOR STACK: +1
	rcall	CalcConst	; load constant to the stack
; CALCULATOR STACK: -1
	rcall	CalcMul		; multiply angle by the constant
CalcToRad9:
	ret

; ----------------------------------------------------------------------------
;                             Arcus Cosine (C_ACS)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3
; ----------------------------------------------------------------------------
; acs(x) = pi/2 - asn(x)

.global CalcAcs
CalcAcs:

	rcall	Calc		; calculator
	.byte	C_ASNRAD	; arcus sinus in radians (asn(x))
	.byte	C_CONST(CONST_PI05) ; stack pi/2 (asn(x),pi/2)
	.byte	C_SUB		; subtract (asn(x)-pi/2)
	.byte	C_NEG		; negate (pi/2-asn(x))
	.byte	C_FROMRAD	; angle from radians
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                             Arcus Tangent (C_ATN)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3
; ----------------------------------------------------------------------------
; atan(x) = asin(x / sqrt(1 + x^2))

.global CalcAtn
CalcAtn:
	rcall	Calc		; calculator (x)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_SQR		; square (x,x^2)
	.byte	C_INC		; increment (x,x^2+1)
	.byte	C_SQRT		; square root (x,sqrt(x^2+1))
	.byte	C_DIV		; divide (x/sqrt(x^2+1))
	.byte	C_ASN		; arcus sine
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                             Ln (C_LN)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
;  Taylor serie D = (x-1)/(x+1),  xi+1 = xi*D^2*(i*2-1)/(i*2+1) ... x0 = 2*D
;  ln(x) = 2*D*(1 + D^2/3 + D^4/5 + D^6/7 ...)

; offset -12: number is 1, result will be 0
	.byte	C_DEL		; delete number
	.byte	C_CONST0	; load constant 0
	.byte	C_JMP		; jump
	.byte	3		; jump to offset -5 (-5--8=3)

; offset -8: error, ln(0)
	.byte	C_DEL		; delete number
	.byte	C_OVER		; load overflow value (and set error)
	.byte	C_NEG		; negate (to indicate -9.99+99)
; offset -5
	.byte	C_END		; end
; offset -4
	.balign 2		; align
; offset -4
	ret
; offset -2

.global CalcLn
CalcLn:
	rcall	Calc		; calculator (x)
; offset 0: number is = zero, invalid
	.byte	C_JUMPZ		; jump if number is = 0 (x)
	.byte	-10		; jump to offset -8 (-8-2 = -10)
; offset 2: number is = 1, result will be 0
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST1	; load constant 1 (x,x,1)
	.byte	C_EQU		; check if number is x = 1 (x,0/1)
	.byte	C_JUMPT		; jump if x = 1
	.byte	-19		; jump to offset -12 (-12-7 = -19)
; offset 7: check if number is > 0
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_GR0		; check if number is > 0 (x,1/0)
	.byte	C_JUMPT		; jump if number is > 0, OK (x)
	.byte	2		; jump to offset 13 (13-11=2)
; offset 11: error, argument is < 0
	.byte	C_ABS		; absolute value (x)
	.byte	C_ERROR		; set error flag
; offset 13: check if number is < 1 (result will be negative)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST1	; load constant 1 (x,x,1)
	.byte	C_GREQ		; check if number is >= 1 (x,0/1)
	.byte	C_SETMEM(TEMP_1) ; save 1/0 into temp 1 (0=result will be negative)
	.byte	C_JUMPT		; skip if x >= 1 (x)
	.byte	1		; jump to offset 20 (20-19=1)
; offset 19: reciprocal value (result will be negative)
	.byte	C_REC		; reciprocal value (1/x)
; offset 20:
	.byte	C_END		; end
	.balign 2		; align

; ----- load exponent and set current exponent to "1" (to get range 1.000...9.999)
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck	; get top number and exponent -> Z, R24
	ldi	r23,EXP_ONE
	std	Z+0,r23		; set exponent to "1" base

; ----- load exponent to the stack
; INPUT: R24 = unsigned integer
; CALCULATOR STACK: +1
	rcall	CalcStackB	; load exponent (x,e)

; ----- subtract bias from exponent

	rcall	Calc
; offset 0
	.byte	C_BYTE,EXP_BIAS	; load bias (x,e,BIAS)
; offset 2:
	.byte	C_SUB		; subtract BIAS (x,e-BIAS)

; offset 3: convert exponent to decimal value - multiply by ln(10)
	.byte	C_CONST(CONST_LN10) ; load constant ln(10) (x,e,ln10)
	.byte	C_MUL		; multiply (x,e*ln10)
	.byte	C_EXC		; exchange (e,x)
; offset 6: prepare number D = (x-1)/(1+x) -> TEMP_2 (member) and result accumulator
	.byte	C_DUP		; duplicate (e,x,x)
	.byte	C_DEC		; decrement (e,x,x-1)
	.byte	C_EXC		; exchange (e,x-1,x)
	.byte	C_INC		; increment (e,x-1,x+1)
	.byte	C_DIV		; divide (e,(x-1)/(x+1)=D)
	.byte	C_SETMEM(TEMP_2) ; save D into temp2 (e,D)
; offset 12: square D^2 -> TEMP_3
	.byte	C_SQR		; square (e,D^2)
	.byte	C_SETMEMDEL(TEMP_3) ; save D^2 (e)
	.byte	C_GETMEM(TEMP_2) ; get D to accumulator (e,D)
; offset 15: prepare factorial coefficient 1 -> TEMP_4
	.byte	C_CONST1	; load constant 1 (e,D,1)
	.byte	C_SETMEMDEL(TEMP_4) ; save factorial coefficient (e,D)

; ===== start of loop
; offset 17: multiply member by D^2
	.byte	C_GETMEM(TEMP_2) ; load member (e,res,mem)
	.byte	C_GETMEM(TEMP_3) ; load D^2 (e,res,mem,D^2)
	.byte	C_MUL		; multiply member by D^2 (e,res,mem*D^2)
	.byte	C_SETMEM(TEMP_2) ; save new member (e,res,mem*D^2)
; offset 21: increase factorial coefficient by 2
	.byte	C_GETMEM(TEMP_4) ; load factorial coefficient (e,res,mem*D^2,fac)
	.byte	C_INC		; increment (e,res,mem*D^2,fac+1)
	.byte	C_INC		; increment (e,res,mem*D^2,fac+2)
	.byte	C_SETMEM(TEMP_4) ; save new factorial coefficient (e,res,mem*D^2,fac+2)
; offset 25: divide member by factorial coefficieint
	.byte	C_DIV		; divide (e,res,mem*D^2/(fac+2)
; offset 26: add member to accumulator and loop if meaningful
	.byte	C_ADDLOOP	; add and loop (e,res2)
	.byte	-11		; jump to offset 17 (17-28=-11)

; offset 28: multiply result by 2
	.byte	C_DUP		; duplicate (e,res,res)
	.byte	C_ADD		; add (e,2*res)
; offset 30: add exponent
	.byte	C_ADD		; add (e+res3)
; offset 31: negate result
	.byte	C_GETMEM(TEMP_1) ; load negative flag
	.byte	C_JUMPT		; jump if number was >= 1
	.byte	1		; jump to offset 35 (35-34=1)
; offset 34:
	.byte	C_NEG		; negate result
; offset 35:
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                             Exp (C_EXP)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3
; ----------------------------------------------------------------------------
;  Taylor serie xi+1 = xi * x / (i+1) ... x0 = 1
;  exp(x) = 1 + x/1! + x^2/2! + x^3/3! + x^4/4! + x^5/5! + ...

; offset -6: number is 0, result will be 1
	.byte	C_INC		; set constant 1
; pffset -5
	.byte	C_END		; end
; offset -4
	.balign 2		; align
; offset -4
	ret
; offset -2

.global CalcExp
CalcExp:
	rcall	Calc		; calculator (x)
; offset 0: zero -> result is 1
	.byte	C_JUMPZ		; jump if zero, result will be 1
	.byte	-8		; jump to offset -6 (-6-2=-8)

; offset 2: check overflow
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST(CONST_EXPMAX) ; constant exponent max (x,x,max)
	.byte	C_LT		; check < (x,0/1)
	.byte	C_JUMPT		; number is OK (x < expmax)
	.byte	4		; jump to offset 11 (11-7=4)
; offset 7: overflow
	.byte	C_DEL		; delete number ()
	.byte	C_OVER		; load overflow value, set error flag (o)
	.byte	C_JMP		; jump
	.byte	-16		; jump to offset -5 (-5-11=-16)

; offset 11: check underflow
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST(CONST_EXPMIN) ; constant exponent min (x,x,min)
	.byte	C_GR		; check > (x,0/1)
	.byte	C_JUMPT		; number is OK
	.byte	4		; jump to offset 20 (20-16=4)
; offset 16: underflow
	.byte	C_DEL		; delete number ()
	.byte	C_UNDER		; load underflow value, set error flag (u)
	.byte	C_JMP		; jump
	.byte	-25		; jump to offset -5 (-5-20=-25)

; offset 20: extract integer part of exponent (= exponent based 10, 10^e)
	.byte	C_DUP		; duplicate (x,x)
	.byte	C_CONST(CONST_RLN10) ; constant 1/ln(10) (x,x,1/ln(10))
	.byte	C_MUL		; multiply (x,x/ln(10)) ... to convert to logarithm based 10
	.byte	C_TRUNC		; truncate (x,int(x/ln(10))) ... get 10-based exponent
	.byte	C_SETMEM(TEMP_2) ; save exponent e -> temp2
	.byte	C_CONST(CONST_LN10) ; constant ln(10) (x,int(x/ln(10)), ln(10))
	.byte	C_MUL		; multiply (x,int(x/ln(10))*ln(10) = ln(e))
	.byte	C_SUB		; subtract (x-ln(e)) ... fraction of logarithm

; offset 28: save multiplier (fraction part) -> TEMP_1
	.byte	C_SETMEMDEL(TEMP_1) ; save multiplier x -> temp1 ()
	.byte	C_GETMEM(TEMP_2) ; load exponent (e)
; offset 30: prepare factorial coefficient -> TEMP_2
	.byte	C_CONST0	; load constant 0 (e,0)
	.byte	C_SETMEMDEL(TEMP_2) ; save factorial coefficient -> temp2 (e)
; offset 32: save member -> TEMP_3
	.byte	C_CONST1	; load constant 1 (e,1)
	.byte	C_SETMEM(TEMP_3) ; save member '1' -> temp3 (e,1)

; ===== start of loop
; offset 34: multiply member by x
	.byte	C_GETMEM(TEMP_3) ; get member temp3 (e,res,mem)
	.byte	C_GETMEM(TEMP_1) ; get multiplier x temp1 (e,res,mem,x)
	.byte	C_MUL		; multiply (e,res,mem*x)
; offset 37: increase factrorial coefficient
	.byte	C_GETMEM(TEMP_2) ; get factorial temp2 (e,res,mem*x,fac)
	.byte	C_INC		; increment (e,res,mem*x,fac+1)
	.byte	C_SETMEM(TEMP_2) ; save new factorial temp2 (e,res,mem*x,fac+1)
; offset 40: divide member by factorial coefficient
	.byte	C_DIV		; divide (e,res,mem*x/(fac+1))
	.byte	C_SETMEM(TEMP_3) ; save member temp3 (e,res,mem2)
; offset 42: add member to accumulator and loop if meaningful
	.byte	C_ADDLOOP	; add and loop (e,res2)
	.byte	-10		; jump to offset 34 (34-44=-10)
; offset 44:
	.byte	C_EXC		; exchange (res2,e)
; offset 45: add bias to exponent
	.byte	C_BYTE,EXP_BIAS	; load bias (res2,e,BIAS)
	.byte	C_ADD		; add bias to exponent
	.byte	C_END		; end
	.balign 2		; align

; ----- get exponent
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcUnstackB	; get exponent

; ----- multiply result by integer part
; OUTPUT: R31:R30 = address of new top number 0
; DESTROYS: R25, R24
; CALCULATOR STACK: +1
	push	r24
	rcall	CalcConst1	; load constant '1'
	pop	r24
	std	Z+0,r24		; set exponent
; DESTROYS: all
; CALCULATOR STACK: -1
	rjmp	CalcMul		; multiply

; ----------------------------------------------------------------------------
;                             Log10 (C_LOG10)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------

.global CalcLog10
CalcLog10:
	rcall	Calc
	.byte	C_LN		; logarithm
	.byte	C_CONST(CONST_RLN10) ; constant 1/ln(10)
	.byte	C_MUL		; multiply
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                             Exp10 (C_EXP10)
; ----------------------------------------------------------------------------
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------

.global CalcExp10
CalcExp10:
	rcall	Calc
	.byte	C_CONST(CONST_LN10) ; constant ln(10)
	.byte	C_MUL		; multiply
	.byte	C_EXP		; exponent
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                       Stack tabled constant (C_CONSTAB)
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the constant in ConstTab
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcConst
CalcConst:

; ----- create new number on top of stack
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number -> Z
	movw	r26,r30		; X <- new number

; ----- prepare constant address -> Z

	ldi	r25,CNUM_BYTES	; length of number
	mul	r25,r24		; recalculate number index to offset
	movw	r30,r0		; R31:R30 <- number offset
	subi	r30,lo8(-(ConstTab)) ; number address -> R31:R30
	sbci	r31,hi8(-(ConstTab))

; ----- load constant

2:	lpm	r24,Z+
	st	X+,r24
	dec	r25
	brne	2b
	ret

; ----------------------------------------------------------------------------
;                          overflow number (C_OVER)
; ----------------------------------------------------------------------------

.global CalcOver
CalcOver:
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; new number
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24
	rjmp	NumSetOver	; set overflow number 9.9999999+99 with error

; ----------------------------------------------------------------------------
;                          unerflow number (C_UNDER)
; ----------------------------------------------------------------------------

.global CalcUnder
CalcUnder:
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; new number
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24
	rjmp	NumSetUnder	; set underflow number 1e-99 with error

; ----------------------------------------------------------------------------
;                      Calculator macro jump table
; ----------------------------------------------------------------------------

.global CalcJmpTab
CalcJmpTab:

; Relative jumps: signed offset in next byte is relative to following byte

; ... control operations (22)
	.word	CalcNop		; #define C_NOP		// no function (required by byte align)
	.word	CalcEnd		; #define C_END		// end macro
	.word	CalcDel		; #define C_DEL		// delete top number from calculator stack
	.word	CalcDup		; #define C_DUP		// duplicate number on calculator stack
	.word	CalcDup2	; #define C_DUP2	// duplicate pre2-last number on calculator stack
	.word	CalcExc		; #define C_EXC		// exchange 2 numbers on top of calculator stack
	.word	CalcExc2	; #define C_EXC2	// exchange 2 numbers on pre-top of calculator stack
	.word	CalcJump	; #define C_JMP		// relative jump
	.word	CalcJumpT	; #define C_JUMPT	// relative jump if top number is true, <> 0, delete it
	.word	CalcJumpF	; #define C_JUMPF	// relative jump if top number is false, = 0, delete it
	.word	CalcJumpNZ	; #define C_JUMPNZ	// relative jump if top number is non zero, do not delete it
	.word	CalcJumpZ	; #define C_JUMPZ	// relative jump if top number is zero, do not delete it
	.word	CalcError	; #define C_ERROR	// set error flag
	.word	CalcConst1	; #define C_CONST1	// load constant 1
	.word	CalcConst0	; #define C_CONST0	// load constant 0
	.word	CalcAddLoop	; #define C_ADDLOOP	// add serie member to accumulator and loop if meaningful
	.word	CalcOver	; #define C_OVER	// load overflow number
	.word	CalcUnder	; #define C_UNDER	// load underflow number
	.word	CalcByte	; #define C_BYTE	// load unsigned byte, will follow
	.word	CalcExecPar	; #define C_EXECPAR	// execute command from R_PARAM register
	.word	CalcGetSeed	; #define C_GETSEED	// load random seed into stack
	.word	CalcSetSeed	; #define C_SETSEED	// save random seed from stack

; ... arithmetics and bitwise operations (2 operands) (7)
	.word	CalcMul		; #define C_MUL		// * multiply
	.word	CalcDiv		; #define C_DIV		// / division
	.word	CalcMod		; #define C_MOD		// modulus with trunc rounding
	.word	CalcMod2	; #define C_MOD2	// modulus with floor rounding
	.word	CalcSub		; #define C_SUB		// - subtract
	.word	CalcAdd		; #define C_ADD		// + addition
	.word	CalcPow		; #define C_POW		// ^ power (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)

; ... comparisons (do not change order of comparison codes - hardcoded in function CalcCmp) (10)
	.word	CalcCmp		; #define C_LTEQ	// <=
	.word	CalcCmp		; #define C_GREQ	// >=
	.word	CalcCmp		; #define C_NEQU	// <>
	.word	CalcLt0		; #define C_LT0		// < 0 (less 0 but not equ 0)
	.word	CalcCmp		; #define C_GR		// >
	.word	CalcCmp		; #define C_LT		// <
	.word	CalcCmp		; #define C_EQU		// =
	.word	CalcGr0		; #define C_GR0		// > 0 (greater 0 but not equ 0)
	.word	CalcLtEq0	; #define C_LTEQ0	// <= 0 (less or equ 0)
	.word	CalcGrEq0	; #define C_GREQ0	// >= 0 (greater or equ 0)

; ... functions 1 (misc) (14)
	.word	CalcRec		; #define C_REC		// 1/x reciprocal value
	.word	CalcInc		; #define C_INC		// increment +1
	.word	CalcDec		; #define C_DEC		// decrement -1
	.word	CalcNeg		; #define C_NEG		// unary- (NEG)
	.word	CalcSgn		; #define C_SGN		// SGN
	.word	CalcAbs		; #define C_ABS		// ABS
	.word	CalcTrunc	; #define C_TRUNC	// truncate (round towards zero)
	.word	CalcFrac	; #define C_FRAC	// fraction
	.word	CalcFloor	; #define C_FLOOR	// round down (uses TEMP_1)
	.word	CalcCeil	; #define C_CEIL	// round up
	.word	CalcRound	; #define C_ROUND	// round nearest
	.word	CalcNot		; #define C_NOT		// NOT
	.word	CalcFact	; #define C_FACT	// x!
	.word	CalcRand	; #define C_RAND	// random

; ... functions 2 (angle) (12)
	.word	CalcArg		; #define C_ARG		// normalize angle argument (uses TEMP_1, TEMP_2)
	.word	CalcSin		; #define C_SIN		// SIN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcCos		; #define C_COS		// COS (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcTan		; #define C_TAN		// TAN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcAsn		; #define C_ASN		// ASN (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcAsnRad	; #define C_ASNRAD	// ASN in radians (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcAcs		; #define C_ACS		// ACS (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcAtn		; #define C_ATN		// ATN (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcToRad	; #define C_TORAD	// TORAD - angle to radians
	.word	CalcFromRad	; #define C_FROMRAD	// FROMRAD - angle from radians
	.word	CalcPR		; #define C_PR		// Convert polar to cartesian (r,a) -> (x,y)
	.word	CalcRP		; #define C_RP		// Convert cartesian to polar (x,y) -> (r,a)

; ... functions 3 (logarithm) (6)
	.word	CalcLn		; #define C_LN		// LN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcExp		; #define C_EXP		// EXP (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcLog10	; #define C_LOG10	// LOG10 (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcExp10	; #define C_EXP10	// EXP10 (uses TEMP_1, TEMP_2, TEMP_3)
	.word	CalcSqrt	; #define C_SQRT	// SQRT (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
	.word	CalcSqr		; #define C_SQR		// x^2 square

; ... groups (compound literals) (4)
;	bit 7: flag of compound literal
;	bit 5..6: group 0..3
;	bit 0..4: parameter 0..31

	.word	CalcConst	; #define C_CONST_GRP	// stack tabled constant (parameter is index in ConstTab)
	.word	CalcSetMem	; #define C_SETMEM_GRP	// set memory from stack (parameter is index of the number)
	.word	CalcGetMem	; #define C_GETMEM_GRP	// get number from memory into stack (parameter is index of the number)
	.word	CalcSetMemDel	; #define C_SETMEMDEL_GRP // set memory from stack and delete (parameter is index of the number)

; ----------------------------------------------------------------------------
;              execute command from R_PARAM register (C_EXECPAR)
; ----------------------------------------------------------------------------

.global CalcExecPar
CalcExecPar:

	pop	r31		; (HIGH)
	pop	r30		; (LOW) destroy return address

	mov	r24,R_PARAM	; required parameter
	rjmp	CalcEnter	; execute

; ----------------------------------------------------------------------------
;                     Calculator macro interpreter
; ----------------------------------------------------------------------------
; INPUT: stack = RCALL return address 2 bytes, calculator literals follow RCALL.
; ----------------------------------------------------------------------------
; Return address will be word-aligned (use ".balign 2" after program block).

; RCALL procedure: [SP] <- addr LOW, SP-1, [SP] <- addr HIGH, SP-1
; To load byte after rcall: pop ZH, pop ZL, add ZL, adc ZH, lpm r24,Z+
; To jump back: lsr ZH, ror ZL, ijmp (or push ZL, push ZH, ret)


; DESTROYS: R31, R30, R27..R24, R1, R0
; ----------------------------------------------------------------------------

.global CalcEditStop
CalcEditStop:
	call	EditStopDispC

; ----- get pointer to literals from the stack and push registers -> R_LITH:R_LITL

.global Calc
Calc:
	pop	r25		; (HIGH)
	pop	r24		; (LOW) get return address from the stack

	push	R_LITL		; push current literal pointer
	push	R_LITH

	movw	R_LITL,r24	; R_LITL <- return address
	add	R_LITL,R_LITL
	adc	R_LITH,R_LITH	; convert to byte offset

; ----- load next literal -> R24
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal

.global CalcReEnter
CalcReEnter:

; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rcall	CalcLit		; get literal -> R24

; ----- compound literal (bit 7 is set)
; bit 7: flag of compound literal
; bit 5..6: subgroup 0..3
; bit 0..4: parameter 0..31

; Enter function by R24

.global CalcEnter
CalcEnter:
	mov	r25,r24		; save literal
	tst	r24		; compound literal?
	brpl	Calc4		; no

	andi	r25,0x1f	; isolate parameter bits
	swap	r24		; swap bits
	lsr	r24		; rotate subgroup to bit position 0
	andi	r24,B0+B1	; isolate bits of the subgroup
	subi	r24,-C_GROUP_BASE ; add group base

; ----- jump to operation R24 (destroys R0, R31, R30)

Calc4:
	ldi	r30,lo8(CalcJmpTab) ; Z <- jump table
	ldi	r31,hi8(CalcJmpTab)
	add	r30,r24
	adc	r31,R_ZERO
	add	r30,r24		; Z <- offset in jump table
	adc	r31,R_ZERO
	lpm	r0,Z+		; R25 <- load jump address LOW
	lpm	r31,Z		; R31 <- load jump address HIGH
	mov	r30,r0		; Z <- jump address (byte offset)
	lsr	r31
	ror	r30		; convert address to word index
	mov	r24,r25		; R24 <- function parameter or literal
	icall			; rcall function (R_LITH:R_LITL=literal pointer, R24=parameter or literal)
	rjmp	CalcReEnter	; process next literal

; ----------------------------------------------------------------------------
;                          Reset calculator stack
; ----------------------------------------------------------------------------

.global CalcInit
CalcInit:

	; reset end of calculator stack
	ldi	r24,lo8(CalcStack)
	std	Y+DATA_STKEND,r24
	ldi	r24,hi8(CalcStack)
	std	Y+DATA_STKEND+1,r24

	; reset levels of arithmetics operations
	std	Y+DATA_LEVEL,R_ZERO ; current level of arithmetics operations

	; reset register X and Last
; OUTPUT: R31:R30 = address of new top number 0
; DESTROYS: R24
; CALCULATOR STACK: +1
	rcall	CalcConst0	; constant 0

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcSetMemX	; clear X register
	ldi	r24,REG_LAST
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcSetMemDel	; clear Last register

	std	Y+DATA_LAST,R_ZERO ; no last operation

	rjmp	ExecLevelInit	; initialize base level of arithmetics operations
