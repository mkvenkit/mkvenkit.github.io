---
title: "Project: UART Transmitter"
description: "Build a UART TX in Verilog — baud rate generation, a partitioned state machine, and a complete simulation — then synthesize it onto an iCE40 FPGA."
chapter_num: 5
prev_url: /begin-fpga/ch04-fpga-architecture/
prev_title: "FPGA Architecture"
next_url: /begin-fpga/ch06-7seg-pmod/
next_title: "Project: 4×7-Segment PMOD"
published: true
---

Universal Asynchronous Receiver-Transmitter (UART) is one of the oldest and most widely used serial protocols in embedded systems. It connects microcontrollers, FPGAs, sensors, and host computers with nothing more than two wires and a shared agreement on speed. In this chapter we build a complete UART transmitter in Verilog, simulate it, and synthesize it onto the iCE40 UP5K FPGA.

All source code lives under `examples/book/uart_tx/` in the companion repository.

**Tools used:**
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`) — simulation
- [GTKWave](http://gtkwave.sourceforge.net/) — waveform viewer
- [Yosys](https://yosyshq.net/yosys/) + [nextpnr](https://github.com/YosysHQ/nextpnr) — synthesis and place-and-route for iCE40

---

## The UART Protocol

UART is *asynchronous* — there is no shared clock wire. Both sides agree in advance on a **baud rate** (bits per second). The transmitter drives the line and the receiver samples it, each counting time independently using their own clocks.

### Idle and Start

When no data is being sent, the TX line sits **high** (logic 1). This is called the *idle* or *mark* state. To signal the start of a new byte, the transmitter pulls the line **low** for exactly one bit period. This falling edge is the **start bit** — the receiver uses it to synchronize.

### Data Bits and Stop

After the start bit, the transmitter sends 8 data bits, **LSB first**. After all 8 bits, it drives the line high for one bit period — the **stop bit** — before returning to idle.

A complete UART frame for a single byte looks like this:

```
Idle  Start  D0   D1   D2   D3   D4   D5   D6   D7  Stop  Idle
 1  |  0  |  x | ... | ... | ... | ... | ... | ... |  x  |  1  |  1
```

Each slot is exactly one bit period = 1 / baud_rate seconds. At 115200 baud, that is about 8.68 µs per bit.

### Why 10 Bits?

A single byte requires 10 bit periods to transmit: 1 start + 8 data + 1 stop. This is the count our state machine will track.

---

## Module Architecture

Rather than stuffing everything into one `always` block, we split the design into two cooperating parts:

- **Controller** — a finite state machine that sequences operations and drives control signals.
- **Datapath** — the shift register and bit counter that do the actual bit-level work.

This *partitioned* or *controller-datapath* architecture keeps each piece simple and testable in isolation. Control signals flow from controller to datapath (`C2D_*`), and status flags flow back from datapath to controller (`D2C_*`).

```
                 ┌─────────────┐   C2D_load, C2D_shift   ┌──────────────┐
  start_tx ────► │             │ ──────────────────────► │              │
                 │  Controller │                          │   Datapath   │ ──► tx
    busy   ◄──── │             │ ◄────────────────────── │              │
                 └─────────────┘   D2C_bc_eq_10          └──────────────┘
```

There is also a third module, the **baud rate generator**, which produces a periodic clock strobe that gates every state transition in both the controller and datapath.

---

## Baud Rate Generator (`baud_gen.v`)

A baud rate generator produces a single-cycle high pulse (`stb_clk_tx`) at exactly the baud rate. We use the fractional accumulator technique from [ZipCPU](https://zipcpu.com/blog/2017/06/02/generating-timing.html): accumulate a fixed increment each clock cycle; the carry-out of the accumulator fires the strobe.

```verilog
reg [15:0] clk_counter;

// f_clk / f_baud  → 25 000 000 / 115 200 ≈ 217
// 2^16  / 217     ≈ 302  (the increment)
parameter divider_tx = 16'd302;

always @(posedge clk_25mhz) begin
    if (!resetn) begin
        clk_counter <= 16'd0;
        stb_clk_tx  <= 1'b0;
    end else begin
        {stb_clk_tx, clk_counter} <= clk_counter + divider_tx;
    end
