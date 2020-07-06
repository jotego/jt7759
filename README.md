# jt7759
Verilog module compatible with NEC ADPCM decoder uPD7759

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

JT775x is an ADPCM sound source written in Verilog, fully compatible with NEC uPD7759.

## Architecture

NEC family of fixed phase playback devices. All use the ADPCM and PCM+waveform element method for synthesis at 5,6 or 8kHz of sampling frequency. The only one using an external memory was uPD7759. Although they all share the same architecture, only uPD7759 seems to be of interest to the classic computing community.

Device | ROM type | ROM size
-------|----------|-----------
 7755  |   mask   |   96 kbit
 7756A |   mask   |  256 kbit
 7757  |   mask   |  516 kbit
 7758  |   mask   | 1024 kbit
 7756  |   PROM   |  256 kbit
 7759  | external | 1024 kbit

## Port Description

Name     | Direction | Width | Purpose
---------|-----------|-------|--------------------------------------
rst      | input     |       | active-high asynchronous reset signal
clk      | input     |       | clock
cen      | input     |       | clock enable (positive edge).
din      | input     | 8     | input data from CPU
dout     | output    | 8     | output data to CPU
rom_addr | output    | 18    | Memory address to be read
rom_data | input     | 8     | Data read
rom_ok   | input     | 1     | high when rom_data is valid and matches rom_addr
sound    | output    | 14    | signed sound output

## Usage

### ROM interface

Port     | Direction | Meaning
---------|-----------|----------------------------
rom_cs   | output    | high when address is valid
rom_addr | output    | Addres to be read
rom_data | input     | Data read from address
rom_ok   | input     | Data read is valid

Note that rom_ok is not valid for the clock cycle immediately after rising rom_cs. Or if rom_addr is changed while rom_cs is high. rom_addr must be stable once rom_cs goes high until rom_ok is asserted.

## FPGA arcade cores using this module:

* [Combat School](https://github.com/jotego/jtcontra), by the same author

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)