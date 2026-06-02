// Chapter 2 — Example 2: Priority Encoder Testbench
`timescale 1ns/1ps
module tb_priority_enc;
    reg  [3:0] req;
    wire [1:0] grant;
    wire       valid;

    priority_enc dut (.req(req), .grant(grant), .valid(valid));

    task check(input [3:0] r, input [1:0] exp_grant, input exp_valid);
        req = r; #5;
        $display("req=%b -> grant=%0d valid=%b  %s",
                 r, grant, valid,
                 (grant == exp_grant && valid == exp_valid) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("priority_enc.vcd");
        $dumpvars(0, tb_priority_enc);
        check(4'b0000, 2'd0, 1'b0);
        check(4'b0001, 2'd0, 1'b1);
        check(4'b0010, 2'd1, 1'b1);
        check(4'b0110, 2'd2, 1'b1);  // bit 2 wins over bit 1
        check(4'b1001, 2'd3, 1'b1);  // bit 3 wins
        check(4'b1111, 2'd3, 1'b1);  // bit 3 wins
        $finish;
    end
endmodule
