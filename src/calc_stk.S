; ****************************************************************************
;
;                        Calculator stack manipulation
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                    Exchange registers X and Z
; ----------------------------------------------------------------------------
; INPUT and OUTPUT: R31:R30 (Z), R27:R26 (X) = registers to exchange
; DESTROYS: -
; ----------------------------------------------------------------------------

.global ExcXZ
ExcXZ:
	eor	r30,r26		; R30 <- ZL^XL
	eor	r26,r30		; R26 <- ZL
	eor	r30,r26		; R30 <- XL

	eor	r31,r27		; R31 <- ZH^XH
	eor	r27,r31		; R27 <- ZH
	eor	r31,r27		; R31 <- XH
	ret

; ----------------------------------------------------------------------------
;                    Get end of calculator stack -> Z
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 (Z) = end of calculator stack
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcStkEnd
CalcStkEnd:
	ldd	r30,Y+DATA_STKEND
	ldd	r31,Y+DATA_STKEND+1 ; end of calculator stack
	ret

; ----------------------------------------------------------------------------
;                  Get last number on calculator stack -> Z
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcTop
CalcTop:
; OUTPUT: R31:R30 (Z) = end of calculator stack
; DESTROYS: -
	rcall	CalcStkEnd	; get end of calculator stack -> Z
	sbiw	r30,CNUM_BYTES	; Z <- last number on calculator stack
	ret

; ----------------------------------------------------------------------------
;             Get exponent and check zero number -> Z, R24
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcTopCheck
CalcTopCheck:

; ----- get last number on calculator stack -> Z
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop

; ----- check zero

	ld	r24,Z		; R24 <- exponent
	cpi	r24,EXP_ZERO	; check zero
	ret

; ----------------------------------------------------------------------------
;                 Get pre-last number on calculator stack -> Z
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 (Z) = pre-last number on calculator stack
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcPreTop
CalcPreTop:
; OUTPUT: R31:R30 (Z) = end of calculator stack
; DESTROYS: -
	rcall	CalcStkEnd	; get end of calculator stack -> Z
	sbiw	r30,2*CNUM_BYTES ; Z <- pre-last number on calculator stack
	ret

; ----------------------------------------------------------------------------
;               Get last 2 numbers on calculator stack -> X, Z
; ----------------------------------------------------------------------------
; OUTPUT: R27:R26 (X) = pre-last number on calculator stack
;	  R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CalcTop2
CalcTop2:
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get last number on calculator stack -> Z
	movw	r26,r30		; X <- last number
	sbiw	r26,CNUM_BYTES	; X <- pre-last number
CalcTop2_ret:
	ret

; ----------------------------------------------------------------------------
;                 Create new number on end of calculator stack
; ----------------------------------------------------------------------------
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

.global CalcNew
CalcNew:

; ----- get current end of calculator stack
; OUTPUT: R31:R30 (Z) = end of calculator stack
; DESTROYS: -
	rcall	CalcStkEnd	; get end of calculator stack -> Z

; ----- shift pointer and save new pointer

	adiw	r30,CNUM_BYTES	; increase pointer
	rcall	CalcDel2	; set new pointer

; ----- shift back to last number

	sbiw	r30,CNUM_BYTES

; ----- internal check overflow

	push	r24
	ldi	r24,hi8(CalcStack+CALC_MAX*CNUM_BYTES) ; end of stack
	cpi	r30,lo8(CalcStack+CALC_MAX*CNUM_BYTES) ; check end of stack
	cpc	r31,r24
	pop	r24
	brcs	CalcTop2_ret	; no overflow
	jmp	Fatal		; fatal error

; ----------------------------------------------------------------------------
;                    Get address of extended register
; ----------------------------------------------------------------------------
; INPUT: R24 = index of register 0..MEM_NUM2-1
; OUTPUT: R31:R30 = address of register
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global CalcAddrRMem
CalcAddrRMem:
        ldi	r30,RNUM_BYTES
	mul	r30,r24		; convert to offset
	movw	r30,r0
	subi	r30,lo8(-(MemReg))
	sbci	r31,hi8(-(MemReg))
	ret

; ----------------------------------------------------------------------------
;                    Get address of base register
; ----------------------------------------------------------------------------
; INPUT: R24 = index of register 0..BASE_NUM
; OUTPUT: R31:R30 = address of register
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global CalcAddrBMem
CalcAddrBMem:
        ldi	r30,BNUM_BYTES
	mul	r30,r24		; convert to offset
	movw	r30,r0
	subi	r30,lo8(-(BaseReg))
	sbci	r31,hi8(-(BaseReg))
	ret

