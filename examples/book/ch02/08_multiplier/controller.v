// Chapter 2 — Example 8: Shift-and-Add Multiplier — Controller FSM
// States: IDLE -> LOADING -> RUNNING -> FINISH -> IDLE
// Two-always-block style: sequential state register + combinational logic.
module controller (
    input  wire clk,
    input  wire rst_n,
    input  wire start,     // begin a multiplication
    input  wire cnt_done,  // from datapath: all 8 shifts done
    input  wire b_lsb,     // from datapath: LSB of current multiplier
    output reg  load,      // to datapath: load operands
    output reg  shift,     // to datapath: shift b right, inc cnt
    output reg  add,       // to datapath: add partial product
    output reg  done       // to top-level: result ready
);
    localparam IDLE    = 2'd0,
               LOADING = 2'd1,
               RUNNING = 2'd2,
               FINISH  = 2'd3;

    reg [1:0] state, next_state;

    // Sequential: state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // Combinational: next-state + output logic (ASM chart)
    always @(*) begin
        load  = 1'b0;
        shift = 1'b0;
        add   = 1'b0;
        done  = 1'b0;
        next_state = state;

        case (state)
            IDLE: begin
                if (start) next_state = LOADING;
            end
            LOADING: begin
                load       = 1'b1;
                next_state = RUNNING;
            end
            RUNNING: begin
                if (cnt_done) begin
                    next_state = FINISH;
                end else begin
                    if (b_lsb) add = 1'b1;   // conditional add (Mealy)
                    shift      = 1'b1;
                end
            end
            FINISH: begin
                done       = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
