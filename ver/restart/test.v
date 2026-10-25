`timescale 1ns/1ps

module test;

`include "test_tasks.vh"

reg clk=0, rst=1, cen=0, stn=1;
reg [7:0] din=0, rom_data=0;
reg rom_ok=0, last_cs=0;
reg [16:0] last_addr=0;
wire busyn, rom_cs;
wire [16:0] rom_addr;
wire signed [8:0] sound;
integer audible;

always #5 clk=~clk;
always @(posedge clk) cen <= ~cen;

// Two ROM directory entries point to distinct, short ADPCM streams.
// Registered reads model the latency of a synchronous external ROM.
always @(posedge clk) begin
    last_addr <= rom_addr;
    last_cs   <= rom_cs;
    rom_ok    <= !rst && rom_cs==last_cs && rom_addr==last_addr;
    case(rom_addr)
        17'd5:  rom_data <= 8'h00;
        17'd6:  rom_data <= 8'h08;
        17'd7:  rom_data <= 8'h00;
        17'd8:  rom_data <= 8'h10;
        17'd17, 17'd33: rom_data <= 8'h89; // four nibbles, divider 9
        17'd18, 17'd34: rom_data <= 8'h03;
        17'd19, 17'd20: rom_data <= 8'h77;
        17'd35, 17'd36: rom_data <= 8'hff;
        default: rom_data <= 8'h00; // end of sample
    endcase
end

task reset_chip;
    begin
        @(negedge clk);
        rst=1;
        repeat(8) @(negedge clk);
        rst=0;
        repeat(16) @(negedge clk);
    end
endtask

task play_sample(input [7:0] sample_id);
    begin
        assert_msg(busyn, "chip must be ready before starting");
        din=sample_id;
        stn=0;
        wait(!busyn);
        @(negedge clk);
        stn=1;
        audible=0;
        while(!busyn) begin
            @(negedge clk);
            if(sample_id==0 ? sound>0 : sound<0) audible=audible+1;
        end
        $display("Sample %d: %0d cycles of expected audio",sample_id,audible);
        assert_msg(audible>0, "sample must produce nonzero audio");
        repeat(16) @(negedge clk);
        assert_msg(sound==0, "decoder must be silent after sample ends");
    end
endtask

initial begin
    reset_chip();
    play_sample(0);
    play_sample(1); // the old terminal DONE state prevents this start
    reset_chip();
    play_sample(0);
    reset_chip();
    play_sample(1);
    pass();
end

initial begin
    #1000000;
    $display("FAIL: timeout waiting for sample playback");
    $finish;
end

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    $dumpon;
end

jt7759 uut(
    .rst      ( rst      ),
    .clk      ( clk      ),
    .cen      ( cen      ),
    .stn      ( stn      ),
    .cs       ( 1'b1     ),
    .mdn      ( 1'b1     ),
    .busyn    ( busyn    ),
    .wrn      ( 1'b1     ),
    .din      ( din      ),
    .drqn     (          ),
    .rom_cs   ( rom_cs   ),
    .rom_addr ( rom_addr ),
    .rom_data ( rom_data ),
    .rom_ok   ( rom_ok   ),
    .sound    ( sound    )
);

endmodule
