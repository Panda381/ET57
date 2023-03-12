; ****************************************************************************
;
;                                Keyboard
;
; ****************************************************************************

#include "include.inc"

	.text

#ifndef TIMSK
#define TIMSK TIMSK1
#endif

; --- ET-57 hardware:

; Keyboard pins:
;  PB6: COL2
;  PB7: COL1
;  PC0: ROW3
;  PC1: ROW2
;  PC2: ROW4
;  PC3: ROW5
;  PC4: COL5
;  PC5: ROW1
;  PD0: ROW6
;  PD1: ROW7
;  PD2: COL4
;  PD3: COL3
;  PD4: ROW8

; COLs are 3D-LOW outputs:
;  COL1: PB7
;  COL2: PB6
;  COL3: PD3
;  COL4: PD2
;  COL5: PC4

; ROWs are pull-up intpus:
;  ROW1: PC5
;  ROW2: PC1
;  ROW3: PC0
;  ROW4: PC2
;  ROW5: PC3
;  ROW6: PD0
;  ROW7: PD1
;  ROW8: PD4

; --- ET-58 hardware:

; Keyboard pins:
;  PB0: ROW4
;  PB1: ROW6
;  PB2: COL2
;  PB3: ROW8
;  PB4: ROW1
;  PB5: COL3
;  PC1: COL4
;  PC2: ROW7
;  PC3: COL5
;  PC4: ROW5
;  PC5: ROW3
;  PD5: COL1
;  PD7: ROW2

; COLs are 3D-LOW outputs:
;  COL1: PD5
;  COL2: PB2
;  COL3: PB5
;  COL4: PC1
;  COL5: PC3

; ROWs are pull-up intpus:
;  ROW1: PB4
;  ROW2: PD7
;  ROW3: PC5
;  ROW4: PB0
;  ROW5: PC4
;  ROW6: PB1
;  ROW7: PC2
;  ROW8: PB3

; remap numeric keys
RemapDig:
	.byte	0x82 	; '0'
	.byte	0x72 	; '1'
	.byte	0x73 	; '2'
	.byte	0x74 	; '3'
	.byte	0x62 	; '4'
	.byte	0x63 	; '5'
	.byte	0x64 	; '6'
	.byte	0x52 	; '7'
	.byte	0x53 	; '8'
	.byte	0x54 	; '9'
	.balign 2
RemapDigEnd:

#define CMD_NONE	11	// invalid remapping (= unused code STO 1)

