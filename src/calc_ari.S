; ****************************************************************************
;
;                     Calculator arithmetics operations
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                              Exchange numbers
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of number 1
;	 R27:R26 (X) = addres of number 2
; ----------------------------------------------------------------------------

.global NumExc
NumExc:
	ldi	r25,CNUM_BYTES
2:	ld	r24,X
	ld	r23,Z
	st	Z+,r24
	st	X+,r23
	dec	r25
	brne	2b
	rjmp	CNumCopy7

; ----------------------------------------------------------------------------
;                      Copy number X -> Z (extended register)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
; ----------------------------------------------------------------------------

.global RNumCopy
RNumCopy:
	ldi	r25,RNUM_BYTES

2:	ld	r24,X+
	st	Z+,r24
	dec	r25
	brne	2b

	sbiw	r26,RNUM_BYTES
	sbiw	r30,RNUM_BYTES
	ret

; ----------------------------------------------------------------------------
;                      Copy number X -> Z (base register)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
; ----------------------------------------------------------------------------

.global BNumCopy
BNumCopy:
	ldi	r25,BNUM_BYTES

2:	ld	r24,X+
	st	Z+,r24
	dec	r25
	brne	2b

	sbiw	r26,BNUM_BYTES
	sbiw	r30,BNUM_BYTES
	ret

; ----------------------------------------------------------------------------
;                     Copy number X -> Z (system register)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
; ----------------------------------------------------------------------------

.global CNumCopy
CNumCopy:
	ldi	r25,CNUM_BYTES

2:	ld	r24,X+
	st	Z+,r24
	dec	r25
	brne	2b
CNumCopy7:
	sbiw	r26,CNUM_BYTES
CNumCopy8:
	sbiw	r30,CNUM_BYTES
CNumCopy9:
	ret

; ----------------------------------------------------------------------------
;                             Signum (C_SGN)
; ----------------------------------------------------------------------------
; Replace number on top of calculator stack by value -1, 0, 1.

.global CalcSgn
CalcSgn:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R25:R24 = exponent (0 = number is zero, 0xFFFF = overflow)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck
	breq	CNumCopy9	; zero number left unchanged

; ----- check sign
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; check if number is negative
	brcc	NumSet1		; number is not negative, set value 1

; NumSetM1 must follow

; ----------------------------------------------------------------------------
;                            Set number to -1
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25
; ----------------------------------------------------------------------------
; 80 99 00 00 00 00 00 00

.global NumSetM1
NumSetM1:
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0			; set number 0
	ldi	r25,EXP_ONE
	st	Z,r25			; store exponent
	ldi	r25,0x99		; set -1, sign and first digit
	std	Z+1,r25			; set sign and first digit
	ret

; ----------------------------------------------------------------------------
;                     Load constant 0 (C_CONST0)
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 = address of new top number 0
; DESTROYS: -
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcConst0
CalcConst0:

; ----- create new number on top of stack
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number -> Z

; NuMSet0 must follow

; ----------------------------------------------------------------------------
;                      Clear number, set to 0 (exponent = 0)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
; ----------------------------------------------------------------------------
; 00 00 00 00 00 00 00 00

.global NumSet0
NumSet0:
	push	r24
	ldi	r24,CNUM_BYTES
2:	st	Z+,R_ZERO
	dec	r24
	brne	2b
	pop	r24
	rjmp	CNumCopy8

; ----------------------------------------------------------------------------
;                     Load constant 1 (C_CONST1)
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 = address of new top number 1
; DESTROYS: R25
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcConst1
CalcConst1:

; ----- create new number on top of stack
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number -> Z

; NuMSet1 must follow

; ----------------------------------------------------------------------------
;                            Set number to 1
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25
; ----------------------------------------------------------------------------
; 80 01 00 00 00 00 00 00

.global NumSet1
NumSet1:
	; set exponent to 1
	ldi	r25,EXP_ONE
	rjmp	NumSetMin2

; ----------------------------------------------------------------------------
;      Increment exponent (with check overflow) = multiply number * 10
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
; ----------------------------------------------------------------------------

.global Mul10
Mul10:

