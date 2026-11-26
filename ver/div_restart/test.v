`timescale 1ns/1ps

module test;

`include "test_tasks.vh"

localparam EVENTS=8, CEN_DIV=5;

reg        clk=0, rst=1, cen=0;
reg  [5:0] divby=6'd12;
reg  [2:0] cencnt=0;
wire       cen_ctl, cen_dec;
integer    ref_t[0:EVENTS-1];
integer    t, k, n, hold;

always #5 clk=~clk;

always @(posedge clk) begin
    cencnt <= cencnt==CEN_DIV-1 ? 3'd0 : cencnt+3'd1;
    cen    <= cencnt==0;
end

jt7759_div uut(
    .rst    ( rst     ),
    .clk    ( clk     ),
    .cen    ( cen     ),
    .divby  ( divby   ),
    .cen_ctl( cen_ctl ),
    .cen_dec( cen_dec )
);

task run(input integer cycles, input integer check);
    begin
        @(negedge clk);
        rst=1;
        repeat(cycles) begin
            @(negedge clk);
            assert_msg(!cen_dec, "cen_dec must stay low during reset");
        end
        while(cencnt!=0) @(negedge clk);
        rst=0;
        t=0; k=0;
        while(k<EVENTS) begin
            @(negedge clk);
            t=t+1;
            if(cen_dec) begin
                if(check) begin
                    if(ref_t[k]!=t) begin
                        $display("hold %0d: event %0d at %0d, expected %0d", cycles, k, t, ref_t[k]);
                        fail();
                    end
                end else ref_t[k]=t;
                k=k+1;
            end
            assert_msg(t<20000, "cen_dec does not pulse");
        end
    end
endtask

initial begin
    run(3, 0);
    for(n=1; n<EVENTS; n=n+1)
        assert_msg(ref_t[n]-ref_t[n-1]==CEN_DIV*4*(divby+1), "decoder rate must be cen/(4*(divby+1))");
    for(hold=4; hold<160; hold=hold+7) run(hold, 1);
    for(hold=1; hold<40; hold=hold+1) begin
        rst=0;
        repeat(hold*13) @(negedge clk);
        run(2, 1);
    end
    pass();
end

endmodule
