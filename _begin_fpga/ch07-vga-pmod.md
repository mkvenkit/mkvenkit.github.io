---
title: "Project: VGA PMOD"
description: "Drive an analog VGA monitor straight from the iCE40UP5K — 640×480 timing, a PLL-generated pixel clock, and a sprite that bounces over a tiled background, all rendered from block RAM with no frame buffer."
chapter_num: 7
prev_url: /begin-fpga/ch06-7seg-pmod/
prev_title: "Project: 4×7-Segment PMOD"
next_url: /begin-fpga/ch08-i2s-mic/
next_title: "Project: I2S Microphone PMOD"
published: true
---

VGA is an analog video standard from 1987 that refuses to die — every FPGA hobby board eventually drives one, because the protocol is dead simple: two digital sync pulses and three analog color channels, timed against a pixel clock. No handshaking, no packets, no HDCP. In this chapter we generate a full 640×480 signal from the iCE40UP5K, using nothing but the PLL, a pair of counters, and three small block-RAM images, and use it to draw a sprite that bounces around the screen over a tiled background — a display technique straight out of 1980s console hardware.

All source code lives under `examples/vga/` in the companion repository.

**Tools used:**
- [Yosys](https://yosyshq.net/yosys/) + [nextpnr](https://github.com/YosysHQ/nextpnr) — synthesis and place-and-route for iCE40
- [Pillow](https://pillow.readthedocs.io/) (Python) — the `img2mem.py` helper that turns PNGs into `.mem` files

**Hardware needed:**
- Humble iCE board (iCE40UP5K, ver0.4)
- [Digilent Pmod VGA](https://digilent.com/reference/pmod/pmodvga/start) module
- A monitor with a VGA input (or a VGA-to-HDMI adapter)

---

## VGA Signal Basics

A VGA cable carries five signals: **HSync**, **VSync**, and analog **Red**, **Green**, **Blue**. The monitor has no idea where one frame starts or ends except by watching these two sync pulses — everything else is inferred from timing.

The screen is scanned left to right, top to bottom, one pixel at a time, using a single pixel clock. Every horizontal line has four phases:

```
| Active video (visible pixels) | Front porch | HSync pulse | Back porch |
```

The **front porch** and **back porch** are quiet periods before and after the sync pulse — a hangover from analog CRTs, which needed time for the electron beam to physically retrace before the next line began. Vertical timing works the same way, one level up: each *line* takes the place of a *pixel*, and VSync fires once per frame instead of once per row.

For 640×480 @ 60 Hz, the standard timings are:

| | Active | Front porch | Sync | Back porch | Total |
|---|---|---|---|---|---|
| Horizontal (pixels) | 640 | 16 | 96 | 48 | 800 |
| Vertical (lines) | 480 | 10 | 2 | 33 | 525 |

Multiply it out: 800 × 525 × 60 Hz ≈ 25.2 MHz — the required pixel clock. Both sync pulses are **active-low** in this mode: the line sits high and only drops during the sync window.

### The PMOD's Resistor DAC

A Digilent Pmod VGA has no real DAC chip — it is a resistor ladder. Each of the 4 bits per color channel drives a weighted resistor, so 4-bit R/G/B gives 16 levels per channel and 4096 total colors (RGB444). That is the entire analog front end: 12 digital outputs plus HSync and VSync, driven directly by FPGA pins.

---

## PLL: Generating the Pixel Clock

The Humble iCE board's 12 MHz oscillator needs multiplying up to ~25 MHz. We reuse the same `SB_PLL40_PAD` configuration as the [UART chapter](/begin-fpga/ch05-uart-tx/) — `DIVF=66, DIVR=0, DIVQ=5` gives 12 × 67 / 32 = 25.125 MHz, close enough to the nominal 25.175 MHz that every monitor tolerates it without complaint.

```verilog
SB_PLL40_PAD #(
    .FEEDBACK_PATH ("SIMPLE"),
    .DIVR          (4'd0),
    .DIVF          (7'd66),
    .DIVQ          (3'd5),
    .FILTER_RANGE  (3'b001)
) pll (
    .PACKAGEPIN    (clk),
    .PLLOUTCORE    (pclk),
    .LOCK          (pll_locked),
    .RESETB        (1'b1),
    .BYPASS        (1'b0)
);
```

As before, an 8-bit saturating counter holds the design in reset until `pll_locked` is high and 256 more clock cycles have passed, giving the PLL time to settle:

```verilog
reg [7:0] rst_cnt = 0;
wire resetn = &rst_cnt;

always @(posedge pclk)
    if (!pll_locked)
        rst_cnt <= 0;
    else if (!resetn)
        rst_cnt <= rst_cnt + 1;
```

---

## Horizontal and Vertical Counters

Two free-running counters track position on the screen. `hcount` increments every pixel clock and wraps at `H_TOTAL`; `vcount` increments once per completed line and wraps at `V_TOTAL`.

```verilog
localparam H_ACTIVE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48;
localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 800

localparam V_ACTIVE = 480, V_FP = 10, V_SYNC = 2, V_BP = 33;
localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 525

wire hlast = (hcount == H_TOTAL - 1);
wire vlast = (vcount == V_TOTAL - 1);

always @(posedge pclk) begin
    if (!resetn)          hcount <= 10'd0;
    else if (hlast)        hcount <= 10'd0;
    else                   hcount <= hcount + 1;
end

always @(posedge pclk) begin
    if (!resetn)     vcount <= 10'd0;
    else if (hlast)  vcount <= vlast ? 10'd0 : vcount + 1;
end
```

`vcount` only ever changes on the last pixel of a line (`hlast`), which is exactly the "increment once per line" behavior we want.

From these two counters, everything else falls out as simple comparisons:

```verilog
wire hsync_i = (hcount < (H_ACTIVE + H_FP) || hcount >= (H_ACTIVE + H_FP + H_SYNC));
wire vsync_i = (vcount < (V_ACTIVE + V_FP) || vcount >= (V_ACTIVE + V_FP + V_SYNC));
wire pixel_valid = (hcount < H_ACTIVE) && (vcount < V_ACTIVE);
wire frame_tick   = hlast && vlast; // pulses once, on the last pixel of the frame
```

`pixel_valid` marks the active drawing region; `frame_tick` is a single-cycle pulse at the very end of each frame, which we will use to animate the sprite once per refresh instead of once per pixel.

---

## Drawing Without a Frame Buffer

A naive approach would allocate a frame buffer — one memory word per pixel, 640 × 480 = 307,200 of them — and write into it however you like. The UP5K does not have anywhere near enough block RAM for that. Instead, this design computes each pixel's color live, on the fly, purely as a function of `(hcount, vcount)`, using two small 64×64 images stored in block RAM as lookup tables.

### Tiled Background

A single 64×64 tile is stored in `bkg_rom` and repeated across the entire 640×480 screen by using only the **low 6 bits** of each counter as the address — 64 = 2⁶, so the address wraps automatically every 64 pixels, both horizontally and vertically:

```verilog
reg [11:0] bkg_rom [0:4095];
initial $readmemh("bkg.mem", bkg_rom);

wire [11:0] addr_bkg = {vcount[5:0], hcount[5:0]};
reg  [11:0] bkg_dout;

always @(posedge pclk)
    bkg_dout <= bkg_rom[addr_bkg];
```

No multiplication, no line-buffer — just bit-slicing the counters we already have. The result is a brick-pattern background tiled seamlessly across the screen.

### A Bouncing Sprite

The moving sprite is also a 64×64 image, but it needs two extra things a tiled background doesn't: a **position** (it moves) and a way to punch a transparent hole around its edges so it doesn't paint a solid 64×64 square over the background.

```verilog
reg [11:0] sprite_color_rom [0:4095];
initial $readmemh("sprite.mem", sprite_color_rom);

reg sprite_mask_rom [0:4095];
initial $readmemb("sprite_mask.mem", sprite_mask_rom);
```

`sprite_color_rom` holds one RGB444 value per pixel; `sprite_mask_rom` holds a single bit per pixel — 1 where the sprite's artwork actually is, 0 for background showing through.

Position and velocity update once per frame, on `frame_tick`, and bounce off all four edges of the active area:

```verilog
localparam [9:0] X_MAX = H_ACTIVE - 64;
localparam [9:0] Y_MAX = V_ACTIVE - 64;
localparam [9:0] STEP  = 10'd2;

reg [9:0] x_pos = 10'd100, y_pos = 10'd100;
reg dx_neg = 1'b0, dy_neg = 1'b0;

always @(posedge pclk) begin
    if (!resetn) begin
        x_pos <= 10'd100; y_pos <= 10'd100;
        dx_neg <= 1'b0;   dy_neg <= 1'b0;
    end else if (frame_tick) begin
        // horizontal bounce
        if (dx_neg) begin
            if (x_pos <= STEP) begin x_pos <= 10'd0;  dx_neg <= 1'b0; end
            else                    x_pos <= x_pos - STEP;
        end else begin
            if (x_pos >= X_MAX - STEP) begin x_pos <= X_MAX; dx_neg <= 1'b1; end
            else                             x_pos <= x_pos + STEP;
        end
        // vertical bounce follows the same pattern with y_pos / dy_neg
    end
end
```

Because the update only happens on `frame_tick`, position changes exactly once per 1/60th of a second — a fixed, frame-rate-independent step regardless of what the pixel clock is doing the rest of the time.

Whether the sprite is visible at the current pixel, and where inside its own 64×64 grid that pixel falls, are both simple range checks and subtractions:

```verilog
wire sprite_active = pixel_valid &&
                      (hcount >= x_pos) && (hcount < x_pos + 64) &&
                      (vcount >= y_pos) && (vcount < y_pos + 64);

wire [5:0]  sprite_lx   = hcount - x_pos;
wire [5:0]  sprite_ly   = vcount - y_pos;
wire [11:0] addr_sprite = {sprite_ly, sprite_lx};
```

---

## Compositing and the One-Cycle Pipeline

Block RAM reads on the iCE40 are registered — the data appears one clock cycle *after* the address is presented. That means `bkg_dout`, `sprite_color_d`, and `sprite_mask_d` all lag `hcount`/`vcount` by a cycle. If we compared them against the *current* `hsync_i`/`pixel_valid`, every edge in the image would be shifted by one pixel.

The fix is to register the control signals too, so everything lines up on the same clock edge as the delayed RAM outputs:

```verilog
reg hsync_d, vsync_d, pixel_valid_d;
reg sprite_active_d;

always @(posedge pclk) begin
    hsync_d         <= hsync_i;
    vsync_d         <= vsync_i;
    pixel_valid_d   <= pixel_valid;
    sprite_color_d  <= sprite_color_rom[addr_sprite];
    sprite_mask_d   <= sprite_mask_rom[addr_sprite];
    sprite_active_d <= sprite_active;
end

wire sprite_pixel = sprite_active_d && sprite_mask_d;

wire [11:0] out_rgb = !pixel_valid_d ? 12'h000        :
                      sprite_pixel   ? sprite_color_d :
                                       bkg_dout;

assign r     = out_rgb[11:8];
assign g     = out_rgb[7:4];
assign b     = out_rgb[3:0];
assign hsync = hsync_d;
assign vsync = vsync_d;
```

The priority is: outside the active region, output black; inside it, the sprite wins if its mask bit is set at this pixel, otherwise the tiled background shows through. This one-cycle discipline — delay every signal that has to agree with a registered memory read — is the single most important habit for pixel-pipeline design, and the most common source of "my sprite is smeared sideways" bugs when it's skipped.

---

## From PNG to Block RAM: `img2mem.py`

Both images started life as ordinary PNGs and were converted with a small Pillow-based script, `tools/img2mem.py`.

**Background tiles** are fit to a 64×64 canvas and each pixel is packed into a 3-hex-digit RGB444 word:

```bash
python3 tools/img2mem.py bkg brick.png bkg.mem
```

```python
word = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4)
f.write("%03x\n" % word)
```

**Sprites** need a second output — the transparency mask — derived either from the source PNG's alpha channel, or by color-keying against a background color sampled from the image's corners:

```bash
python3 tools/img2mem.py sprite raptor.png sprite.mem --mask-out sprite_mask.mem
```

The result is two parallel 4096-line files: `sprite.mem` (RGB444 color, don't-care where masked out) and `sprite_mask.mem` (a single "0"/"1" per pixel). Swap in any PNG and re-run the script to change the artwork — no Verilog edits required.

---

## PMOD Pinout and Constraints

The Digilent Pmod VGA's 12 signals (4×R, 4×G, 4×B, HSync, VSync) don't fit on a single Humble iCE PMOD header, so `vga.pcf` spreads them across two:

```
# Red   -- PMOD2A row A
set_io r[0]  43
set_io r[1]  38
set_io r[2]  34
set_io r[3]  31

# Green -- PMOD2B row A
set_io g[0]  27
set_io g[1]  25
set_io g[2]  21
set_io g[3]  19

# Blue  -- PMOD2A row B
set_io b[0]  42
set_io b[1]  36
set_io b[2]  32
set_io b[3]  28

# Sync  -- PMOD2B row B
set_io hsync 26
set_io vsync 23
```

Check the pin comments against your board's PMOD silkscreen before wiring — swapping bit order within a channel just shifts colors, but swapping HSync/VSync will desync the whole picture.

---

## Synthesis and Programming

```bash
# synthesize, place-and-route, and pack
make

# flash to the board
make prog
```

Resource usage is worth a look here — this is the first design in the book that leans heavily on block RAM rather than logic:

```
24 cells
   1  SB_PLL40_PAD
  23  SB_RAM40_4K
 184  SB_LUT4
  54  SB_DFF / SB_DFFESR / SB_DFFSR
```

Two 4096-word × 12-bit ROMs (background and sprite color) plus one 4096-word × 1-bit mask ROM consume 23 of the UP5K's 30 available 4 Kb block RAMs. Images larger than 64×64, or more than one on-screen sprite, will run out of BRAM quickly — the next step up from here is a proper frame buffer with a smaller color depth, or generating pixels algorithmically instead of from a lookup table.

Connect the Pmod VGA, power up the board, and you should see a brick-tiled background with a sprite bouncing around it like a screensaver — driven entirely by counters and block RAM, with not a single frame buffer in sight.

---

## Summary

This chapter turned two PNG files into a live analog video signal:

- VGA needs only sync timing and a pixel clock — 640×480 @ 60 Hz uses a ~25.2 MHz clock, an 800×525 total raster, and active-low sync pulses.
- A resistor-ladder PMOD needs no DAC chip: 4 bits per color channel wired straight to FPGA pins gives RGB444.
- Free-running horizontal and vertical counters generate HSync, VSync, and the active-video window with nothing but comparisons.
- Pixels are computed on the fly from block RAM rather than stored in a frame buffer — a repeating background tile addressed with the low bits of the counters, and a moving sprite with its own position and transparency mask.
- Registered block-RAM reads must be matched by registering the control signals one cycle later, or the whole image shifts sideways.
- `img2mem.py` bridges ordinary PNGs and Verilog `$readmemh`/`$readmemb`, so artwork can be swapped without touching the design.

In the next chapter we turn to digital audio, capturing sound from an I2S microphone PMOD.