.global ExpInc
ExpInc:
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R24 = exponent
;	 CY = exponent is not in valid range
	rcall	ExpIsValid	; check if exponent is in valid range EXP_MIN..EXP_MAX
	brcs	CNumCopy9	; exponent is not in valid range
	inc	r24		; increment exponent
	st	Z,r24		; save exponent
	cpi	r24,EXP_MAX+1	; check maximal exponent
	brcs	CNumCopy9	; exponent is OK

; NumSetOverS must follow

; ----------------------------------------------------------------------------
;                Set overflow number, remains sign
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
; ----------------------------------------------------------------------------

.global NumSetOverS
NumSetOverS:
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; check if number is negative
	brcc	NumSetOver	; number is not negative

; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24
	rcall	NumSetOver	; set overflow number 9.9999999+99
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rjmp	NumNeg		; negate number

; ----------------------------------------------------------------------------
;           Set overflow number (positive, number = 9.9999999+99)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24
; ----------------------------------------------------------------------------
; E3 09 99 99 99 99 99 00

.global NumSetOver
NumSetOver:
	rcall	CalcError		; set error

; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0			; set number to 0

	ldi	r25,EXP_OVER		; overflow exponent
	st	Z+,r25			; store exponent

	ldi	r25,9			; set sign to 0 and first digit to 9

; Note: In correct way, we should set all digits of CNUM to '9'.
; It brings problem when storing negative result into extended registers with 
; lower precission (rounding error + overflow exponent). Better to set only
; visible digits to '9'.

	ldi	r24,VMANT_BYTE		; mantissa length (in bytes)
2:	st	Z+,r25			; store one byte
	ldi	r25,0x99		; set all other digits to 0x99
	dec	r24			; loop counter
	brne	2b			; next loop
	sbiw	r30,VMANT_BYTE+1
	ret

; ----------------------------------------------------------------------------
;      Decrement exponent (with check underflow) = divide number / 10
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24
; ----------------------------------------------------------------------------

.global Div10
Div10:

.global ExpDec
ExpDec:
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R24 = exponent
;	 CY = exponent is not in valid range
	rcall	ExpIsValid	; check if exponent is in valid range EXP_MIN..EXP_MAX
	brcs	CNumCopy9	; exponent is not in valid range
	dec	r24		; decrement exponent
	st	Z,r24		; save exponent
	cpi	r24,EXP_MIN	; check minimal exponent
	brcc	CNumCopy9	; exponent is OK

; NumSetUnderS must follow

; ----------------------------------------------------------------------------
;                    Set underflow number, remains sign
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
; ----------------------------------------------------------------------------

.global NumSetUnderS
NumSetUnderS:
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; check if number is negative
	brcc	NumSetUnder	; number is not negative

; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24
	rcall	NumSetUnder	; set underflow number 
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rjmp	NumNeg		; negate number

; ----------------------------------------------------------------------------
;           Set underflow number (positive, number = 1-99)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25
; ----------------------------------------------------------------------------
; 1D 01 00 00 00 00 00 00

.global NumSetUnder
NumSetUnder:
	rcall	CalcError		; set error
	ldi	r25,EXP_UNDER		; underflow exponent
NumSetMin2:
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0			; set number 0
	st	Z,r25			; store exponent
	ldi	r25,1			; set sign to 0 and first digit to 1 
	std	Z+1,r25			; set sign and first digit
	ret

; ----------------------------------------------------------------------------
;                     Check if number is negative
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
;	  R24 = highest byte of mantissa
; ----------------------------------------------------------------------------

.global NumIsNeg
NumIsNeg:
	ldd	r24,Z+1		; get highest digit of mantissa
	cpi	r24,SIGN_THRES	; check if number is negative (NC = negative)
	rjmp	Ccf		; complement carry flag

; ----------------------------------------------------------------------------
;                 Check if number is zero (checks only exponent)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is zero
; DESTROYS: R24
; ----------------------------------------------------------------------------

.global NumIsZero
NumIsZero:
	ld	r24,Z		; load exponent
	cpi	r24,EXP_ZERO+1	; check if number is zero (CY = number is zero)
	ret

; ----------------------------------------------------------------------------
;             Check if number is overflow (checks only exponent)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is overflow
; DESTROYS: R24
; ----------------------------------------------------------------------------

.global NumIsOver
NumIsOver:
	ld	r24,Z		; load exponent
	cpi	r24,EXP_OVER	; check if number is overflow (NC = number is overflow)
	rjmp	Ccf		; complement carry flag

