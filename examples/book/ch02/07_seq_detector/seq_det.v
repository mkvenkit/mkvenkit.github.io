// Chapter 2 — Example 7: Sequence Detector FSM
// Detects the bit pattern 1011 on serial input si.
// found pulses high for one clock when the pattern is detected (Mealy output).
// Implements the two-always-block FSM style:
//   always 1 — state register (sequential)
//   always 2 — next-state + output logic (combinational)
module seq_det (
    input  wire clk,
    input  wire rst_n,   // active-low asynchronous reset
    input  wire si,      // serial input
    output reg  found    // pulses high when 1011 is detected
);
    // State encoding
    localparam IDLE = 2'd0,
               S1   = 2'd1,
               S10  = 2'd2,
               S101 = 2'd3;

    reg [1:0] state, next_state;

    // Sequential: state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Combinational: next-state and output logic
    always @(*) begin
        next_state = IDLE;
        found      = 1'b0;

        case (state)
            IDLE:  next_state = si ? S1   : IDLE;
            S1:    next_state = si ? S1   : S10;
            S10:   next_state = si ? S101 : IDLE;
            S101: begin
                if (si) begin
                    found      = 1'b1;   // Mealy output — pattern complete
                    next_state = IDLE;
                end else begin
                    next_state = S10;    // overlap: last 0 restarts from S10
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
