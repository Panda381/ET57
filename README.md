# ET57
Clone of TI-57 calculator with ATmega8 processor.
(c) 2020 Miroslav Nemecek, Panda38@seznam.cz
open source

Translation of manuals into English and French: Pierre Houbert http://pierre.phweb.me

Last update: 1.11.2020, build 201101

project home web page: https://www.breatharian.eu/hw/et57/index_en.html
ET-57 on GitHub: https://github.com/Panda381/ET57


Description
-----------
The ET-57 calculator was created as an effort to fit a fully functional programmable calculator into the 8 KB memory of the ATmega8 processor. The popular TI-57 calculator from Texas Instruments from 1977 was chosen as a model. This is not a replica with processor emulation, but an independent new firmware based on the functionality of the original calculator. The calculator could be expanded with more memory and more functions without compromising compatibility with the original. Programs for the TI-57 can usually be run in the ET-57 calculator without the need for modifications.

The ET-57 calculator is intended for those interested in retro technology and also as a teaching aid for school clubs, thanks to its ease of use, economical coding of programs, low price, support for external peripherals and fully open code.

The ET-57 calculator software is also available for the ET-58 calculator hardware, as an ET-57B variant. https://www.breatharian.eu/hw/et58/index_en.html


Properties
----------
- ATmega8 processor (8MHz, 8KB ROM, 1KB RAM, 512B EEPROM)
- 5 V supply voltage (from USB charger or from USB port)
- Calculations in BCD code
- Accuracy of calculations 17 digits
- Accuracy of basic registers 15 digits
- Accuracy of extended registers 13 digits
- Display data at 11 significant digits
- Exponent 2 digits, range + - 99
- 10 program spaces
- Each space 50 program steps (total 500 steps)
- User program stored in EEPROM (without battery)
- 10 basic registers (accessible by direct addressing)
- 70 extended registers (accessible by index addressing)
- Two-line LCD display (2 x 16 alphanumeric characters)
- 40 buttons
- Control of external devices via ISP connector
- Calculator code completely written in AVR assembler
- Exponential and logarithmic functions
- Trigonometric functions
- Factorial
- Random number generator
- Index access to variables
- Scientific display mode with exponent
- Statistical function
- 10 labels in each program space
- Function calls and jumps between program spaces
- Fully open source hardware and software


Diagram
-------
The USB connector is only used to power +5V the calculator from an external charger or USB port. The processor uses an internal 8 MHz RC oscillator. Resistor R2 is used to limit the LED current for the display backlight. With this variant of the display, it is probably possible to omit and connect directly to GND (not verified). Resistor R3 regulates the bias voltage for the display contrast. It may be necessary to change to a different value for another display.


Construction
------------
For maximum simplification of the construction, microswitches without a fingerboard were used as buttons, only protruding above the surface of the calculator. The display is soldered via a pin strip. The printed circuit board was chosen to be 10x7.5 cm because it is both available from GM and meets the board size limit for the free Eagle version. The printed circuit board is sufficient on one side, supplemented by 5 wire jumpers. The construction was chosen "sandwich" for simplicity - from above and below the printed circuit board is screwed to the plexiglass boards. But they are not necessary and the calculator can be easily operated even without a cover - it is enough to place a paper template with button labels over the buttons.

The display was chosen with pins on the bottom to make do with a smaller printed circuit board (and also because I had a supply of these displays). I list a similar display in the parts list (I did not find the original one), but its suitability for replacement has not been verified, it must be verified. E.g. there may be a different order of pins for LED illumination - my display has the opposite numbering 15 and 16, but as a result the pins appear to be the same on the printed circuit board.

Be careful when attaching wire to pin 8 of the ISP connector, it could touch the display cover plate. It is therefore guided by an arc. The display is soldered via a pin strip. Before soldering the pin on the display, press it from top to bottom (as far as it will go) so that it does not obstruct the cover. Although I soldered the ISP programming connector from the display side, it may be more practical to solder from the PCB side, because the display of the connector interferes a bit.

The label of the buttons can be glued to the cover or just placed over the buttons. The holes for the buttons are punched through the intersection of 4 mm on the skin. Printed paper can be coated with laminating foil or transparent double-sided insulating tape.

A hole for the USB power connector needs to be cut in the bottom cover. It might also be useful to cut a hole for the ISP programming connector (it is also used to connect peripherals).


Firmware programming
--------------------
The firmware includes source code in the AVR assembler (compiled with WinAVR) and compiled HEX files for the ET-57 variant with ATmega8 processor, and files for the ET-57B variant (ET-58 hardware) with ATmega88, ATmega168 or ATmega328 processor.

ATmega8 processor fuse settings (for ET-57 hardware): low E4, high D1.

For hardware ET-58, ATmega88: low 42, high D6, ext F9, ATmega168: low 42, high D6, ext F9, ATmega328: low 42, high D1, ext FE.

An 8-pin KONPC-SPK-8 busbar with the following pin assignment is used as the ISP connector:

1 SCK
2 MISO
3 MOSI
4 orientation key (pin missing, blinded in the connector so that it cannot be inserted)
5 /RESET
6 GND (ground, 0V)
7 VCC (power,+5V)
8 not used


External device and ports
-------------------------
The calculator allows the connection of external peripherals via the ISP connector, with the SPI protocol. As an example, the LED control on the ERAM100 effects frame (ATmega8 processor) is shown here.


Used components
---------------
Note: The LCD display shown here is not verified if it works with the specified connection and was selected only by similarity.

958-174, 1 piece, ATMEGA8A-AU TQFP32 ATMEL, 66 Kc https://www.gme.cz/atmega8a-au-tqfp32-atmel
513-219, 1 piece, LCD alfanumeric display 2x16 haracters, green WH1602A-YGH-CT, 139 Kc https://www.gme.cz/lcd-alfanumericky-displej-winstar-wh1602a-ygh-ct
832-177, 1 piece, Connector USB-MINI B F SMD, 17 Kc https://www.gme.cz/usb-konektor-usb-mini-b-f-smd
630-158, 40 pieces, Microswitch TC-0108-T, 2.80 Kc (10 ks 2.11) ... 84.40 Kc https://www.gme.cz/tc-0108-t
832-017, 1 piece, Pin rail S1G20 2,54mm, 3.60 Kc https://www.gme.cz/oboustranny-kolik-s1g20-2-54mm
832-470, 1 piece, Pin rail S1G08W 2,54mm, 2.30 Kc https://www.gme.cz/oboustranny-kolik-s1g08w-2-54mm
906-096, 1 piece, Ceramic capacitor CKS0805 100n/50V X7R 10%, 5.50 Kc https://www.gme.cz/cks0805-100n-50v-x7r-10-yageo
906-089, 1 piece, Ceramic capacitor CKS0805 10n/50V X7R 10% YAGEO, 2.20 Kc https://www.gme.cz/cks0805-10n-50v-x7r-10-yageo
901-029, 2 pieces, SMD Resistor R0805 1k0 5%, 0.68 Kc ... 1.36 Kc https://www.gme.cz/r0805-1k0-5-yageo
901-573, 1 piece, SMD Resistor R0805 15R 1%, 2.50 Kc https://www.gme.cz/r0805-15r-1-yageo
661-073, 1 piece, Fotocuprextit 75x100x1,5 one-sided, 39 Kc https://www.gme.cz/fotocuprextit-75x100x1-5-jednovrstvy
Sum of the price for all 324 CZK (without photocuprextite and without cover).
