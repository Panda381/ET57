
/*=============================================================================
                                 
                               Definitions

=============================================================================*/

/*-----------------------------------------------------------------------------
                                   bits
-----------------------------------------------------------------------------*/

#define	B0	0x1
#define	B1	0x2
#define	B2	0x4
#define	B3	0x8
#define	B4	0x10
#define	B5	0x20
#define	B6	0x40
#define	B7	0x80
#define	B8	0x100
#define	B9	0x200
#define	B10	0x400
#define	B11	0x800
#define	B12	0x1000
#define	B13	0x2000
#define	B14	0x4000
#define	B15	0x8000
#define B16	0x10000
#define B17	0x20000
#define B18	0x40000
#define	B19	0x80000
#define B20	0x100000
#define B21	0x200000
#define B22	0x400000
#define B23	0x800000
#define B24	0x1000000
#define B25	0x2000000
#define B26	0x4000000
#define B27	0x8000000
#define B28	0x10000000
#define B29	0x20000000
#define B30	0x40000000
#define B31	0x80000000

#define BIT(pos) ((u32)1 << (pos))

/*-----------------------------------------------------------------------------
                                 data types
-----------------------------------------------------------------------------*/

typedef signed char s8;

typedef unsigned char u8;
typedef unsigned char BYTE;
typedef unsigned char byte;
typedef unsigned char uchar;

typedef signed short s16;

typedef unsigned short u16;
typedef unsigned short WORD;
typedef unsigned short word;
typedef unsigned short ushort;

typedef unsigned int uint;

typedef signed long int s32;

typedef unsigned long int u32;
typedef unsigned long int DWORD;
typedef unsigned long int dword;
typedef unsigned long int ulong;

typedef signed long long int s64;

typedef unsigned long long int u64;
typedef unsigned long long int QWORD;
typedef unsigned long long int qword;

typedef char BOOL;
#define TRUE 1
#define FALSE 0
#define NULL (void*)0

#include <avr/io.h>
#include <avr/interrupt.h> // interrupts
#include <util/delay.h>

/*-----------------------------------------------------------------------------
                                SPI protocol
-----------------------------------------------------------------------------*/
// Data entry value: 0..255
// Number of data entries: 256 (address 0..255, ET-57 memory registers -1..-256)

// Communication protocol:
//  - Master always sends 1 or 3 bytes. 1st byte is command, 2nd byte is address, 3rd byte is data.
//    Speed SCK is set to f = fosc/32 = 250 kHz, 1 bit is 4 us, 1 byte is 32 us + delay 10 us = 42 us, 3 bytes are 126 us.
//
//  - Before transmission, master sends synchronization 0x53 (='S'). If slave is in synchronization,
//    it responses with 0x53, master continue with next commands. If master receives 0xff (pull-up resistor)
//    or 0x00 (short-cut to ground) slave is not connected, master abort. On other bytes master waits
//    until slave synchronizes, with little delay between bytes (100 us).
//
//  - To read from slave: Master sends '0x52 (='R') aa 0xff' to read byte from address aa.
//    Slave responses with data 'xx 0x52 dd'.
//
//  - To write to slave: Master sends '0x57 (='W') aa dd' to write byte dd to address aa.
//    Slave responses 'xx 0x57 aa'.

#define SPIDATA_MAX	256	// number of data entries of this slave
extern u8 SPIData[SPIDATA_MAX];

#define SPICMD_SYNC	0x53	// synchro command ('S')
#define SPICMD_READ	0x52	// read command ('R')
#define SPICMD_WRITE	0x57	// write command ('W')
#define SPICMD_ERR	0x55	// invalid synchronization ('U')
#define SPICMD_ERR2	0xAA	// alternate invalid synchronization