; remap keys KEY_* to commands CMD_*
RemapCmd:
	; without INV
	.byte	CMD_0		; 0 digit 0
	.byte	CMD_1		; 1 digit 1
	.byte	CMD_2		; 2 digit 2
	.byte	CMD_3		; 3 digit 3
	.byte	CMD_4		; 4 digit 4
	.byte	CMD_5		; 5 digit 5
	.byte	CMD_6		; 6 digit 6
	.byte	CMD_7		; 7 digit 7
	.byte	CMD_8		; 8 digit 8
	.byte	CMD_9		; 9 digit 9

	.byte	CMD_NONE	; 10 OFF
	.byte	CMD_NONE	; 11 2nd
	.byte	CMD_NONE	; 12 INV
	.byte	CMD_LNX		; 13 lnx
	.byte	CMD_CE		; 14 CE
	.byte	CMD_CLR		; 15 CLR
	.byte	CMD_NONE	; 16 2nd 2nd
	.byte	CMD_NONE	; 17 2nd INV
	.byte	CMD_LOG		; 18 log
	.byte	CMD_CT		; 19 C.t

	.byte	CMD_TAN		; 20 tan
	.byte	CMD_NONE	; 21 LRN
	.byte	CMD_XT		; 22 x<>t
	.byte	CMD_X2		; 23 x^2
	.byte	CMD_SQRT	; 24 Vx
	.byte	CMD_1X		; 25 1/x
	.byte	CMD_DMS		; 26 D.MS
	.byte	CMD_PR		; 27 P->R
	.byte	CMD_SIN		; 28 sin
	.byte	CMD_COS		; 29 cos

	.byte	CMD_PI		; 30 pi
	.byte	CMD_NONE	; 31 SST
	.byte	CMD_STO		; 32 STO
	.byte	CMD_RCL		; 33 RCL
	.byte	CMD_SUM		; 34 SUM
	.byte	CMD_YX		; 35 y^x
	.byte	CMD_PAUSE	; 36 Pause
	.byte	CMD_NONE	; 37 Ins
	.byte	CMD_EXC		; 38 Exc
	.byte	CMD_PRD		; 39 Prd

	.byte	CMD_ABS		; 40 IxI
	.byte	CMD_NONE	; 41 BST
	.byte	CMD_EE		; 42 EE
	.byte	CMD_LPAR	; 43 (
	.byte	CMD_RPAR	; 44 )
	.byte	CMD_DIV		; 45 :
	.byte	CMD_NOP		; 46 Nop
	.byte	CMD_NONE	; 47 Del
	.byte	CMD_FIX		; 48 Fix
	.byte	CMD_INT		; 49 Int

	.byte	CMD_DEG		; 50 Deg
	.byte	CMD_GTO		; 51 GTO
	.byte	CMD_NONE	; 52 (7)
	.byte	CMD_NONE	; 53 (8)
	.byte	CMD_NONE	; 54 (9)
	.byte	CMD_MUL		; 55 x
	.byte	CMD_DSZ		; 56 Dsz
	.byte	CMD_STO_IND	; 57 STO*
	.byte	CMD_RCL_IND	; 58 RCL*
	.byte	CMD_SUM_IND	; 59 SUM*

	.byte	CMD_RAD		; 60 Rad
	.byte	CMD_SBR		; 61 SBR
	.byte	CMD_NONE	; 62 (4)
	.byte	CMD_NONE	; 63 (5)
	.byte	CMD_NONE	; 64 (6)
	.byte	CMD_SUB		; 65 -
	.byte	CMD_EQ		; 66 x=t
	.byte	CMD_INC_IND	; 67 Inc*
	.byte	CMD_EXC_IND	; 68 Exc*
	.byte	CMD_PRD_IND	; 69 Prd*

	.byte	CMD_GRAD	; 70 Grad
	.byte	CMD_RST		; 71 RST
	.byte	CMD_NONE	; 72 (1)
	.byte	CMD_NONE	; 73 (2)
	.byte	CMD_NONE	; 74 (3)
	.byte	CMD_ADD		; 75 +
	.byte	CMD_GE		; 76 x>=t
	.byte	CMD_INC		; 77 Inc
	.byte	CMD_PGM		; 78 Pgm
	.byte	CMD_RAND	; 79 Rand

	.byte	CMD_VAR		; 80 Var
	.byte	CMD_RS		; 81 R/S
	.byte	CMD_NONE	; 82 (0)
	.byte	CMD_DOT		; 83 .
	.byte	CMD_NEG		; 84 +/-
	.byte	CMD_RES		; 85 =
	.byte	CMD_LBL		; 86 Lbl
	.byte	CMD_FACT	; 87 x!
	.byte	CMD_STAT	; 88 Stat
	.byte	CMD_MEAN	; 89 Mean

	; with INV
	.byte	CMD_0		; 90 INV digit 0
	.byte	CMD_1		; 91 INV digit 1
	.byte	CMD_2		; 92 INV digit 2
	.byte	CMD_3		; 93 INV digit 3
	.byte	CMD_4		; 94 INV digit 4
	.byte	CMD_5		; 95 INV digit 5
	.byte	CMD_6		; 96 INV digit 6
	.byte	CMD_7		; 97 INV digit 7
	.byte	CMD_8		; 98 INV digit 8
	.byte	CMD_9		; 99 INV digit 9
                                  
	.byte	CMD_NONE	; 100 INV OFF
	.byte	CMD_NONE	; 101 INV 2nd
	.byte	CMD_NONE	; 102 INV INV
	.byte	CMD_INV_LNX	; 103 INV lnx
	.byte	CMD_CE		; 104 INV CE
	.byte	CMD_CLR		; 105 INV CLR
	.byte	CMD_NONE	; 106 INV 2nd 2nd
	.byte	CMD_NONE	; 107 INV 2nd INV
	.byte	CMD_INV_LOG	; 108 INV log
	.byte	CMD_INV_CT	; 109 INV C.t
                                      
	.byte	CMD_INV_TAN	; 110 INV tan
	.byte	CMD_NONE	; 111 INV LRN
	.byte	CMD_XT		; 112 INV x<>t
	.byte	CMD_X2		; 113 INV x^2
	.byte	CMD_SQRT	; 114 INV Vx
	.byte	CMD_1X		; 115 INV 1/x
	.byte	CMD_INV_DMS	; 116 INV D.MS
	.byte	CMD_INV_PR	; 117 INV P->R
	.byte	CMD_INV_SIN	; 118 INV sin
	.byte	CMD_INV_COS	; 119 INV cos
                                      
	.byte	CMD_PI		; 120 INV pi
	.byte	CMD_NONE	; 121 INV SST
	.byte	CMD_INV_STO	; 122 INV STO
	.byte	CMD_INV_RCL	; 123 INV RCL
	.byte	CMD_INV_SUM	; 124 INV SUM
	.byte	CMD_INV_YX	; 125 INV y^x
	.byte	CMD_PAUSE	; 126 INV Pause
	.byte	CMD_NONE	; 127 INV Ins
	.byte	CMD_INV_EXC	; 128 INV Exc
	.byte	CMD_INV_PRD	; 129 INV Prd
                                      
	.byte	CMD_INV_ABS	; 130 INV IxI
	.byte	CMD_NONE	; 131 INV BST
	.byte	CMD_INV_EE	; 132 INV EE
	.byte	CMD_LPAR	; 133 INV (
	.byte	CMD_RPAR	; 134 INV )
	.byte	CMD_INV_DIV	; 135 INV :
	.byte	CMD_NOP		; 136 INV Nop
	.byte	CMD_NONE	; 137 INV Del
	.byte	CMD_INV_FIX	; 138 INV Fix
	.byte	CMD_INV_INT	; 139 INV Int
                                      
	.byte	CMD_DEG		; 140 INV Deg
	.byte	CMD_NONE	; 141 INV GTO
	.byte	CMD_NONE	; 142 INV (7)
	.byte	CMD_NONE	; 143 INV (8)
	.byte	CMD_NONE	; 144 INV (9)
	.byte	CMD_MUL		; 145 INV x
	.byte	CMD_INV_DSZ	; 146 INV Dsz
	.byte	CMD_INV_STO_IND	; 147 INV STO*
	.byte	CMD_INV_RCL_IND	; 148 INV RCL*
	.byte	CMD_INV_SUM_IND	; 149 INV SUM*
                                      
	.byte	CMD_RAD		; 150 INV Rad
	.byte	CMD_INV_SBR	; 151 INV SBR (RTN)
	.byte	CMD_NONE	; 152 INV (4)
	.byte	CMD_NONE	; 153 INV (5)
	.byte	CMD_NONE	; 154 INV (6)