; ----------------------------------------------------------------------------
;       Check if number is underflow, but not zero (checks only exponent)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is underflow, but not zero
; DESTROYS: R24
; ----------------------------------------------------------------------------

.global NumIsUnder
NumIsUnder:
	ld	r24,Z		; load exponent
	cpi	r24,EXP_ZERO	; zero?
	breq	9f		; number is zero, it is OK
	cpi	r24,EXP_UNDER+1	; check if number is underflow (CY = number is underflow)
9:	ret

; ----------------------------------------------------------------------------
;      Check if exponent is in valid range EXP_MIN..EXP_MAX (not zero)
; ----------------------------------------------------------------------------
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R24 = exponent
;	 CY = exponent is not in valid range
; ----------------------------------------------------------------------------

.global ExpIsValid
ExpIsValid:
	ld	r24,Z		; load exponent
	cpi	r24,EXP_MIN	; underflow?
	brcs	Ccf9		; exponent is zero or underflow
	cpi	r24,EXP_MAX+1	; overflow? (CY = valid range)

; Ccf must follow

; ----------------------------------------------------------------------------
;                       Complement carry flag
; ----------------------------------------------------------------------------
; INPUT: C = input carry flag
; OUTPUT: ~C = complement carry flag
; ----------------------------------------------------------------------------

.global Ccf
Ccf:
	brcc	Ccf8		; carry not set -> set carry flag
	clc			; carry is set -> clear carry flag
	ret

Ccf8:	sec			; set carry flag
Ccf9:	ret

; ----------------------------------------------------------------------------
;                            Subtraction (C_SUB)
; ----------------------------------------------------------------------------
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcSub
CalcSub:

; ----- negate second number
; DESTROYS: R31, R30, R25, R24
	rcall	CalcNeg

; CalcAdd must follow

; ----------------------------------------------------------------------------
;                            Addition (C_ADD)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R21, R1, R0
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcAdd
CalcAdd:

; ----- get address of last 2 numbers -> 1st number Z, 2nd number X, delete last number
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack (1st number)
;	  R31:R30 (Z) = last number on calculator stack (2nd number)
	rcall	CalcTop2
	rcall	CalcDel2	; delete 2nd number
	rcall	ExcXZ		; exchange pointers, Z <- 1st number, X <- 2nd number

; ----- prepare order of numbers - exponent of 2nd number (X) must not be larger than 1st one (Z)

	ld	r24,Z		; exponent of 1st number
	ld	r25,X		; exponent of 2nd number
	cp	r24,r25		; compare exponents
	brcc	2f		; correct order of numbers
; INPUT: R31:R30 (Z) = address of number 1
;	 R27:R26 (X) = addres of number 2
; DESTROYS: R25, R24, R23
	rcall	NumExc		; exchange numbers

; ----- shift 2nd number to the right to same exponent as 1st number
; 1st number: R31:R30 (Z)
; 2nd number: R27:R26 (X)

2:	ld	r21,Z		; exponent of 1st number
	ld	r25,X		; exponent of 2nd number
	tst	r25		; is 2nd number zero?
	breq	CalcAdd9	; 2nd number is zero
	sub	r21,r25		; difference of exponents
	breq	4f		; exponents are equal
	cpi	r21,CMANT_DIG	; check max. difference
	brcc	CalcAdd9	; 2nd number is too small, 1st number will be only one result

	rcall	ExcXZ		; exchange registers X and Z
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
3:	rcall	MantRightS	; shift mantissa right
	dec	r21		; loop cout	
	brne	3b		; next shift
	rcall	ExcXZ		; exchange registers X and Z

; ----- add mantissas
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R22, R21
;	 R23 = carry 0..1

4:	rcall	MantAdd0	; add mantissas

	; normalize result
CalcNorm:

; ----- check if result is zero
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = mantissa is zero
; DESTROYS: R25, R24, R23
	rcall	MantIsZero	; check if result is zero
	brcc	5f		; mantissa is OK
CalcAdd0:
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rjmp	NumSet0		; set result to 0

; ----- shift number right if carry (sign digit is 0x1x or 0x8x if carry)

