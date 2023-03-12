; ****************************************************************************
;
;                                Execute arithmetics
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                     Get current operation
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 = pointer into OperStack
;	  R24 = current operation
; ----------------------------------------------------------------------------

.global ExecLevel
ExecLevel:
	ldd	r24,Y+DATA_LEVEL ; current level of arithmetics operations
	ldi	r30,lo8(OperStack) ; stack of arithmetics operations
	ldi	r31,hi8(OperStack)
	add	r30,r24
	adc	r31,R_ZERO
	ld	r24,Z		; get current operation at this level
	ret

; ----------------------------------------------------------------------------
;                 Calculate one level of arithmetics operations
; ----------------------------------------------------------------------------

.global ExecCalc
ExecCalc:

	; edit stop
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

	; load X into stack
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	; check if current operation is valid to save it
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current operation
	andi	r24,OPER_MASK | LEVEL_MASK ; check current operation
	breq	2f		; current operation is not valid

	; copy X into LAST, save last operation
	std	Y+DATA_LAST,r24	; save last operation (LOWER = 0)
	ldi	r24,REG_LAST	; register Last
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcSetMem	; save Last (does not delete it from the stack)


; ----- switch by current operation
; OUTPUT: R31:R30 = pointer into OperStack
;	  R24 = current operation
	rcall	ExecLevel	; get current operation

ExecCalcOn:
2:	andi	r24,OPER_MASK	; mask operation

	; +
	cpi	r24,OPER_PLUS
	brne	3f
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcAdd		; add
	rjmp	9f

	; -
3:	cpi	r24,OPER_MINUS
	brne	4f
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcSub		; sub
	rjmp	9f

	; *
4:	cpi	r24,OPER_MUL
	brne	5f
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcMul		; multiply
	rjmp	9f

	; :
5:	cpi	r24,OPER_DIV
	brne	6f
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcDiv		; divide
	rjmp	9f

	; :
6:	cpi	r24,OPER_MOD
	brne	2f
; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcMod		; modulo
	rjmp	9f

	; ^
2:	cpi	r24,OPER_POWER
	brne	7f
	rcall	DispC		; display C
	rcall	CalcPow		; power
	rjmp	9f

	; root
7:	cpi	r24,OPER_ROOT
	brne	8f
	rcall	DispC		; display C
	call	CalcRec		; reciprocal
	rcall	CalcPow		; power
	rjmp	9f

	; no operation - only delete 2nd operand
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
8:	rcall	CalcDel		; delete 2nd operand

	; save result into X
9:
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcSetMemX	; set X

	SET_XVALID		; set X valid

	; clear current operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK
	st	Z,r24		; clear current operation

; DESTROYS: R1, R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                         Increase arithmetics level
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R27..R24, R1, R0
; ----------------------------------------------------------------------------

.global ExecLevelInc
ExecLevelInc:

	; increase operation level (with overflow check)
	ldd	r24,Y+DATA_LEVEL ; current level of arithmetics operations
	cpi	r24,LEVEL_MAX	; check level
	brcc	ExecLevelDec2	; fatal error

	inc	r24		; increase level
	std	Y+DATA_LEVEL,r24 ; set new level

	; initialize current level
.global ExecLevelInit
ExecLevelInit:

	; load X into stack
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	; clear current operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	st	Z,R_ZERO	; clear flag
	ret

; ----------------------------------------------------------------------------
;                         Decrease arithmetics level
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R24
; ----------------------------------------------------------------------------

.global ExecLevelDec
ExecLevelDec:
	ldd	r24,Y+DATA_LEVEL ; current number of arithmetics operations
	tst	r24		; already base level?
	brne	2f		; not base level, OK

ExecLevelDec2:
	rjmp	Fatal		; fatal error

; DESTROYS: R31, R30
; CALCULATOR STACK: -1
2:	rcall	CalcDel		; delete number from stack

	dec	r24		; decrease level
	std	Y+DATA_LEVEL,r24 ; set new level
ExecLevelDec9:
	ret

; ----------------------------------------------------------------------------
;                                   (
; ----------------------------------------------------------------------------

.global ExecLPar
ExecLPar:

	; stop edit mode (not validating X)
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; stop edit mode
	CLR_XVALID		; register X is NOT valid
	rcall	ExecLevelInc	; increase level
; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                                   )
; ----------------------------------------------------------------------------

