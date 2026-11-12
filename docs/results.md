# Preliminary results (Phase I)

All numbers below come from `sh sim/run_all.sh` (Icarus Verilog) and `yosys -s synth/synth_<design>.ys`
(Yosys 0.33, generic synthesis). Re-run them on your own machine before quoting them in the report.

## Functional tests

| Testbench | Checks | Result |
|---|---|---|
| `tb_units.v` | rw_control for all 6 opcodes, both decoders at every boundary address, PC reset/count/hold | all PASS |
| `tb_harvard.v` | final RAM contents, OUT register, accumulator, blocked write to 0x90, cycle count, for P1 to P3 | all PASS |
| `tb_shared.v` | the same checks on the shared-memory baseline (data at 0x80 + offset) | all PASS |

Both designs produce identical final data, OUT and accumulator values on all three programs.

## Cycle counts

N = instructions executed (HALT included), M = instructions that touch data memory (LOAD, STORE, ADD),
f = M / N. Predicted: Harvard = N, shared = N + M, speed-up = 1 + f.

| Program | N | M | f | Harvard cycles (measured) | Shared cycles (measured) | Speed-up |
|---|---|---|---|---|---|---|
| P1 block copy | 18 | 13 | 0.72 | 18 | 31 | 1.72x |
| P2 array sum | 16 | 11 | 0.69 | 16 | 27 | 1.69x |
| P3 compute-heavy | 16 | 4 | 0.25 | 16 | 20 | 1.25x |

Every measured count matches the prediction exactly. The speed-up is not a fixed 2x: it grows with the
fraction of instructions that need the data bus, which is exactly the "simultaneous access opportunity"
the Harvard design exploits. A program with no data accesses would show no speed-up at all.

## Generic synthesis (cell counts only, program P2)

| Module | Harvard cells | Shared cells |
|---|---|---|
| Memory | data_ram 16 912 (8 192 flip-flops) + instr_rom 39 | shared_mem 16 912 (8 192 flip-flops) |
| Controller | harvard_ctrl 384 | shared_ctrl 368 |
| Decoder | 15 | 16 |
| PC, OUT register, rw_control (x2 in shared), top-level glue | 131 | 175 |
| **Total** | **17 481** | **17 471** |

What these numbers mean, and what they do not:

- Both totals are dominated by a 256 x 32-bit memory built from 8 192 flip-flops. That happens because the
  memories read combinationally (no clock). FPGA block RAM reads on a clock edge, so a combinational-read
  memory cannot be mapped to it. This is the price of the one-cycle Harvard design and a Phase II item.
- The Harvard instruction ROM costs only 39 cells because the program is a constant and the tool folds it
  into logic. In the shared design the program sits in writable memory, so it costs flip-flops instead.
- These are technology-independent counts, not FPGA LUT/BRAM figures, and they give **no maximum frequency**.
  Fmax needs place-and-route on a chosen FPGA with a clock constraint: planned for Phase II.

## Finding worth reporting

An earlier version pre-filled the instruction memory with HALT in a `for` loop before `$readmemh`.
Simulation was correct, but Yosys applied `$readmemh` first and the loop afterwards, so the synthesised ROM
contained only HALT words and was optimised to 0 cells. The loop was removed. This is a real
simulation/synthesis mismatch and the reason the report should never quote synthesis numbers without
checking they are plausible.
