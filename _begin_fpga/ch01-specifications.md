---
title: "Humble iCE Specifications"
description: "A complete technical reference for the Humble iCE board: the iCE40UP5K FPGA, RP2040 programmer, PMODs, power supply, schematic, and firmware."
chapter_num: 1
prev_url: /begin-fpga/
prev_title: "Overview"
next_url: /begin-fpga/ch02-getting-started/
next_title: "Getting Started with Humble iCE"
published: true
---

The **Humble iCE** (ver 0.4) is a compact FPGA development board built around the Lattice **iCE40UP5K** FPGA and a **Raspberry Pi RP2040** microcontroller. The RP2040 acts as a USB programmer and clock source for the FPGA — plug the board into your computer via USB-C and you can synthesise, flash, and run Verilog designs without any external programmer hardware.

---

## Block Diagram

```
                  USB-C (J1)
                      │
                 ┌────▼────┐       SPI slave
                 │  RP2040 │──GP3-6 (MOSI/MISO/SS/SCK)──► iCE40UP5K
                 │  (U3)   │──GP14 (~CRESET), GP15 (CDONE)─►
                 │         │──GP21 (12 MHz clock out)───────►
                 │         │──GP12/13 (UART TX/RX)──────────►
                 └────┬────┘
                      │ QSPI (internal)
                 ┌────▼────┐
                 │ W25Q32  │  4 MB flash (shared)
                 │  (U4)   │  0x000000–0x1DFFFF: RP2040 firmware (1920 KB)
                 └─────────┘  0x1E0000–0x1FFFFF: FPGA bitstream (128 KB)

Power:
  USB VBUS (5 V) ──► STPS2L40AF (D1) ──► 3.3 V rail (NCP115, U2)
                                      └─► 1.2 V rail (NCP114, U1) → iCE40 core
```

---

## iCE40UP5K FPGA

The iCE40UP5K is a member of Lattice's iCE40 UltraPlus family — a low-power FPGA well-suited to embedded and battery-operated applications.

| Resource | Quantity |
|---|---|
| LUTs (4-input) | 5,280 |
| Flip-flops | 5,280 |
| Embedded block RAM (EBR) | 120 Kbits (30 × 4 Kbit blocks) |
| Single-port RAM (SPRAM) | 1 Mbit (4 × 256 Kbit, single-cycle) |
| DSP blocks (SB_MAC16) | 8 |
| PLLs | 2 |
| I/O pins (SG48 package) | 39 |
| I/O standard | 3.3 V LVCMOS |
| Hard IP | SB_I2C, SB_SPI, SB_LEDDA_IP, SB_RGBA_DRV |

The board uses the **SG48** package (7 × 7 mm, 48-pin QFN). The FPGA core runs at 1.2 V supplied by U1; I/O banks run at 3.3 V from U2.

---

## RP2040 Programmer

The RP2040 (U3) handles two jobs:

**USB programmer.** When you run `hiprog.py`, the RP2040 receives the bitstream over USB-CDC, stores it in the flash chip, then configures the iCE40 via SPI slave mode. After that, every power-up replays the SPI configuration automatically — no PC required once the bitstream is loaded.

**12 MHz clock source.** The iCE40 has no on-board oscillator. The RP2040 generates a 12 MHz clock on GP21 (via PIO/PWM) and drives the FPGA's clock input. This eliminates one component compared to having a dedicated crystal for the FPGA.

The RP2040 itself clocks from a 12 MHz crystal (Y1, 3225 package) and uses an on-chip PLL to reach its operating frequency.

### RP2040 Pin Map