#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)
	.byte	CMD_NONE	; 155 INV -
#else
	.byte	CMD_SUB		; 155 INV -
#endif
	.byte	CMD_INV_EQ	; 156 INV x=t
	.byte	CMD_INV_INC_IND	; 157 INV Inc*
	.byte	CMD_INV_EXC_IND	; 158 INV Exc*
	.byte	CMD_INV_PRD_IND	; 159 INV Prd*
                                      
	.byte	CMD_GRAD	; 160 INV Grad
	.byte	CMD_RST		; 161 INV RST
	.byte	CMD_NONE	; 162 INV (1)
	.byte	CMD_NONE	; 163 INV (2)
	.byte	CMD_NONE	; 164 INV (3)
#ifdef USEDEBUG			// use debug mode (INV + DEBUG ON, INV - DEBUG OFF)
	.byte	CMD_NONE	; 165 INV +
#else
	.byte	CMD_ADD		; 165 INV +
#endif
	.byte	CMD_INV_GE	; 166 INV x>=t
	.byte	CMD_INV_INC	; 167 INV Inc
	.byte	CMD_PGM		; 168 INV Pgm
	.byte	CMD_RAND	; 169 INV Rand
                                          
	.byte	CMD_INV_VAR	; 170 INV Var
	.byte	CMD_RS		; 171 INV R/S
	.byte	CMD_NONE	; 172 INV (0)
	.byte	CMD_DOT		; 173 INV .
	.byte	CMD_NEG		; 174 INV +/-
	.byte	CMD_RES		; 175 INV =
	.byte	CMD_LBL		; 176 INV Lbl
	.byte	CMD_FACT	; 177 INV x!
	.byte	CMD_INV_STAT	; 178 INV Stat
	.byte	CMD_INV_MEAN	; 179 INV Mean
                                      
