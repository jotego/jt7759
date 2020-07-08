/*  This file is part of JT7759.
    JT7759 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT7759 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT7759.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2020 */

module jt7759(
    input                  rst,
    input                  clk,
    input                  cen,  // 640kHz
    input                  stn,  // STart (active low)
    input                  cs,
    input                  mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
    output                 busyn,
    // CPU interface
    input                  wrn,  // for slave mode only
    input         [ 7:0]   din,
    // ROM interface
    output                 rom_cs,      // equivalent to DRQn in original chip
    output        [16:0]   rom_addr,
    input         [ 7:0]   rom_data,
    input                  rom_ok,
    // Sound output
    output signed [ 8:0]   sound
);

wire   [ 5:0] divby;
wire          cendec;    // internal clock enable for sound
wire          cen4;      // cen divided by 4

wire          dec_rst;
wire   [ 3:0] encoded;

jt7759_div u_div(
    .clk        ( clk       ),
    .cen        ( cen       ),
    .cen4       ( cen4      ),
    .divby      ( divby     ),
    .cendec     ( cendec    )
);

jt7759_ctrl u_ctrl(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen4       ( cen4      ),
    .cendec     ( cendec    ),
    .divby      ( divby     ),
    // chip interface
    .stn        ( stn       ),
    .cs         ( cs        ),
    .mdn        ( mdn       ),
    .busyn      ( busyn     ),
    .wrn        ( wrn       ),
    .din        ( din       ),
    // ADPCM engine
    .dec_rst    ( dec_rst   ),
    .dec_din    ( encoded   ),
    // ROM interface
    .rom_cs     ( rom_cs    ),
    .rom_addr   ( rom_addr  ),
    .rom_data   ( rom_data  ),
    .rom_ok     ( rom_ok    )
);


jt7759_adpcm u_adpcm(
    .rst        ( dec_rst   ),
    .clk        ( clk       ),
    .cendec     ( cendec    ),
    .encoded    ( encoded   ),
    .sound      ( sound     )
);


`ifdef SIMULATION
integer fsnd;
initial begin
    fsnd=$fopen("jt7759.raw","wb");
end
wire signed [15:0] snd_log = { sound, 2'b0 };
always @(posedge cendec) begin
    $fwrite(fsnd,"%u", {snd_log, snd_log});
end
`endif
endmodule