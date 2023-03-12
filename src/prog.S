; ****************************************************************************
;
;                            Program
;
; ****************************************************************************

#include "include.inc"

	.text

; key names for display (250 bytes)
.global DispName
DispName:
	.asciz	"0"		; #define KEY_0		0 // digit 0
	.asciz	"1"		; #define KEY_1		1 // digit 1
	.asciz	"2"		; #define KEY_2		2 // digit 2
	.asciz	"3"		; #define KEY_3		3 // digit 3
	.asciz	"4"		; #define KEY_4		4 // digit 4
	.asciz	"5"		; #define KEY_5		5 // digit 5
	.asciz	"6"		; #define KEY_6		6 // digit 6
	.asciz	"7"		; #define KEY_7		7 // digit 7
	.asciz	"8"		; #define KEY_8		8 // digit 8
	.asciz	"9"		; #define KEY_9		9 // digit 9

	.asciz	"OFF"		; #define KEY_OFF	10 // OFF
	.asciz	""		; #define KEY_2ND	11 // 2nd
	.asciz	"INV"		; #define KEY_INV	12 // INV
	.asciz	"lnx"		; #define KEY_LNX	13 // lnx
	.asciz	"CE"		; #define KEY_CE	14 // CE
	.asciz	"CLR"		; #define KEY_CLR	15 // CLR
	.asciz	""		; #define KEY_2ND2	16 // 2nd 2nd
	.asciz	""		; #define KEY_INV2	17 // 2nd INV
	.asciz	"log"		; #define KEY_LOG	18 // log
	.asciz	"C.t"		; #define KEY_CT	19 // C.t

	.asciz	"tan"		; #define KEY_TAN	20 // tan
	.asciz	""		; #define KEY_LRN	21 // LRN
	.asciz	"x<->t"		; #define KEY_XT	22 // x<>t
	.asciz	"x^2"		; #define KEY_X2	23 // x^2
	.asciz	"Vx"		; #define KEY_VX	24 // Vx
	.asciz	"1/x"		; #define KEY_1X	25 // 1/x
	.asciz	"D.MS"		; #define KEY_DMS	26 // D.MS
	.asciz	"P->R"		; #define KEY_PR	27 // P->R
	.asciz	"sin"		; #define KEY_SIN	28 // sin
	.asciz	"cos"		; #define KEY_COS	29 // cos

	.asciz	"pi"		; #define KEY_PI	30 // pi
	.asciz	""		; #define KEY_SST	31 // SST
	.asciz	"STO"		; #define KEY_STO	32 // STO
	.asciz	"RCL"		; #define KEY_RCL	33 // RCL
	.asciz	"SUM"		; #define KEY_SUM	34 // SUM
	.asciz	"y^x"		; #define KEY_YX	35 // y^x
	.asciz	"Pause"		; #define KEY_PAUSE	36 // Pause
	.asciz	""		; #define KEY_INS	37 // Ins
	.asciz	"Exc"		; #define KEY_EXC	38 // Exc
	.asciz	"Prd"		; #define KEY_PRD	39 // Prd

	.asciz	"|x|"		; #define KEY_ABS	40 // IxI
	.asciz	""		; #define KEY_BST	41 // BST
	.asciz	"EE"		; #define KEY_EE	42 // EE
	.asciz	"("		; #define KEY_LPAR	43 // (
	.asciz	")"		; #define KEY_RPAR	44 // )
	.asciz	":"		; #define KEY_DIV	45 // :
	.asciz	"Nop"		; #define KEY_NOP	46 // Nop
	.asciz	""		; #define KEY_DEL	47 // Del
	.asciz	"Fix"		; #define KEY_FIX	48 // Fix
	.asciz	"Int"		; #define KEY_INT	49 // Int

	.asciz	"Deg"		; #define KEY_DEG	50 // Deg
	.asciz	"GTO"		; #define KEY_GTO	51 // GTO
	.asciz	""		; #define KEY_TMP_7	52 // (7)
	.asciz	""		; #define KEY_TMP_8	53 // (8)
	.asciz	""		; #define KEY_TMP_9	54 // (9)
	.asciz	"x"		; #define KEY_MUL	55 // x
	.asciz	"Dsz"		; #define KEY_DSZ	56 // Dsz
	.asciz	"STO*"		; #define KEY_STO_IND	57 // STO*
	.asciz	"RCL*"		; #define KEY_RCL_IND	58 // RCL*
	.asciz	"SUM*"		; #define KEY_SUM_IND	59 // SUM*

	.asciz	"Rad"		; #define KEY_RAD	60 // Rad
	.asciz	"SBR"		; #define KEY_SBR	61 // SBR
	.asciz	""		; #define KEY_TMP_4	62 // (4)
	.asciz	""		; #define KEY_TMP_5	63 // (5)
	.asciz	""		; #define KEY_TMP_6	64 // (6)
	.asciz	"-"		; #define KEY_SUB	65 // -
	.asciz	"x=t"		; #define KEY_EQ	66 // x=t
	.asciz	"Inc*"		; #define KEY_INC_IND	67 // Inc*
	.asciz	"Exc*"		; #define KEY_EXC_IND	68 // Exc*
	.asciz	"Prd*"		; #define KEY_PRD_IND	69 // Prd*

	.asciz	"Grad"		; #define KEY_GRAD	70 // Grad
	.asciz	"RST"		; #define KEY_RST	71 // RST
	.asciz	""		; #define KEY_TMP_1	72 // (1)
	.asciz	""		; #define KEY_TMP_2	73 // (2)
	.asciz	""		; #define KEY_TMP_3	74 // (3)
	.asciz	"+"		; #define KEY_ADD	75 // +
	.asciz	"x>=t"		; #define KEY_GE	76 // x>=t
	.asciz	"Inc"		; #define KEY_INC	77 // Inc
	.asciz	"Pgm"		; #define KEY_PGM	78 // Pgm
	.asciz	"Rand"		; #define KEY_RAND	79 // Rand

	.asciz	"Var"		; #define KEY_VAR	80 // Var
	.asciz	"R/S"		; #define KEY_RS	81 // R/S
	.asciz	""		; #define KEY_TMP_0	82 // (0)
	.asciz	"."		; #define KEY_DOT	83 // .
	.asciz	"+/-"		; #define KEY_NEG	84 // +/-
	.asciz	"="		; #define KEY_RES	85 // =
	.asciz	"Lbl"		; #define KEY_LBL	86 // Lbl
	.asciz	"x!"		; #define KEY_FACT	87 // x!
	.asciz	"Stat"		; #define KEY_STAT	88 // Stat
	.asciz	"Mean"		; #define KEY_MEAN	89 // Mean
	.balign 2

