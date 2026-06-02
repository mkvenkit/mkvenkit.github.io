// Chapter 2 — Example 7: Sequence Detector Testbench
`timescale 1ns/1ps
module tb_seq_det;
    reg  clk, rst_n, si;
    wire found;

    seq_det dut (.clk(clk), .rst_n(rst_n), .si(si), .found(found));

    always #5 clk = ~clk;

    // Helper: send one bit and advance clock
    task send_bit(input b);
        si = b;
        @(posedge clk); #1;
    endtask

    integer found_count;

    initial begin
        $dumpfile("seq_det.vcd");
        $dumpvars(0, tb_seq_det);
        clk = 0; rst_n = 0; si = 0; found_count = 0;
        @(posedge clk); rst_n = 1;

        // Test 1: send 0_1011 — should detect 1011 once
        $display("Test 1: 0 1 0 1 1");
        send_bit(0);
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);

        // Test 2: send 1_0_1_1 directly
        $display("Test 2: 1 0 1 1");
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);

        // Test 3: overlapping — 1 0 1 1 0 1 1 should detect twice
        $display("Test 3: 1 0 1 1 0 1 1 (overlapping)");
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);
        send_bit(0); send_bit(1); send_bit(1);

        // Test 4: no match
        $display("Test 4: 0 0 0 0");
        send_bit(0); send_bit(0); send_bit(0); send_bit(0);

        #20;
        $display("Total detections: %0d (expect 5)", found_count);
        $finish;
    end

    always @(posedge clk) begin
        if (found) begin
            found_count = found_count + 1;
            $display("  t=%0t  FOUND sequence 1011! (count=%0d)", $time, found_count);
        end
    end
endmodule
