// Chapter 2 — Example 4: Encoder/Decoder Testbench
`timescale 1ns/1ps
module tb_encoder;
    // Encoder signals
    reg  [3:0] enc_in;
    wire [1:0] enc_out;
    wire       enc_valid;
    // Decoder signals
    reg  [1:0] dec_in;
    reg        dec_en;
    wire [3:0] dec_out;

    encoder4to2 enc (.in(enc_in), .out(enc_out), .valid(enc_valid));
    decoder2to4 dec (.in(dec_in), .en(dec_en),   .out(dec_out));

    initial begin
        $dumpfile("encoder.vcd");
        $dumpvars(0, tb_encoder);

        $display("=== Encoder tests ===");
        enc_in = 4'b0000; #5;
        $display("in=%b -> out=%0d valid=%b", enc_in, enc_out, enc_valid);
        enc_in = 4'b0001; #5;
        $display("in=%b -> out=%0d valid=%b", enc_in, enc_out, enc_valid);
        enc_in = 4'b0110; #5;
        $display("in=%b -> out=%0d valid=%b (bit2 wins)", enc_in, enc_out, enc_valid);
        enc_in = 4'b1001; #5;
        $display("in=%b -> out=%0d valid=%b (bit3 wins)", enc_in, enc_out, enc_valid);

        $display("=== Decoder tests ===");
        dec_en = 1; dec_in = 2'b00; #5;
        $display("en=%b in=%b -> out=%b", dec_en, dec_in, dec_out);
        dec_in = 2'b01; #5;
        $display("en=%b in=%b -> out=%b", dec_en, dec_in, dec_out);
        dec_in = 2'b10; #5;
        $display("en=%b in=%b -> out=%b", dec_en, dec_in, dec_out);
        dec_in = 2'b11; #5;
        $display("en=%b in=%b -> out=%b", dec_en, dec_in, dec_out);
        dec_en = 0; #5;
        $display("en=%b in=%b -> out=%b (disabled)", dec_en, dec_in, dec_out);
        $finish;
    end
endmodule