.global DispNameErr
DispNameErr:
	.asciz	""		; invalid code
	.balign 2

; ----------------------------------------------------------------------------
;                   Get display name of program byte
; ----------------------------------------------------------------------------
; INPUT: R24 = code KEY_*
; OUTPUT: R31:R30 = ASCIIZ text in ROM
; DESTROYS: R25, R24
; ----------------------------------------------------------------------------

.global GetDispName
GetDispName:

; ----- invalid code

	ldi	r30,lo8(DispNameErr)
	ldi	r31,hi8(DispNameErr)
	cpi	r24,90
	brcc	8f

; ----- find text

	ldi	r30,lo8(DispName)
	ldi	r31,hi8(DispName)
	tst	r24
	breq	8f

2:	lpm	r25,Z+
	tst	r25
	brne	2b
	dec	r24
	brne	2b

8:	ret

; ----------------------------------------------------------------------------
;                           Open program
; ----------------------------------------------------------------------------
; INPUT: R24 = program index 0..9
; DESTROYS: R25, R24, R1, R0
; ----------------------------------------------------------------------------

.global OpenProg
OpenProg:

; ----- set new program index

	std	Y+DATA_PROGINX,r24	; current program index
	std	Y+DATA_PROGNEXT,r24	; next program index

; ----- program begin address

	ldi	r25,PROG_SIZE
	mul	r24,r25
	std	Y+DATA_PROGBEG,r0	; begin address
	std	Y+DATA_PROGBEG+1,r1

; ----- new current address

	std	Y+DATA_ADDR,r0
	std	Y+DATA_ADDR+1,r1

; ----- program end address

	dec	r25
	add	r0,r25
	adc	r1,R_ZERO
	std	Y+DATA_PROGEND,r0	; end address
	std	Y+DATA_PROGEND+1,r1
	ret

; ----------------------------------------------------------------------------
;                     Check and check program address
; ----------------------------------------------------------------------------
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
; ----------------------------------------------------------------------------

.global GetCheckAddr
GetCheckAddr:

	ldd	r26,Y+DATA_ADDR		; current program address
	ldd	r27,Y+DATA_ADDR+1

; CheckAddr must follow

; ----------------------------------------------------------------------------
;                         Check program address
; ----------------------------------------------------------------------------
; INPUT: R27:R26 (X) = address
; OUTPUT: CY = invalid address
; DESTROYS: -
; ----------------------------------------------------------------------------