5:	ldd	r24,Z+1		; get sign digit
	cpi	r24,10		; <= 0x09 is OK (positive number)
	brcs	6f		; result is OK
	cpi	r24,0x90	; >= 0x90 is OK (negative number)
	brcc	6f		; result is OK
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantRightS	; shift mantissa right
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
	rcall	ExpInc		; increment exponent

; ----- shift mantissa left to normalize number
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22, R0
6:	rcall	MantLMax	; shift mantissa left to normalize

; ----- check exponent overflow

	ld	r24,Z		; load exponent
	cpi	r24,EXP_MAX+1	; check maximal exponent
	brcs	7f		; exponent is OK
CalcAddOver:
	rjmp	NumSetOverS	; set overflow

; ----- check exponent underflow

7:	cpi	r24,EXP_MIN	; check minimal exponent
	brcc	CalcAdd9	; exponent is OK
CalcAddUnder:
	rjmp	NumSetUnderS	; set underflow

CalcAdd9:
	ret

; ----------------------------------------------------------------------------
;                      Multiply prepare sign
; ----------------------------------------------------------------------------
; INPUT: X,Z = numbers
; OUTPUT: R19 = 9x negative
; DESTROYS: R24, R20
; ----------------------------------------------------------------------------

; ----- correct 2nd number X

MulSign:
	clr	r19		; clear sign byte
	rcall	ExcXZ		; exchange pointers
	rcall	MulSign2	; correct number X
	rcall	ExcXZ		; exchange pointers

; ----- correct 1st number Z

MulSign2:
	rcall	NumIsNeg	; check sign
	mov	r20,r24		; save sign byte
	brcc	2f		; number is not negative
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	MantNeg		; negate mantissa
2:	eor	r19,r20
	ret

; ----------------------------------------------------------------------------
;              Multiplicate two numbers on top of stack (C_MUL)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R17, R1, R0
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcMul
CalcMul:

; ----- get address of last 2 numbers, delete 2nd number
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack (1st number)
;	  R31:R30 (Z) = last number on calculator stack (2nd number)
	rcall	CalcTop2
	rcall	CalcDel2	; delete 2nd number

; ----- copy 1st number to temporary buffer
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	adiw	r30,CNUM_BYTES
	rcall	CNumCopy		; copy number
	sbiw	r30,CNUM_BYTES	

	rcall	ExcXZ		; exchange pointers, Z <- 1st number, X <- 2nd number

; ----- sum exponents
;  mem[0] Z = 1st number (accumulator)
;  mem[1] X = 2nd number
;  mem[2] save 1st number

	; check if 1st number is zero
	ld	r24,Z		; exponent of 1st number
	cpi	r24,EXP_ZERO	; is 1st number zero?
	breq	CalcAdd0	; result will be 0
	clr	r25		; 1st exponent HIGH

	; check if 2nd number is zero
	ld	r22,X		; exponent of 2nd number
	cpi	r22,EXP_ZERO	; is 2nd number zero?
CalcMul0:
	breq	CalcAdd0	; result will be 0
	clr	r23		; 2nd exponent HIGH

	; sum exponents
	add	r22,r24
	adc	r23,r25		; sum HIGH
	subi	r22,EXP_ONE-1	; correction
	sbc	r23,R_ZERO
	brmi	CalcAddUnder	; underflow

	; check oveflow
	cpi	r22,EXP_MAX+1
	cpc	r23,R_ZERO
	brcc	CalcAddOver	; overflow

	; check underflow
	cpi	r22,EXP_MIN
	brcs	CalcAddUnder	; underflow

; ----- clear accumulator of result
; mem[0] Z = accumulator
; mem[1] X = 2nd number (taken digits)
; mem[2] 1st number (added to accumulator)

; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0		; set 0
	st	Z,r22		; set new exponent

; ----- prepare sign -> R19

	adiw	r26,CNUM_BYTES	; shift pointer X to temporary buffer with 1st number

; mem[0] Z = accumulator
; mem[1] 2nd number (taken digits, counter R20)
; mem[2] X = 1st number (added to accumulator)

	adiw	r30,CNUM_BYTES	; shift pointer Z to 2nd number
	rcall	MulSign		; prepare sign
	sbiw	r30,CNUM_BYTES	; return pointer Z to accumulator