RemapCmdEnd:
; table must have even size
;	.balign 2

; ----------------------------------------------------------------------------
;                          Read keyboard rows
; ----------------------------------------------------------------------------
; INPUT: R30 = previous detected key code, 0=none, 0xff=multiply keys
;	 R31 = column
; OUTPUT: R30 = new key
;	  R31 = new column
; DESTROYS: R24
; ----------------------------------------------------------------------------
 
.global KeyInRow
KeyInRow:

; ----- short delay to stabilize signals
; DESTROYS: -
	rcall	Wait100us

; ----- prepare - no key

	ldi	r24,0x0f

; ----- detect rows (0x0f no key, 0xR0 key row)

#ifdef HW_ET57				// use hardware of ET-57

	sbis	_SFR_IO_ADDR(PINC),5	; ROW1
	subi	r24,-0x01		; R24 <- 0x10
	sbis	_SFR_IO_ADDR(PINC),1	; ROW2
	subi	r24,-0x11		; R24 <- 0x20
	sbis	_SFR_IO_ADDR(PINC),0	; ROW3
	subi	r24,-0x21		; R24 <- 0x30
	sbis	_SFR_IO_ADDR(PINC),2	; ROW4
	subi	r24,-0x31		; R24 <- 0x40
	sbis	_SFR_IO_ADDR(PINC),3	; ROW5
	subi	r24,-0x41		; R24 <- 0x50
	sbis	_SFR_IO_ADDR(PIND),0	; ROW6
	subi	r24,-0x51		; R24 <- 0x60
	sbis	_SFR_IO_ADDR(PIND),1	; ROW7
	subi	r24,-0x61		; R24 <- 0x70
	sbis	_SFR_IO_ADDR(PIND),4	; ROW8
	subi	r24,-0x71		; R24 <- 0x80

#else // HW_ET57

	sbis	_SFR_IO_ADDR(PIND),7	; ROW1
	subi	r24,-0x01		; R24 <- 0x10
	sbis	_SFR_IO_ADDR(PINC),5	; ROW2
	subi	r24,-0x11		; R24 <- 0x20
	sbis	_SFR_IO_ADDR(PINB),0	; ROW3
	subi	r24,-0x21		; R24 <- 0x30
	sbis	_SFR_IO_ADDR(PINC),4	; ROW4
	subi	r24,-0x31		; R24 <- 0x40
	sbis	_SFR_IO_ADDR(PINB),1	; ROW5
	subi	r24,-0x41		; R24 <- 0x50
	sbis	_SFR_IO_ADDR(PINC),2	; ROW6
	subi	r24,-0x51		; R24 <- 0x60
	sbis	_SFR_IO_ADDR(PINB),3	; ROW7
	subi	r24,-0x61		; R24 <- 0x70
	sbis	_SFR_IO_ADDR(PINC),0	; ROW8
	subi	r24,-0x71		; R24 <- 0x80

#endif // HW_ET57

; ----- check no key

	cpi	r24,0x0f
	breq	8f		; no key

; ----- check if we have already some key

	tst	r30		; any key?
	brne	2f		; multiply keys

; ----- compose key code (R24 = key row 0xR0, R31 = key column 0x0C)

	mov	r30,r24		; key row
	or	r30,r31		; add key column

; ----- check if only 1 key is pressed

	andi	r24,0x0f	; number of pressed keys - 1
	breq	8f		; key is OK

; ----- flag - multiply keys

2:	ldi	r30,0xff	; flag - multiply keys

; ----- increase column

8:	inc	r31		; increase column
	ret