end
```

The trick: `{stb_clk_tx, clk_counter}` is a 17-bit concatenation. When the 16-bit accumulator overflows, the carry lands in `stb_clk_tx`, making it high for exactly one clock cycle. The rate at which overflows occur is `f_clk × divider / 2^16 = 25 MHz × 302 / 65536 ≈ 115 207 Hz` — close enough to 115200.

For simulation (Icarus Verilog defines `__ICARUS__`) we use a much larger divider so the waveform is easier to inspect at human-readable time scales.

---

## UART Transmitter (`uart_tx.v`)

### Interface

```verilog
module uart_tx (
    input  clk_25mhz,    // 25 MHz system clock
    input  resetn,       // active-low reset
    input  [7:0] data,   // byte to send
    input  start_tx,     // pulse high to begin transmission
    output busy,         // high while transmitting
    output reg tx        // serial output
);
```

`busy` is simply `(curr_state != sIDLE)`. The caller must hold `data` stable while `busy` is high, and should only assert `start_tx` when `busy` is low.

### Controller

The controller has two states: `sIDLE` and `sSENDING`.

```verilog
localparam sIDLE    = 2'b00;
localparam sSENDING = 2'b01;

// Next-state / output logic (combinational)
always @(*) begin
    // default outputs
    C2D_load   = 1'b0;
    C2D_shift  = 1'b0;
    C2D_inc_bc = 1'b0;
    C2D_clr_bc = 1'b0;
    next_state = sIDLE;

    case (curr_state)
        sIDLE: begin
            if (start_tx) begin
                C2D_load   = 1'b1;      // latch data into shift register
                next_state = sSENDING;
            end else
                next_state = sIDLE;
        end

        sSENDING: begin
            if (D2C_bc_eq_10) begin     // all 10 bits sent
                C2D_clr_bc = 1'b1;
                next_state  = sIDLE;
            end else begin
                C2D_inc_bc = 1'b1;
                C2D_shift  = 1'b1;
                next_state  = sSENDING;
            end
        end
    endcase
end

// State register — advances only on baud strobe
always @(posedge clk_25mhz) begin
    if (!resetn)
        curr_state <= sIDLE;
    else if (stb_clk_tx)
        curr_state <= next_state;
end
```

Notice that `curr_state` only advances when `stb_clk_tx` is high. Between strobes the controller is frozen — the FPGA runs at 25 MHz but the state machine steps at 115 200 Hz.

### Datapath

The datapath holds a 10-bit shift register (`sr_data`) packed as `{stop, D7..D0, start}` = `{1'b1, data, 1'b0}`.

```verilog
reg [9:0] sr_data;
reg [3:0] bit_counter;

