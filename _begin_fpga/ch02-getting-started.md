---
title: "Getting Started with Humble iCE"
description: "Install the open-source iCE40 toolchain on Windows, macOS, or Linux, then build, simulate, and flash your first Verilog design — a blinking LED and an RGB blinky."
chapter_num: 2
prev_url: /begin-fpga/ch01-specifications/
prev_title: "Humble iCE Specifications"
next_url: /begin-fpga/ch03-digital-design-with-verilog/
next_title: "A Crash Course in Digital Design with Verilog HDL"
---

{% include begin-fpga/svg-anim-assets.html %}

This chapter gets you from a bare board and an empty terminal to a blinking LED programmed over USB — entirely with open-source tools. Along the way you will write your first Verilog module, run a simulation, inspect the waveform, synthesize to a bitstream, and flash it to the iCE40. Two projects carry the chapter: a single-LED **blinky** and an on-board **RGB blinky**.

Source code lives under `examples/blinky/` and `examples/rgb_blinky/` in the companion repository.

---

## The Humble iCE Board

Humble iCE is a compact development board built around the **Lattice iCE40 UP5K** FPGA. An RP2040 microcontroller lives alongside the FPGA and serves two roles: it generates the 12 MHz clock the FPGA needs, and it acts as the USB programmer — no separate JTAG probe required.

Key facts about the iCE40 UP5K:

| Resource | Count |
|---|---|
| Logic cells (4-LUT + FF) | 5280 |
| SPRAM (single-port RAM) | 4 × 256 Kb |
| BRAM (block RAM) | 30 × 4 Kbit |
| DSP blocks | 8 |
| PLLs | 1 |
| Package | SG48 (QFN-48) |

The UP5K is small enough that synthesis and place-and-route finish in seconds, which makes it ideal for learning.

---

## Installing the Toolchain

The open-source iCE40 toolchain has three main components:

- **Yosys** — synthesis: turns Verilog into a netlist of logic primitives
- **nextpnr-ice40** — place and route: maps the netlist onto iCE40 fabric
- **IceStorm** (`icepack`, `iceprog`) — packs the routed design into a bitstream and programs the chip

You also need **Icarus Verilog** (`iverilog`) and **GTKWave** for simulation.

### macOS

