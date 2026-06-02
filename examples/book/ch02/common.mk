# examples/book/ch02/common.mk
# Common simulation and synthesis targets.
# Usage in each example's Makefile:
#   TOP := module_name
#   SRC := source.v [more.v ...]
#   TB  := tb_source.v
#   include ../common.mk

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
YOSYS    ?= yosys

SIM_FLAGS := -Wall -g2012

.PHONY: sim wave synth clean

sim: $(TOP).vcd

$(TOP).vcd: $(SRC) $(TB)
	$(IVERILOG) $(SIM_FLAGS) -o $(TOP).vvp $(TB) $(SRC)
	$(VVP) $(TOP).vvp

wave: $(TOP).vcd
	$(GTKWAVE) $(TOP).vcd &

synth: $(SRC)
	$(YOSYS) -p "read_verilog $(SRC); synth_ice40 -top $(TOP); stat"

clean:
	rm -f *.vvp *.vcd *.json *.asc *.blif