; ----------------------------------------------------------------------------
;                           Timer1 interrupt
; ----------------------------------------------------------------------------
; Interrupt every 10 ms

.global	TIMER1_COMPA_vect
TIMER1_COMPA_vect:

; ----- push registers

	push	r24
	in	r24,_SFR_IO_ADDR(SREG)	; status register
	push	r24
	push	r30
	push	r31

; ----- increment timer counter

	lds	r30,Time
	inc	r30
	sts	Time,r30

; ----- scan keyboard (takes 500 us)
; INPUT: R30 = previous detected key code, 0=none, 0xff=multiply keys
;	 R31 = column
; OUTPUT: R30 = new key
;	  R31 = new column
; DESTROYS: R24

	clr	r30		; key code accumulator
	ldi	r31,1		; key column = 1

#ifdef HW_ET57				// use hardware of ET-57

	sbi	_SFR_IO_ADDR(DDRB),7 ; set output to COL1
	rcall	KeyInRow	; detect keys of COL1
	cbi	_SFR_IO_ADDR(DDRB),7 ; clear output to COL1

	sbi	_SFR_IO_ADDR(DDRB),6 ; set output to COL2
	rcall	KeyInRow	; detect keys of COL2
	cbi	_SFR_IO_ADDR(DDRB),6 ; clear output to COL2

	sbi	_SFR_IO_ADDR(DDRD),3 ; set output to COL3
	rcall	KeyInRow	; detect keys of COL3
	cbi	_SFR_IO_ADDR(DDRD),3 ; clear output to COL3

	sbi	_SFR_IO_ADDR(DDRD),2 ; set output to COL4
	rcall	KeyInRow	; detect keys of COL4
	cbi	_SFR_IO_ADDR(DDRD),2 ; clear output to COL4

	sbi	_SFR_IO_ADDR(DDRC),4 ; set output to COL5
	rcall	KeyInRow	; detect keys of COL5
	cbi	_SFR_IO_ADDR(DDRC),4 ; clear output to COL5

#else // HW_ET57

	sbi	_SFR_IO_ADDR(DDRD),5 ; set output to COL1
	rcall	KeyInRow	; detect keys of COL1
	cbi	_SFR_IO_ADDR(DDRD),5 ; clear output to COL1

	sbi	_SFR_IO_ADDR(DDRB),2 ; set output to COL2
	rcall	KeyInRow	; detect keys of COL2
	cbi	_SFR_IO_ADDR(DDRB),2 ; clear output to COL2

	sbi	_SFR_IO_ADDR(DDRB),5 ; set output to COL3
	rcall	KeyInRow	; detect keys of COL3
	cbi	_SFR_IO_ADDR(DDRB),5 ; clear output to COL3

	sbi	_SFR_IO_ADDR(DDRC),1 ; set output to COL4
	rcall	KeyInRow	; detect keys of COL4
	cbi	_SFR_IO_ADDR(DDRC),1 ; clear output to COL4

	sbi	_SFR_IO_ADDR(DDRC),3 ; set output to COL5
	rcall	KeyInRow	; detect keys of COL5
	cbi	_SFR_IO_ADDR(DDRC),3 ; clear output to COL5

#endif // HW_ET57

; ----- check if exactly 1 key is pressed

	CLR_TRACE		; clear trace flag
	tst	r30		; no key?
	breq	4f		; no key - release key
	cpi	r30,0xff	; multiply keys?
	breq	4f		; multiply keys - release key
 
; ----- trace

	cpi	r30,0x51	; GTO key?
	brne	5f
	SET_TRACE		; set trace flag

; ----- check if new key is pressed

5:	lds	r31,KeyRaw	; old key
	cp	r31,r30		; is this key alreay in buffer?
	breq	2f		; key not changed
	sts	Key,r30		; output new key
2:	sts	KeyRaw,r30	; save new raw key

; ----- reset release counter

	ldi	r24,8		; release counter to time-out 80 ms
	sts	KeyCnt,r24	; set new release counter
	rjmp	8f

; ----- decrease release key counter

4:	lds	r24,KeyCnt	; key counter
	dec	r24		; decrease counter
	brmi	8f		; no key
	sts	KeyCnt,r24	; save new key counter
	brne	8f		; key is still valid