; ----- multiply mantissas

	ldi	r20,CMANT_DIG-1	; number of valid digits

	; save carry
2:	mov	r17,r23

	; load next digit of 2nd number
	adiw	r30,CNUM_BYTES	; shift pointer Z to 2nd number
;	clr	r23		; input carry not needed
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = new highest digit 0..9
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantRight	; shift mantissa right
	sbiw	r30,CNUM_BYTES	; return pointer Z to accumulator

	; repeated add 1st number (X) to accumulator (Z)
	tst	r23		; is digit zero?
	breq	4f		; digit is zero
	mov	r18,r23		; digit counter
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R23, R22, R21
;	 R23 = carry 0..1
3:	rcall	MantAdd0	; add mantissas
	dec	r18		; digit counter
	brne	3b		; next loop

	; shift accumulator Z
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
4:	clr	r23
	rcall	MantRight	; shift accumulator right

	; loop next digit
	dec	r20		; counter of digits
	brne	2b		; multiply next digit

; ----- maximize

MulNorm:
	ldd	r24,Z+1		; load highest byte of mantissa
	cpi	r24,0		; zero?
	brne	7f		; normalized
	rcall	MantLeft	; shift mantissa left
	mov	r23,r17
	rcall	ExpDec		; decrement exponent

; ----- round result up

7:	cpi	r23,5		; round result?
	brcs	5f		; no rounding
	rcall	MantInc		; increment mantissa

; ----- correct sign

5:	tst	r19		; check sign
	brpl	8f		; not negative
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R25, R24, R23, R22
	rcall	MantNeg		; negate mantissa

8:	rjmp	CalcNorm	; normalize result

; ----------------------------------------------------------------------------
;                          Division (C_DIV)
; ----------------------------------------------------------------------------
; DESTROYS: all
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcDiv
CalcDiv:

; ----- get address of last 2 numbers, delete 2nd number
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack (1st number)
;	  R31:R30 (Z) = last number on calculator stack (2nd number)
	rcall	CalcTop2
	rcall	CalcDel2	; delete 2nd number

; ----- copy 1st number to temporary buffer
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	adiw	r30,CNUM_BYTES
	rcall	CNumCopy	; copy number
	sbiw	r30,CNUM_BYTES	

	rcall	ExcXZ		; exchange pointers, Z <- 1st number, X <- 2nd number

; ----- subtract exponents
;  mem[0] Z = 1st number (accumulator)
;  mem[1] X = 2nd number (divisor)
;  mem[2] save 1st number (dividend)

	; check if 2nd number is zero - result is overflow
	ld	r24,X		; exponent of 2nd number
	cpi	r24,EXP_ZERO	; is 2nd number zero?
	brne	2f		; not zero
DivOver:
	rjmp	NumSetOverS	; set overflow
2:	clr	r25		; 2nd exponent HIGH (R25:R24)

	; check if 1st number is zero - result is 0
	ld	r22,Z		; exponent of 1st number
	cpi	r22,EXP_ZERO	; is 1st number zero?
	breq	CalcMul0	; result will be 0
	clr	r23		; 1st exponent HIGH (R23:R22)

	; subtract exponents: R23:R22 = R23:R22 - R25:R24
	ldi	r21,EXP_ONE
	add	r22,r21		; correction
	adc	r23,R_ZERO
	sub	r22,r24
	sbc	r23,r25		; subtract
	brpl	3f		; ok
DivUnder:
	rjmp	NumSetUnderS	; underflow

	; check oveflow
3:	cpi	r22,EXP_MAX+1
	cpc	r23,R_ZERO
	brcc	DivOver		; overflow

	; check underflow
	cpi	r22,EXP_MIN
	brcs	DivUnder	; underflow

; ----- clear accumulator of result
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: -
	rcall	NumSet0		; set 0
	st	Z,r22		; set new exponent

; ----- prepare sign -> R19

	adiw	r30,2*CNUM_BYTES ; shift pointer Z to temporary buffer with 1st number

; mem[0] accumulator
; mem[1] X = 2nd number (taken digits, counter R20)
; mem[2] Z = 1st number (added to accumulator)

; INPUT: X,Z = numbers
; OUTPUT: R19 = 9x negative
; DESTROYS: R24, R20
	rcall	MulSign		; prepare sign

