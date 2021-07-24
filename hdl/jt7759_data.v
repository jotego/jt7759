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
    input             ctrl_cs,      // equivalent to DRQn in original chip
    input      [16:0] ctrl_addr,
    output     [ 7:0] ctrl_din,
    output            ctrl_ok,
    // ROM interface
    output            rom_cs,      // equivalent to DRQn in original chip
    output     [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok,
    // Passive interface
    input             cs,
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    output            drqn
);

reg  [7:0] fifo;
//reg  [1:0] last_a;
reg        last_ctrl_cs;
reg  [1:0] cnt;
reg        fifo_ok;
//wire       achg;
reg        pre_drqn, last_wrn;

//assign achg     = last_a != ctrl_addr[1:0];
assign rom_addr = ctrl_addr;
assign rom_cs   = mdn ? ctrl_cs  : 0;
assign ctrl_din = mdn ? rom_data : fifo;
assign ctrl_ok  = mdn ? rom_ok   : fifo_ok;
assign drqn     = cnt==0 || mdn ? pre_drqn : 1;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        fifo_ok <= 0;
        fifo    <= 0;
        last_wrn<= 1;
    end else begin
        last_wrn <= wrn;
        if( cs && !wrn && last_wrn ) begin
            fifo    <= din;
            fifo_ok <= 1;
        end
        if( !ctrl_cs ) fifo_ok <= 0;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        //last_a  <= 1;
        pre_drqn<= 1;
        cnt     <= 0;
        last_ctrl_cs <= 0;
    end else begin
        //last_a <= ctrl_addr[1:0];
        last_ctrl_cs <= ctrl_cs;
        if( !ctrl_cs )
            cnt <= 2;
        else if( cen_ctl && cnt!=0 )
            cnt<=cnt-1'd1;
        if( ctrl_cs & ~last_ctrl_cs ) begin
            pre_drqn <= 0;
        end
        if( (cs && !wrn) || !ctrl_cs ) pre_drqn <= 1;
    end
end

endmodule