.global CheckAddr
CheckAddr:

; ----- push registers

	push	r24

; ----- check start of program

	ldd	r24,Y+DATA_PROGBEG ; end of program
	cp	r26,r24
	ldd	r24,Y+DATA_PROGBEG+1
	cpc	r27,r24
	brcs	6f		; invalid pointer

; ----- check end of program

	ldd	r24,Y+DATA_PROGEND ; end of program
	cp	r24,r26		; check pointer
	ldd	r24,Y+DATA_PROGEND+1
	cpc	r24,r27		; set CY = invalid pointer

; ----- pop registers

6:	pop	r24
	ret

; ----------------------------------------------------------------------------
;                        Load one byte from program
; ----------------------------------------------------------------------------
; INPUT: R27:R26 (X) = address (can be out of range)
; OUTPUT: R24 = byte (0 if invalid)
;	  R27:R26 (X+1) = new address, increased by 1 (not changed on error)
;	  CY = invalid address (R27:R26 not changed)
; DESTROYS: -
; ----------------------------------------------------------------------------

.global LoadByte
LoadByte:

; ----- check address
; INPUT: R27:R26 (X) = address
; OUTPUT: CY = invalid address
; DESTROYS: -
	clr	r24		; R24 <- invalid code 0
	rcall	CheckAddr	; check address
	brcs	6f		; invalid address

; ----- read byte from EEPROM
; INPUT: R27:R26 = source address
; OUTPUT: R24 = data
; DESTROYS: -
	call	EERead
	adiw	r26,1		; shift address
	clc			; NC, operation OK

; ----- pop registers

6:	ret

; ----------------------------------------------------------------------------
;  Load one byte from program, increments address (stop program on overflow)
; ----------------------------------------------------------------------------
; OUTPUT: R24 = byte (0 on error)
;	  CY = invalid address (address not changed)
; DESTROYS: -
; ----------------------------------------------------------------------------

.global LoadPrg
LoadPrg:

; ----- push registers

	push	r26
	push	r27

; ----- prepare current address -> X
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
	rcall	GetCheckAddr

; ----- load byte
; INPUT: R27:R26 (X) = address (can be out of range)
; OUTPUT: R24 = byte (0 if invalid)
;	  R27:R26 (X+1) = new address, increased by 1 (not changed on error)
;	  CY = invalid address (R27:R26 not changed)
; DESTROYS: -
	rcall	LoadByte
	std	Y+DATA_ADDR,r26
	std	Y+DATA_ADDR+1,r27 ; save new pointer
	brcc	8f		; pointer is OK

	; stop running on end of memory
	CLR_RUNNING		; stop program (do not modify C flag)

; ----- pop registers

8:	pop	r27
	pop	r26
	ret

; ----------------------------------------------------------------------------
;                     Find label (fatal error if not found)
; ----------------------------------------------------------------------------
; INPUT: R24 = label 0..9
; OUTPUT: R27:R26 = absolute address
; DESTROYS: -
; ----------------------------------------------------------------------------

.global FindLab
FindLab:

; ----- push registers

	push	r24
	push	r25

; ----- required label code

	mov	r25,r24		; required label
	subi	r25,-CMD_LBL	; key code
	
; ----- prepare address of program start -> R27:R26 (X)

	ldd	r26,Y+DATA_PROGBEG
	ldd	r27,Y+DATA_PROGBEG+1

; ----- load next byte
; INPUT: R27:R26 (X) = address (can be out of range)
; OUTPUT: R24 = byte (0 if invalid)
;	  R27:R26 (X+1) = new address, increased by 1 (not changed on error)
;	  CY = invalid address (R27:R26 not changed)
; DESTROYS: -
2:	rcall	LoadByte
	brcc	3f		; address is OK

; ----- fatal error, label not found

	rjmp	Fatal

; ----- check label

3:	cp	r24,r25
	brne	2b		; next byte

; ----- pop registers

	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;               Write key code into program at current address
; ----------------------------------------------------------------------------
; INPUT: R24 = key HEX code 0x00..0xFF
; DESTROYS: R27, R26, R25, R24
; ----------------------------------------------------------------------------

.global ProgKey
ProgKey:

; ----- check if programming mode

	IFN_PROGRAM		; if not programming
2:	ret			; return if not programming mode

; ----- prepare and check address
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
	rcall	GetCheckAddr	; get address
	brcs	2b		; invalid address

; ----- write key code

	mov	r25,r24
