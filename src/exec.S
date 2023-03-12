; ****************************************************************************
;
;                                Execute buttons
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                           CLR (0x25)
; ----------------------------------------------------------------------------
; INPUT: R24 = key HEX code 0x00..0xFF
;	 R23 = INV flag (1=set)
;	 Z = clear if INV flag was set (=brne)
; ----------------------------------------------------------------------------

.global ExecClr
ExecClr:
; CLR does not clear T register!
	rcall	CalcInit	; reset calculator stack
	CLR_ERROR		; clear error flag
	rcall	FlagClrEE	; clear EE flag
	rcall	EditStart	; start edit mode
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                       Rand
; ----------------------------------------------------------------------------

.global ExecRand
ExecRand:
	rcall	CalcEditStop
	.byte	C_RAND		; random
	.byte	C_SETMEMDEL(REG_X) ; set X back from stack
	.byte	C_END		; end
	.balign 2		; align
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                    Execute parameter function R_PARAM
; ----------------------------------------------------------------------------

.global ExecParFnc
ExecParFnc:
	rcall	CalcEditStop
	.byte	C_GETMEM(REG_X) ; load X into stack
	.byte	C_EXECPAR	; execute parameter function
	.byte	C_SETMEMDEL(REG_X) ; set X back from stack
	.byte	C_END		; end
	.balign 2		; align
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                            x!
; ----------------------------------------------------------------------------

.global ExecFact
ExecFact:

	ldi	R_PARAM,C_FACT	; function - x!
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                             Nop
; ----------------------------------------------------------------------------

.global ExecNop
ExecNop:
	ret

; ----------------------------------------------------------------------------
;                            C.t
; ----------------------------------------------------------------------------

.global ExecCt
ExecCt:

; OUTPUT: R31:R30 = address of new top number 0
; DESTROYS: R24
; CALCULATOR STACK: +1
	rcall	CalcConst0	; load constant 0
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemDelT	; clear register T

; ----------------------------------------------------------------------------
;                            INV C.t
; ----------------------------------------------------------------------------

.global ExecInvCt
ExecInvCt:

; OUTPUT: R31:R30 = address of new top number 0
; DESTROYS: R24
; CALCULATOR STACK: +1
	rcall	CalcConst0	; load constant 0

	ldi	r24,MEM_0
2:	push	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcSetMemUser
	pop	r24
	inc	r24
	cpi	r24,MEM_0+MEM_NUM
	brne	2b
	
	rjmp	CalcDel

; ----------------------------------------------------------------------------
;                           x<>t (0x32)
; ----------------------------------------------------------------------------
; INPUT: R24 = key HEX code 0x00..0xFF
;	 R23 = INV flag (1=set)
;	 Z = clear if INV flag was set (=brne)
; ----------------------------------------------------------------------------

.global ExecXt
ExecXt:

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcEditStop
	.byte	C_GETMEM(REG_X) ; load X into stack
	.byte	C_GETMEM(REG_T) ; load T into stack
	.byte	C_SETMEMDEL(REG_X) ; set X back from stack
	.byte	C_SETMEMDEL(REG_T) ; set T back from stack
	.byte	C_END
	.balign 2
; DESTROYS: R0
	rjmp	Disp		; display all


; ----------------------------------------------------------------------------
;                             Pgm
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecPgm
ExecPgm:

; ----- if running, open program later

	IF_RUNNING		; if running
	std	Y+DATA_PROGNEXT,r24 ; next program index
	IF_RUNNING		; if running
	ret

	jmp	OpenProg

; ----------------------------------------------------------------------------
;                           P->R
; ----------------------------------------------------------------------------

.global ExecPr
ExecPr:
; ----- not INV, convert P->R (polar -> cartesian)
; input polar: x=angle, t=radius
; output cartesian: x=Y, t=X

	ldi	R_PARAM,C_PR	; function - P->R
	rjmp	ExecRp2

; ----------------------------------------------------------------------------
;                           INV P->R
; ----------------------------------------------------------------------------

.global ExecInvPr
ExecInvPr:
; ----- INV, convert R->P (cartesian -> polar)
; input cartesian: x=Y, t=X
; output polar: x=angle, t=radius

	ldi	R_PARAM,C_RP	; function - R->P

ExecRp2:
	rcall	EditStopDispC	; display C

	; stop edit mode, validate X and display C if not running
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	Calc		; calculator
	.byte	C_GETMEM(REG_T)	; load T (x) ... X
	.byte	C_GETMEM(REG_X)	; load X (x,y) ... Y
	.byte	C_EXECPAR	; execute parameter function
	.byte	C_SETMEMDEL(REG_X) ; save angle (r)
	.byte	C_SETMEMDEL(REG_T) ; save radius ()
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                           Load invert indirect
; ----------------------------------------------------------------------------
; OUTPUT: R24 = use memory index 0...MEM_NUM-1 or SPI index 0..255
;	  CF: 1 CS use SPI index, 0 CC use memory index
; Notes: do not stop on SPI error
; ----------------------------------------------------------------------------

.global LoadInvInd
LoadInvInd:
#ifdef HW_ET57				// use hardware of ET-57
	rcall	FlagClrSpiErr	; do not stop on SPI error
#endif
	ldi	r24,REG_IND2
	rjmp	LoadInd1

; ----------------------------------------------------------------------------
;                           Load indirect
; ----------------------------------------------------------------------------
; OUTPUT: R24 = use memory index 0...MEM_NUM-1 or SPI index 0..255
;	  CF: 1 CS use SPI index, 0 CC use memory index
;	     - CF not used with ET-58 hardware
; Notes: stop on SPI error
; ----------------------------------------------------------------------------

.global LoadInd
LoadInd:
#ifdef HW_ET57				// use hardware of ET-57
	rcall	FlagSetSpiErr	; stop on SPI error
#endif
	ldi	r24,REG_IND
LoadInd1:
	; load indirect register
	rcall	CalcGetMemUser
LoadInd3:

#ifdef HW_ET57				// use hardware of ET-57
	; check if number is negative
; OUTPUT: R31:R30 (Z) = last number on calculator stack
; DESTROYS: -
	rcall	CalcTop
; INPUT: R31:R30 (Z) = address of the number
; OUTPUT: CY = number is negative
; DESTROYS: R24
	rcall	NumIsNeg	; negative?
	brcc	2f		; non-negative number

	; load byte = SPI address
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcUnstackB	; load byte
	dec	r24		; index correction
	sec			; set carry flag = use SPI index
	ret