; ----- divide mantissas

	ldi	r20,CMANT_DIG+1	; number of valid digits (with 2 digits redundant)

	; subtract 2nd number from 1st number until borrow
2:	ldi	r18,-1		; digit accumulator
3:	inc	r18		; increase digit
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R22, R21
;	 R23 = borrow 0..1
	rcall	MantSub0	; subtract
	tst	r23		; borrow?
	breq	3b		; continue loop

	; return
; INPUT: R31:R30 (Z) = address of destination (first) number
;	 R27:R26 (X) = address of source (second) number
; DESTROYS: R25, R24, R23, R22, R21
;	 R23 = carry 0..1
	rcall	MantAdd0	; add back

	; save digit into accumulator
	sbiw	r30,2*CNUM_BYTES
	mov	r23,r18		; digit
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = new highest digit 0..9
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantLeft	; shift right
	mov	r17,r23		; save carry
	adiw	r30,2*CNUM_BYTES

	; shift 1st number left
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry highest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantLeft0

	; loop next digit
	dec	r20		; digit counter
	brne	2b		; next loop

	sbiw	r30,2*CNUM_BYTES ; shift pointer Z to result number

	; shift right highest '0' and get 2 redunant digits
; INPUT: R31:R30 (Z) = address of the number
;	 R23 = new highest digit 0..9
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	mov	r23,r17		; highest digit '0'
	rcall	MantRight	; shift right
	mov	r17,r23
	clr	r23		; highest digit '0'
	rcall	MantRight	; shift right
	rjmp	MulNorm		; normalize result

; ----------------------------------------------------------------------------
;                      Modulus with trunc rounding (C_MOD)
; ----------------------------------------------------------------------------
; DESTROYS: stack, R31, R30
; ----------------------------------------------------------------------------
; - result has same sign as divisor

.global CalcMod
CalcMod:
	rcall	Calc
	.byte	C_DUP2		; pre-duplicate (a,b,a)
	.byte	C_DUP2		; pre-duplicate (a,b,a,b)
	.byte	C_DIV		; division (a,b,a/b)
	.byte	C_TRUNC		; trunc (a,b,trunc(a/b))
	.byte	C_MUL		; multiply (a,b*trunc(a/b))
	.byte	C_SUB		; subtract (a-b*trunc(a/b))
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                      Modulus with floor rounding (C_MOD2)
; ----------------------------------------------------------------------------
; DESTROYS: stack, R31, R30
; ----------------------------------------------------------------------------
; - result has same sign as dividend

.global CalcMod2
CalcMod2:
	rcall	Calc
	.byte	C_DUP2		; pre-duplicate (a,b,a)
	.byte	C_DUP2		; pre-duplicate (a,b,a,b)
	.byte	C_DIV		; division (a,b,a/b)
	.byte	C_FLOOR		; floor (a,b,floor(a/b))
	.byte	C_MUL		; multiply (a,b*floor(a/b))
	.byte	C_SUB		; subtract (a-b*floor(a/b))
	.byte	C_END		; end
	.balign 2		; align
	ret

; ----------------------------------------------------------------------------
;                           Square root (C_SQRT)
; ----------------------------------------------------------------------------
; DESTROYS: all
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
; Uses Newton's method

.global CalcSqrt
CalcSqrt:

; ----- number is 0, result will be 0
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck	; check zero
	breq	9f		; number is zero

; ----- number is negative, error
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
;	  R24 = highest byte of mantissa
	rcall	NumIsNeg	; check negative
	brcc	2f		; not negative
; INPUT: R31:R30 (Z) = address of the number
	rcall	NumNeg		; negate
	rcall	CalcError	; set error

; ----- prepare result with exponent/2
; DESTROYS: R31, R30, R27..R24
; CALCULATOR STACK: +1
2:	rcall	CalcDup		; duplicate
	rcall	CalcTopCheck	; get top number and exponent
	subi	r24,EXP_BIAS	; exponent relative
	asr	r24		; exponent / 2
	subi	r24,-EXP_BIAS	; back base
	st	Z,r24		; set new exponent

; ----- calculate using Newton's method

	rcall	Calc		; calculator (x)
; offset 0	
	.byte	C_EXC		; exchange (y,x)
	.byte	C_BYTE,10	; load loop counter (y,x,c) ... minimum 6