; ----------------------------------------------------------------------------
;                    Get address of calculator register
; ----------------------------------------------------------------------------
; INPUT: R24 = index of register 0..CALC_MAX2-1
; OUTPUT: R31:R30 = address of register
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global CalcAddrCMem
CalcAddrCMem:
        ldi	r30,CNUM_BYTES
	mul	r30,r24		; convert to offset
	movw	r30,r0
	subi	r30,lo8(-(CalcStack))
	sbci	r31,hi8(-(CalcStack))
	ret

; ----------------------------------------------------------------------------
;            Set memory from stack and delete it (C_SETMEMDEL)
; ----------------------------------------------------------------------------
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
; ----------------------------------------------------------------------------

; ----- set number T from stack and delete it
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
.global CalcSetMemDelT	; set register T
CalcSetMemDelT:
	ldi	r24,REG_T
	rjmp	CalcSetMemDel

; ----- set number X from stack and delete it
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
.global CalcSetMemDelX	; set register X
CalcSetMemDelX:
	ldi	r24,REG_X

; ----- set number from stack and delete it
.global CalcSetMemDel
CalcSetMemDel:
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcSetMem	; copy number
; DESTROYS: R31, R30
; CALCULATOR STACK: -1
	rjmp	CalcDel		; delete top number

; ----- set user register from stack and delete it
.global CalcSetMemUserDel
CalcSetMemUserDel:
	rcall	CalcSetMemUser
	rjmp	CalcDel

; ----------------------------------------------------------------------------
;                  Set register from stack (C_SETMEM)
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..31 (MEM_0..MEM_19, REG_T, REG_X, REG_TEMP...)
; DESTROYS: R31, R30, R27..R21, R1, R0
; ----------------------------------------------------------------------------
; Does not delete the number from calculator stack.

; ----- set number T from stack
; DESTROYS: R31, R30, R27..R24, R1, R0
.global CalcSetMemT
CalcSetMemT:
	ldi	r24,REG_T	; set register T
	rjmp	CalcSetMem

; ----- set number X from stack
; DESTROYS: R31, R30, R27..R24, R1, R0
.global CalcSetMemX
CalcSetMemX:
	ldi	r24,REG_X	; set register X

.global CalcSetMem
CalcSetMem:
	cpi	r24,REG_SYS_BASE	; system register X or LAST?
	brcc	CalcSetMemSys		; set system register

	cpi	r24,REG_TEMP_BASE	; temp register?
	brcs	CalcSetMemUser		; no temp register, set user register

	subi	r24,-REG_TEMP_SHIFT	; recalculate to CalcStack index

; CalcSetCMem must follow

; ----------------------------------------------------------------------------
;               Set system register (in CalcStack) from stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..CALC_MAX2-1
; DESTROYS: R31, R30, R27..R24, R1, R0
; ----------------------------------------------------------------------------
; Does not delete the number from calculator stack.

CalcSetCMem:

; ----- get address of the number -> R27:R26 (X, destination)
; INPUT: R24 = index of variable 0..CALC_MAX2-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrCMem	; get number address -> Z
	movw	r26,r30		; R27:R26 (X) <- destination address

; ----- get address of last number -> R31:R30 (Z, source)
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get number in stack -> Z

; ----- copy number

	rcall	ExcXZ		; exchange registers X and Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rjmp	CNumCopy	; copy number from X to Z

; ----------------------------------------------------------------------------
;              Set base register (in BaseReg) from stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..BASE_NUM-1
; DESTROYS: R31, R30, R27..R21, R1, R0
; ----------------------------------------------------------------------------
; Does not delete the number from calculator stack.

CalcSetMemSys:
	subi	r24,-REG_SYS_SHIFT	; recalc SYS to BaseRegindex

; ----- set base register from BaseReg

CalcSetBMem:

; ----- get address of the number -> R27:r26 (X, destination)
; INPUT: R24 = index of variable 0..MEM_NUM2-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrBMem	; get number address -> Z
	movw	r26,r30		; R27:R26 (X) <- destination address

; ----- get address of last number -> R31:R30 (Z, source)
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get number in stack -> Z

; ----- copy number

#if BMANT_DIF > 0
	ldd	r21,Z+BNUM_BYTES ; load following byte
