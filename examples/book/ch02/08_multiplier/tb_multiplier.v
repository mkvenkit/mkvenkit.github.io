// Chapter 2 — Example 8: Multiplier Testbench
`timescale 1ns/1ps
module tb_multiplier;
    reg        clk, rst_n, start;
    reg  [7:0] a, b;
    wire       done;
    wire [15:0] product;

    multiplier dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .done(done), .product(product)
    );

    always #5 clk = ~clk;

    task run_test(input [7:0] ta, input [7:0] tb_val);
        integer expected;
        a = ta; b = tb_val;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        // Wait for done
        @(posedge done); @(posedge clk); #1;
        expected = ta * tb_val;
        $display("  %3d x %3d = %5d  (expected %5d)  %s",
                 ta, tb_val, product, expected,
                 (product == expected[15:0]) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("multiplier.vcd");
        $dumpvars(0, tb_multiplier);
        clk = 0; rst_n = 0; start = 0; a = 0; b = 0;
        repeat(2) @(posedge clk); #1;
        rst_n = 1;

        $display("=== Multiplier Tests ===");
        run_test(8'd3,   8'd7);      // 21
        run_test(8'd12,  8'd15);     // 180
        run_test(8'd255, 8'd255);    // 65025
        run_test(8'd0,   8'd42);     // 0
        run_test(8'd1,   8'd1);      // 1
        run_test(8'd128, 8'd2);      // 256

        $finish;
    end
endmodule