#endif

	; load memory index
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
2:	rcall	CalcUnstackB	; load byte
	cpi	r24,MEM_NUM	; check memory index
	brcs	LoadInd2	; index is OK
	rjmp	Fatal		; fatal error

LoadInd2:
#ifdef HW_ET57				// use hardware of ET-57
	clc			; flag, use memory index
#endif
	ret

; ----------------------------------------------------------------------------
;                           INV STO Ind
; ----------------------------------------------------------------------------

.global ExecInvStoInd
ExecInvStoInd:

	rcall	LoadInvInd	; load invert indirect
#ifdef HW_ET57				// use hardware of ET-57
	rjmp	ExecStoInd2
#else
	rjmp	ExecSto
#endif

; ----------------------------------------------------------------------------
;                           STO Ind
; ----------------------------------------------------------------------------

.global ExecStoInd
ExecStoInd:
    	rcall	LoadInd		; load indirect
ExecStoInd2:

#ifdef HW_ET57				// use hardware of ET-57
	brcc	ExecSto		; use memory index

	push	r24		; SPI address
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcUnstackB	; load byte
	pop	r25		; address
	mov	r23,r24		; data to send
	jmp	SPI_Send	; send data
#else
	rjmp	ExecSto
#endif

; ----------------------------------------------------------------------------
;                           INV STO
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvSto
ExecInvSto:

	subi	r24,-10		; shift to registers 10..19

; ExecSto must follow

; ----------------------------------------------------------------------------
;                           STO
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecSto
ExecSto:

	push	r24
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack
	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           INV RCL Ind
; ----------------------------------------------------------------------------

.global ExecInvRclInd
ExecInvRclInd:

	rcall	LoadInvInd	; load invert indirect
#ifdef HW_ET57				// use hardware of ET-57
	rjmp	ExecRclInd2
#else
	rjmp	ExecRcl
#endif

; ----------------------------------------------------------------------------
;                           RCL Ind
; ----------------------------------------------------------------------------

.global ExecRclInd
ExecRclInd:

	rcall	LoadInd		; load indirect
ExecRclInd2:
#ifdef HW_ET57				// use hardware of ET-57
	brcc	ExecRcl		; use memory index

	mov	r25,r24		; address
; INPUT: R25 = address 0..255
; OUTPUT: CY = error (break on 0xff or 0x00 - no device connected)
;	 R24 = received data
; DESTROYS: R23
	call	SPI_Recv	; receive data
; INPUT: R24 = unsigned byte
; DESTROYS: R25, R24, R23, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcStackB	; stack byte
	rjmp	ExecRcl2
#else
	rjmp	ExecRcl
#endif

; ----------------------------------------------------------------------------
;                           INV RCL
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvRcl
ExecInvRcl:

	subi	r24,-10		; shift to registers 10..19

; ExecRcl must follow

; ----------------------------------------------------------------------------
;                           RCL
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecRcl
ExecRcl:

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; load memory into stack
ExecRcl2:
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcSetMemDelX	; set X from stack
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                           SUM Ind
; ----------------------------------------------------------------------------

.global ExecSumInd
ExecSumInd:

	rcall	LoadInd		; load indirect

; ExecSum must follow

; ----------------------------------------------------------------------------
;                           SUM
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecSum
ExecSum:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; load memory into stack
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcAdd		; add

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           INV SUM Ind
; ----------------------------------------------------------------------------

.global ExecInvSumInd
ExecInvSumInd:

	rcall	LoadInd		; load indirect

; ExecInvSum must follow

; ----------------------------------------------------------------------------
;                           INV SUM
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvSum
ExecInvSum:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; load memory into stack
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; load X into stack

; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcSub		; subtract

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           Inc Ind
; ----------------------------------------------------------------------------

.global ExecIncInd
ExecIncInd:

	rcall	LoadInd		; load indirect

; ExecInc must follow

; ----------------------------------------------------------------------------
;                           Inc
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInc
ExecInc:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; load memory into stack

; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcInc		; increment

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           INV Inc Ind
; ----------------------------------------------------------------------------

.global ExecInvIncInd
ExecInvIncInd:

	rcall	LoadInd		; load indirect

; ExecInvInc must follow

; ----------------------------------------------------------------------------
;                           INV Inc
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvInc
ExecInvInc:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; load memory into stack

; DESTROYS: R31, R30, R25, R24
	rcall	CalcDec		; decrement

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           Exc Ind
; ----------------------------------------------------------------------------

.global ExecExcInd
ExecExcInd:

	rcall	LoadInd		; load indirect
	rjmp	ExecExc

; ----------------------------------------------------------------------------
;                           INV Exc Ind
; ----------------------------------------------------------------------------

.global ExecInvExcInd
ExecInvExcInd:

	rcall	LoadInvInd	; load invert indirect
	rjmp	ExecExc

; ----------------------------------------------------------------------------
;                           INV Exc
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvExc
ExecInvExc:

	subi	r24,-10		; shift to registers 10..19

; ExecExc must follow

; ----------------------------------------------------------------------------
;                           Exc
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecExc
ExecExc:

	push	r24
; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; get memory
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; get X

	pop	r24

; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcSetMemUserDel ; set memory
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcSetMemDelX	; set X
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                           Prd Ind
; ----------------------------------------------------------------------------

.global ExecPrdInd
ExecPrdInd:

	rcall	LoadInd		; load indirect

; ExecPrd must follow

; ----------------------------------------------------------------------------
;                           Prd
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecPrd
ExecPrd:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; get memory
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; get X

; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcMul		; multiply

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           INV Prd Ind
; ----------------------------------------------------------------------------

.global ExecInvPrdInd
ExecInvPrdInd:

	rcall	LoadInd		; load indirect

; ExecInvPrd must follow

; ----------------------------------------------------------------------------
;                           INV Prd
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecInvPrd
ExecInvPrd:

	push	r24

; INPUT: R24 = index of the number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemUser	; get memory
; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	EditStop	; stop edit mode
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: +1
	rcall	CalcGetMemX	; get X

; DESTROYS: all
; CALCULATOR STACK: -1
	rcall	CalcDiv		; divide

	pop	r24
; INPUT: R24 = index of a number
; DESTROYS: R31, R30, R27..R24, R1, R0
; CALCULATOR STACK: -1
	rjmp	CalcSetMemUserDel ; set memory

; ----------------------------------------------------------------------------
;                           Deg
; ----------------------------------------------------------------------------

