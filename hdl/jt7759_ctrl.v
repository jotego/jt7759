/*  This file is part of JT7759.
    JT7759 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public Licen4se as published by
    the Free Software Foundation, either version 3 of the Licen4se, or
    (at your option) any later version.

    JT7759 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public Licen4se for more details.

    You should have received a copy of the GNU General Public Licen4se
    along with JT7759.  If not, see <http://www.gnu.org/licen4ses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2020 */

module jt7759_ctrl(
    input             rst,
    input             clk,
    input             cen4,  // 640kHz
    input             cendec,
    output reg [ 5:0] divby,
    input             stn,  // STart (active low)
    input             cs,
    input             mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
    output            busyn,
    // CPU interface
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    // Slave mode
    output reg        drqn,
    // ADPCM engine
    output reg        dec_rst,
    output reg [ 3:0] dec_din,
    // ROM interface
    output reg        rom_cs,      // equivalent to DRQn in original chip
    output reg [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok
);

localparam STW = 12;
localparam [STW-1:0] RST    =1<<0,
                     IDLE   =1<<1,
                     SND_CNT=1<<2,
                     PLAY   =1<<3,
                     WAIT   =1<<4,
                     GETN   =1<<5,
                     MUTED  =1<<6,
                     LOAD   =1<<7,
                     READCMD=1<<8,
                     READADR=1<<9,
                     SIGN   =1<<10,
                     DREQ   =1<<11; // passive mode

localparam MTW = 13; // Mute counter 7+6 bits

reg  [    7:0] max_snd; // sound count: total number of sound samples
reg  [STW-1:0] st;
reg  [    3:0] next, next2;
reg  [MTW-1:0] mute_cnt;
reg  [    8:0] data_cnt;
reg  [    3:0] rep_cnt;
reg  [   15:0] addr_latch;
reg  [   16:0] rep_latch;
reg  [    7:0] sign[0:3];
reg            last_wr, waitc, getdiv, headerok;
reg            last_mdn;
reg            signok; // ROM signature ok
wire           write, wr_posedge;
wire [   16:0] next_rom;
wire [    1:0] sign_addr = rom_addr[1:0]-2'd1;

// Passive mode
wire           mdn_negedge, mdn_posedge;
reg      [1:0] drq_ibf;
reg      [3:0] drq_cnt;

assign write       = cs && !stn;
assign wr_posedge  = !last_wr && write;
assign mdn_negedge =  last_mdn && !mdn;
assign mdn_posedge = !last_mdn &&  mdn;
assign busyn       = st == IDLE && st != DREQ;
assign next_rom    = rom_addr+1'b1;

initial begin
    sign[0] = 8'h5a;
    sign[1] = 8'ha5;
    sign[2] = 8'h69;
    sign[3] = 8'h55;
end

// Simulation log
`ifdef SIMULATION
`define JT7759_SILENCE $display("jt7759: read silence");
`define JT7759_PLAY $display("jt7759: read play");
`define JT7759_PLAY_LONG $display("jt7759: read play long");
`define JT7759_REPEAT $display("jt7759: read repeat");
`else
`define JT7759_SILENCE
`define JT7759_PLAY
`define JT7759_PLAY_LONG
`define JT7759_REPEAT
`endif

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        max_snd   <= 8'd0;
        st        <= RST;
        rom_cs    <= 0;
        rom_addr  <= 17'd0;
        divby     <= 6'd1;
        last_wr   <= 0;
        last_mdn  <= 1;
        dec_rst   <= 1;
        dec_din   <= 4'd0;
        mute_cnt  <= 0;
        data_cnt  <= 0;
        waitc     <= 1;
        signok    <= 0;
        rep_cnt   <= ~4'd0;
        rep_latch <= 17'd0;
        drqn      <= 1;
    end else begin
        last_wr  <= write;
        last_mdn <= mdn;

        if( mdn_posedge ) begin
            st   <= IDLE;
            drqn <= 1;
        end

        if( mdn_negedge ) begin
            st       <= DREQ;
            drqn     <= 1;
            drq_ibf  <= 0;
            drq_cnt  <= 11;  // wait for ~62.5us
            divby    <= 19; // /20 = 8kHz, this is a guess. The manual doesn't tell
            dec_rst  <= 1;
        end else case( st )
            // Passive mode
            DREQ: begin
                if(cen4) begin
                    if( drq_cnt!=0 ) begin
                        drq_cnt <= drq_cnt-1;
                    end else if( drq_ibf==0 ) begin
                        drqn <= 0;
                    end
                end
                if( cendec ) begin
                    dec_din <= next;
                    next    <= next2;
                    drq_ibf <= drq_ibf >> 1;
                end
                if( wr_posedge && !drqn ) begin
                    { next, next2 } <= din;
                    drqn    <= 1;
                    dec_rst <= 0;
                    drq_ibf <= 3;
                end
            end

            // Active Mode
            default: if(cen4) begin // start up process
                rom_addr <= 17'd0;
                rom_cs   <= 1;
                waitc    <= 1;
                dec_rst  <= 1;
                st       <= SND_CNT;
            end
            // Check the chip signature
            SIGN: if (cen4) begin
                waitc <= 0;
                if( rom_ok ) begin
                    if( rom_data != sign[sign_addr] ) begin
                        signok <= 0;
                        st <= IDLE;
                        `ifdef SIMULATION
                        $display("Wrong ROM assigned to jt7759");
                        $finish;
                        `endif
                    end
                    else begin
                        if( &sign_addr ) begin
                            signok <= 1;
                            st<=IDLE;
                        end
                        rom_addr<= next_rom;
                        waitc   <= 1;
                    end
                end
            end
            IDLE: begin // Active mode
                if( wr_posedge ) begin
                    if( din <= max_snd ) begin
                        rom_cs   <= 1;
                        waitc    <= 1;
                        rom_addr <= { 7'd0, {1'd0, din} + 9'd2, 1'b1 };
                        st       <= READADR;
                    end
                end else begin
                    rom_cs  <= 0;
                    dec_rst <= 1;
                end
            end
            SND_CNT: begin
                waitc <= 0;
                if( rom_ok && !waitc ) begin
                    max_snd <= rom_data;
                    rom_addr<= next_rom;
                    waitc   <= 1;
                    st      <= SIGN;
                end
            end
            READADR: if(cen4) begin
                waitc <= 0;
                if( rom_ok && !waitc ) begin
                    if( rom_addr[0] ) begin
                        rom_addr <= next_rom;
                        waitc    <= 1;
                        addr_latch[ 7:0] <= rom_data;
                    end else begin
                        addr_latch[15:8] <= addr_latch[7:0];
                        addr_latch[ 7:0] <= rom_data;
                        st               <= LOAD;
                        rom_cs           <= 0;
                    end
                end
            end
            LOAD: if(cen4) begin
                rom_addr <= { addr_latch, 1'b1 };
                headerok <= 0;
                st       <= READCMD;
                rom_cs   <= 1;
                waitc    <= 1;
                rep_cnt  <= ~4'd0;
            end
            READCMD: if(cen4) begin
                waitc <= 0;
                if( rom_ok && !waitc ) begin
                    rom_addr <= next_rom;
                    waitc    <= 1;
                    if( ~&rep_cnt ) begin
                        rep_cnt  <= rep_cnt-1'd1;
                    end

                    if( rom_data==8'd0 ) begin
                        if( headerok ) begin
                            st      <= IDLE;
                            dec_rst <= 1;
                        end
                    end else begin
                        headerok <= 1;                     
                        case( rom_data[7:6] )
                            2'd0: begin
                                mute_cnt <= {rom_data[5:0],7'd0};
                                st       <= MUTED;
                                rom_cs   <= 0;
                                `JT7759_SILENCE
                            end
                            2'd1: begin
                                data_cnt  <= 9'hFF;
                                divby     <= rom_data[5:0];
                                st        <= PLAY;
                                `JT7759_PLAY
                            end
                            2'd2: begin
                                divby       <= rom_data[5:0];
                                data_cnt[8] <= 0;
                                st          <= GETN;
                                `JT7759_PLAY_LONG
                            end
                            2'd3: begin
                                rep_cnt   <= {1'b0, rom_data[2:0]};
                                rep_latch <= next_rom;
                                `JT7759_REPEAT
                            end
                        endcase
                    end
                end
            end
            GETN: begin
                waitc <= 0;
                if( !waitc && rom_ok ) begin
                    rom_addr <= next_rom;
                    rom_cs        <= 0;
                    data_cnt[7:0] <= rom_data;
                    st            <= PLAY;
                end
            end
            MUTED: if( cen4 ) begin
                dec_rst<= 1;
                if( |mute_cnt ) begin
                    mute_cnt <= mute_cnt-1'd1;
                end else begin
                    st     <= READCMD;
                    rom_cs <= 1;
                    waitc  <= 1;
                end
            end
            PLAY: begin
                waitc <= 0;
                if( &data_cnt ) begin
                    // dec_rst <= 1;
                    st       <= READCMD;
                    rom_cs   <= 1;
                    waitc    <= 1;
                end else if(cendec) begin
                    if( rom_cs ) begin
                        if( rom_ok && !waitc ) begin
                            { dec_din, next } <= rom_data;
                            dec_rst           <= 0;
                            rom_cs            <= 0;
                            data_cnt          <= data_cnt-1'd1;
                        end
                    end else begin
                        dec_din  <= next;
                        rom_addr <= next_rom;
                        rom_cs   <= 1;
                        data_cnt <= data_cnt-1'd1;
                        waitc    <= 1;
                    end
                end
            end
        endcase
    end
end


endmodule