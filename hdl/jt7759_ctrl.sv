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

module jt7759_ctrl(
    input             rst,
    input             clk,
    input             cen,  // 640kHz
    output reg [ 4:0] divby,
    input             cendec
    input             stn,  // STart (active low)
    input             cs,
    input             mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
    output            busyn,
    // CPU interface
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    // ADPCM engine
    output reg        dec_rst,
    output reg [ 3:0] dec_din,
    // ROM interface
    output            rom_cs,      // equivalent to DRQn in original chip
    output reg [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok
);

localparam STW = 5;
localparam [STW-1:0] RST    =1<<0;
localparam [STW-1:0] IDLE   =1<<1;
localparam [STW-1:0] SND_CNT=1<<2;
localparam [STW-1:0] READIN =1<<3;
localparam [STW-1:0] WAIT   =1<<4;

localparam MTW = 13; // Mute counter 7+6 bits

reg  [    7:0] snd_cnt; // sound count: total number of sound samples
reg  [STW-1:0] st;
reg  [    3:0] next;
reg  [MTW-1:0] mute_cnt;
wire           write, wr_posedge;

assign      write      = cs && !stn;
assign      wr_posedge = !last_wr && write;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        snd_cnt   <= 8'd0;
        st        <= RST;
        rom_cs    <= 0;
        rom_addr  <= 'd0;
        busyn     <= 0;
        divby     <= 5'd1;
        last_wr   <= 0;
        dec_rst   <= 1;
        mute_cnt  <= 0;
    end else begin
        last_wr <= write;
        if( ~|mute_cnt ) mute_cnt <= mute_cnt-1'd1;
        case( st )
            RST: begin
                if( mdn ) begin
                    rom_addr <= 17'd0;
                    rom_cs   <= 1;
                    st       <= SND_CNT;
                end
                else st <= IDLE;
            IDLE: begin
                if( wr_posedge ) begin
                    if( din <= snd_cnt && mdn ) begin
                        rom_cs   <= 1;
                        rom_addr <= { 8'd0, din, 1'b0 };
                        st       <= READIN;
                    end
                end
            end
            SND_CNT: begin
                if( rom_ok ) begin
                    snd_cnt <= rom_data;
                    rom_cs  <= 0;
                    st      <= IDLE;
                end
            end
            READIN: begin
                if( rom_ok ) begin
                    if( rom_data==8'd0 ) begin
                        dec_end <= 1;
                        st      <= IDLE;
                    end else if(cendec) begin
                        { dec_din, next } <= rom_data;
                        dec_rst           <= 0;
                        st                <= WAIT;
                        rom_cs            <= 0;
                    end
                end
            end
            WAIT: if(cendec) begin
                if( half ) begin
                    dec_din  <= next;
                    st       <= READIN;
                    rom_addr <= rom_addr+18'd1;
                    rom_cs   <= 1;
                end
            end
        endcase
    end
end


endmodule