; ****************************************************************************
;
;                                LCD display
;
; ****************************************************************************

#include "include.inc"

	.text

; LCD pins:
;   PD5: RS register select, 1=data, 0=command
;   PD6: E enable, 1=enable state
;   PD7: DB4
;   PB0: DB5
;   PB1: DB6
;   PB2: DB7

; LCD commands
#define LCD_CLEAR	B0	// 00000001 Clear Display and Home the Cursor
#define LCD_HOME	B1	// 0000001* Return Cursor and LCD to Home Position
#define LCD_MOVE	B2	// 000001IS Set Cursor Move Direction (I: increment/decrement; S: shift display)
#define LCD_DISPLAY	B3	// 00001DCB Enable Display/Cursor (D: display on, C: cursor on, B: blink on)
#define LCD_SHIFT	B4	// 0001SR** Move Cursor/Shift Display (S: diplay shift, R: direction right)
#define LCD_SETUP	B5	// 001DNF** Set Interface Length (D: 8 bit interface, N: 2 rows, F: big font 5x10)
#define LCD_CGRAM	B6	// 01AAAAAA Move Cursor into CGRAM (A: address)
#define LCD_DDRAM	B7	// 1AAAAAAA Move Cursor to Display (A: address)

#ifdef HW_ET57				// use hardware of ET-57

; Set data mode
#define DATA_MODE sbi _SFR_IO_ADDR(PORTD),5

; Set command mode
#define CMD_MODE cbi _SFR_IO_ADDR(PORTD),5

; Set enable state ON
#define EN_ON sbi _SFR_IO_ADDR(PORTD),6

; Set enable state OFF
#define EN_OFF cbi _SFR_IO_ADDR(PORTD),6

#else // HW_ET57

; Set data mode
#define DATA_MODE sbi _SFR_IO_ADDR(PORTB),6

; Set command mode
#define CMD_MODE cbi _SFR_IO_ADDR(PORTB),6

; Set enable state ON
#define EN_ON sbi _SFR_IO_ADDR(PORTD),4

; Set enable state OFF
#define EN_OFF cbi _SFR_IO_ADDR(PORTD),4

#endif // HW_ET57

; ----------------------------------------------------------------------------
;                       Output nibble (takes 20 us)
; ----------------------------------------------------------------------------
; INPUT: R24 = data (bit 0..3 = nibble)
; DESTROYS: -
; ----------------------------------------------------------------------------

LCD_OutNibble:

#ifdef HW_ET57				// use hardware of ET-57

; ----- clear output bits

	cbi _SFR_IO_ADDR(PORTD),7	; PD7: DB4
	cbi _SFR_IO_ADDR(PORTB),0	; PB0: DB5
	cbi _SFR_IO_ADDR(PORTB),1	; PB1: DB6
	cbi _SFR_IO_ADDR(PORTB),2	; PB2: DB7

; ----- set bits

	sbrc	r24,0
	sbi _SFR_IO_ADDR(PORTD),7	; PD7: DB4

	sbrc	r24,1
	sbi _SFR_IO_ADDR(PORTB),0	; PB0: DB5

	sbrc	r24,2
	sbi _SFR_IO_ADDR(PORTB),1	; PB1: DB6

	sbrc	r24,3
	sbi _SFR_IO_ADDR(PORTB),2	; PB2: DB7

#else // HW_ET57

; ----- clear output bits

	cbi _SFR_IO_ADDR(PORTD),3	; PD3: DB4
	cbi _SFR_IO_ADDR(PORTD),2	; PD2: DB5
	cbi _SFR_IO_ADDR(PORTD),1	; PD1: DB6
	cbi _SFR_IO_ADDR(PORTD),0	; PD0: DB7

; ----- set bits

	sbrc	r24,0
	sbi _SFR_IO_ADDR(PORTD),3	; PD3: DB4

	sbrc	r24,1
	sbi _SFR_IO_ADDR(PORTD),2	; PD2: DB5

	sbrc	r24,2
	sbi _SFR_IO_ADDR(PORTD),1	; PD1: DB6

	sbrc	r24,3
	sbi _SFR_IO_ADDR(PORTD),0	; PD0: DB7

#endif // HW_ET57

; ----- enable pulse

	EN_ON			; enable
; DESTROYS: -
	rcall	Wait10us	; delay 10 us
	EN_OFF			; disable
; DESTROYS: -
	rjmp	Wait10us	; delay 10 us

; ----------------------------------------------------------------------------
;                          Write command (takes 140 us)
; ----------------------------------------------------------------------------
; INPUT: R24 = data
; DESTROYS: -
; ----------------------------------------------------------------------------

LCD_WriteCmd:

	CMD_MODE		; switch to command mode