.global ExecDeg
ExecDeg:

	ldi	r24,UNIT_DEG
ExecDeg2:
	std	Y+DATA_UNIT,r24
; DESTROYS: -
	rjmp	DispFlags

; ----------------------------------------------------------------------------
;                               Inv GTO
; ----------------------------------------------------------------------------

.global ExecInvGto
ExecInvGto:

	; load 2 digits
; OUTPUT: R24 = parameter 0..9 (or another value if invalid)
;	  CY = paramerer is valid
; DESTROYS: R1, R0
	rcall	Load1Dig	; load 1st digit
	brcc	9f
	mov	r25,r24
	rcall	Load1Dig	; load 2nd digit
	brcc	9f

	; convert to address
	ldi	r23,10
	mul	r25,r23
	add	r24,r0		; address
	cpi	r24,PROG_SIZE
	brcc	9f		; invalid address

	; set new address
	ldd	r0,Y+DATA_PROGBEG
	ldd	r1,Y+DATA_PROGBEG+1
	add	r0,r24
	adc	r1,R_ZERO
	std	Y+DATA_ADDR,r0
	std	Y+DATA_ADDR+1,r1
; DESTROYS: R0
9:	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                               GTO
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecGto
ExecGto:

	mov	r23,r24		; label 0..9

; ----- switch to new program

	ldd	r24,Y+DATA_PROGNEXT ; next program
; INPUT: R24 = program index 0..9
; DESTROYS: R25, R24, R1, R0
	IF_RUNNING		; if not running, do not switch to another program
	rcall	OpenProg	; open program

; ----- find label, check address
; INPUT: R24 = label 0..9
; OUTPUT: R27:R26 = absolute address
; DESTROYS: -
	mov	r24,r23
	call	FindLab		; find label, check address

; ----- set new address

	std	Y+DATA_ADDR,r26
	std	Y+DATA_ADDR+1,r27
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                           Pause
; ----------------------------------------------------------------------------

.global ExecPause
ExecPause:

	; only if running
	IFN_RUNNING		; if not running
	ret			; return if not running

	; temporary disable runnung
	CLR_RUNNING

	; display
	rcall	Disp

	; wait for a while
	call	Wait250ms

	; return running flag
	SET_RUNNING

	; display C again
	rjmp	DispC

; ----------------------------------------------------------------------------
;                       Compare X and T
; ----------------------------------------------------------------------------
; saves R23

CompXT:
	push	r23

	; stop edit mode, validate X and display C if not running
; DESTROYS: R31, R30, R27..R24, R1, R0
	; compare registers X and T if equal
	rcall	CalcEditStop	; calculator
	.byte	C_GETMEM(REG_X)	; load X
	.byte	C_GETMEM(REG_T)	; load T
	.byte	C_SUB		; subtract to compare
	.byte	C_END
	.balign 2

; OUTPUT: R31:R30 (Z) = last number on calculator stack
;	  R25:R24 = exponent (0 = number is zero)
;	  ZY = number is 0
; DESTROYS: -
	rcall	CalcTopCheck	; check zero

	rcall	CalcDel2	; delete number (saves SREG)

	pop	r23
	ret

; ----------------------------------------------------------------------------
;                           INV x=t
; ----------------------------------------------------------------------------

.global ExecInvEq
ExecInvEq:
	ldi	r23,1
	rjmp	ExecEq1

; ----------------------------------------------------------------------------
;                           x=t
; ----------------------------------------------------------------------------

.global ExecEq
ExecEq:
	ldi	r23,0

ExecEq1:
	rcall	CompXT		; compare X and T

ExecEq2: ; here is 0 = base condition is TRUE

	breq	2f		; result is 0, numbers are equal

	; numbers are not equal, check INV
	tst	r23		; INV flag?	
	brne	6f		; INV flag is set, different numbers are OK
	; false condition, skip following command
4:	rjmp	LoadPrg		; skip following byte

	; number are equal, check INV
2:	tst	r23		; INV flag?
	brne	4b		; INV flag is set, equal numbers are not OK
	; condition is OK, execute following command
6:	ret

; ----------------------------------------------------------------------------
;                           INV x>=t
; ----------------------------------------------------------------------------

.global ExecInvGe
ExecInvGe:
	ldi	r23,1
	rjmp	ExecGe1

; ----------------------------------------------------------------------------
;                           x>=t
; ----------------------------------------------------------------------------

.global ExecGe
ExecGe:
	ldi	r23,0

ExecGe1:
	rcall	CompXT		; compare X and T

	ldd	r24,Z+1		; get mantissa high
	andi	r24,B7		; check sign

	rjmp	ExecEq2		; 0 if base condition is TRUE, x>=t

; ----------------------------------------------------------------------------
;                               Rad
; ----------------------------------------------------------------------------

.global ExecRad
ExecRad:
	ldi	r24,UNIT_RAD
	rjmp	ExecDeg2

; ----------------------------------------------------------------------------
;                      RTN - return from program
; ----------------------------------------------------------------------------

.global ExecRtn
ExecRtn:

; ----- stop program on base level

	ldd	r24,Y+DATA_PROGLEVEL	; current level of program stack
	tst	r24
	brne	2f			; not base level

.global StopProg
StopProg:
	CLR_RUNNING		; clear running flag

; DESTROYS: R0
	rjmp	Disp		; display all

; ----- decrease current level

2:	dec	r24		; decrease current level
	std	Y+DATA_PROGLEVEL,r24 ; save new level

; ----- open old program

	push	r24
	ldi	r30,lo8(ProgStackInx)
	ldi	r31,hi8(ProgStackInx)
	add	r30,r24
	adc	r31,R_ZERO
	ld	r24,Z
; INPUT: R24 = program index 0..9
; DESTROYS: R31, R30, R24, R0
	rcall	OpenProg
	pop	r24

; ----- return program address

	ldi	r30,lo8(ProgStackAddr)
	ldi	r31,hi8(ProgStackAddr)
	add	r24,r24
	add	r30,r24
	adc	r31,R_ZERO
	ld	r0,Z+
	ld	r31,Z
	std	Y+DATA_ADDR,r0	; return address
	std	Y+DATA_ADDR+1,r31
	ret

; ----------------------------------------------------------------------------
;                                 SBR
; ----------------------------------------------------------------------------
; INPUT: R24 = parameter 0..9
; ----------------------------------------------------------------------------

.global ExecSbr
ExecSbr:

	mov	r23,r24		; label 0..9

