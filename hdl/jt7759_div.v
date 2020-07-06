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

module jt7759_div(
    input            clk,
    input            cen,  // 640kHz
    input      [5:0] divby,
    output reg       cen4,
    output reg       cendec
);

reg [1:0] cnt4;
reg [5:0] cntdiv;
wire      pre4;

assign pre4 = cen && (&cnt4);

`ifdef SIMULATION
initial begin
    cnt4   = 'd0;
    cntdiv = 'd0;
end
`endif

always @(posedge clk) if(cen) begin
    cnt4   <= cnt4+2'd1;
    if( &cnt4 ) begin
        cntdiv <= cntdiv==divby ? 'd0 : (cntdiv+1'd1);
    end
end

always @(posedge clk) begin
    cen4   <= pre4;
    cendec <= pre4 && cntdiv==divby;
end

endmodule