; offset 3: start of loop
	.byte	C_EXC2		; pre-exchange (c,x,y)
	.byte	C_DUP2		; pre-duplicate (c,x,y,x)
	.byte	C_DUP2		; pre-duplicate (c,x,y,x,y)
	.byte	C_DIV		; divide (c,x,y,x/y)
	.byte	C_ADD		; add (c,x,y+x/y)
	.byte	C_BYTE,2	; load constant 2 (c,x,y+x/y,2)
	.byte	C_DIV		; average value (c,x,y)
	.byte	C_EXC2		; pre-exchange (y,x,c)
	.byte	C_DEC		; decrement (y,x,c-1)
	.byte	C_JUMPNZ	; jump if not zero (y,x,c)
	.byte	-12		; jump to offset 3 (3-15=-12)
; offset 15: end of loop
	.byte	C_DEL		; delete (y,x)
	.byte	C_DEL		; delete (y)
	.byte	C_END		; end
	.balign 2		; align
9:
	ret

;.global CalcSqrt
;CalcSqrt:
;	ldi	r24,CONST_05
;	rcall	CalcConst

; CalcPow must follow

; ----------------------------------------------------------------------------
;                             Power (C_POW)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R4
; USES: TEMP_1, TEMP_2, TEMP_3, TEMP_4
; ----------------------------------------------------------------------------
; Calculate power x^y. Special cases: x^0=1, 0^+y=0, 0^-y=overflow.

.global CalcPow
CalcPow:
				; (x,y) ... want to get x^y
	rcall	Calc		; calculator

; offset 0: exponent is 0, result will be 1
	.byte	C_JUMPNZ	; jump if exponent is not zero (x,y)
	.byte	5		; jump to offset 7 (7-2=5) (x,y)
; offset 2
	.byte	C_DEL		; delete y (x)
	.byte	C_DEL		; delete x ()
	.byte	C_CONST1	; load constant 1 (1)
	.byte	C_JMP		; jump
	.byte	16		; jump to offset 23 (23-7=16)

; offset 7: base is 0
	.byte	C_EXC		; exchange (y,x)
	.byte	C_JUMPNZ	; jump if base is not zero (y,x)
	.byte	10		; jump to offset 20 (20-10=10)
; offset 10: base is 0, check exponent
	.byte	C_DEL		; delete x (y)
	.byte	C_GR0		; check y > 0 (0/1)
	.byte	C_JUMPF		; jump if y < 0
	.byte	3		; jump to offset 17 (17-14=3)
; offset 14: exponent is > 0, result will be 0
	.byte	C_CONST0	; result will be 0 (0)
	.byte	C_JMP		; jump
	.byte	6		; jump to offset 23 (23-17=6)
; offset 17: exponent is < 0, result will be overflow
	.byte	C_OVER		; load overflow number
	.byte	C_JMP		; jump back
	.byte	3		; jump to offset 23 (23-20=3)

; offset 20: calculate x^y
	.byte	C_LN		; ln (y,ln(x)) ... uses TEMP_1, TEMP_2, TEMP_3, TEMP_4
	.byte	C_MUL		; multiply (y*ln(x))
	.byte	C_EXP		; exponent ... uses TEMP_1, TEMP_2, TEMP_3
; offset 23
	.byte	C_END		; end
; offset 24
	.balign 2		; align
; offset 24
	ret

; ----------------------------------------------------------------------------
;                    Convert polar to cartesian (C_PR)
; ----------------------------------------------------------------------------
; INPUT: pre-top (T) = radius r
;	  top (X) = angle a
; OUTPUT: pre-top (T) = real x
;	  top (X) = imaginary y
; ----------------------------------------------------------------------------
; x = r*cos(a)
; y = r*sin(a)

.global CalcPR
CalcPR:
	rcall	Calc		; calculator (r,a)
	.byte	C_DUP2		; pre-duplicate (r,a,r)
	.byte	C_DUP2		; pre-duplicate (r,a,r,a)
	.byte	C_COS		; cosinus (r,a,r,cos(a))
	.byte	C_MUL		; multiply (r,a,r*cos(a)=x)
	.byte	C_EXC2		; pre-exchange (x,a,r)
	.byte	C_EXC		; exchange (x,r,a)
	.byte	C_SIN		; sinus (x,r,sin(a))
	.byte	C_MUL		; multiply (x,r*sin(a)=y)
	.byte	C_END		; (x,y)
	.balign 2
	ret