#if BMANT_DIF > 1
	ldd	r20,Z+BNUM_BYTES+1 ; load following byte
#if BMANT_DIF > 2
	ldd	r19,Z+BNUM_BYTES+2 ; load following byte
#endif
#endif
#endif

	rcall	ExcXZ		; exchange registers X and Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rcall	BNumCopy	; copy number from X to Z

; ----- rounding

#if BMANT_DIF > 0
	; check if rounding needed
	cpi	r21,0x50	; rounding?
	brcs	9f		; no rounding
	rcall	ExpIsValid	; check 2nd number
	brcs	9f		; invalid exponent

	; increment mantissa
	adiw	r30,BNUM_BYTES	; shift to last byte of mantissa
	ldi	r22,BMANT_BYTES	; mantissa length in bytes
	ldi	r23,1		; increment
	rcall	MantAddC2	; round up

	; shift if overflow
	ldd	r24,Z+1		; get sign digit
	cpi	r24,10		; <= 0x09 is OK (positive number)
	brcs	9f		; result is OK
	cpi	r24,0x90	; >= 0x90 is OK (negative number)
	brcc	9f		; result is OK

; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantRightS	; shift mantissa right
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
	rcall	ExpInc		; increment exponent

#if BMANT_DIF > 0
	std	Z+BNUM_BYTES,r21 ; restore following number
#if BMANT_DIF > 1
	std	Z+BNUM_BYTES+1,r20 ; restore following number
#if BMANT_DIF > 2
	std	Z+BNUM_BYTES+2,r19 ; restore following number
#endif
#endif
#endif

#endif

9:	ret

; ----------------------------------------------------------------------------
;              Set extended register (in MemReg) from stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..MEM_NUM2-1
; DESTROYS: R31, R30, R27..R21, R1, R0
; ----------------------------------------------------------------------------
; Does not delete the number from calculator stack.

; ----- set random seed from stack
.global CalcSetSeed
CalcSetSeed:
	ldi	r24,MEM_NUM

; ----- set user register 0..MEM_NUM-1
.global CalcSetMemUser
CalcSetMemUser:
	cpi	r24,10			; base register?
	brcs	CalcSetBMem		; set base register
	subi	r24,10			; recalculate to MemReg index

; CalcSetRMem must follow

CalcSetRMem:

; ----- get address of the number -> R27:r26 (X, destination)
; INPUT: R24 = index of variable 0..MEM_NUM2-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrRMem	; get number address -> Z
	movw	r26,r30		; R27:R26 (X) <- destination address

; ----- get address of last number -> R31:R30 (Z, source)
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop		; get number in stack -> Z

; ----- copy number

#if RMANT_DIF > 0
	ldd	r21,Z+RNUM_BYTES ; load following byte
#if RMANT_DIF > 1
	ldd	r20,Z+RNUM_BYTES+1 ; load following byte
#if RMANT_DIF > 2
	ldd	r19,Z+RNUM_BYTES+2 ; load following byte
#endif
#endif
#endif

	rcall	ExcXZ		; exchange registers X and Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rcall	RNumCopy	; copy number from X to Z

; ----- rounding

#if RMANT_DIF > 0
	; check if rounding needed
	cpi	r21,0x50	; rounding?
	brcs	9f		; no rounding
	rcall	ExpIsValid	; check 2nd number
	brcs	9f		; invalid exponent

	; increment mantissa
	adiw	r30,RNUM_BYTES	; shift to last byte of mantissa
	ldi	r22,RMANT_BYTES	; mantissa length in bytes
	ldi	r23,1		; increment
	rcall	MantAddC2	; round up

	; shift if overflow
	ldd	r24,Z+1		; get sign digit
	cpi	r24,10		; <= 0x09 is OK (positive number)
	brcs	9f		; result is OK
	cpi	r24,0x90	; >= 0x90 is OK (negative number)
	brcc	9f		; result is OK
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: R23 = carry lowest digit 0..9
; DESTROYS: R25, R24, R22, R0
	rcall	MantRightS	; shift mantissa right
; INPUT: R31:R30 (Z) = address of the number
; DESTROYS: R24, R23, R22
	rcall	ExpInc		; increment exponent

#if RMANT_DIF > 0
	std	Z+RNUM_BYTES,r21 ; restore following number
#if RMANT_DIF > 1
	std	Z+RNUM_BYTES+1,r20 ; restore following number
#if RMANT_DIF > 2
	std	Z+RNUM_BYTES+2,r19 ; restore following number