; ----- delete current key

	ldi	r24,NOKEY
	sts	KeyRaw,r24

; ----- pop registers

8:	pop	r31
	pop	r30
	pop	r24
	out	_SFR_IO_ADDR(SREG),r24
	pop	r24
	reti

; ----------------------------------------------------------------------------
;                   Initialize keyboard
; ----------------------------------------------------------------------------
; DESTROYS: R24
; ----------------------------------------------------------------------------
; Prescaler clk/64. Result interrupt frequency: 8000000/64/1250 = 4000000/64/625 = 100 Hz
; 1 timer tick = 10 ms

.global KEY_Init
KEY_Init:

; ----- Timer1: set CTC mode, prescaler 1/64

	sts	TCCR1A,R_ZERO
	ldi	r24,BIT(WGM12) + 3
	sts	TCCR1B,r24

; ----- set interval to 1250

#if F_CPU >= 6000000

	ldi	r24,hi8(1250-1)
	sts	OCR1AH,r24
	ldi	r24,lo8(1250-1)
	sts	OCR1AL,r24
	
#else

	ldi	r24,hi8(625-1)
	sts	OCR1AH,r24
	ldi	r24,lo8(625-1)
	sts	OCR1AL,r24

#endif

; ----- reset counter

	sts	TCNT1H,R_ZERO
	sts	TCNT1L,R_ZERO

; ----- Enable interrupt from Timer1 compare match

	lds	r24,TIMSK
	ori	r24,BIT(OCIE1A)
	sts	TIMSK,r24

; ----- clear key buffer

	ldi	r24,NOKEY
	std	Y+DATA_KEY,r24
	std	Y+DATA_KEYRAW,r24
	std	Y+DATA_KEYSAVE,r24
	ret

; ----------------------------------------------------------------------------
;               Terminate keyboard (before going to sleep)
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

#ifdef HW_ET58				// use hardware of ET-58

.global KEY_Term
KEY_Term:

; ----- Disable interrupt from Timer1 compare match

	sts	TIMSK,R_ZERO

; ----- stop Timer1

	sts	TCCR1A,R_ZERO
	sts	TCCR1B,R_ZERO
	ret

#endif

; ----------------------------------------------------------------------------
;             Remap 2nd key (change column 1..5 to 6..0 or A..E)
; ----------------------------------------------------------------------------
; INPUT/OUTPUT: R24 = key HEX code
; DESTROYS: R25
; ----------------------------------------------------------------------------

.global Remap2nd
Remap2nd:

; ----- check 2nd mode

	rcall	FlagTest2nd	; check flag 2nd
	breq	9f		; flag not set

; ----- switch 2nd flag off

	rcall	FlagClr2nd	; clear flag 2nd
	rcall	DispFlags	; display flags

; ----- prepare key

	push	r24		; push key code
	andi	r24,0x0f	; mask key column

; ----- remap 2nd key

	subi	r24,-5		; key column + 5, shift key column 1..5 to 6..10
	cpi	r24,10		; check key column	
	brne	6f
	clr	r24		; change column 10 to 0

; ----- add key row

6:	pop	r25		; pop key code
	andi	r25,0xf0	; mask key row
	or	r24,r25		; add key row to key code

9:	ret

; ----------------------------------------------------------------------------
;                     Read key from key buffer
; ----------------------------------------------------------------------------
; OUTPUT: R24 = key code 0..179 KEY_* (NZ brne) or 0xff no key (NOKEY, ZY breq)
;	  ZY = set if NOKEY
; DESTROYS: R1, R0
; NOTE: Enables interrupts
; ----------------------------------------------------------------------------

.global GetKey
GetKey:

; ----- push registers

	push	r25
	push	r30
	push	r31

; ----- get saved key

1:	ldi	r25,NOKEY
	ldd	r24,Y+DATA_KEYSAVE
	std	Y+DATA_KEYSAVE,r25
	cp	r24,r25
	brne	9f	; valid key

; ----- get key

	cli		; disable interrupts
	ldd	r24,Y+DATA_KEY
	std	Y+DATA_KEY,r25
	sei		; enable interrupts
	cp	r24,r25
	breq	9f	; no valid key