; ----- switch to new program

	; save current address and index
	ldd	r24,Y+DATA_ADDR+1
	push	r24
	ldd	r24,Y+DATA_ADDR
	push	r24
	ldd	r24,Y+DATA_PROGINX ; index of current program
	push	r24

	ldd	r24,Y+DATA_PROGNEXT ; next program
; INPUT: R24 = program index 0..9
; DESTROYS: R25, R24, R1, R0
	rcall	OpenProg	; open program

; ----- find label, check address
; INPUT: R24 = label 0..9
; OUTPUT: R27:R26 = absolute address
; DESTROYS: -
	mov	r24,r23
	rcall	FindLab		; find label, check address

; ----- save current address into stack

	; increase stack level
	IFN_RUNNING		; if not running
	std	Y+DATA_PROGLEVEL,R_ZERO ; clear current level if not running
	ldd	r24,Y+DATA_PROGLEVEL ; current level in stack
	cpi	r24,PROGSTACK_NUM ; check max. level
	brcc	ExecGoSbr9	; stack overflow - go to Fatal
	inc	r24		; increase level
	IF_RUNNING		; if not running, do not increase current level
	std	Y+DATA_PROGLEVEL,r24

	; save index of current program (R24 = level + 1)
	ldi	r30,lo8(ProgStackInx-1) ; program indices
	ldi	r31,hi8(ProgStackInx-1)
	add	r30,r24
	adc	r31,R_ZERO	; address of entry

	pop	r25		; old index of current program
	st	Z,r25		; save index

	; save address of current program
	add	r24,r24		; current level * 2
	ldi	r30,lo8(ProgStackAddr-2) ; program addresses
	ldi	r31,hi8(ProgStackAddr-2)
	add	r30,r24
	adc	r31,R_ZERO	; address of entry
	pop	r25
	st	Z+,r25		; save address
	pop	r25
	st	Z,r25

; ----- save new address

	std	Y+DATA_ADDR,r26
	std	Y+DATA_ADDR+1,r27

; ----- if not running, run program and display C

	IF_RUNNING		; if running
	ret

	SET_RUNNING		; set running flag
	rcall	DispC		; display C
	jmp	Wait100ms	; short delay

ExecGoSbr9:
	rjmp	Fatal		; invalid address

; ----------------------------------------------------------------------------
;                              INV Stat+
; ----------------------------------------------------------------------------
; input: y in RegX, x in RegT
; output: N in RegX, x-1 in RegT
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecInvStat
ExecInvStat:

; ----- INV set, subtract number

; DESTROYS: R31, R30, R27..R24, R1, R0
	rcall	CalcEditStop	; calculator
	; sumy -= y
	.byte	C_GETMEM(MEM_SUMY) ; load sumy (sumy)
	.byte	C_GETMEM(REG_X) ; load Y from reg. x (sumy,y)
	.byte	C_SUB		; subtract (sumy-y)
	.byte	C_SETMEMDEL(MEM_SUMY) ; save sumy ()
	; sumy2 -= y^2
	.byte	C_GETMEM(MEM_SUMY2) ; load sumy2 (sumy2)
	.byte	C_GETMEM(REG_X) ; load Y from reg. x (sumy2,y)
	.byte	C_SQR		; square (sumy2,y^2)
	.byte	C_SUB		; subtract (sumy2-y^2)
	.byte	C_SETMEMDEL(MEM_SUMY2) ; save sumy2 ()
	; memn -= 1
	.byte	C_GETMEM(MEM_N) ; load memn (memn)
	.byte	C_DEC		; decrement (memn-1)
	.byte	C_SETMEMDEL(MEM_N) ; save memn ()
	; sumx -= x
	.byte	C_GETMEM(MEM_SUMX) ; load sumx (sumx)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumx,x)
	.byte	C_SUB		; subtract (sumx-x)
	.byte	C_SETMEMDEL(MEM_SUMX) ; save sumx ()
	; sumx2 -= x^2
	.byte	C_GETMEM(MEM_SUMX2) ; load sumx2 (sumx2)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumx2,x)
	.byte	C_SQR		; square (sumx2,x^2)
	.byte	C_SUB		; subtract (sumx2-x^2)
	.byte	C_SETMEMDEL(MEM_SUMX2) ; save sumx2 ()
	; sumxy -= x*y
	.byte	C_GETMEM(MEM_SUMXY) ; load sumxy (sumxy)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumxy,x)
	.byte	C_GETMEM(MEM_SUMXY) ; load Y from reg. x (sumxy,x,y)
	.byte	C_MUL		; multiply (sumxy,x*y)
	.byte	C_SUB		; subtract (sumxy-x*y)
	.byte	C_SETMEMDEL(MEM_SUMXY) ; save sumxy ()
	; load reg X from memn
	.byte	C_GETMEM(MEM_N) ; load memn (memn)
	.byte	C_SETMEMDEL(REG_X) ; save reg X
	; decrement X (reg T)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (x)
	.byte	C_DEC		; decrement (x-1)
	.byte	C_SETMEMDEL(REG_T) ; save reg t
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                              Stat+
; ----------------------------------------------------------------------------
; input: y in RegX, x in RegT
; output: N in RegX, x+1 in RegT
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecStat
ExecStat:

; ----- INV not set, add number