The easiest path is [Homebrew](https://brew.sh):

```bash
brew install icestorm yosys nextpnr
brew install icarus-verilog gtkwave
```

Verify the tools are on your PATH:

```bash
yosys --version
nextpnr-ice40 --version
icepack --version
iverilog -V
```

### Linux (Ubuntu / Debian)

```bash
sudo apt update
sudo apt install fpga-icestorm nextpnr-ice40 yosys iverilog gtkwave
```

For newer versions of any tool, build from source following the instructions at [github.com/YosysHQ](https://github.com/YosysHQ).

On Linux, add yourself to the `dialout` group so you can access the USB serial port without `sudo`:

```bash
sudo usermod -aG dialout $USER
# Log out and back in for the change to take effect
```

### Windows

The recommended approach on Windows is [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), a self-contained bundle with all tools pre-built:

1. Download the latest `oss-cad-suite-windows-x64-*.tgz` from the [releases page](https://github.com/YosysHQ/oss-cad-suite-build/releases).
2. Extract it to a folder such as `C:\oss-cad-suite`.
3. Activate the environment in each terminal session before using the tools:

```bat
C:\oss-cad-suite\environment.bat
```

Or add `C:\oss-cad-suite\bin` to your `PATH` permanently via System Properties → Environment Variables → Path.

Verify from a Command Prompt or PowerShell:

```bat
yosys --version
nextpnr-ice40 --version
icepack --version
iverilog -V
```

### Programmer: hiprog

Humble iCE uses a custom programmer called **hiprog** that communicates with the RP2040 over USB. It is a Python script bundled in the companion repository:

```
hiprog_ver0.4/hiprog.py
```

Install its only dependency:

```bash
pip install pyserial
```

Plug in the board. The RP2040 enumerates as a USB serial port:

- **macOS** — `/dev/cu.usbmodemHI_V3_0011` (or similar)
- **Linux** — `/dev/ttyACM0`
- **Windows** — `COM3` (check Device Manager)

The `make prog` target auto-detects the port. If detection fails, or you have more than one board attached, name the port explicitly:

```bash
make prog PORT=/dev/cu.usbmodemHI_V3_0011   # macOS
make prog PORT=/dev/ttyACM0                  # Linux
make prog PORT=COM3                          # Windows
```

---

## The Blinky Project

The blinky project drives a single LED through two demos that alternate automatically: a square-wave **blink** at ~1.4 Hz, then a PWM **breathe** that fades the LED in and out. Each phase lasts about 2.8 s before switching to the other. The blink half confirms the clock is running; the breathe half is a first taste of pulse-width modulation, which returns in the RGB project below.

```
examples/blinky/
├── top.v        ← Verilog design
├── blinky.pcf   ← Pin constraints
└── Makefile     ← Build rules
```

### Wiring the LED

The ver0.4 board has no on-board user LED, so blinky drives an external one on a breadboard. The signal comes out of **PMOD_2 pin 1** (FPGA package pin 43, `IOT_51A`):

```
PMOD_2 pin1 ----[ 220–1k Ω ]----|>|---- GND
   (pkg 43)        resistor       LED   (PMOD_2 pin 5 or 11)
```

Put the LED's longer leg (anode) toward the resistor and the shorter leg (cathode) to any GND pin on the PMOD. The resistor limits current so you don't burn out the LED.

### Pin Constraints (`blinky.pcf`)

The Physical Constraints File maps Verilog port names to physical FPGA pins:

```
set_io clk 35
set_io led 43
```

Pin 35 is connected to the RP2040's GP21, which outputs a 12 MHz clock. Pin 43 is PMOD_2 pin 1, driving the external LED.

### The Verilog Design (`top.v`)

```verilog
`default_nettype none

module blinky(
  input  clk,  // 12 MHz from RP2040 GP21 — FPGA pin 35
  output led   // external LED on PMOD_2 pin1 — FPGA pin 43
);
```

**Always open with `` `default_nettype none ``.** Without it, any undeclared signal is implicitly a 1-bit wire, silently turning typos into phantom nets. With it, the tools error on any undeclared name.

#### Reset Synchronizer

```verilog
reg [7:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @(posedge clk) begin
    if (!resetn)
        resetn_counter <= resetn_counter + 1;
end
```

iCE40 registers always power up as 0. The 8-bit counter starts at `8'h00` and increments every clock cycle. `&resetn_counter` is a **reduction AND** — it returns 1 only when every bit is 1, i.e., after 255 cycles. Until then `resetn` is 0 and the rest of the design stays in reset. At 12 MHz, 255 cycles is about 21 µs — enough time for power rails to stabilise before logic starts running.

#### The Master Time Counter

A single free-running 26-bit counter, `tick`, drives everything. Different bits of the same counter tick at different rates, so we can pull a phase select, a blink signal, and a brightness ramp all from one register.

```verilog
reg [25:0] tick = 0;
always @(posedge clk) begin
    if (!resetn)
        tick <= 0;
    else
        tick <= tick + 1;
end

wire phase = tick[25];  // 0 = blink, 1 = breathe
```

The top bit, `tick[25]`, flips every `2^25 / 12e6 ≈ 2.8 s`, so it cleanly alternates between the two phases.

#### Phase 0 — Blink

```verilog
wire blink = tick[22];
```

`tick[22]` toggles every `2^22 / 12e6 ≈ 0.35 s`, giving an on/off period of ~0.70 s — a **~1.4 Hz** blink. No extra logic needed: it is just a wire tapped off the counter.

#### Phase 1 — Breathe (PWM)

Pulse-width modulation dims an LED by switching it on and off faster than the eye can follow; the fraction of time it stays on — the **duty cycle** — sets the apparent brightness.

```verilog
reg [7:0] pwm_cnt = 0;
always @(posedge clk) begin
    if (!resetn)
        pwm_cnt <= 0;
    else
        pwm_cnt <= pwm_cnt + 1;
end

wire [7:0] ramp  = tick[21:14];
wire [7:0] duty  = tick[22] ? ~ramp : ramp;
wire breathe     = (pwm_cnt < duty);
```

`pwm_cnt` is an 8-bit carrier that wraps at `12e6 / 256 ≈ 47 kHz` — far too fast to see flicker. The LED is on whenever `pwm_cnt < duty`, so a larger `duty` means a brighter LED.

{% include begin-fpga/ch02-fig1-pwm.html %}

To make the LED *fade*, `duty` itself sweeps slowly. `ramp` is eight mid-range bits of `tick`, and `tick[22]` inverts it every half-cycle, producing a triangle wave that climbs `0 → 255` then falls `255 → 0`. The result is a smooth fade in and out.

{% include begin-fpga/ch02-fig2-breathe.html %}

#### Choosing the Output

```verilog
assign led = phase ? breathe : blink;
```

A single multiplexer picks the blink wave or the breathe wave based on the current phase, and drives the LED.

---

## Simulation

Simulation lets you inspect every internal signal before touching the hardware. You can verify the reset sequence fires correctly and the counter is counting — all in a few seconds.

Create `testbench.v` alongside `top.v`:

```verilog
`default_nettype none
`timescale 1ns/1ps

module tb();

reg clk = 0;
wire led;

blinky dut (
    .clk(clk),
    .led(led)
);

// 12 MHz clock: period ≈ 83 ns → half-period ≈ 42 ns
always #42 clk = ~clk;

initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, tb);
    #50000
    $finish;
end

endmodule
```

Compile and run:

```bash
iverilog -o tb.out -s tb testbench.v top.v
vvp tb.out
```

Open the waveform:

```bash
gtkwave testbench.vcd
```

In GTKWave, drag `clk`, `resetn_counter`, `resetn`, `tick`, `pwm_cnt`, and `led` into the signals pane. What you should see:

1. `resetn_counter` incrementing from 0 on every rising clock edge.
2. `resetn` going high once `resetn_counter` reaches `8'hFF`.
3. `tick` resetting to 0 then counting freely; `pwm_cnt` wrapping every 256 cycles.
4. At simulation scale the phase and blink bits (`tick[25]`, `tick[22]`) take millions of cycles to flip, so you won't watch the LED blink or breathe in real time — but you can confirm the reset releases and both counters advance correctly.

The Makefile wraps both steps:

```bash
make sim       # compile and run
make sim-show  # open GTKWave
```

---

## Synthesis and Place-and-Route

Running `make` triggers the three-stage build:

```
top.v
  │
  ▼  yosys — synthesis
blinky.json   (technology-mapped netlist)
  │
  ▼  nextpnr-ice40 — place and route
blinky.asc    (placed-and-routed design)
  │
  ▼  icepack — bitstream packing
blinky.bin    (binary bitstream ready to flash)
```

```bash
make
```

**Synthesis (Yosys)** parses the Verilog, applies optimisations, and maps to iCE40 primitives — `SB_LUT4`, `SB_DFF`, `SB_CARRY`. It writes `blinky.json` and a log file (`blinky-yosys.log`) worth reading once to understand what the synthesiser decided.

**Place and route (nextpnr-ice40)** assigns each logic cell to a physical iCE40 cell and routes all connections through the programmable interconnect. It reads `blinky.json` and `blinky.pcf` and writes `blinky.asc`.

**Bitstream packing (icepack)** converts the ASCII routing description to the compact binary `blinky.bin`.

### Visualising the Design

The Makefile has four targets that open synthesis diagrams as SVG:

```bash
make show-rtl    # RTL view — closest to the Verilog you wrote
make show-gates  # gate-level after synthesis (AND/OR/NOT/DFF)
make show-synth  # iCE40 primitives (SB_LUT4, SB_DFF)
make show-pnr    # place-and-routed result in nextpnr GUI
```

For blinky the RTL view shows the `tick` and `pwm_cnt` counter registers, the reduction AND feeding `resetn`, the PWM comparator, and the multiplexer that selects blink or breathe onto `led`. The synth view shows how Yosys packed all of that into a modest set of `SB_LUT4`, `SB_DFF`, and `SB_CARRY` primitives — confirming the design is tiny.

---

## Uploading to the Board

With the board connected over USB:

```bash
make prog
```

This runs hiprog, which sends the bitstream to the RP2040 which streams it to the iCE40 over SPI. The transfer takes under a second. If everything is correct the LED blinks at ~1.4 Hz for a few seconds, then fades smoothly in and out, then returns to blinking — repeating forever.

### Troubleshooting

**Nothing lights up** — First check the LED wiring: the anode (longer leg) must face the resistor and pin 43, the cathode must go to GND. A backwards LED stays dark. Then check that `blinky.bin` has a non-zero size (`ls -lh blinky.bin`); a zero-byte binary usually means a port name mismatch between the PCF and the Verilog module.

**`hiprog` can't open the port on Linux** — Verify you are in the `dialout` group (`groups $USER`). If not: `sudo usermod -aG dialout $USER`, then log out and back in.

**`hiprog` can't find the port** — Pass it explicitly, e.g. `make prog PORT=COM5` on Windows (check Device Manager) or `make prog PORT=/dev/ttyACM0` on Linux.

**nextpnr reports an error placing cells** — This won't happen with blinky, but if you modify the design and see placement errors, confirm the PCF pin numbers match the actual board schematic.

---

## The RGB Blinky Project

Blinky used a plain I/O pin and an external LED. The second project drives the board's **on-board RGB LED (D3)** — and to do it well, it reaches for a piece of dedicated silicon inside the iCE40UP5K: the hard **`SB_RGBA_DRV`** LED driver.

```
examples/rgb_blinky/
├── top.v            ← Verilog design
├── rgb_blinky.pcf   ← Pin constraints
└── Makefile         ← Build rules
```

Each colour fades smoothly in and out, then the design steps to the next, cycling through red, green, blue, yellow, cyan, magenta, and white.

### Pin Constraints (`rgb_blinky.pcf`)

```
set_io clk  35
set_io RGB0 39   # Blue  cathode  (iCE40 RGB0)
set_io RGB1 40   # Green cathode  (iCE40 RGB1)
set_io RGB2 41   # Red   cathode  (iCE40 RGB2)
```

D3 is **common-anode**: its anode sits at 3.3 V, and each colour lights when the driver sinks current out of its cathode. Note the mapping is not in R-G-B order — `RGB0` is blue, `RGB2` is red — so it pays to keep the schematic handy.

### The Constant-Current Driver (`SB_RGBA_DRV`)

Rather than a normal output pin plus an external resistor per colour, the iCE40UP5K provides three dedicated **constant-current sinks** that drive an RGB LED directly. You instantiate them as a hard primitive:

```verilog
SB_RGBA_DRV #(
    .CURRENT_MODE("0b1"),
    .RGB0_CURRENT("0b000001"),  // Blue
    .RGB1_CURRENT("0b000001"),  // Green
    .RGB2_CURRENT("0b000001")   // Red
) rgba (
    .CURREN  (1'b1),
    .RGBLEDEN(1'b1),
    .RGB0PWM (blue),
    .RGB1PWM (green),
    .RGB2PWM (red),
    .RGB0    (RGB0),
    .RGB1    (RGB1),
    .RGB2    (RGB2)
);
```

`CURRENT_MODE` and the per-channel `*_CURRENT` parameters set the sink current at build time — here the lowest half-current step, which is comfortably dim and easy on the eyes. Each `RGBxPWM` input is a simple on/off gate for its channel, and the `RGBx` outputs go straight to the LED pins.

{% include begin-fpga/ch02-fig3-rgb-driver.html %}

### Brightness by PWM

Because the driver's current is *fixed*, brightness has to come from switching each channel on and off — the same PWM idea as blinky's breathe phase. A fast 8-bit counter provides the carrier:

```verilog
reg [7:0] pwm_cnt;
always @(posedge clk)
    if (!resetn) pwm_cnt <= 0;
    else         pwm_cnt <= pwm_cnt + 1;

wire pwm_on = (pwm_cnt < duty);
```

`pwm_cnt` wraps at `12e6 / 256 ≈ 47 kHz`, and a channel is enabled when `pwm_cnt < duty`.

### Fading with a Gamma-Corrected Triangle

A slow triangle ramp sweeps `level` from 0 up to 255 and back down; when it returns to 0 the design advances to the next colour:

```verilog
reg [14:0] prescale;
reg [7:0]  level;
reg        falling;
reg [2:0]  color;

wire step = &prescale;

always @(posedge clk) begin
    if (!resetn) begin
        prescale <= 0; level <= 0; falling <= 0; color <= 0;
    end else begin
        prescale <= prescale + 1;
        if (step) begin
            if (!falling) begin
                if (level == 8'd255) falling <= 1;
                else                 level   <= level + 1;
            end else begin
                if (level == 8'd0) begin
                    falling <= 0;
                    color   <= (color == 3'd6) ? 3'd0 : color + 1;
                end else level <= level - 1;
            end
        end
    end
end
```

`&prescale` fires once every `2^15 / 12e6 ≈ 2.7 ms`, so a full fade in and out takes about 1.4 s.

The eye's response to light is non-linear, so a linear ramp *looks* like it brightens in a rush and then crawls. Squaring the level — a rough **gamma correction** — cancels this out and makes the fade look even:

```verilog
wire [15:0] level_sq = level * level;
wire [7:0]  duty     = level_sq[15:8];
```

{% include begin-fpga/ch02-fig4-gamma.html %}

Note the 16-bit `level_sq` wire: writing `(level*level) >> 8` directly would evaluate the multiply at the 8-bit target width and truncate to zero. Giving the product a full-width wire first is a common Verilog gotcha worth remembering.

Finally a `case` on the 3-bit `color` picks which channels are active for each of the seven colours, and each channel is `AND`ed with `pwm_on` before feeding the driver.

### Build and Flash

```bash
make
make prog
```

The on-board RGB LED cycles through the colour set, each fading gently in and out.

---

## Summary

You now have a working iCE40 development environment and have completed the full toolchain loop: write Verilog → simulate → synthesize → place and route → flash, across two projects.

The key ideas from this chapter:

- `` `default_nettype none `` catches undeclared-wire bugs at compile time.
- A reduction AND (`&resetn_counter`) cleanly detects the all-ones state without a comparator.
- Taps off a single free-running counter give you multiple time bases for free — a phase select, a blink, and a fade ramp all came from `tick`.
- PWM turns a one-bit output into apparent brightness; gamma-correcting the duty makes fades look linear to the eye.
- The iCE40UP5K's hard `SB_RGBA_DRV` drives an RGB LED with constant current — no external resistors needed.
- The three-step build is: Yosys (synthesis) → nextpnr (P&R) → icepack (bitstream).
- Simulate with Icarus Verilog and inspect waveforms in GTKWave before going near hardware.
- hiprog streams the bitstream to the iCE40 through the RP2040 over USB — no extra probe needed.

In the next chapter we step back from the toolchain and take a proper tour of digital design with Verilog: gates, state machines, and the datapath-controller pattern.
