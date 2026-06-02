// Chapter 2 — Example 4b: 2-to-4 Decoder
// Given a 2-bit index and enable, asserts exactly one of four output lines.
module decoder2to4 (
    input  wire [1:0] in,
    input  wire       en,
    output reg  [3:0] out
);
    always @(*) begin
        if (!en) begin
            out = 4'b0000;
        end else begin
            case (in)
                2'b00: out = 4'b0001;
                2'b01: out = 4'b0010;
                2'b10: out = 4'b0100;
                2'b11: out = 4'b1000;
            endcase
        end
    end
endmodule
