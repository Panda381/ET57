; ****************************************************************************
;
;                            Execute flags
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                               Set flag
; ----------------------------------------------------------------------------
; B0: F_INV ... INV flag
; B1: F_2ND ... 2nd flag
; B2: F_EE ... EE mode
; B3: F_DP ... decimal point entered
; B4: F_EXP ... entering exponent
; B5: F_SPIERR stop on SPI error
; B6: F_RESDEC restart DecNum function
; B7: F_EXPDIG exponent digits

; set flag INV
; DESTROYS: -
.global FlagSetInv
FlagSetInv:
	push	r25
	ldi	r25,BIT(F_INV)
FlagSet:
	push	r24
	ldd	r24,Y+DATA_FLAGS
	or	r24,r25
	std	Y+DATA_FLAGS,r24
	pop	r24
	pop	r25
	ret

; set flag 2nd
; DESTROYS: -
.global FlagSet2nd
FlagSet2nd:
	push	r25
	ldi	r25,BIT(F_2ND)
	rjmp	FlagSet

; set flag 'EE mode'
; DESTROYS: -
.global FlagSetEE
FlagSetEE:
	push	r25
	ldi	r25,BIT(F_EE)
	rjmp	FlagSet

; set flag 'decimal point'
; DESTROYS: -
.global FlagSetDP
FlagSetDP:
	push	r25
	ldi	r25,BIT(F_DP)
	rjmp	FlagSet

; set flag 'exponent'
; DESTROYS: -
.global FlagSetExp
FlagSetExp:
	push	r25
	ldi	r25,BIT(F_EXP)
	rjmp	FlagSet

; set flag 'stop on SPI error'
; DESTROYS: -
#ifdef HW_ET57				// use hardware of ET-57
.global FlagSetSpiErr
FlagSetSpiErr:
	push	r25
	ldi	r25,BIT(F_SPIERR)
	rjmp	FlagSet
#endif

; set flag 'restart DecNum'
; DESTROYS: -
.global FlagSetResDec
FlagSetResDec:
	push	r25
	ldi	r25,BIT(F_RESDEC)
	rjmp	FlagSet

; set flag 'exponent digits'
; DESTROYS: -
.global FlagSetExpDig
FlagSetExpDig:
	push	r25
	ldi	r25,BIT(F_EXPDIG)
	rjmp	FlagSet

; ----------------------------------------------------------------------------
;                               Clear flag
; ----------------------------------------------------------------------------

; clear flag INV
; DESTROYS: -
.global FlagClrInv
FlagClrInv:
	push	r25
	ldi	r25,~BIT(F_INV)
FlagClr:
	push	r24
	ldd	r24,Y+DATA_FLAGS
	and	r24,r25
	std	Y+DATA_FLAGS,r24
	pop	r24
	pop	r25
	ret

; clear flag 2nd
; DESTROYS: -
.global FlagClr2nd
FlagClr2nd:
	push	r25
	ldi	r25,~BIT(F_2ND)
	rjmp	FlagClr

; clear flag 'EE mode'
; DESTROYS: -
.global FlagClrEE
FlagClrEE:
	push	r25
	ldi	r25,~BIT(F_EE)
	rjmp	FlagClr

; clear flag 'decimal point'
; DESTROYS: -
.global FlagClrDP
FlagClrDP:
	push	r25
	ldi	r25,~BIT(F_DP)
	rjmp	FlagClr

; clear flag 'exponent'
; DESTROYS: -
.global FlagClrExp
FlagClrExp:
	push	r25
	ldi	r25,~BIT(F_EXP)
	rjmp	FlagClr

; clear flag 'stop on SPI error'
; DESTROYS: -
#ifdef HW_ET57				// use hardware of ET-57
.global FlagClrSpiErr
FlagClrSpiErr:
	push	r25
	ldi	r25,~BIT(F_SPIERR)
	rjmp	FlagClr
#endif

; clear flag 'restart DecNum'
; DESTROYS: -
.global FlagClrResDec
FlagClrResDec:
	push	r25
	ldi	r25,~BIT(F_RESDEC)
	rjmp	FlagClr

; clear flag 'exponent digits'
; DESTROYS: -
.global FlagClrExpDig
FlagClrExpDig:
	push	r25
	ldi	r25,~BIT(F_EXPDIG)
	rjmp	FlagClr

; ----------------------------------------------------------------------------
;                               Test flag
; ----------------------------------------------------------------------------

; test flag INV
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestInv
FlagTestInv:
	push	r25
	ldi	r25,BIT(F_INV)
FlagTest:
	push	r24
	ldd	r24,Y+DATA_FLAGS
	and	r24,r25
	pop	r24
	pop	r25
	ret

; test flag 2nd
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTest2nd
FlagTest2nd:
	push	r25
	ldi	r25,BIT(F_2ND)
	rjmp	FlagTest

; test flag 'EE mode'
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestEE
FlagTestEE:
	push	r25
	ldi	r25,BIT(F_EE)
	rjmp	FlagTest

; test flag 'decimal point'
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestDP
FlagTestDP:
	push	r25
	ldi	r25,BIT(F_DP)
	rjmp	FlagTest

; test flag 'exponent'
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestExp
FlagTestExp:
	push	r25
	ldi	r25,BIT(F_EXP)
	rjmp	FlagTest

; test flag 'stop on SPI error'
; OUTPUT: NZ = flag is set
; DESTROYS: -
#ifdef HW_ET57				// use hardware of ET-57
.global FlagTestSpiErr
FlagTestSpiErr:
	push	r25
	ldi	r25,BIT(F_SPIERR)
	rjmp	FlagTest
#endif

; test flag 'restart DecNum'
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestResDec
FlagTestResDec:
	push	r25
	ldi	r25,BIT(F_RESDEC)
	rjmp	FlagTest

; test flag 'exponent digits'
; OUTPUT: NZ = flag is set
; DESTROYS: -
.global FlagTestExpDig
FlagTestExpDig:
	push	r25
	ldi	r25,BIT(F_EXPDIG)
	rjmp	FlagTest