; DESTROYS: R31, R30, R27..R24, R1, R0
4:	rcall	CalcEditStop	; calculator
	; sumy += y
	.byte	C_GETMEM(MEM_SUMY) ; load sumy (sumy)
	.byte	C_GETMEM(REG_X) ; load Y from reg. x (sumy,y)
	.byte	C_ADD		; add (sumy+y)
	.byte	C_SETMEMDEL(MEM_SUMY) ; save sumy ()
	; sumy2 += y^2
	.byte	C_GETMEM(MEM_SUMY2) ; load sumy2 (sumy2)
	.byte	C_GETMEM(REG_X) ; load Y from reg. x (sumy2,y)
	.byte	C_SQR		; square (sumy2,y^2)
	.byte	C_ADD		; add (sumy2+y^2)
	.byte	C_SETMEMDEL(MEM_SUMY2) ; save sumy2 ()
	; memn += 1
	.byte	C_GETMEM(MEM_N) ; load memn (memn)
	.byte	C_INC		; increment (memn+1)
	.byte	C_SETMEMDEL(MEM_N) ; save memn ()
	; sumx += x
	.byte	C_GETMEM(MEM_SUMX) ; load sumx (sumx)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumx,x)
	.byte	C_ADD		; add (sumx+x)
	.byte	C_SETMEMDEL(MEM_SUMX) ; save sumx ()
	; sumx2 += x^2
	.byte	C_GETMEM(MEM_SUMX2) ; load sumx2 (sumx2)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumx2,x)
	.byte	C_SQR		; square (sumx2,x^2)
	.byte	C_ADD		; add (sumx2+x^2)
	.byte	C_SETMEMDEL(MEM_SUMX2) ; save sumx2 ()
	; sumxy += x*y
	.byte	C_GETMEM(MEM_SUMXY) ; load sumxy (sumxy)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (sumxy,x)
	.byte	C_GETMEM(REG_X) ; load Y from reg. x (sumxy,x,y)
	.byte	C_MUL		; multiply (sumxy,x*y)
	.byte	C_ADD		; add (sumxy+x*y)
	.byte	C_SETMEMDEL(MEM_SUMXY) ; save sumxy ()
	; load reg X from memn
	.byte	C_GETMEM(MEM_N) ; load memn (memn)
	.byte	C_SETMEMDEL(REG_X) ; save reg X
	; increment X (reg T)
	.byte	C_GETMEM(REG_T) ; load X from reg. t (x)
	.byte	C_INC		; increment (x+1)
	.byte	C_SETMEMDEL(REG_T) ; save reg t
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                           Mean
; ----------------------------------------------------------------------------
; output: arithmetic mean y
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecMean
ExecMean:

	rcall	CalcEditStop	; calculator
	; offset 0
	.byte	C_GETMEM(MEM_SUMY) ; load sumy (sumy)
	.byte	C_JMP		; jump
	.byte	4		; jump to offset 7 (7-3=4)
	; offset 3
	.balign 2
	; offset 4

; ExecInvMean must follow

; ----------------------------------------------------------------------------
;                           INV Mean
; ----------------------------------------------------------------------------
; output: arithmetic mean x
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecInvMean
ExecInvMean:

	rcall	CalcEditStop	; calculator
	; offset 0 (ExecMean offset 6)
	.byte	C_GETMEM(MEM_SUMX) ; load sumx (sumx)
	; offset 1 (ExecMean offset 7)
	.byte	C_GETMEM(MEM_N) ; load memn (sumx,memn)
	.byte	C_DIV		; divide (sumx/memn)
	.byte	C_SETMEMDEL(REG_X) ; save average into X

	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                               Var
; ----------------------------------------------------------------------------
; output: variance y
; variance y = sum(y^2)/N - (sum(y)/N)^2 = MEM_SUMY2/MEM_N - (MEM_SUMY/MEM_N)^2
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecVar
ExecVar:

	rcall	CalcEditStop	; calculator
	; offset 0
	.byte	C_GETMEM(MEM_SUMY2) ; load sumy2 (sumy2)
	.byte	C_GETMEM(MEM_N)	; load memn (sumy2,memn)
	.byte	C_DIV		; divide (sumy2/memn)
	.byte	C_GETMEM(MEM_SUMY) ; load sumy (sumy2/memn,sumy)
	.byte	C_JMP		; jump
	.byte	6		; jump to offset 12 (12-6=6)
	; offset 6
	.balign 2
	; offset 6

; ExecInvVar must follow

; ----------------------------------------------------------------------------
;                               INV Var
; ----------------------------------------------------------------------------
; output: variance x
; variance x = sum(x^2)/N - (sum(x)/N)^2 = MEM_SUMX2/MEM_N - (MEM_SUMX/MEM_N)^2
;  mem 1 (MEM_SUMY): sum y
;  mem 2 (MEM_SUMY2): sum y^2
;  mem 3 (MEM_N): N
;  mem 4 (MEM_SUMX): sum x
;  mem 5 (MEM_SUMX2): sum x^2
;  mem 6 (MEM_SUMXY): sum x*y

.global ExecInvVar
ExecInvVar:

	rcall	CalcEditStop	; calculator
	; offset 0 (ExecVar offset 8)
	.byte	C_GETMEM(MEM_SUMX2) ; load sumx2 (sumx2)
	.byte	C_GETMEM(MEM_N)	; load memn (sumx2,memn)
	.byte	C_DIV		; divide (sumx2/memn)
	.byte	C_GETMEM(MEM_SUMX) ; load sumx (sumx2/memn,sumx)
	; offset 4 (ExecVar offset 12)
	.byte	C_GETMEM(MEM_N)	; load memn (sumx2/memn,sumx,memn)
	.byte	C_DIV		; divide (sumx2/memn,sumx/memn)
	.byte	C_SQR		; square (sumx2/memn,(sumx/memn)^2)
	.byte	C_SUB		; subtract (varx)
	.byte	C_SETMEMDEL(REG_X) ; save deviation into X
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                           Grad
; ----------------------------------------------------------------------------

.global ExecGrad
ExecGrad:
	ldi	r24,UNIT_GRAD
	rjmp	ExecDeg2

; ----------------------------------------------------------------------------
;                           RST
; ----------------------------------------------------------------------------

.global ExecRst
ExecRst:
	; reopen current program (reset pointer)
; INPUT: R24 = program index (0=main)
; DESTROYS: R31, R30, R24, R0
	ldd	r24,Y+DATA_PROGINX ; current program index
	rcall	OpenProg
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                            INV D.MS
; ----------------------------------------------------------------------------

.global ExecInvDms
ExecInvDms:

; ----- convert degrees.decimals -> degrees.minutes_seconds

	rcall	CalcEditStop	; calculator
	; load constant 60
	.byte	C_BYTE,60	; load byte 60 (60)
	; degrees integer
	.byte	C_GETMEM(REG_X)	; load reg X (60,deg.dec)
	.byte	C_DUP		; duplicate (60,deg.dec,deg.dec)
	.byte	C_TRUNC		; truncate (60,deg.dec,deg.) ... to get degrees integer
	.byte	C_SETMEM(REG_X) ; save degrees integer (60,deg.dec,deg.) ... result accumulator
	; minutes integer
	.byte	C_SUB		; sub (60,.dec) ... to get degrees decimals
	.byte	C_DUP2		; pre-duplicate (60,.dec,60)
	.byte	C_MUL		; multiply*60 to get minutes with decimals (60,min.dec)
	.byte	C_DUP		; duplicate (60,min.dec,min.dec)
	.byte	C_TRUNC		; truncate, to get minutes integer (60,min.dec,min.)
	.byte	C_DUP		; duplicate (60,min.dec,min.,min.)
	.byte	C_CONST(CONST_001) ; load constant 0.01 (60,min.dec,min.,min.,0.01)
	.byte	C_MUL		; multiply (60,min.dec,min.,.min)
	.byte	C_GETMEM(REG_X) ; load result accumulator (60,min.dec,min.,.min,a)
	.byte	C_ADD		; add (60,min.dec,min.,a)
	.byte	C_SETMEMDEL(REG_X) ; save accumulator (60,min.dec,min.)
	; seconds
	.byte	C_SUB		; subtract, to get minuts decimal (60,.min)
	.byte	C_MUL		; multiply*60 to get seconds (sec.dec)
	.byte	C_CONST(CONST_00001) ; load constant 0.0001 (sec.dec,0.0001)
	.byte	C_MUL		; multiply (.00sec)
	.byte	C_GETMEM(REG_X) ; load accumulator (.00sec,a)
	.byte	C_ADD		; add (a)
	.byte	C_SETMEMDEL(REG_X) ; save result ()
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                            D.MS
; ----------------------------------------------------------------------------