; ----- INV

	cpi	r24,0x12	; INV key
	brne	5f

	rcall	FlagTestInv	; check INV flag
	brne	4f		; flag is set
	rcall	FlagSetInv	; set flag
	rjmp	7f

4:	rcall	FlagClrInv	; clear flag
	rjmp	7f

; ----- 2nd

5:	cpi	r24,0x11 	; 2nd key
	brne	2f

	rcall	FlagTest2nd	; check 2nd flag
	brne	6f		; flag is set
	rcall	FlagSet2nd	; set flag
	rjmp	7f

6:	rcall	FlagClr2nd	; clear flag
7:	rcall	DispFlags	; display flags
	rjmp	1b		; get next key

; ----- remap 2nd (shift column 1..5 to 6..0 or A..E)
; INPUT/OUTPUT: R24 = key HEX code
; DESTROYS: R25
2:	rcall	Remap2nd	; remap key R24

; ----- remap numeric digits

3:	ldi	r30,lo8(RemapDig)
	ldi	r31,hi8(RemapDig)
4:	cpi	r30,lo8(RemapDigEnd)
	breq	5f		; end of table, key not found
	lpm	r25,Z+		; load key from the table
	cp	r24,r25		; is it this key?
	brne	4b		; next key

	mov	r24,r30		; key address + 1
	subi	r24,lo8(RemapDig+1) ; offset in table = key code

; ----- convert HEX code to binary number

5:	mov	r25,r24		; key code
	andi	r24,0x0f	; code LOW (column)
	swap	r25		; sawp nibbles
	andi	r25,0x0f	; code HIGH (row)
	ldi	r30,10
	mul	r25,r30		; row * 10
	add	r24,r0		; compose row and column

; ----- INV flag

	rcall	FlagTestInv	; check INV flag
	breq	9f		; flag is not set
	rcall	FlagClrInv	; clear flag
	rcall	DispFlags	; display flags
	subi	r24,-INV_SHIFT	; INV flag

; ----- pop registers

9: 	cpi	r24,NOKEY	; test NOKEY
	pop	r31
	pop	r30
	pop	r25
	ret

; ----------------------------------------------------------------------------
;                 Return unused key into keyboard buffer
; ----------------------------------------------------------------------------
; INPUT: R24 = key code 0..179
; DESTROYS: -
; ----------------------------------------------------------------------------

.global ReturnKey
ReturnKey:
	std	Y+DATA_KEYSAVE,r24
	ret

; ----------------------------------------------------------------------------
;                            Wait for a key
; ----------------------------------------------------------------------------
; OUTPUT: R24 = key code 0..179 KEY_*
; DESTROYS: R1, R0
; NOTE: Enables interrupts
; ----------------------------------------------------------------------------

.global WaitKey
WaitKey:
; OUTPUT: R24 = key code 0..179 KEY_* (NZ brne) or 0xff no key (NOKEY, ZY breq)
;	  ZY = set if NOKEY
; DESTROYS: R1, R0
; NOTE: Enables interrupts
	rcall	GetKey
	breq	WaitKey
	ret

; ----------------------------------------------------------------------------
;                         Load 1 digit parameter
; ----------------------------------------------------------------------------
; OUTPUT: R24 = parameter 0..9 (or another value if invalid)
;	  CY = paramerer is valid
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global Load1Dig
Load1Dig:

; ----- display prompt

	ldi	r24,ROW1+LCD_COLNUM-1
	rcall	DispSetPos	; set position on last character of 1st row
	ldi	r24,'?'
	rcall	DispChar	; display character '?'

; ----- wait for a key

; OUTPUT: R24 = key code 0..179 KEY_*
; DESTROYS: R1, R0
; NOTE: Enables interrupts
	rcall	WaitKey		; wait for a key

; ----- restore display
; DESTROYS: R1, R0
	rcall	Disp		; restore display flags

; ----- check 

	cpi	r24,10
	ret

