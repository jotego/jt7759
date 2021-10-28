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
    input             ctrl_flush,
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

reg cen_ctl2, wrl;
wire write = cs & ~wrn;

always @(posedge clk) begin
    cen_ctl2 <= cen_ctl;
    wrl <= write;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        drqn     <= 1;
        ctrl_ok  <= 0;
        ctrl_din <= 0;
    end else begin
        if( cen_ctl2 ) ctrl_ok <= 0;
        if( cen_ctl2 && ctrl_cs ) begin
            drqn    <= 0;
        end
        if( write && !wrl ) begin
            drqn     <= 1;
            ctrl_din <= din;
            ctrl_ok  <= ctrl_cs;
        end
    end
end

endmodule