assign D2C_bc_eq_10 = (bit_counter == 4'd10);

always @(posedge clk_25mhz) begin
    if (!resetn) begin
        sr_data     <= {10{1'b1}};  // idle line high
        bit_counter  = 4'd0;
        tx          <= 1'b1;
    end else if (stb_clk_tx) begin
        if (C2D_clr_bc)  bit_counter <= 0;
        else if (C2D_inc_bc) bit_counter <= bit_counter + 1;

        if (C2D_load)
            sr_data <= {1'b1, data, 1'b0};  // stop | D7..D0 | start

        if (C2D_shift) begin
            tx      <= sr_data[0];           // LSB first
            sr_data <= {1'b1, sr_data[9:1]}; // shift right, fill with 1s
        end
    end
end
```

Each baud strobe, the LSB of `sr_data` goes to `tx` and the register shifts right. After 10 shifts the bit counter reaches 10, the controller returns to `sIDLE`, and the line naturally idles high because the stop bit (and the fill value `1'b1`) leaves `tx` high.

---

## PLL: Generating 25 MHz (`pll.v`)

The iCE40 UP5K on the Humble Ice board runs off a 12 MHz oscillator. We use the iCE40's built-in `SB_PLL40_PAD` primitive to multiply it up to 25 MHz for the UART logic. The PLL parameters were calculated with `icepll`:

```
Input:   12.000 MHz
Output:  25.125 MHz  (≈25 MHz; close enough for UART)
DIVR=0, DIVF=66, DIVQ=5
```

```verilog
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'b0000),
    .DIVF(7'b1000010),  // 66
    .DIVQ(3'b101),      // 5
    .FILTER_RANGE(3'b001)
) pll_inst (
    .PACKAGEPIN(clock_in),
    .PLLOUTCORE(clock_out),
    .LOCK(locked),
    .RESETB(1'b1),
    .BYPASS(1'b0)
);
```

The `locked` signal goes high once the PLL has stabilised. In `top.v` we use it (together with a reset counter) to hold the rest of the design in reset until the clock is clean.

---

## Top Level (`top.v`)

`top.v` wires the PLL, UART transmitter, and a small sender FSM together, plus a blinking LED so you can see the board is alive.

### Reset Sequence

The iCE40 does not allow registers to initialize to non-zero values. To work around this we use an 8-bit counter whose MSB becomes the active-low reset after 256 clock cycles:

```verilog
reg [7:0] resetn_counter = 0;
wire resetn = &resetn_counter;  // high only when all bits are 1

always @(posedge clk_25mhz)
    if (!resetn)
        resetn_counter <= resetn_counter + 1;
```

`&resetn_counter` is a reduction AND — it is 1 only when every bit is 1, i.e., after 255 cycles. This gives the PLL time to lock before the rest of the design comes out of reset.

### Sender State Machine

A three-state FSM in `top.v` feeds bytes to the UART one at a time:

```verilog
localparam sWAITING = 2'b00;
localparam sSENDING = 2'b01;
localparam sUPDATE  = 2'b10;

always @(posedge clk_25mhz) begin
    if (!resetn) begin
        data       <= 8'd0;
        data_ready <= 1'b1;
        curr_state <= sWAITING;
    end else begin
        case (curr_state)
            sWAITING: if (busy)  curr_state <= sSENDING;
            sSENDING: if (!busy) curr_state <= sUPDATE;
            sUPDATE: begin
                data       <= data + 1;   // next byte
                curr_state <= sWAITING;
            end
        endcase
    end
end
```

This sends bytes 0, 1, 2, 3, … in an endless loop. Open a serial terminal at 115200 8N1 and you'll see the raw binary values arriving.

---

## Testbench and Simulation

The testbench (`testbench.v`) instantiates `uart_tx` directly — no PLL needed for simulation — and drives it with the same sender FSM from `top.v`.

```bash
# Compile and run
make sim

# View waveform
make sim-show
```

The simulation uses a large baud divider (`divider_tx = 16'd2048`) so each bit period spans thousands of clock edges and is easy to inspect in GTKWave.

What to look for in the waveform:

1. `resetn` goes low then high — the module comes out of reset.
2. `start_tx` asserts and `busy` goes high — transmission begins.
3. `tx` falls to 0 — the **start bit**.
4. Eight data bits follow, LSB first.
5. `tx` returns to 1 — the **stop bit** — and `busy` drops.
6. The sender increments `data` and queues the next byte.

---

## Synthesis and Programming

```bash
# Synthesize, place-and-route, and pack
make

# Flash to iCE40 via Humble Ice programmer
make hiprog
```

The PCF file assigns the three used pins:

```
set_io clk 35   # 12 MHz oscillator
set_io TX   9   # UART TX output
set_io LED 13   # Heartbeat LED
```

Connect pin 9 (TX) to a USB–UART adapter and open a terminal at **115200 baud, 8 data bits, no parity, 1 stop bit** (115200 8N1). You should see a continuous stream of incrementing bytes.

To inspect the synthesized design:

```bash
make show-rtl    # RTL-level schematic (most readable)
make show-gates  # gate-level after synthesis
make show-synth  # iCE40 primitives (SB_LUT4, SB_DFF)
make show-pnr    # placed-and-routed in nextpnr GUI
```

---

## Summary

This chapter built a complete UART transmitter from scratch. The key ideas:

- UART frames each byte as start bit + 8 data bits (LSB first) + stop bit — 10 bit periods total.
- A fractional accumulator generates an accurate baud-rate strobe from any input clock.
- The partitioned controller-datapath style keeps the FSM simple: the controller issues `load`, `shift`, and counter commands; the datapath does the register work.
- State transitions are gated by the baud strobe, so the 25 MHz FPGA clock and the 115200 baud rate coexist cleanly.
- The iCE40 PLL multiplies the 12 MHz board oscillator to 25 MHz; a reset counter ensures the design holds in reset until the PLL locks.

In the next chapter we extend this to a full UART receiver, introducing oversampling and the challenges of clock-domain crossing.