.global ExecDms
ExecDms:

; ----- convert degrees.minutes_seconds -> degrees.decimals

	rcall	CalcEditStop	; calculator
	; load constants 36 and 60
	.byte	C_BYTE,36	; load constant 36 (36)
	.byte	C_BYTE,60	; load constant 60 (36,60)
	; degrees integer
	.byte	C_GETMEM(REG_X)	; load reg X (36,60,deg.min_sec)
	.byte	C_DUP		; duplicate (36,60,deg.min_sec,deg.min_sec)
	.byte	C_TRUNC		; truncate (36,60,deg.min_sec,deg.) ... to get degrees integer
	.byte	C_SETMEM(REG_X) ; save degrees integer (36,60,deg.min_sec,deg.) ... result accumulator
	; minutes
	.byte	C_SUB		; sub (36,60,.min_sec) ... to get degrees decimals
	.byte	C_CONST(CONST_100) ; load constant 100 (36,60,.min_sec,100)
	.byte	C_MUL		; multiply (36,60,min.sec)
	.byte	C_EXC		; exchange (36,min.sec,60)
	.byte	C_DUP2		; pre-duplicate (36,min.sec,60,min.sec)
	.byte	C_TRUNC		; truncate to get minutes (36,min.sec,60,min.)
	.byte	C_DUP		; duplicate (36,min.sec,60,min.,min.)
	.byte	C_EXC2		; pre-exchange (36,min.sec,min.,min.,60)
	.byte	C_DIV		; divide (36,min.sec,min.,.min)
	.byte	C_GETMEM(REG_X) ; load result accumulator (36,min.sec,min.,.min,a)
	.byte	C_ADD		; add (36,min.sec,min.,a) ... degrees + minutes/60
	.byte	C_SETMEMDEL(REG_X) ; save accumulator (36,min.sec,min.)
	; seconds
	.byte	C_SUB		; subtract (36,.sec) ... to get seconds / 100
	.byte	C_EXC		; exchange (.sec,36)
	.byte	C_DIV		; divide (.00sec) ... convert seconds to decimals (=seconds*100/3600)
	.byte	C_GETMEM(REG_X) ; load accumulator (.00sec,a)
	.byte	C_ADD		; add (a) ... degrees + minutes/60 + seconds/3600
	.byte	C_SETMEMDEL(REG_X) ; save result ()
	.byte	C_END
	.balign 2

	rjmp	Disp		; display

; ----------------------------------------------------------------------------
;                            pi
; ----------------------------------------------------------------------------

.global ExecPi
ExecPi:
	rcall	CalcEditStop
	.byte	C_CONST(CONST_PI) ; constant Pi
	.byte	C_SETMEMDEL(REG_X) ; set X back from stack
	.byte	C_END
	.balign 2

	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                            R/S
; ----------------------------------------------------------------------------

.global ExecRs
ExecRs:

; ----- break program

	IF_RUNNING		; if running
	rjmp	StopProg	; stop program

; ----- start program

.global StartProg
StartProg:
	SET_RUNNING		; set running
	rcall	DispC		; display "C"
	rjmp	Wait100ms	; short delay

; ----------------------------------------------------------------------------
;                            INV Dsz
; ----------------------------------------------------------------------------

.global ExecInvDsz
ExecInvDsz:

; ----- load INV flag into stack

	rcall	CalcConst1	; load 1 - INV flag
	rjmp	ExecDsz2

; ----------------------------------------------------------------------------
;                            Dsz
; ----------------------------------------------------------------------------

.global ExecDsz
ExecDsz:

; ----- load INV flag into stack

	rcall	CalcConst0	; load 0 - no INV

; ----- load register into stack

ExecDsz2:

; ----- inc/dec register

	rcall	Calc		; calculator (inv,x)
	; offset 0: load Dsz register
	.byte	C_GETMEM(REG_DSZ) ; get Dsz register
	; offset 1: check if number is already zero
	.byte	C_DUP		; duplicate (inv,x,x)
	.byte	C_NOT		; invert, check if number is zero (inv,x,0/1)
	.byte	C_JUMPNZ	; jump if x = 0 (inv,x,0/1)
	.byte	13		; jump to offset 18 (18-5=13)
	; offset 5: check if number is negative
	.byte	C_DEL		; delete
	.byte	C_DUP		; duplicate (inv,x,x)
	.byte	C_LT0		; check if number is < 0 (inv,x,0/1)
	.byte	C_JUMPT		; jump if x < 0 (inv,x)
	.byte	5		; jump to offset 15 (15-10=5)
	; offset 10: number is positive or 0 - decrement
	.byte	C_DEC		; decrement (inv,x-1)
	; offset 11: check if result is <= 0 (=skip condition TRUE)
	.byte	C_DUP		; duplicate (inv,x-1,x-1)
	.byte	C_LTEQ0		; check if number is <= 0 (inv,x-1,0/1)
	.byte	C_JMP		; jump
	.byte	3		; jump to offset 18 (18-15=3)
	; offset 15: number is negative - increment
	.byte	C_INC		; increment (inv,x+1)
	; offset 16: check if result is >= 0 (=skip condition TRUE)
	.byte	C_DUP		; duplicate (inv,x+1,x+1)
	.byte	C_GREQ0		; check if number is >= 0 (inv,x+1,0/1)
	; ofrfset 18: invert result
	.byte	C_EXC		; exchange (inv,0/1,x2)
	.byte	C_EXC2		; pre-exchange (x2,0/1,inv)
	.byte	C_JUMPF		; skip if not invert (x2,0/1)
	.byte	1		; jump to offset 23 (23-22=1)
	; offset 22
	.byte	C_NOT		; inverse result (x2,0/1)
	; offset 23: exchange
	.byte	C_EXC		; exchange (0/1,x2)
	.byte	C_SETMEMDEL(REG_DSZ) ; save result into Dsz register
	.byte	C_END
	.balign 2