.global ExecRPar
ExecRPar:

	; stop edit mode (not validating X)
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

; ----- close levels of one parenthesis

2:	rcall	ExecCalc	; calculate current level

; OUTPUT: R31:R30 = pointer into OperStack
;	  R24 = current operation
	rcall	ExecLevel	; get current level

	push	r24		; current operation

	ldd	r24,Y+DATA_LEVEL ; current level of arithmetics operations
	tst	r24		; already base level?
	breq	4f		; already base level

; DESTROYS: R31, R30, R24
	rcall	ExecLevelDec	; decrease level

4:	pop	r24

	andi	r24,LOWER_MASK	; mask lower level
	cpi	r24,LOWER_NONE	; level () ?
	brne	2b		; close up to () level

; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                                 +
; ----------------------------------------------------------------------------

.global ExecAdd
ExecAdd:

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

	IFN_XVALID		; if X is not valid
	rjmp	8f		; only update operation

; ----- close higher level - power

	; close higher level - power
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask current level
	cpi	r24,LEVEL_POWER ; higher level - power?
	brne	4f
	rcall	ExecCalc	; calculate current level

	; decrease level, if lower level is */ or +-
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower level
	cpi	r24,LOWER_MULDIV ; level */ ?
	breq	3f		; decrease level
	cpi	r24,LOWER_PLUSMINUS ; level +- ?
	brne	4f
3:	rcall	ExecLevelDec	; decrease level

; ----- close higher level - multiply

	; close higher level - multiply
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
4:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask operation
	cpi	r24,LEVEL_MULDIV ; higher level - multiply?
	brne	6f
	rcall	ExecCalc	; calculate current level

	; decrease level, if lower level is +-
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower level
	cpi	r24,LOWER_PLUSMINUS ; level +- ?
	brne	6f
	rcall	ExecLevelDec	; decrease level

; ----- close this level

; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
6:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask operation
	cpi	r24,LEVEL_PLUSMINUS ; this level - add?
	brne	7f
	rcall	ExecCalc	; calculate current level

; ----- update this level

; DESTROYS: R31, R30
; CALCULATOR STACK: -1
7:	rcall	CalcDel		; delete accumulator
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	CLR_XVALID		; register X is NOT valid

	; update this level - set +- operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
8:	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation
	ori	r24,LEVEL_PLUSMINUS | OPER_PLUS
	st	Z,r24		; set current operation

	; display flags with current operation
; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                           -
; ----------------------------------------------------------------------------

.global ExecSub
ExecSub:
	rcall	ExecAdd		; close +/- operations

; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
;	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation
	ori	r24,LEVEL_PLUSMINUS | OPER_MINUS
ExecSub2:
	st	Z,r24		; set current operation

; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                           x
; ----------------------------------------------------------------------------

.global ExecMul
ExecMul:

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

	IFN_XVALID		; if X is not valid
	rjmp	8f		; only update operation

; ----- close higher level - power

	; close higher level - power
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask current level
	cpi	r24,LEVEL_POWER ; higher level - power?
	brne	4f
	rcall	ExecCalc	; calculate current level

	; decrease level, if lower level is */
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower level
	cpi	r24,LOWER_MULDIV ; level */ ?
	brne	4f
	rcall	ExecLevelDec	; decrease level

; ----- close this level - mul

	; close this level - mul
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
4:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask operation
	cpi	r24,LEVEL_MULDIV ; this level - mul?
	brne	6f
	rcall	ExecCalc	; calculate current level

; ----- increase lower level +-

	; increase lower level +-
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
6:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask current level
	cpi	r24,LEVEL_PLUSMINUS ; lower level - plus?
	brne	7f

	; increase level
	rcall	ExecLevelInc	; increase level
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	ldi	r24,LOWER_PLUSMINUS
	st	Z,r24		; ser lower level

; ----- update this level

; DESTROYS: R31, R30
; CALCULATOR STACK: -1
7:	rcall	CalcDel		; delete accumulator
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	CLR_XVALID		; register X is NOT valid

	; update this level - set */ operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
8:	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation
	ori	r24,LEVEL_MULDIV | OPER_MUL
	st	Z,r24		; set current operation

	; display flags
; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                           INV :
; ----------------------------------------------------------------------------

.global ExecInvDiv
ExecInvDiv:
	rcall	ExecMul		; close */ operations

; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
;	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation
	ori	r24,LEVEL_MULDIV | OPER_MOD
	rjmp	ExecDiv2

; ----------------------------------------------------------------------------
;                           :
; ----------------------------------------------------------------------------

.global ExecDiv
ExecDiv:
	rcall	ExecMul		; close */ operations

; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
;	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation
	ori	r24,LEVEL_MULDIV | OPER_DIV
ExecDiv2:
	st	Z,r24		; set current operation

; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                           INV y^x
; ----------------------------------------------------------------------------

.global ExecInvYx
ExecInvYx:
	ldi	r23,1		; flag - INV set
	rjmp	ExecYx2

; ----------------------------------------------------------------------------
;                           y^x
; ----------------------------------------------------------------------------

.global ExecYx
ExecYx:
	ldi	r23,0		; flag - no INV

ExecYx2:
	push	r23		; push INV flag

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

	IFN_XVALID		; if X is not valid
	rjmp	8f		; only update operation

; ----- close this level

	; close this level - power
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
2:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask operation
	cpi	r24,LEVEL_POWER ; this level - power?
	brne	4f
	rcall	ExecCalc	; calculate current level

; ----- increase lower level */

	; increase lower level */
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
4:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask current level
	cpi	r24,LEVEL_MULDIV ; lower level - mul?
	brne	5f

	rcall	ExecLevelInc	; increase level
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	ldi	r24,LOWER_MULDIV
	st	Z,r24		; ser lower level

; ----- increase lower level +-

	; increase lower level +-
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
5:	rcall	ExecLevel	; get current level
	andi	r24,LEVEL_MASK	; mask current level
	cpi	r24,LEVEL_PLUSMINUS ; lower level - plus?
	brne	6f

	rcall	ExecLevelInc	; increase level
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current level
	ldi	r24,LOWER_PLUSMINUS
	st	Z,r24		; ser lower level

; ----- update this level - set ^ operation

; DESTROYS: R31, R30
; CALCULATOR STACK: -1
6:	rcall	CalcDel		; delete accumulator
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	CLR_XVALID		; register X is NOT valid

; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
8:	rcall	ExecLevel	; get current level
	andi	r24,LOWER_MASK	; mask lower operation

	pop	r23		; pop INV flag

	tst	r23		; INV flag?
	ldi	r23,LEVEL_POWER | OPER_POWER
	breq	7f		; power
	ldi	r23,LEVEL_POWER | OPER_ROOT
7:	or	r24,r23
	st	Z,r24		; set current operation

; DESTROYS: -
	rjmp	DispFlags	; disp flags

; ----------------------------------------------------------------------------
;                            =
; ----------------------------------------------------------------------------

.global ExecRes
ExecRes:

	; stop edit mode (not validating X)
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStopNoX	; edit stop (not validating X)

	; level = 0 ? (condition to repeat last operation)
	ldd	r24,Y+DATA_LEVEL ; current level of arithmetics operations
	tst	r24		; base level?
	brne	2f		; not base level, no repeat last operation

	; check open operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current operation
	andi	r24,OPER_MASK	; mask operation
	breq	4f		; no operation - repeat last operation

	; close all levels
2:	rcall	ExecRPar	; close one level )
	ldd	r24,Y+DATA_LEVEL ; current level of arithmetics operations
	tst	r24		; valid?
	brne	2b
	rjmp	ExecRPar	; close last level

; ===== repeat last operation (Level must be 0 and no open operation, OPER_NONE)

	; check if last operation is valid
4:	ldd	r24,Y+DATA_LAST ; valid last operation?
	tst	r24
	breq	9f		; not valid

	; delete accumulator and load X
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
	rcall	CalcDel		; delete accumulator
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

	; load LAST as second operand
	ldi	r24,REG_LAST
; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMem	; load register Last

	; set last operation as current operation
; OUTPUT: R31:R30 = pointer into OperStack
;	 R24 = current operation
	rcall	ExecLevel	; get current operation
	ldd	r24,Y+DATA_LAST
	st	Z,r24

	rjmp	ExecCalcOn	; calculate operation

9:	ret