; ----------------------------------------------------------------------------
;                    Convert cartesian to polar (C_RP)
; ----------------------------------------------------------------------------
; INPUT: pre-top (T) = real x
;	  top (X) = imaginary y
; OUTPUT: pre-top (T) = radius r
;	  top (X) = angle a
; ----------------------------------------------------------------------------
; r = sqrt(x^2 + y^2)
; a = atan(y/x) ... if X < 0 then a = a + pi

.global CalcRP
CalcRP:

; ----- convert R->P (cartesian -> polar)

	rcall	Calc		; calculator (x,y)
; offset 0: check if x is 0
	.byte	C_EXC		; exchange (y,x)
	.byte	C_JUMPNZ	; jump if x is not 0 (y,x)
	.byte	11		; jump to offset 14 (14-3=11)
; offset 3: x is zero, angle will be PI/2 or -PI/2
	.byte	C_DEL		; delete (y)
	.byte	C_DUP		; duplicate (y,y)
	.byte	C_SGN		; signum (y,-1/0/1)
	.byte	C_CONST(CONST_PI05) ; constant PI/2 (y,-1/0/1,pi)
	.byte	C_MUL		; multiply (y,a)
	.byte	C_FROMRAD	; angle from radians
	.byte	C_EXC		; exchange (a,y)
	.byte	C_ABS		; absolute value (a,r)
	.byte	C_EXC		; exchange (r,a)
	.byte	C_JMP		; jump
	.byte	20		; jump to offset 34 (34-14=20)
; offset 14
	.byte	C_EXC		; exchange (x,y)
; offset 15: calculate radius
	.byte	C_DUP2		; pre-duplicate (x,y,x)
	.byte	C_DUP2		; pre-duplicate (x,y,x,y)
	.byte	C_SQR		; square (x,y,x,y^2)
	.byte	C_EXC		; exchange (x,y,y^2,x)
	.byte	C_SQR		; square (x,y,y^2,x^2)
	.byte	C_ADD		; add (x,y,y^2+x^2)
	.byte	C_SQRT		; square root = radius (x,y,sqrt(y^2+x^2) = r)
; offset 22: calculate angle
	.byte	C_EXC2		; pre-exchange (r,y,x)
	.byte	C_EXC		; exchange (r,x,y)
	.byte	C_DUP2		; pre-duplicate (r,x,y,x)
	.byte	C_DIV		; divide (r,x,y/x)
	.byte	C_ATN		; arcus tangent (r,x,atan(y/x)) = (a))
; offset 27: angle correction
	.byte	C_EXC		; exchange (r,a,x)
	.byte	C_LT0		; check if X < 0 (r,a,0/1)
	.byte	C_JUMPF		; skip if not X < 0 (r,a)
	.byte	3		; jump to offset 34 (34-31=3)
; offset 31: X is negative
	.byte	C_CONST(CONST_PI) ; load constant PI (r,a,PI)
	.byte	C_FROMRAD	; angle from radians
	.byte	C_ADD		; add (r,a+PI)
; offset 34:
	.byte	C_END		; (r,a)
	.balign 2

	ret

; ----------------------------------------------------------------------------
;                          Integer factorial
; ----------------------------------------------------------------------------

.global CalcFact
CalcFact:

; ----- load constant 1

	rcall	CalcConst1	; load constant 1
	rcall	CalcExc		; exchange

; ----- load number of steps (absolute value)
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcUnstackB
	cpi	r24,0		; check 0!
	breq	9f		; zero

	cpi	r24,70
	brcs	2f
	ldi	r24,70

; ----- multiply accumulator by coefficient

2:	push	r24

; INPUT: (R25:)R24 = unsigned integer
; DESTROYS: R31, R30, R25, R24, R_M1..R_M10, R0
; CALCULATOR STACK: +1
	rcall	CalcStackB	; stack coefficient

	rcall	CalcMul		; multiply

; ----- next coefficient

	pop	r24

	dec	r24		; decrement
	brne	2b		; next loop

9:	ret

