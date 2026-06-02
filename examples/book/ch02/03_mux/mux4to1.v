// Chapter 2 — Example 3: Parameterised 4-to-1 Multiplexer
// WIDTH controls the bus width; default is 8 bits.
module mux4to1 #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] d0, d1, d2, d3,
    input  wire [1:0]       sel,
    output reg  [WIDTH-1:0] y
);
    always @(*) begin
        case (sel)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            2'b11: y = d3;
        endcase
    end
endmodule
