---
layout: post
title: Bare Metal ARM Programming on Nordic nRF52832 BLE SoC
excerpt: "Following is an example with minimal code that demonstrates writing a small blinky application from scratch, only using C."  
tags: [nRF52832, C]
categories: [Electronics]
comments: true
modified: 2018-09-10
thumbnail: images/2018/09/nrf52_blink_cropped.jpg
images: images/2018/09/nrf52_blink_cropped.jpg
---

**Author: Tavish Naruka**

**Editor: Mahesh Venkitachalam**

This post will have enough information to help someone understand the startup code and all the intermediate files present in a C project for a microcontroller. This will be explained through a minimal blinky example that pulls no external dependencies.

Over here at Electronut Labs, we have been using the Nordic Semiconductor SoCs for a while now, and we'll use them for this demonstration. The nRF52 series of chips from Nordic semiconductor are ARM cortex-M4F based SoCs.

## ARM Introduction

[Cortex-M](https://en.wikipedia.org/wiki/ARM_Cortex-M) are 32-bit processor cores licensed by ARM to chip manufacturers. This CPU core is used in microcontrollers like our chip (we'll mostly look at nRF52832 used in [bluey](https://github.com/electronut/ElectronutLabs-bluey/)). 

## ARM Cortex M3/M4 Architecture

Cortex-M4F means Cortex-M4 CPU with floating point unit in hardware. Cortex-M4 is basically Cortex-M3 with DSP instructions, and Cortex-M3 supports only thumb instructions (which are mostly 16-bit wide, unlike the usual 32-bit wide ARM instructions). Cortex m4 implements the ARMv7E-M architecture. Cortex-M CPU is designed for low interrupt latency of 12 cycles and has up to [240 interrupts](http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0439b/Cihfihfe.html).

One thing to note, in thumb mode, the LSb (bit) for each 32-bit dword is set to 1, but since all instructions are aligned to 16 or 32 bit boundary, the LSb is not used in the jump instruction. You can see this later in the disassmbly code for the reset vector address (it's 0x000000b7, not alighned to 4byte boundary).

![](/images/2018/09/2018-07-31-02-34-11.png)

These are the core CPU registers of the CPU. R15 is the program counter.

## Startup Sequence

The flash/ROM address starts at 0x00000000. Upon reset, the
first four bytes are loaded onto the stack pointer, which 
sets up the stack (stack grows down). The next four bytes 
are loaded onto the program counter, which means that the first instruction which executes upon reset is the one at this address.

## Project Setup, files 

Following is an example with minimal code that demonstrates writing a small blinky application from scratch, only using C.

We'll use a very simple and minimal project to compile our code. In total we have 4 source files, of which two are **.c** C source files, one is a linker **.ld** file, and one is a **Makefile** which contains the rules for compiling the code.

First, here is the memory mapping for nRF52832 chip:

![](/images/2018/09/Photo%20from%20datasheet.png)

Let's take a look at the linker script first. It starts with the `MEMORY` directive first, and we have two regions in the memory map of the microcontroller enumerated here, which their start address and lengths. 

Next is the `SECTIONS` directive, where we specify how 'memory sections' in our code are organized. A memory section or a section name is something given by the compiler to chunks of compiled code, depending on what it is. For example, you can see `.text`, which is for compiled machine code, and for which the logical location to place in, is the `FLASH` memory, because that's where we are executing code from. The `.data` section contains static data that was in the code, for example, a global (i.e. file scope) variable `int a = 10`.

File: `linker.ld`:
<script src="https://gist.github.com/ntavish/1a6f8c1e670d746b36629f051d4e1921.js"></script>

Here is our Startup code, which according to the ARM manual, has the stack top address, and the reset vector address, which will be out c startup code. Our C startup code copies the initialization values of variables in `.data` section from the LMA (load memory address) which is located right after the end of `.text` (we have a label there called `_etext`). See:

<div class="preformatted">
    .data : AT ( _etext ) {
    ..
    ..
    } >RAM

</div>

And the relevant code in the startup file is:
    
<div class="preformatted">
    src = &_etext;
    dst = &_sdata;
    while(dst < &_edata) 
            *(dst++) = *(src++);

</div>

The symbols `_etext` and `_sdata` are exported by the linker, as whatever their address is in the linker file.

In our case, the LMA will be determined during linking, but the VMA (virtual memory address) can be manually determined though, and it is `0x20000000`, because this is the first section placed inside `RAM`, and so the counter for `RAM` is at 0 right now.

Similarly our C startup code has to set 0 to all non initialized static / global variables. See:

<div class="preformatted">
    .bss : {
    ..
    ..
    } >RAM

</div>

This section simply is placed in `RAM`, and also initialized to zero. Since we already know the initialization value to be zero, we do not need an LMA chunk with a bunch of zeros. We can just do :

<div class="preformatted">
    src = &_sbss;
    while(src < &_ebss) 
            *(src++) = 0;

</div>


File `startup.c`:
<script src="https://gist.github.com/ntavish/156adfa69bfd500b429a635bbe9af0b3.js"></script>

If you see the variable `vectors` (whose section we have set to `.isr_vectors`), you will see the first element (a pointer, which will be 32-bit) is set to `STACK_TOP` which we have set to `(void *)0x20005000`. So the stack pointer starts at this value, and it decrements as things are pushed onto it until it collides with the bss/data section, which is called stack overflow.

Next element is and should be the address which is loaded into the `PC` register, essentially meaning the reset vector or the address at which code starts executing. In our case, it is the `c_startup` function's address.

After initialization, we jump to `main()` function.

File `main.c`:
<script src="https://gist.github.com/ntavish/3a8f717bef4f3d125bdc388a28ffdbff.js"></script>

In this file we are setting a GPIO pin with an LED as an output pin, and then toggling it, giving delays in between with a long for loop. Relevant register addresses from nRF52832 datasheet:

![](/images/2018/09/2018-09-09-02-56-50.png)

![](/images/2018/09/2018-09-09-02-58-52.png)

Here's the `Makefile` we use to compile this:
<script src="https://gist.github.com/ntavish/a0bba0f4924a71c2f12524f30aa3f7d7.js"></script>


## Compilation and Intermediates 

The general comppilation process for C code is preprocess->compile->assemble->link.

<div class="preformatted">
    gcc -E # stop at preprocessor stage
    gcc -S # stop at assembly output
    gcc -c # compile, don't link
    objdump -D # to dissassemble ELF file, some information about ELF format. 
               # .o, .out, .elf are all in this same ELF format.

</div>

## Various types of files - hex, bin, .ld, .map etc.

*Note:* All of the following information is better available in the GCC tools documentation.

In the above simple Makefile based project, apart from the Makefile and the .c file, we also had a .ld file, which we passed to the linker. 

The linker script basically tells how to map the sections in the code to the output/linked binary. At the linker stage of compilation, we have to map the different sections in the object files (machine code), and into an output binary.

We compiled to a .elf, but we need either a binary file or a hex file to directly flash onto the chip's internal flash memory, from where it executes code from. `objcopy` (from gcc toolchain) is the utility which is used to generate these files. 

The .hex file we produced earlier is in intel HEX, or ihex format. It's a simple format, which basically has address and corresponding data on that address. A binary file, on the other hand is just data, it has no information about where it starts (and it cannot be 'sparse' like a .hex), so you need to know where it's start address is if you want to write it to your chip's flash.

The map file we generated earlier contains the locations and sizes of all the symbols present in our output file.

Disassembly of the compiled binary `build.elf`, using `arm-none-eabi-objdump -D build.elf`:

<script src="https://gist.github.com/ntavish/1dda4a64b9d8a30b0f034ee04c0c0b42.js"></script>

Also inspect the output of the hex file. I'm pasting the parsed hex file to clearly show address and data only. First column is address, second is length of record, 3rds is record type, and 4th is data if any:

<script src="https://gist.github.com/ntavish/2807c6f40505ef186b6f42d188f01a35.js"></script>

This is the complete code that will go onto the chip.


## Conclusion
  
If you flash the output hex file using `nrfjprog -f nrf52 --program build.hex --sectorerase` to an nrf52-DK, you should see the LED blinking.

With the included code, we now know how the linker file is used to put together the compiled code into a binary, and what minimum startup code is required for 'bootstrapping C code' / 'C runtime'. We also saw how to configure a GPIO, and how to toggle it, from looking at the register addresses in the datasheet.

This code will actually run on nRF52840 also, you just need to change the LED pin number; you can set LED to 13 in main.c to make it work.

![](/images/2018/09/nrf52_blink.jpg)