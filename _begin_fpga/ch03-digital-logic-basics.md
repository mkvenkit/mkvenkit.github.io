---
title: "Digital Logic Basics"
description: "Logic gates, Boolean algebra, truth tables, and the combinational circuits that form an FPGA's fundamental building blocks."
chapter_num: 3
prev_url: /begin-fpga/ch02-digital-design-with-verilog/
prev_title: "Digital Design with Verilog"
next_url: /begin-fpga/ch04-fpga-architecture/
next_title: "FPGA Architecture"
published: false
---

## Binary and Logic Levels

Every signal inside a digital circuit is either **high** (logic 1, typically 3.3 V or 1.8 V) or **low** (logic 0, typically 0 V). There is no in-between in the digital abstraction — the analog world's messy voltages are reduced to a single bit.

This binary representation is why digital design maps so cleanly to mathematics. Two voltage levels correspond to two Boolean values: TRUE and FALSE, 1 and 0. Boolean algebra — a branch of mathematics developed by George Boole in the 1840s — turns out to be exactly the right tool for reasoning about circuits.

## Logic Gates

Logic gates are the fundamental building blocks of every digital circuit, including the inside of an FPGA. Each gate takes one or more binary inputs and produces a binary output according to a fixed rule.

### AND Gate

The AND gate outputs 1 only when **all** inputs are 1.

| A | B | A AND B |
|---|---|---------|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

In Boolean notation: `Y = A · B` (or `Y = AB`).

### OR Gate

The OR gate outputs 1 when **at least one** input is 1.

| A | B | A OR B |
|---|---|--------|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

Notation: `Y = A + B`.

### NOT Gate (Inverter)

The NOT gate inverts its single input.

| A | NOT A |
|---|-------|
| 0 | 1 |
| 1 | 0 |

Notation: `Y = Ā` or `Y = ~A`.

### NAND and NOR Gates

**NAND** is AND followed by NOT. **NOR** is OR followed by NOT. These are particularly important because any logic function can be built entirely from NAND gates alone — or entirely from NOR gates alone. This property is called *functional completeness* and is why early ICs like the 7400-series TTL chips were so popular.

### XOR Gate (Exclusive OR)

The XOR gate outputs 1 when its inputs *differ*.

| A | B | A XOR B |
|---|---|---------|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

Notation: `Y = A ⊕ B`. XOR is the backbone of adders and error detection circuits.

## Boolean Algebra

Boolean algebra has a set of laws that let you simplify logic expressions, which in turn reduces the number of gates you need in a design. The most useful rules are:

**Identity laws:**
- `A + 0 = A`
- `A · 1 = A`

**Null laws:**
- `A + 1 = 1`
- `A · 0 = 0`

**Idempotent laws:**
- `A + A = A`
- `A · A = A`

**Complement laws:**
- `A + Ā = 1`
- `A · Ā = 0`

**De Morgan's Theorems** are especially powerful:
- `NOT(A AND B) = (NOT A) OR (NOT B)` → `A̅·̅B̅ = Ā + B̄`
- `NOT(A OR B) = (NOT A) AND (NOT B)` → `A̅+̅B̅ = Ā · B̄`

De Morgan's laws let you push inversions through gates and swap AND/OR, which is essential when mapping logic to NAND/NOR-only implementations.

## Combinational vs Sequential Logic

Digital circuits divide neatly into two families.

### Combinational Logic

In a combinational circuit, the output depends **only on the current inputs**. There is no memory. Given the same inputs, you always get the same outputs. Combinational circuits are described entirely by truth tables.

Examples: adders, multiplexers, decoders, comparators.

### Sequential Logic

In a sequential circuit, the output depends on **current inputs *and* past state**. Sequential circuits have memory elements — flip-flops — that capture state on a clock edge and hold it until the next clock edge.

Examples: counters, registers, state machines, RAM.

Inside an FPGA, both families coexist. The LUTs (which we'll cover next chapter) implement combinational logic; the flip-flops hold state between clock cycles.

## Key Combinational Circuits

### Half Adder

A half adder adds two 1-bit numbers and produces a Sum and a Carry:

```
Sum   = A XOR B
Carry = A AND B
```

### Full Adder

A full adder also accepts a carry-in from a previous stage:

```
Sum   = A XOR B XOR Cin
Cout  = (A AND B) OR (Cin AND (A XOR B))
```

Chain N full adders together and you have an N-bit ripple-carry adder — the simplest multi-bit adder architecture.

### Multiplexer (MUX)

A 2-to-1 MUX selects one of two inputs based on a select signal:

```
Y = (SEL AND B) OR (NOT SEL AND A)
```

Multiplexers are everywhere in FPGAs — the routing fabric itself is built from them.

### Decoder

A 2-to-4 decoder takes a 2-bit binary input and asserts exactly one of four output lines. Decoders are used for address decoding, memory chips, and display drivers.

## Timing in Combinational Circuits

Gates are not instantaneous — each one has a small propagation delay (typically tens of picoseconds to a few nanoseconds). When a signal passes through several gates in series, the delays accumulate. The longest path through a combinational block is called the **critical path**, and its total delay is the minimum clock period your circuit can use.

This is why synthesis tools perform **timing analysis**: they identify critical paths and tell you the maximum clock frequency your design can achieve. Understanding propagation delay now will make timing closure much less mysterious when you reach Chapter 7.

## Summary

Digital logic reduces the analog world to binary values and manipulates them with logic gates. AND, OR, NOT, NAND, NOR, and XOR are the basic operations; Boolean algebra provides rules to simplify expressions. Combinational circuits produce outputs purely from current inputs; sequential circuits add memory via flip-flops. Key building blocks like adders and multiplexers will appear repeatedly in every design you write.

Next we'll go inside the FPGA itself and see exactly how these gates and flip-flops are implemented in programmable silicon.
