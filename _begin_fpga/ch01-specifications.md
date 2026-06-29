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