#endif
#endif
#endif

#endif

9:	ret

; ----------------------------------------------------------------------------
;                  Get register into stack (C_GETMEM)
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..31 (MEM_0..MEM_19, REG_T, REG_X, REG_TEMP...)
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

; ----- get number T from stack
; DESTROYS: R31, R30, R27..R24, R1, R0
.global CalcGetMemT
CalcGetMemT:
	ldi	r24,REG_T	; get register T
	rjmp	CalcGetMem

; ----- get number X from stack
; DESTROYS: R31, R30, R27..R24, R1, R0
.global CalcGetMemX
CalcGetMemX:
	ldi	r24,REG_X	; get register X

.global CalcGetMem
CalcGetMem:
	cpi	r24,REG_SYS_BASE	; system register X or LAST?
	brcc	CalcGetMemSys		; get system register

	cpi	r24,REG_TEMP_BASE	; temp register?
	brcs	CalcGetMemUser		; no temp register, get user register

	subi	r24,-REG_TEMP_SHIFT	; recalculate to CalcStack index

; CalcGetCMem must follow

; ----------------------------------------------------------------------------
;              Get system register (from CalcStack) into stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..CALC_MAX2-1
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

CalcGetCMem:

; ----- get address of the number -> R31:R30 (Z)
; INPUT: R24 = index of variable 0..CALC_MAX2-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrCMem

; ----- create new number on top of stack (and save Z pointer)

	movw	r26,r30		; save address into X (source)
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number Z (destination)

; ----- copy number X -> Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24
	rjmp	CNumCopy	; copy number from X to Z

; ----------------------------------------------------------------------------
;              Get base register (from BaseReg) into stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..BASE_NUM-1
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

CalcGetMemSys:
	subi	r24,-REG_SYS_SHIFT	; recalc SYS to BaseRegindex

; ----- get base register from BaseReg

CalcGetBMem:

; ----- get address of the number -> R31:R30 (Z)
; INPUT: R24 = index of variable 0..BASE_NUM-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrBMem

; ----- create new number on top of stack (and save Z pointer)

	movw	r26,r30		; save address into X (source)
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number Z (destination)

; ----- copy number X -> Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24

#if BMANT_DIF > 0
	std	Z+CNUM_BYTES-1,R_ZERO ; clear last byte
#if BMANT_DIF > 1
	std	Z+CNUM_BYTES-2,R_ZERO ; clear last byte
#if BMANT_DIF > 2
	std	Z+CNUM_BYTES-3,R_ZERO ; clear last byte
#endif
#endif
#endif

	rjmp	BNumCopy	; copy number from X to Z

; ----------------------------------------------------------------------------
;              Get extended register (from MemReg) into stack
; ----------------------------------------------------------------------------
; INPUT: R24 = index of the number 0..MEM_NUM2-1
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
; ----------------------------------------------------------------------------

; ----- get random seed into stack
.global CalcGetSeed
CalcGetSeed:
	ldi	r24,MEM_NUM

; ----- get user register 0..MEM_NUM-1
.global CalcGetMemUser
CalcGetMemUser:
	cpi	r24,10			; base register?
	brcs	CalcGetBMem		; get base register
	subi	r24,10			; recalculate to MemReg index

; CalcGetRMem must follow

; ----- get extended register from MemReg

CalcGetRMem:

; ----- get address of the number -> R31:R30 (Z)
; INPUT: R24 = index of variable 0..MEM_NUM2-1
; OUTPUT: R31:R30 = address of variable
; DESTROYS: R1, R0
	rcall	CalcAddrRMem

; ----- create new number on top of stack (and save Z pointer)

	movw	r26,r30		; save address into X (source)
; OUTPUT: R31:R30 (Z) = new number
; DESTROYS: -
; CALCULATOR STACK: +1
	rcall	CalcNew		; create new number Z (destination)

; ----- copy number X -> Z
; INPUT: R31:R30 (Z) = address of destination number
;	 R27:R26 (X) = addres of source number
; DESTROYS: R25, R24

#if RMANT_DIF > 0
	std	Z+CNUM_BYTES-1,R_ZERO ; clear last byte
#if RMANT_DIF > 1
	std	Z+CNUM_BYTES-2,R_ZERO ; clear last byte
#if RMANT_DIF > 2
	std	Z+CNUM_BYTES-3,R_ZERO ; clear last byte
#endif
#endif
#endif

	rjmp	RNumCopy	; copy number from X to Z