; ----- operation result
; OUTPUT: R24 = unsigned byte
; DESTROYS: R31, R30, R25..R22, R1, R0
; CALCULATOR STACK: -1
	rcall	CalcUnstackB	; load result
	tst	r24		; check if skip condition is TRUE
	brne	4f		; condition is TRUE, skip command

	; skip condition is FALSE, loop jump (execute following command )
	ret

	; false condition, skip following command
4:	rjmp	LoadPrg		; skip following byte

; ----------------------------------------------------------------------------
;                       Program code jump table (152 bytes)
; ----------------------------------------------------------------------------

.global CmdTab
CmdTab:
	.word	ExecLnx		; #define CMD_LNX		// 180 lnx
	.word	ExecCe		; #define CMD_CE		// 181 CE
	.word	ExecClr		; #define CMD_CLR		// 182 CLR
	.word	ExecLog		; #define CMD_LOG		// 183 log
	.word	ExecCt		; #define CMD_CT		// 184 C.t

	.word	ExecXt		; #define CMD_XT		// 185 x<>t
	.word	ExecX2		; #define CMD_X2		// 186 x^2
	.word	ExecVx		; #define CMD_SQRT		// 187 Vx
	.word	Exec1x		; #define CMD_1X		// 188 1/x
	.word	ExecDms		; #define CMD_DMS		// 189 D.MS
	.word	ExecPr		; #define CMD_PR		// 190 P->R
	.word	ExecSin		; #define CMD_SIN		// 191 sin
	.word	ExecCos		; #define CMD_COS		// 192 cos
	.word	ExecTan		; #define CMD_TAN		// 193 tan

	.word	ExecYx		; #define CMD_YX		// 194 y^x
	.word	ExecPause	; #define CMD_PAUSE		// 195 Pause
	.word	ExecPi		; #define CMD_PI		// 196 pi

	.word	ExecEE		; #define CMD_EE		// 197 EE
	.word	ExecLPar	; #define CMD_LPAR		// 198 (
	.word	ExecRPar	; #define CMD_RPAR		// 199 )
	.word	ExecDiv		; #define CMD_DIV		// 200 :
	.word	ExecInt		; #define CMD_INT		// 201 Int
	.word	ExecAbs		; #define CMD_ABS		// 202 IxI

	.word	ExecMul		; #define CMD_MUL		// 203 x
	.word	ExecDsz		; #define CMD_DSZ		// 204 Dsz
	.word	ExecStoInd	; #define CMD_STO_IND		// 205 STO*
	.word	ExecRclInd	; #define CMD_RCL_IND		// 206 RCL*
	.word	ExecSumInd	; #define CMD_SUM_IND		// 207 SUM*
	.word	ExecDeg		; #define CMD_DEG		// 208 Deg

	.word	ExecSub		; #define CMD_SUB		// 209 -
	.word	ExecEq		; #define CMD_EQ		// 210 x=t
	.word	ExecIncInd	; #define CMD_INC_IND		// 211 Inc*
	.word	ExecExcInd	; #define CMD_EXC_IND		// 212 Exc*
	.word	ExecPrdInd	; #define CMD_PRD_IND		// 213 Prd*
	.word	ExecRad		; #define CMD_RAD		// 214 Rad

	.word	ExecRst		; #define CMD_RST		// 215 RST
	.word	ExecAdd		; #define CMD_ADD		// 216 +
	.word	ExecGe		; #define CMD_GE		// 217 x>=t
	.word	ExecRand	; #define CMD_RAND		// 218 Rand
	.word	ExecGrad	; #define CMD_GRAD		// 219 Grad

	.word	ExecRs		; #define CMD_RS		// 220 R/S
	.word	ExecDot		; #define CMD_DOT		// 221 .
	.word	ExecNeg		; #define CMD_NEG		// 222 +/-
	.word	ExecRes		; #define CMD_RES		// 223 =
	.word	ExecFact	; #define CMD_FACT		// 224 x!
	.word	ExecStat	; #define CMD_STAT		// 225 Stat
	.word	ExecMean	; #define CMD_MEAN		// 226 Mean
	.word	ExecVar		; #define CMD_VAR		// 227 Var

	.word	ExecInvLnx	; #define CMD_INV_LNX		// 228 INV lnx
	.word	ExecInvLog	; #define CMD_INV_LOG		// 229 INV log
	.word	ExecInvCt	; #define CMD_INV_CT		// 230 INV C.t
	.word	ExecInvDms	; #define CMD_INV_DMS		// 231 INV D.MS
	.word	ExecInvPr	; #define CMD_INV_PR		// 232 INV P->R
	.word	ExecInvSin	; #define CMD_INV_SIN		// 233 INV sin
	.word	ExecInvCos	; #define CMD_INV_COS		// 234 INV cos
	.word	ExecInvTan	; #define CMD_INV_TAN		// 235 INV tan
	.word	ExecInvYx	; #define CMD_INV_YX		// 236 INV y^x
	.word	ExecInvEE	; #define CMD_INV_EE		// 237 INV EE
	.word	ExecInvInt	; #define CMD_INV_INT		// 238 INV Int
	.word	ExecInvAbs	; #define CMD_INV_ABS		// 239 INV IxI ... SGN
	.word	ExecInvDsz	; #define CMD_INV_DSZ		// 240 INV Dsz
	.word	ExecInvStoInd	; #define CMD_INV_STO_IND	// 241 INV STO*
	.word	ExecInvRclInd	; #define CMD_INV_RCL_IND	// 242 INV RCL*
	.word	ExecInvSumInd	; #define CMD_INV_SUM_IND	// 243 INV SUM*
	.word	ExecInvEq	; #define CMD_INV_EQ		// 244 INV x=t
	.word	ExecInvIncInd	; #define CMD_INV_INC_IND	// 245 INV Inc*
	.word	ExecInvExcInd	; #define CMD_INV_EXC_IND	// 246 INV Exc*
	.word	ExecInvPrdInd	; #define CMD_INV_PRD_IND	// 247 INV Prd*
	.word	ExecInvGe	; #define CMD_INV_GE		// 248 INV x>=t
	.word	ExecInvStat	; #define CMD_INV_STAT		// 249 INV Stat
	.word	ExecInvMean	; #define CMD_INV_MEAN		// 250 INV Mean
	.word	ExecInvVar	; #define CMD_INV_VAR		// 251 INV Var
	.word	ExecRtn		; #define CMD_INV_SBR		// 252 INV SBR (RTN)
	.word	ExecInvFix	; #define CMD_INV_FIX		// 253 INV Fix
	.word	ExecInvDiv	; #define CMD_INV_DIV		// 254 INV Div

	.word	ExecNop		; #define CMD_NOP		// 255 Nop

