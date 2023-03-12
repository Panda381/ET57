; ****************************************************************************
;
;                                SPI interface
;
; ****************************************************************************
; Data entry value: 0..255
; Number of data entries: 256 (address 0..255, ET-57 memory registers -1..-256)

; Communication protocol:
;  - Master always sends 1 or 3 bytes. 1st byte is command, 2nd byte is address, 3rd byte is data.
;    Speed SCK is set to f = fosc/32 = 250 kHz, 1 bit is 4 us, 1 byte is 32 us + delay 10 us = 42 us, 3 bytes are 126 us.
;
;  - Before transmission, master sends synchronization 0x53 (='S'). If slave is in synchronization,
;    it responses with 0x53, master continue with next commands. If master receives 0xff (pull-up resistor)
;    or 0x00 (short-cut to ground) slave is not connected, master abort. On other bytes master waits
;    until slave synchronizes, with little delay between bytes (100 us).
;
;  - To read from slave: Master sends '0x52 (='R') aa 0xff' to read byte from address aa.
;    Slave responses with data 'xx 0x52 dd'.
;
;  - To write to slave: Master sends '0x57 (='W') aa dd' to write byte dd to address aa.
;    Slave responses 'xx 0x57 aa'.

#include "include.inc"

	.text

#ifdef HW_ET57				// use hardware of ET-57

; ----------------------------------------------------------------------------
;                        Initialize SPI interface
; ----------------------------------------------------------------------------

.global SPI_Init
SPI_Init:
; enable SPI in master mode (MSB first, sampled on leading edge, leading edge is rising), SCK=fosc/32
;  B0,B1 (SPR0, SPR1): SCK clock rate (Master mode) ... and SPI2X bit of SPSR too
;  B2 (CPHA): clock phase, sampled 0=leading edge (default ISP), 1=trailing edge
;  B3 (CPOL): clock polarity, leading edge 0=rising (default ISP), 1=falling
;  B4 (MSTR): select mode 0=slave, 1=master
;  B5 (DORD): data order 0=MSB first (default ISP), 1=LSB first
;  B6 (SPE): 1=SPI enabled
;  B7 (SPIE): 1=SPI interrupt enable
	ldi	r24,BIT(SPE)|BIT(MSTR)|BIT(SPR1)
	out	_SFR_IO_ADDR(SPCR),r24
	ldi	r24,BIT(SPI2X)
	out	_SFR_IO_ADDR(SPSR),r24
	ret

; ----------------------------------------------------------------------------
;                              Send SPI byte
; ----------------------------------------------------------------------------
; INPUT: R24 = byte to send
; OUTPUT: R24 = byte received
; DESTROYS: R0
; ----------------------------------------------------------------------------

;.global SPI_SendByte
SPI_SendByte:

	; send data register
	out	_SFR_IO_ADDR(SPDR),r24

	; wait for transmission complete
#ifdef MCU88
2:	lds	r0,SPSR
	lsl	r0
	brcc	2b
#else
2:	sbis	_SFR_IO_ADDR(SPSR),SPIF
	rjmp	2b
#endif
	; short delay (wait for slave ready)
	rcall	Wait10us

	; receive data
	in	r24,_SFR_IO_ADDR(SPDR)
	ret

; ----------------------------------------------------------------------------
;                              SPI synchronization
; ----------------------------------------------------------------------------
; OUTPUT: CY = error (break on 0xff or 0x00 - no device connected)
; DESTROYS: -
; ----------------------------------------------------------------------------

3:	rcall	Wait100us	; delay 100 us
	pop	r24

;.global SPI_Sync
SPI_Sync:

	push	r24

	; send SYNC command
	ldi	r24,SPICMD_SYNC
	rcall	SPI_SendByte

	; send SYNC command
	ldi	r24,SPICMD_SYNC
	rcall	SPI_SendByte

	; send SYNC command
	ldi	r24,SPICMD_SYNC
	rcall	SPI_SendByte

	; send SYNC command
	ldi	r24,SPICMD_SYNC
	rcall	SPI_SendByte

	; OK
	cpi	r24,SPICMD_SYNC
	breq	9f

	; repeat on error
	cpi	r24,0xff
	breq	8f
	cpi	r24,0
	brne	3b

8:	sec			; set carry flag
9:	pop	r24
	ret

; ----------------------------------------------------------------------------
;                              SPI receive data
; ----------------------------------------------------------------------------
; INPUT: R25 = address 0..255
; OUTPUT: CY = error (break on 0xff or 0x00 - no device connected)
;	 R24 = received data
; DESTROYS: R23
; ----------------------------------------------------------------------------

.global SPI_Recv
SPI_Recv:
	ldi	r24,SPICMD_READ
	ldi	r23,0xff
	rjmp	SPI_RecvSend

; ----------------------------------------------------------------------------
;                              SPI send data
; ----------------------------------------------------------------------------
; INPUT: R25 = address 0..255
;	 R23 = data 0..255
; OUTPUT: CY = error (break on 0xff or 0x00 - no device connected)
; DESTROYS: R24
; ----------------------------------------------------------------------------

.global SPI_Send
SPI_Send:
	ldi	r24,SPICMD_WRITE ; write command

; ----------------------------------------------------------------------------
;                              SPI send/receive data
; ----------------------------------------------------------------------------
; INPUT: R24 = command
;	 R25 = address 0..255
;	 R23 = data 0..255
; OUTPUT: CY = error (break on 0xff or 0x00 - no device connected)
;	 R24 = received data
; DESTROYS: -
; ----------------------------------------------------------------------------

;.global SPI_RecvSend
SPI_RecvSend:

	; synchronization
	rcall	SPI_Sync
	brcs	9f		; break on error

	; send command
	rcall	SPI_SendByte	; send byte
	mov	r24,r25		; address
	rcall	SPI_SendByte	; send address
	mov	r24,r23		; data
	rcall	SPI_SendByte	; send data
	clc			; clear error flag
8:	ret

	; error
9:	rcall	FlagTestSpiErr	; stop on SPI error?
	clr	r24
	sec			; set error flag
	breq	8b		; do not stop on SPI error
	jmp	CalcError	; set error

#endif // HW_ET57
