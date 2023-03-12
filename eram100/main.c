
// =============================================================================
//                                 
//                           LED frame ERAM100
//
// =============================================================================

#include "include.h"

// SPI slave data
u8 SPIData[SPIDATA_MAX];

// index of SPI command
u8 SPIInx;

// SPI command
u8 SPICmd;	// 1st byte - SPI command
u8 SPIAddr;	// 2nd byte - SPI address

// ports to TPIC6B595:
//   PD5 (9) ... DDT ... SERIN (3)
//   PD6 (10) ... SCLK ... CLOCK (13)
//   PD7 (11) ... STB ... STB (12)
//   PB1 (13) ... /OE ... /OE (9)

// output all LEDs
void SetAll(u8 led)
{
	u8 i;

	// loop through 8 LEDs
	for (i = 8; i > 0; i--)
	{
		// output data bit SERIN
		if (led & BIT(7))
			PORTD |= B5;
		else
			PORTD &= ~B5;

		// shift LED register
		led <<= 1;

		// pulse clock SCLK
		PORTD |= B6;
		PORTD &= ~B6;
	}

	// strobe data to output register STB
	PORTD |= B7;
	PORTD &= ~B7;
}

// SPI init (Slave mode)
void SPI_SlaveInit()
{
	// reset SPI index
	SPIInx = 0;

	// enable SPI in slave mode (MSB first, sampled on leading edge, leading edge is rising)
	//  B0,B1 (SPR0, SPR1): SCK clock rate (Master mode) ... and SPI2X bit of SPSR too
	//  B2 (CPHA): clock phase, sampled 0=leading edge, 1=trailing edge
	//  B3 (CPOL): clock polarity, leading edge 0=rising, 1=falling
	//  B4 (MSTR): select mode 0=slave, 1=master
	//  B5 (DORD): data order 0=MSB first, 1=LSB first
	//  B6 (SPE): 1=SPI enabled
	//  B7 (SPIE): 1=SPI interrupt enable
	SPCR = BIT(SPE) | BIT(SPIE);
}

// SPI terminate
void SPI_Term()
{
	// SPI disable
	SPCR = 0;

	// flush flags
	volatile u8 k = SPSR;
	k = SPDR;
}

// SPI interrupt
ISR(SPI_STC_vect)
{
	// read data byte
	u8 d = SPDR;

	// receive command
	if (SPIInx == 0)
	{
		// check known commands
		if (	(d != SPICMD_SYNC) &&
			(d != SPICMD_READ) &&
			(d != SPICMD_WRITE))
		{
			// error, try to re-synchronize
			SPDR = SPICMD_ERR; // report error to master
			SPI_Term(); // terminate SPI
			_delay_us(50); // short delay 50 us (master delays 100 us after syncerror)
			SPI_SlaveInit(); // re-initialize SPI
			return;
		}

		// shift to next byte of the command
		if (d != SPICMD_SYNC)
		{
			SPICmd = d;
			SPIInx = 1; // next index = address
		}
	}

	// receive address
	else if (SPIInx == 1)
	{
		SPIAddr = d; // save address
		SPIInx = 2; // next index = data

		// read data
		if (SPICmd == SPICMD_READ) SPDR = SPIData[d];
	}

	// receive data
	else
	{
		// next index = command
		SPIInx = 0;

		// write data
		if (SPICmd == SPICMD_WRITE) SPIData[SPIAddr] = d;
	}
}

// main function
int main(void)
{
	// set port B
	//  PB5: SCK, input from SPI, pull-up
	//  PB4: MISO, output to SPI, LOW
	//  PB3: MOSI, input from SPI, pull-up
	//  PB2: SS, input connected to GND
	//  PB1: /OE, output LOW
	DDRB = B4 + B1; // set outputs
	PORTB = B5 + B3; // set pull-ups

	// set port D
	//  PD7: STB, output to TPIC6B595, LOW
	//  PD6: SCLK, output to TPIC6B595, LOW
	//  PD5: SERIN, output to TPIC6B595, LOW
	DDRD = B7 + B6 + B5; // set outpus
	PORTD = 0; // set LOWs

	// clear slave data
	u16 i;
	for (i = 0; i < SPIDATA_MAX; i++) SPIData[i] = 0;

	// interrupt enable
	sei();

	// SPI init (Slave mode)
	SPI_SlaveInit();

	while (1)
	{
		// set all LEDs
		SetAll(SPIData[0]);
//		_delay_ms(100);
	}
}