; ----------------------------------------------------------------------------
;             Read key from key buffer and remap to program code
; ----------------------------------------------------------------------------
; OUTPUT: R24 = program code 0..255 CMD_* (if NC) or key code 0..179 KEY_* (if CY) or NOKEY (if CY)
;	  CY = set if program code is not valid (returns key code or NOKEY)
; DESTROYS: R1, R0, R30, R31, R25
; NOTE: Enables interrupts
; ----------------------------------------------------------------------------

.global GetKeyCmd
GetKeyCmd:

; ----- get key code
; OUTPUT: R24 = key code 0..179 KEY_* (NZ brne) or 0xff no key (NOKEY, ZY breq)
;	  ZY = set if NOKEY
; DESTROYS: R1, R0
; NOTE: Enables interrupts
	rcall	GetKey
	breq	9f		; no key

; ----- remap key code

	mov	r30,r24		; key code
	clr	r31
	subi	r30,lo8(-(RemapCmd))
	sbci	r31,hi8(-(RemapCmd))
	lpm	r25,Z		; load program code

; ----- invalid program code, returns key code

	cpi	r25,CMD_NONE	; invalid program code?
	breq	9f		; returns key code

; ----- check if parameter is required	

	cpi	r25,CMD_PARBEG
	brcs	7f		; no parameter
	cpi	r25,CMD_PAREND+1
	brcc	7f		; no parameter

; ----- get parameter
; OUTPUT: R24 = parameter 0..9 (or another value if invalid)
;	  CY = paramerer is valid
; DESTROYS: R1, R0
	rcall	Load1Dig	; load parameter
	brcc	GetKeyCmd	; invalid digit, input another key

; ----- add parameters

	add	r25,r24

; ----- program code is OK

7:	mov	r24,r25		; remapped program code
8:	clc			; clar carry flag
	ret

; ----- no program code or no key

9:	sec			; set carry flag
	ret

; ----------------------------------------------------------------------------
;                 Remap program code to key code
; ----------------------------------------------------------------------------
; INPUT: R24 = program code CMD_*
; OUTPUT: R24 = key code KEY_* (including INV flag) (or KEY_NOP if command not found)
;	  R25 = parameter 0..9, or NOKEY 255 = no parameter
; DESTROYS: R1, R0
; ----------------------------------------------------------------------------

.global CmdKey
CmdKey:

; ----- push registers

	push	r30
	push	r31

; ----- check parametric command

	ldi	r25,NOKEY	; no parameter
	cpi	r24,CMD_PARBEG	; minimal code
	brcs	3f		; no parametric command 
	cpi	r24,CMD_PAREND+1 ; maximal code
	brcc	3f		; no parametric command

; ----- split command to code and parameter
; INPUT: R24 = dividend (N0)
; OUTPUT: R24 = quotient (Q0), 0..25
;	  R25 = remainder, 0..9
; DESTROYS: R0, R1
	rcall	DivB10		; split
	ldi	r30,10
	mul	r30,r24		; get command base code
	mov	r24,r0

; ----- find command code

3:	ldi	r30,lo8(RemapCmd)
	ldi	r31,hi8(RemapCmd)
4:	lpm	r0,Z+		; load command code
	cp	r0,r24		; compare code
	breq	5f		; code found OK
	cpi	r30,lo8(RemapCmdEnd)
	brne	4b		; next code

; ----- not found

	ldi	r24,KEY_NOP
	rjmp	8f

; ----- get key code

5:	mov	r24,r30
	subi	r24,lo8(RemapCmd+1)

; ----- pop registers

8:	pop	r31
	pop	r30
	ret

; ----------------------------------------------------------------------------
;                      Check break program R/S
; ----------------------------------------------------------------------------

.global BreakKey
BreakKey:

	; check only if running
	IFN_RUNNING		; if not running
2:	ret			; not running

	; get key
	rcall	GetKey		; get key
	breq	2b		; no key

	; check key
	cpi	r24,KEY_RS	; stop program?
	breq	4f		; R/S, stop program
	mov	r25,r24		; save key
	rcall	GetKey		; get another key (not from buffer)
	breq	3f		; no key, return previous key
	cpi	r24,KEY_RS	; stop program?
	brne	5f		; return key	

	;stop program
4:	rjmp	StopProg	; stop program

	; return key
3:	mov	r24,r25		; previous key
5:	rjmp	ReturnKey	; return key