; INPUT: R27:R26 = destination address
;	 R25 = data
; OUTPUT: R24 = old byte
	call	EEWrite

; ----- increase address

	adiw	r26,1
	std	Y+DATA_ADDR,r26
	std	Y+DATA_ADDR+1,r27
8:
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                                LRN
; ----------------------------------------------------------------------------

.global ExecLrn
ExecLrn:
 	IF_RUNNING
	ret			; skip if running

	IF_PROGRAM		; if programming
	rjmp	2f		; programming
	
	SET_PROGRAM		; set programming
	rjmp	4f	
	
2:	CLR_PROGRAM		; clear programming

4:
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                               SST
; ----------------------------------------------------------------------------

.global ExecSst
ExecSst:

; ----- skip if running

 	IF_RUNNING
	ret			; skip if running

; ----- read key code and increase address
; OUTPUT: R24 = byte (0 on error)
;	  CY = invalid address (address not changed)
; DESTROYS: -
	rcall	LoadPrg
	brcs	9f		; invalid address

; ----- if not programming, execute code

	IF_PROGRAM		; if programming
	rjmp	9f		; programming, no operation

; ----- start running

	push	r24
	rcall	StartProg	; start program
	pop	r24

; ----- execute code, not programming keys

	rcall	ExecCmd		; execute code

; ----- stop running

	call	StopProg
9:
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                               Ins
; ----------------------------------------------------------------------------

.global ExecIns
ExecIns:

; ----- skip if running

 	IF_RUNNING
	ret			; skip if running

; ----- skip if not programming

	IFN_PROGRAM		; not programming?
2:	ret			; not programming

; ----- prepare start address
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
	rcall	GetCheckAddr	; get address
	brcs	2b		; invalid address

; ----- write previous byte
; INPUT: R27:R26 = destination address
;	 R25 = data
; OUTPUT: R24 = old byte
	ldi	r25,CLEARKEY	; new byte
5:	call	EEWrite		; write byte R25
	mov	r25,r24		; shift old byte to new position

; ----- shift address

	adiw	r26,1		; shift address
; INPUT: R27:R26 (X) = address
; OUTPUT: CY = invalid address
; DESTROYS: -
	rcall	CheckAddr	; check address
	brcc	5b		; address is OK

; ----- display new state

; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                               BST
; ----------------------------------------------------------------------------

.global ExecBst
ExecBst:

; ----- skip if running

 	IF_RUNNING
	ret			; skip if running

; ----- skip if not programming

	IFN_PROGRAM		; not programming?
2:	ret			; not programming

; ----- load address
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
	rcall	GetCheckAddr	; get address

; ----- decrease address

	sbiw	r26,1
; INPUT: R27:R26 (X) = address
; OUTPUT: CY = invalid address
; DESTROYS: -
	rcall	CheckAddr	; check address
	brcs	2b		; invalid address

; ----- save address

	std	Y+DATA_ADDR,r26
	std	Y+DATA_ADDR+1,r27

; ----- display new state
; DESTROYS: R0
	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                               Del
; ----------------------------------------------------------------------------

.global ExecDel
ExecDel:

; ----- skip if running

 	IF_RUNNING
	ret			; skip if running

; ----- skip if not programming

	IFN_PROGRAM		; not programming?
2:	ret			; not programming

; ----- prepare start address
; OUTPUT: R27:R26 (X) = current program address
; 	  CY = invalid address
; DESTROYS: -
	rcall	GetCheckAddr	; get address
	brcs	2b		; invalid address
	movw	r30,r26		; R31:R30 stop address

; ----- prepare stop address

	ldd	r26,Y+DATA_PROGEND ; end of program
	ldd	r27,Y+DATA_PROGEND+1

; ----- write next byte
; INPUT: R27:R26 = destination address
;	 R25 = data
; OUTPUT: R24 = old byte
	ldi	r25,CLEARKEY	; new byte
5:	call	EEWrite		; write byte R25
	mov	r25,r24		; shift old byte to new position

; ----- check address

	cp	r26,r30
	cpc	r27,r31
	breq	6f
	
; ----- shift address

	sbiw	r26,1		; shift address
	rjmp	5b		; next address

; ----- display new state

; DESTROYS: R0
6:	rjmp	Disp		; display all

; ----------------------------------------------------------------------------
;                            Programming program code
; ----------------------------------------------------------------------------
; INPUT: R24 = program code 0..179 CMD_*
; ----------------------------------------------------------------------------

.global ProgramCmd
ProgramCmd:
	; write code
	rcall	ProgKey		; write key
	rjmp	Disp		; display all