; ----------------------------------------------------------------------------
;                  Parameter program code jump table (36 bytes)
; ----------------------------------------------------------------------------

.global CmdTab2
CmdTab2:
	.word	ExecDig		; #define CMD_DIG		// 0..9 digit base (10 codes)
	.word	ExecSto		; #define CMD_STO		// 10..19 STO base (10 codes)
	.word	ExecRcl		; #define CMD_RCL		// 20..29 RCL base (10 codes)
	.word	ExecSum		; #define CMD_SUM		// 30..39 SUM base (10 codes)
	.word	ExecExc		; #define CMD_EXC		// 40..49 Exc base (10 codes)
	.word	ExecPrd		; #define CMD_PRD		// 50..59 Prd base (10 codes)
	.word	ExecInc		; #define CMD_INC		// 60..69 Inc base (10 codes)
	.word	ExecInvSto	; #define CMD_INV_STO		// 70..79 INV STO base (10 codes)
	.word	ExecInvRcl	; #define CMD_INV_RCL		// 80..89 INV RCL base (10 codes)
	.word	ExecInvSum	; #define CMD_INV_SUM		// 90..99 INV SUM base (10 codes)
	.word	ExecInvExc	; #define CMD_INV_EXC		// 100..109 INV Exc base (10 codes)
	.word	ExecInvPrd	; #define CMD_INV_PRD		// 110..119 INV Prd base (10 codes)
	.word	ExecInvInc	; #define CMD_INV_INC		// 120..129 INV Inc base (10 codes)
	.word	ExecNop		; #define CMD_LBL		// 130..139 Lbl (10 codes)
	.word	ExecGto		; #define CMD_GTO		// 140..149 GTO (10 codes)
	.word	ExecSbr		; #define CMD_SBR		// 150..159 SBR (10 codes)
	.word	ExecFix		; #define CMD_FIX		// 160..169 Fix (10 codes)
	.word	ExecPgm 	; #define CMD_PGM		// 170..179 Pgm (10 codes)

; ----------------------------------------------------------------------------
;                            Execute program code
; ----------------------------------------------------------------------------
; INPUT: R24 = program code CMD_*
; ----------------------------------------------------------------------------

.global ExecCmd
ExecCmd:

	; jump to custom program code
	mov	r25,r24			; program code
	cpi	r24,CMD_PAREND+1	; offset of custom code
	brcs	4f			; not custom program code

	subi	r24,CMD_PAREND+1	; offset of custom code
	ldi	r30,lo8(CmdTab)		; jump table
	ldi	r31,hi8(CmdTab)

2:	add	r24,r24			; offset of code * 2
	add	r30,r24			; add command code
	adc	r31,R_ZERO
	lpm	r24,Z+			; load jump address LOW
	lpm	r31,Z			; load jump address HIGH
	mov	r30,r24			; address LOW
	lsr	r31
	ror	r30			; convert address to word index
	mov	r24,r25			; R24 <- parameter
	ijmp				; jump to function (R24 = parameter)

	; jump to parameter code
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = parameter 0..9
; DESTROYS: R0, R1
4:	rcall	DivB10			; divide code R24 / 10
	ldi	r30,lo8(CmdTab2)	; jump table 2 with parameter
	ldi	r31,hi8(CmdTab2)
	rjmp	2b

; ----------------------------------------------------------------------------
;                            Execute key code
; ----------------------------------------------------------------------------
; INPUT: R24 = key code 0..179 KEY_* (if CY) or NOKEY (if CY)
; ----------------------------------------------------------------------------

.global ExecKey
ExecKey:
	; LRN
	cpi	r24,KEY_LRN
	brne	2f
	rjmp	ExecLrn

	; SST
2:	cpi	r24,KEY_SST
	brne	3f
	rjmp	ExecSst

	; BST
3:	cpi	r24,KEY_BST
	brne	4f
	rjmp	ExecBst

	; Ins
4:	cpi	r24,KEY_INS
	brne	5f
	rjmp	ExecIns

	; Del
5:	cpi	r24,KEY_DEL
	brne	6f
	rjmp	ExecDel

	; Inv +, debug ON
6:
#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)
	cpi	r24,KEY_INV_ADD
	brne	9f
	SET_DEBUG
	rjmp	Disp
	
	; Inv -, debug OFF
9:	cpi	r24,KEY_INV_SUB
	brne	1f
	CLR_DEBUG
	rjmp	Disp
#endif

	; Inv GTO
1:	cpi	r24,KEY_INV_GTO
	brne	2f
	rjmp	ExecInvGto

2:
#ifdef HW_ET58				// use hardware of ET-58
	; OFF - turn calculator off
	cpi	r24,KEY_OFF
	brne	3f
	rjmp	GoSleep

	; INV OFF - set LCD contrast
3:	cpi	r24,KEY_INV_OFF
	brne	4f

	; get parameter
; OUTPUT: R24 = parameter 0..9 (or another value if invalid)
;	  CY = paramerer is valid
; DESTROYS: R1, R0
	rcall	Load1Dig	; load parameter
	brcc	4f		; invalid digit, input another key
	; calculate divider = 70 - par*7
; 0 -> 70
; 1 -> 63
; 2 -> 56
; 3 -> 49
; 4 -> 42
; 5 -> 35
; 6 -> 28
; 7 -> 21
; 8 -> 14
; 9 -> 7
	ldi	r25,7		; multiplier
	mul	r24,r25
	ldi	r25,70
	sub	r25,r0		; complement
	
; INPUT: R27:R26 = destination address
;	 R25 = data
; OUTPUT: R24 = old byte
	ldi	r26,lo8(CFG_LCD)
	ldi	r27,hi8(CFG_LCD)
	rcall	EEWrite		; write correction to EEPROM
	rcall	LCD_Init	; initialice LCD
	rjmp	Disp		; restore display

#endif

4:
	ret