| Signal | RP2040 GPIO | Net name |
|---|---|---|
| iCE40 SPI MOSI | GP3 | `RP_IO3_iCE_SI` |
| iCE40 SPI MISO | GP4 | `RP_IO4_iCE_SO` |
| iCE40 SPI SS | GP5 | `RP_IO5_iCE_SS` |
| iCE40 SPI SCK | GP6 | `RP_IO6_iCE_SCK` |
| FPGA ~CRESET | GP14 | `~{CRESET}` |
| FPGA CDONE | GP15 | `CDONE` |
| RP2040 LED | GP1 | `RP_USER_LED` |
| FPGA clock out (12 MHz) | GP21 | — |
| UART TX (to iCE40) | GP12 | `RP_IO12_iCE_IOB_18A` |
| UART RX (from iCE40) | GP13 | `RP_IO13_iCE_IOB_16A` |

---

## Flash Memory

A single **W25Q32JVSSIQ** (4 MB, SOIC-8) flash chip is shared between the RP2040 and the iCE40. The RP2040 accesses it via its internal QSPI interface (XIP). When configuring the iCE40, the RP2040 reads the bitstream from the XIP-mapped address and clocks it out over SPI slave mode.

| Region | Offset | Size | Contents |
|---|---|---|---|
| Firmware | `0x000000` | 1920 KB | RP2040 firmware (XIP) |
| Bitstream | `0x1E0000` | 128 KB | FPGA bitstream |

A custom linker script (`pico_flash_region.ld`) prevents the RP2040 firmware from growing into the bitstream region.

---

## Power Supply

| Rail | Voltage | IC | Load |
|---|---|---|---|
| VBUS | 5 V (USB) | — | Input via D1 (Schottky) |
| 3.3 V | 3.3 V | NCP115ASN330T2G (U2, SOT-23-5) | RP2040, iCE40 I/O, flash, crystal, LEDs |
| 1.2 V | 1.2 V | NCP114ASN120T2G (U1, SOT-23-5) | iCE40 core |

D1 (STPS2L40AF, SMA) provides reverse-polarity and overvoltage protection on the USB VBUS line.

---

## Connectors and Headers

| Ref | Part | Description |
|---|---|---|
| J1 | GCT USB4105-GF-A | USB-C receptacle |
| J2, J3 | 2×15 pin header, 2.54 mm pitch | FPGA and RP2040 I/O expansion |
| J4 | 1×3 pin header, 2.54 mm pitch | RP2040 SWD debug (SWDIO, SWDCLK, GND) |

J2 and J3 expose iCE40 I/O pins, RP2040 GPIOs, and power rails (3.3 V, GND). The pin assignments are organised to be compatible with standard 2×6 PMOD modules — refer to the schematic for the full pinout.

The SWD header (J4) lets you flash the RP2040 via an external debug probe (e.g. Raspberry Pi Debug Probe + OpenOCD) without needing to enter BOOTSEL mode.

---

## PMOD Expansion Boards

Five PMOD add-on boards extend the Humble iCE for common peripherals. Each uses the standard 2×6, 2.54 mm dual-row PMOD connector (pins 5/11 = GND, 6/12 = VCC/3.3 V unless noted) and plugs into PMOD1 or the PMOD2A/PMOD2B pair described above.

### 4×7-Segment Display

Drives a 4-digit common-cathode 7-segment display via multiplexed scanning: 8 segment lines (a–g, dp) plus 4 digit-select lines switched through NPN transistors (MMBT3904). Uses **PMOD2A + PMOD2B**.

| PMOD Pin | Signal | iCE40 Pin |
|---|---|---|
| 2A.1–2A.4, 2A.7–2A.10 | SEG[0:7] (a,b,c,d,e,f,g,dp) | 43, 38, 34, 32, 42, 36, 31, 28 |
| 2B.1–2B.4 | DIG[0:3] (digit select, active high → NPN) | 27, 25, 21, 19 |

Segment lines use 100 Ω current-limiting resistors (~13 mA peak, ~3.3 mA average per digit); digit-select transistors switch up to ~104 mA per digit through 2.2 kΩ base resistors.

### VGA Output (12-bit Color)

