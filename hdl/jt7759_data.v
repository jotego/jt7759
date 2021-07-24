/*  This file is part of JT7759.
    JT7759 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public Licen_ctlse as published by
    the Free Software Foundation, either version 3 of the Licen_ctlse, or
    (at your option) any later version.

    JT7759 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public Licen_ctlse for more details.

    You should have received a copy of the GNU General Public Licen_ctlse
    along with JT7759.  If not, see <http://www.gnu.org/licen_ctlses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 21-7-2021 */

module jt7759_data(
    input             rst,
    input             clk,
    input             cen_ctl,
    input             cen_dec,
    input             mdn,
    // Control interface
    input             ctrl_cs,
    input             ctrl_busyn,
    input      [16:0] ctrl_addr,
    output reg [ 7:0] ctrl_din,
    output reg        ctrl_ok,
    // ROM interface
    output            rom_cs,
    output reg [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok,
    // Passive interface
    input             cs,
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    output reg        drqn
);

reg  [7:0] fifo[4];
reg  [3:0] fifo_ok;
reg        drqn_l, ctrl_cs_l;
reg  [1:0] rd_addr, wr_addr;
reg        readin, readout;

wire       good    = mdn ? rom_ok & ~drqn_l & ~drqn : (cs&~wrn);
wire [7:0] din_mux = mdn ? rom_data : din;

assign rom_cs  = mdn && !drqn;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        fifo_ok  <= 0;
        rom_addr <= 0;
        drqn     <= 1;
    end else if(cen_ctl) begin
        if( ctrl_busyn ) begin
            fifo_ok <= 0;
        end else begin
            if(fifo_ok!=4'hf) begin
                drqn <= ~drqn;
                if( drqn ) rom_addr <= rom_addr + 1;
            end else begin
                drqn <= 1;
            end
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rd_addr   <= 0;
        ctrl_cs_l <= 0;
        readout   <= 0;
        ctrl_ok   <= 0;
    end else begin
        ctrl_cs_l <= ctrl_cs;
        if( ctrl_cs && !ctrl_cs_l ) begin
            readout <= 1;
            ctrl_ok <= 0;
        end
        if( readout && fifo_ok[rd_addr] ) begin
            ctrl_din <= fifo[ rd_addr ];
            ctrl_ok  <= 1;
            rd_addr  <= rd_addr + 1'd1;
            fifo_ok[ rd_addr ] <= 0;
            readout  <= 0;
        end
        if( !ctrl_cs ) begin
            readout <= 0;
            ctrl_ok <= 0;
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        wr_addr <= 0;
        drqn_l  <= 1;
    end else begin
        drqn_l <= drqn;
        if( !drqn && drqn_l ) begin
            readin <= 1;
        end
        if( good && readin ) begin
            fifo[ wr_addr ] <= din_mux;
            fifo_ok[ wr_addr ] <= 1;
            wr_addr <= wr_addr + 1;
            readin  <= 0;
        end
    end
end

endmodule