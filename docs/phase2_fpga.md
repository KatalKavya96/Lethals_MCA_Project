# Phase II: FPGA timing and resources

Reproduce with `sh synth/run_fpga.sh` (Yosys 0.33, nextpnr-ecp5 0.6). Target: Lattice ECP5-25F, CABGA256,
50 MHz clock constraint, program P2, placement seeds 1 to 5. Logs: `synth/reports/`.
The RTL is unchanged from Phase I.

## Maximum frequency (post-route, 5 seeds)

| Design | Seed 1 | 2 | 3 | 4 | 5 | Mean |
|---|---|---|---|---|---|---|
| Harvard | 56.12 | 54.02 | 57.89 | 55.54 | 53.78 | **55.5 MHz** (period 18.0 ns) |
| Shared | 75.11 | 70.00 | 75.22 | 71.17 | 71.30 | **72.6 MHz** (period 13.8 ns) |

The Harvard clock is about 24% slower. Its critical path chains both memories in one cycle:
PC register -> instruction ROM (block RAM, 5.6 ns clock-to-out) -> decode / address compare -> data RAM read
(distributed RAM) -> adder -> accumulator. The shared design splits fetch and data access over two cycles,
so neither cycle contains both memory reads.

## Execution time = cycles / Fmax (mean Fmax)

| Program | f = M/N | Harvard | Shared | Speed-up (cycles) | Speed-up (time) |
|---|---|---|---|---|---|
| P1 block copy | 0.72 | 18 cyc = 324 ns | 31 cyc = 427 ns | 1.72x | **1.32x** |
| P2 array sum | 0.69 | 16 cyc = 288 ns | 27 cyc = 372 ns | 1.69x | **1.29x** |
| P3 compute-heavy | 0.25 | 16 cyc = 288 ns | 20 cyc = 276 ns | 1.25x | **0.96x** |

Model: speed-up in time = (1 + f) x (Fmax_H / Fmax_S) = (1 + f) / 1.31.
Harvard wins only when f > about 0.31. On P3 the shared design is faster.

## Resources (ECP5-25F, program P2)

| | Harvard | Shared |
|---|---|---|
| LUT4 | 917 | 1 453 |
| Flip-flops | 73 | 86 |
| Distributed RAM (TRELLIS_DPR16X4, 16x4 each) | 64 | 128 |
| Block RAM (DP16KD) | 1 | 0 |
| Logic slices used (TRELLIS_COMB) | 1 363 / 24 288 (5%) | 2 271 / 24 288 (9%) |

How to read this honestly:
- Harvard ROM in block RAM: block RAM reads on a clock edge. Yosys made the asynchronous ROM fit by absorbing
  the PC register into the block RAM's address register. Behaviour is unchanged.
- Harvard data RAM is half the size of the shared memory (64 vs 128 LUT-RAM cells). The program is a
  constant, so Yosys can see that only some data addresses are ever used and drops the rest. The Harvard
  area is therefore specialised to P2. The shared memory holds a writable program, so it cannot be pruned.
- iCE40 HX8K (no distributed RAM): Harvard fits (2 110 / 7 680 logic cells). The shared design does not
  (15 143 / 7 680, 197%), because its asynchronous-read 256 x 32 memory has to be built from flip-flops.

## Still open (future work)

Synchronous-read memories that map to block RAM in both designs. These would change the cycle model: a
one-cycle Harvard needs a read-ahead fetch or a pipeline. Also multi-cycle memory latency, the optional
shared lower-level memory, and a dual-ported shared baseline.