Standard DB-15 VGA output at 4-4-4 RGB (12-bit color) plus HSYNC/VSYNC, using a binary-weighted resistor DAC per channel (2 kΩ/1 kΩ/510 Ω/270 Ω). Equivalent to the Digilent PmodVGA design. Uses **PMOD2A + PMOD2B**, matching the existing `vga_hello` example pinout exactly.

| PMOD Pin | Signal | iCE40 Pin |
|---|---|---|
| 2A.1–2A.4 | R[0:3] (red, LSB→MSB) | 43, 38, 34, 31 |
| 2A.7–2A.10 | B[0:3] (blue, LSB→MSB) | 42, 36, 32, 28 |
| 2B.1–2B.4 | G[0:3] (green, LSB→MSB) | 27, 25, 21, 19 |
| 2B.7, 2B.8 | VSYNC, HSYNC | 23, 26 |

Supports 640×480@60Hz (25.175 MHz pixel clock), 800×600@60Hz (40 MHz), and 640×480@75Hz (31.5 MHz) via PLL-generated pixel clocks.

### HM01B0 Camera

324×324 monochrome camera (HM01B0-MNA-00FT870, 87° FOV) in 4-bit parallel mode, connected via a 24-pin 0.5 mm FPC. Onboard LDOs generate AVDD (2.8 V) and DVDD (1.5 V) from the 3.3 V PMOD rail; IOVDD runs at 3.3 V directly (above the 3.0 V datasheet max, but standard practice on known HM01B0 breakouts). Uses **PMOD1**.

| PMOD Pin | Signal | iCE40 Pin |
|---|---|---|
| 1–4 | D[0:3] (4-bit pixel data) | 44, 46, 48, 3 |
| 7 | PCLK | 45 |
| 8 | VSYNC (FLVD) | 47 |
| 9, 10 | SCL, SDA (I²C, addr 0x24) | 2, 4 |

The sensor uses its internal 48 MHz oscillator (no MCLK from the FPGA) and has no LVLD (line valid) on the connector — the FPGA derives line boundaries by counting PCLK cycles.

### USB-C (Soft-Logic USB Device)

USB-C receptacle for a Full-Speed (12 Mbps) USB device implemented entirely in iCE40 soft logic — no USB PHY IC. Includes USBLC6-2SC6 ESD protection, 5.1 kΩ CC1/CC2 pull-downs for UFP device advertisement, a 1.5 kΩ D+ pull-up, and a resistor-divider VBUS detect. Uses **PMOD1** (3 of 8 signals).

| PMOD Pin | Signal | iCE40 Pin |
|---|---|---|
| 1 | USB_DP (D+, via 33 Ω series) | 44 |
| 2 | USB_DN (D−, via 33 Ω series) | 46 |
| 3 | VBUS_DET (~1.65 V when connected) | 48 |

Compatible with soft-USB cores such as `usb_cdc` and TinyFPGA-Bootloader-style designs, and with the UAC1 audio path used by the I2S/PDM mic PMOD below.

### I2S + PDM Stereo Microphone

Pairs an I2S mic (ICS-43434, left channel) with a PDM mic (MP34DT01-M, right channel) to form a stereo pair, decoded in the FPGA to PCM and streamed out over the USB-C PMOD as UAC1 audio. Uses **PMOD1** (5 of 8 signals).

| PMOD Pin | Signal | iCE40 Pin |
|---|---|---|
| 1, 2 | I2S_SCK, I2S_WS (FPGA → mic) | 44, 46 |
| 3 | I2S_SD (mic → FPGA) | 48 |
| 4 | PDM_CLK (FPGA → mic) | 3 |
| 7 | PDM_DATA (mic → FPGA, open-drain, 10 kΩ pull-up) | 45 |

I2S runs at ~3 MHz SCK / 48 kHz WS; PDM runs at 2.4 MHz clock, decimated in-FPGA with a sinc3 CIC filter. For exact 48 kHz audio, the iCE40 PLL is configured for 49.152 MHz and divided down.

