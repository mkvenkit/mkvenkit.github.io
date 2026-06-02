// Chapter 2 — Example 6: Counter Testbench
`timescale 1ns/1ps
module tb_counter;
    reg        clk, rst_n, en, up, load;
    reg  [3:0] din;
    wire [3:0] q;
    wire       carry, borrow;

    counter #(.N(4)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .up(up),
        .load(load), .din(din), .q(q),
        .carry(carry), .borrow(borrow)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("counter.vcd");
        $dumpvars(0, tb_counter);
        clk = 0; rst_n = 0; en = 0; up = 1; load = 0; din = 0;
        @(posedge clk); #1; rst_n = 1;

        // Count up from 0
        en = 1; up = 1;
        $display("=== Count up ===");
        repeat(18) begin
            @(posedge clk); #1;
            $display("q=%0d carry=%b borrow=%b", q, carry, borrow);
        end

        // Load value 5, then count down
        load = 1; din = 4'd5; up = 0;
        @(posedge clk); #1; load = 0;
        $display("=== Count down from 5 ===");
        repeat(8) begin
            @(posedge clk); #1;
            $display("q=%0d carry=%b borrow=%b", q, carry, borrow);
        end

        $finish;
    end
endmodule
