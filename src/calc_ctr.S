; ****************************************************************************
;
;                        Calculator control operations
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                          No function (C_NOP)
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcNop
CalcNop:
	ret

; ----------------------------------------------------------------------------
;                        End calculator macro (C_END)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to current literals (jumps to next location)
; OUTPUT: R_LITH:R_LITL = pointer to previous literals
; DESTROYS: stack+4, R31, R30
; ----------------------------------------------------------------------------

.global CalcEnd
CalcEnd:
	pop	r31		; (HIGH)
	pop	r30		; (LOW) destroy return address

	movw	r30,R_LITL	; Z <- literal pointer

	pop	R_LITH		; pop registers
	pop	R_LITL

	adiw	r30,1		; round up
	lsr	r31
	ror	r30		; convert pointer back to word index
	ijmp			; jump back to the program

; ----------------------------------------------------------------------------
;                Delete number from top of the stack (C_DEL)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

.global CalcDel
CalcDel:

; ----- get last number on calculator stack
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get last number -> Z

; ----- internal check underflow

	push	r24
	ldi	r24,hi8(CalcStack-CNUM_BYTES)
	cpi	r30,lo8(CalcStack-CNUM_BYTES)
	cpc	r31,r24
	pop	r24
	brne	CalcDel2	; stack is OK
	jmp	Fatal		; fatal error

; ----- set new end of stack to Z (saves SREG)

.global CalcDel2
CalcDel2: ; jump here from CalcNew and CalcAdd
	std	Y+DATA_STKEND,r30 ; save new end of stack
	std	Y+DATA_STKEND+1,r31
	ret

; ----------------------------------------------------------------------------
;              Duplicate pre2-last number on top of stack (C_DUP2)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R24
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcDup2
CalcDup2:

; ----- create new number on top of stack
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number -> Z

; ----- copy number

	movw	r26,r30		; X <- Z
	sbiw	r26,2*CNUM_BYTES ; shift to source number
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rjmp	CNumCopy

; ----------------------------------------------------------------------------
;                  Duplicate number on top of stack (C_DUP)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R24
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcDup
CalcDup:

; ----- create new number on top of stack
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number -> Z

; ----- copy number

	movw	r26,r30		; X <- Z
	sbiw	r26,CNUM_BYTES	; shift to source number
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rjmp	CNumCopy

; ----------------------------------------------------------------------------
;                   Exchange two numbers on top of stack (C_EXC)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R23
; ----------------------------------------------------------------------------
; - exchange top number and last number

.global CalcExc
CalcExc:

; OUTPUT: R27:R26 (X) = pre-last number on calculator stack
;	  R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop2	; get pre-last number -> X and last number -> Z

; INPUT: R31:R30 (Z) = address of number 1
;	 R27:R26 (X) = addres of number 2
; DESTROYS: R25, R24, R23
	rjmp	NumExc		; exchange numbers X and Z

; ----------------------------------------------------------------------------
;              Exchange two numbers on pre-top of stack (C_EXC2)
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R23
; ----------------------------------------------------------------------------
; - exchange top number and pre-last number

.global CalcExc2
CalcExc2:

; OUTPUT: R27:R26 (X) = pre-last number on calculator stack
;	  R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop2	; get pre-last number -> X and last number -> Z
	sbiw	r26,CNUM_BYTES	; pre2-last number -> X

; INPUT: R31:R30 (Z) = address of number 1
;	 R27:R26 (X) = addres of number 2
; DESTROYS: R25, R24, R23
	rjmp	NumExc		; exchange numbers X and Z

; ----------------------------------------------------------------------------
;                         Relative jump (C_JUMP)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
; ----------------------------------------------------------------------------

.global CalcJump
CalcJump:
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rcall	CalcLit		; load literal -> R24

	ldi	r25,0		; jump HIGH positive offset
	tst	r24		; negative number?
	brpl	2f		; jump offset is positive
	ldi	r25,0xff	; HIGH negative offset
2:	add	R_LITL,r24	; add offset LOW
	adc	R_LITH,r25	; add offset HIGH
	ret

; ----------------------------------------------------------------------------
;   Relative jump if top number is true (<>0), delete top number (C_JUMPT)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R31, R30, R25, R24
; CALCULATOR STACK: -1
; NOTES: Jump offset is relative to next byte after JUMP intruction
; ----------------------------------------------------------------------------

.global CalcJumpT
CalcJumpT:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck

; ----- destroy last number (saves SREG)
; DESTROYS: -
	rcall	CalcDel2	; set stack end to Z (saves SREG)

; ----- jump if not zero
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
CalcJumpT2:
	brne	CalcJump	; not zero, jump is valid

; ----- or only destroy literal with jump offset
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rjmp	CalcLit		; load literal -> R24

; ----------------------------------------------------------------------------
;   Relative jump if top number is false (=0), delete top number (C_JUMPF)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R31, R30, R25, R24
; CALCULATOR STACK: -1
; NOTES: Jump offset is relative to next byte after JUMP intruction
; ----------------------------------------------------------------------------

.global CalcJumpF
CalcJumpF:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck

; ----- destroy last number (saves SREG)
; DESTROYS: -
	rcall	CalcDel2	; set stack end to Z (saves SREG)

; ----- jump if zero
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
CalcJumpF2:
	breq	CalcJump	; zero, jump is valid

; ----- or only destroy literal with jump offset
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
;	 R24 = next literal
; DESTROYS: -
	rjmp	CalcLit		; load literal -> R24

; ----------------------------------------------------------------------------
; Relative jump if top number is not zero, do not delete top number (C_JUMPNZ)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R31, R30, R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
; ----------------------------------------------------------------------------

.global CalcJumpNZ
CalcJumpNZ:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck
	rjmp	CalcJumpT2

; ----------------------------------------------------------------------------
;   Relative jump if top number is zero, do not delete top number (C_JUMPZ)
; ----------------------------------------------------------------------------
; INPUT: R_LITH:R_LITL = pointer to literals
; OUTPUT: R_LITH:R_LITL = new pointer to literals
; DESTROYS: R31, R30, R25, R24
; NOTES: Jump offset is relative to next byte after JUMP intruction
; ----------------------------------------------------------------------------

.global CalcJumpZ
CalcJumpZ:

; ----- get last number and check if zero -> Z, R24
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck
	rjmp	CalcJumpF2

; ----------------------------------------------------------------------------
;                        Set error flag (C_ERROR)
; ----------------------------------------------------------------------------

.global CalcError
CalcError:
	CLR_RUNNING		; clear running flag
	SET_ERROR		; set error flag
	sec			; set error flag
	ret