---

## LEDs and Buttons

| Ref | Part | Function |
|---|---|---|
| D2 | Red LED (0603) | RP2040 status LED (GP1) |
| D3 | WS2812B-2020 RGB LED | iCE40 RGB LED (driven via SB_RGBA_DRV hard IP) |
| SW1 | Push button | USB BOOT — hold at power-up to enter RP2040 BOOTSEL mode |
| SW2 | Push button | RP RESET — resets the RP2040 |
| SW3 | Push button | USER BUTTON — available to FPGA and RP2040 designs |

The RGB LED (D3) connects to the iCE40's dedicated **SB_RGBA_DRV** hard IP pins (RGB0, RGB1, RGB2). This block has built-in programmable current control, so no external current-limiting resistors are needed. Use the `SB_RGBA_DRV` primitive in your Verilog to drive it.

---

## hiprog Firmware

The RP2040 runs **rp_prog_v4** firmware, which implements:

- **USB-CDC dual port**: CDC 0 for bitstream programming; CDC 1 as a UART bridge to the iCE40 (any baud rate, set from the host).
- **Framed programming protocol**: the host sends an 8-byte header `[0xAA 0x55 0x50 0x00 <size_u32_le>]`; the firmware ACKs when the flash is erased and ready.
- **Auto-boot**: on every power-up, the firmware checks for the iCE40 sync word (`FF 00 00 FF`) at flash offset `0x1E0000` and, if found, automatically replays the SPI slave configuration — the FPGA starts without any PC interaction.
- **LED feedback**: solid on during erase/write; 3 blinks (200 ms) on success; 5 rapid blinks on failure.

### Programming a Bitstream

```bash
python3 hiprog.py --port /dev/cu.usbmodemHI_V4_0011 --bitstream blinky.bin
```

```
Bitstream : blinky.bin
Size      : 104090 bytes (101.7 KB)
Port      : /dev/cu.usbmodemHI_V4_0011  (baud 115200)

Sending header...
Waiting for flash erase (may take a few seconds)...
Flash erased. Streaming bitstream...
Writing [####################################] 101/101 KB (100.0%)

Done! (4.1s, 24.8 KB/s)
FPGA configured via SPI slave mode -- CDONE asserted.
```

---

## Schematic

The full schematic for ver 0.4 is included in the code repository:

[humble_ice_sch_v0.4.pdf](https://github.com/mkvenkit/hice/blob/main/humble_ice_sch_v0.4.pdf)

---

## Bill of Materials (Summary)

| Ref | Value / Part | Description |
|---|---|---|
| U1 | NCP114ASN120T2G | 1.2 V LDO, SOT-23-5 |
| U2 | NCP115ASN330T2G | 3.3 V LDO, SOT-23-5 |
| U3 | RP2040 | MCU programmer, QFN-57 |
| U4 | W25Q32JVSSIQ | 4 MB SPI flash, SOIC-8 |
| U5 | iCE40UP5K-SG48ITR50 | FPGA, QFN-48 |
| Y1 | 12 MHz crystal | 3225 4-pin SMD (for RP2040) |
| J1 | USB4105-GF-A | USB-C connector |
| J2, J3 | Conn_02x15 | 2×15 I/O expansion headers |
| J4 | 1×3 header | SWD debug port |
| D1 | STPS2L40AF | Schottky diode, power protection |
| D2 | Red LED (0603) | RP2040 status LED |
| D3 | WS2812B-2020 | RGB LED (iCE40) |
| D4 | CDBU0520 | Schottky diode |
| SW1 | Push button | USB BOOT |
| SW2 | Push button | RP RESET |
| SW3 | Push button | USER BUTTON |
| H1–H4 | M2.5 mounting hole | PCB standoffs |
| TP1–TP7 | Test point | Probe pads for debug |