; LCD_OutByte must follow

; ----------------------------------------------------------------------------
;                          Output byte (takes 140 us)
; ----------------------------------------------------------------------------
; INPUT: R24 = data
; DESTROYS: -
; ----------------------------------------------------------------------------

LCD_OutByte:

	swap	r24		; swap nibbles
; INPUT: R24 = data (bit 0..3 = nibble)
; DESTROYS: -
	rcall	LCD_OutNibble	; output high nibble

	swap	r24		; swap nibbles back
; INPUT: R24 = data (bit 0..3 = nibble)
; DESTROYS: -
	rcall	LCD_OutNibble	; output low nibble

; DESTROYS: -
	rjmp	Wait100us	; delay 100 us

; ----------------------------------------------------------------------------
;                       Write data (takes 140 us)
; ----------------------------------------------------------------------------
; INPUT: R24 = data
; DESTROYS: -
; ----------------------------------------------------------------------------

LCD_WriteData:

	DATA_MODE		; switch to data mode
	rjmp	LCD_OutByte	; output data byte

; ----------------------------------------------------------------------------
;                      Display character (takes 140 us)
; ----------------------------------------------------------------------------
; INPUT: R24 = character
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispChar
DispChar:

	push	r24
; INPUT: R24 = data
; DESTROYS: -
	rcall	LCD_WriteData	; output data byte

	; increase display X position
	ldd	r24,Y+DATA_POSX
	inc	r24		; increase display X position
	std	Y+DATA_POSX,r24	

	pop	r24
	ret

; ----------------------------------------------------------------------------
;                   Set 8-bit interface (takes 10 ms)
; ----------------------------------------------------------------------------
; DESTROYS: R24
; ----------------------------------------------------------------------------

LCD_Set8bit:
	ldi	r24,B1+B0	; (LCD_SETUP command + 8-bit interface) >> 4
LCD_Setbit:
; INPUT: R24 = data (bit 0..3 = nibble)
; DESTROYS: -
	rcall	LCD_OutNibble	; switch to 8-bit interface
; INPUT: R24 = numer of [ms]
; DESTROYS: -
	ldi	r24,10
	rjmp	Waitms		; delay 10 ms

; ----------------------------------------------------------------------------
;                   Initialize LCD display
; ----------------------------------------------------------------------------
; DESTROYS: R31, R30, R25, R24
; ----------------------------------------------------------------------------

.global LCD_Init
LCD_Init:

; ----- initialize LCD contrast generator

#ifdef HW_ET58				// use hardware of ET-58

	; start generator of LCD contrast control
	ldi	r25,B6+2	; toggle OC0A on compare match, mode CRC (top on OCRA)
	out	_SFR_IO_ADDR(TCCR0A),r25

	; set prescaler
	ldi	r25,2		; prescaler 8, output sample frequency 8000000/8/(OCR0A+1)/2 = 2 kHz .. 500 kHz
	out	_SFR_IO_ADDR(TCCR0B),r25

	; OCR0A divider
	ldi	r26,lo8(CFG_LCD)
	ldi	r27,hi8(CFG_LCD)
; INPUT: R27:R26 = source address
; OUTPUT: R24 = data
; DESTROYS: -
	call	EERead		; read LCD contrast
	cpi	r24,0xff	; check valid value
	brne	2f
	ldi	r24,35		; default value
2:	out	_SFR_IO_ADDR(OCR0A),r24

#endif // HW_ET58

; ----- disable ouput

	EN_OFF

; ----- wait for some time to LCD power up
; DESTROYS: R24
	rcall	Wait250ms	; wait 250 ms

; ----- set command mode

	CMD_MODE

; ----- byte synchronisation using 8-bit interface - switch to 8-bit interface
; DESTROYS: R24
	rcall	LCD_Set8bit
	rcall	LCD_Set8bit
	rcall	LCD_Set8bit

; ----- switch to 4-bit interface
; DESTROYS: R24
	ldi	r24,B1		; LCD_SETUP command >> 4
	rcall	LCD_Setbit

; ----- setup 4-bit interface, 2 rows, font 5x7
; INPUT: R24 = data
; DESTROYS: -
	ldi	r24,LCD_SETUP+B3
	rcall	LCD_WriteCmd

; ----- display off, cursor off, blinking off
; INPUT: R24 = data
; DESTROYS: -
	ldi	r24,LCD_DISPLAY
	rcall	LCD_WriteCmd

; ----- clear display
; DESTROYS: R24
	ldi	r24,LCD_CLEAR
	rcall	LCD_Home2

; ----- auto move cursor right
; INPUT: R24 = data
; DESTROYS: -
	ldi	r24,LCD_MOVE+B1
	rcall	LCD_WriteCmd

