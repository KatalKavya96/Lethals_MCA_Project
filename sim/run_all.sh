#!/bin/sh
# Compile and run both testbenches from the repository root:  sh sim/run_all.sh
set -e
COMMON="rtl/common/pc.v rtl/common/instr_rom.v rtl/common/data_ram.v rtl/common/out_reg.v rtl/common/rw_control.v"

# 1) unit tests for the small control modules
iverilog -Wall -o sim/tb_units.out rtl/common/pc.v rtl/common/rw_control.v \
    rtl/harvard/harvard_decoder.v rtl/shared/shared_decoder.v tb/tb_units.v
vvp -n sim/tb_units.out

# 2) Harvard design, three programs
iverilog -Wall -o sim/tb_harvard.out $COMMON \
    rtl/harvard/harvard_decoder.v rtl/harvard/harvard_ctrl.v rtl/harvard/harvard_top.v \
    tb/tb_harvard.v
vvp -n sim/tb_harvard.out

# 3) Shared-memory baseline, same three programs
iverilog -Wall -o sim/tb_shared.out $COMMON \
    rtl/shared/shared_decoder.v rtl/shared/shared_mem.v rtl/shared/shared_ctrl.v rtl/shared/shared_top.v \
    tb/tb_shared.v
vvp -n sim/tb_shared.out

echo ""
echo "Waveforms: sim/harvard.vcd and sim/shared.vcd  (open with: gtkwave sim/harvard.vcd)"