; ----- display on, cursor off, blinking off
; INPUT: R24 = data
; DESTROYS: -
	ldi	r24,LCD_DISPLAY+B2
	rcall	LCD_WriteCmd

; ----- set cursor home position

	std	Y+DATA_POSX,R_ZERO ; clear display X position
	ldi	r24,LCD_HOME
LCD_Home2:
; INPUT: R24 = data
; DESTROYS: -
	rcall	LCD_WriteCmd	; write command
; INPUT: R24 = numer of [ms]
; DESTROYS: -
	ldi	r24,5
	rjmp	Waitms		; wait 5 ms

; ----------------------------------------------------------------------------
;                         Set display position
; ----------------------------------------------------------------------------
; INPUT: R24 = position 0..15, add ROW1 or ROW2
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispSetPos
DispSetPos:
	push	r24
	push	r25

	mov	r25,r24
	andi	r25,0x3f	; mask position X
	std	Y+DATA_POSX,r25	; set new position X
	ori	r24,LCD_DDRAM
; INPUT: R24 = data
; DESTROYS: -
	rcall	LCD_WriteCmd

	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                      Set cursor to start or ROW2
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispSetRow2
DispSetRow2:
	push	r24
	ldi	r24,LCD_DDRAM+ROW2
	rjmp	DispSetRow1B

; ----------------------------------------------------------------------------
;                      Set cursor to start or ROW1
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispSetRow1
DispSetRow1:
	push	r24
	ldi	r24,LCD_DDRAM+ROW1
DispSetRow1B:
	std	Y+DATA_POSX,R_ZERO ; clear X position
; INPUT: R24 = data
; DESTROYS: -
	rcall	LCD_WriteCmd
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                         Display ASCIIZ text from ROM
; ----------------------------------------------------------------------------
; INPUT: R31:R30 = text in ROM (terminated with 0)
; DESTROYS: R31, R30, R24
; ----------------------------------------------------------------------------

DispTextRom2:
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar

.global DispTextRom
DispTextRom:
	lpm	r24,Z+
	tst	r24
	brne	DispTextRom2
	ret

; ----------------------------------------------------------------------------
;                         Display ASCIIZ text from RAM
; ----------------------------------------------------------------------------
; INPUT: R31:R30 = text in RAM (terminated with 0)
; DESTROYS: R31, R30, R24
; ----------------------------------------------------------------------------

DispTextRam2:
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar

.global DispTextRam
DispTextRam:
	ld	r24,Z+
	tst	r24
	brne	DispTextRam2
	ret

; ----------------------------------------------------------------------------
;                        Display space character
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispSpc
DispSpc:
	push	r24
	ldi	r24,' '
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; output byte
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                    Display spaces until X position
; ----------------------------------------------------------------------------
; INPUT: R24 = position X
; DESTROYS: R25
; ----------------------------------------------------------------------------

DispSpcPos2:
	rcall	DispSpc

.global DispSpcPos
DispSpcPos:
	ldd	r25,Y+DATA_POSX
	cp	r25,r24
	brcs	DispSpcPos2
	ret

; ----------------------------------------------------------------------------
;                          Clear rest of line
; ----------------------------------------------------------------------------
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispSpcClr
DispSpcClr:
	push	r24
	push	r25

	ldi	r24,LCD_COLNUM
	rcall	DispSpcPos

	pop	r25
	pop	r24
	ret

; ----------------------------------------------------------------------------
;                         Display HEX word
; ----------------------------------------------------------------------------
; INPUT: R25:R24 = byte
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispHexW
DispHexW:
	push	r24
	mov	r24,r25
; INPUT: R24 = byte
; DESTROYS: -
	rcall	DispHexB
	pop	r24

; DispHexB must follow

; ----------------------------------------------------------------------------
;                         Display HEX byte
; ----------------------------------------------------------------------------
; INPUT: R24 = byte
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispHexB
DispHexB:
	swap	r24
; INPUT: R24 = nibble
; DESTROYS: -
	rcall	DispHexDig
	swap	r24

; DispHexDig must follow

; ----------------------------------------------------------------------------
;                         Display HEX digit
; ----------------------------------------------------------------------------
; INPUT: R24 = nibble
; DESTROYS: -
; ----------------------------------------------------------------------------

.global DispHexDig
DispHexDig:
	push	r24

	andi	r24,0x0f	; mask low nibble
	cpi	r24,10		; digit?
	brcs	2f		; digit 0..9
	subi	r24,-7		; correction for digits A..F
2:	subi	r24,-0x30	; conversion to ASCII character
; INPUT: R24 = character or data
; DESTROYS: -
	rcall	DispChar	; display character

	pop	r24
	ret
