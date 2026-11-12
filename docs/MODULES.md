# Module walkthrough

One section per work package. Before the owner commits a module, they should be able to explain every line
of it without notes. The "why" lines are the design decisions most likely to be questioned.

Instruction word: `{opcode[31:28], imm[27:8], addr[7:0]}`

| Op | Name | Action | Data memory? |
|---|---|---|---|
| 0 | NOP | nothing | no |
| 1 | LOAD | acc <- mem[addr] | read |
| 2 | STORE | mem[addr] <- acc | write |
| 3 | LDI | acc <- imm | no |
| 4 | ADD | acc <- acc + mem[addr] | read |
| F | HALT | done <- 1, PC stops | no |

## WP1 Memories: `instr_rom.v`, `data_ram.v`, `out_reg.v`, `shared_mem.v`, `programs/*.hex`

- `data_ram` is the register-file lab pattern: write on the clock edge, read combinationally.
- **Why combinational read?** So the Harvard design can fetch, decode and access data in one cycle.
  The cost: FPGA block RAM reads on a clock edge, so these memories synthesise to flip-flops (see results.md).
- **Why no HALT pre-fill loop in the ROM?** Yosys applies `$readmemh` before the loop, so the synthesised ROM
  would hold only HALT words. Simulation would not show the bug.
- `shared_mem` is the same array with one port. Program at 0x00-0x7F, data at 0x80 and above.
- `out_reg` is a memory-mapped output: a STORE to offset 0x70 lands here and drives the `out` port.

## WP2 Control glue: `pc.v`, `rw_control.v`, `harvard_decoder.v`, `shared_decoder.v`, `tb/tb_units.v`

- `pc` is the synchronous counter lab with an enable. It holds on HALT.
- `rw_control` turns an opcode into `mem_rd` / `mem_wr`. `active` forces both low during reset and after HALT.
  The shared design uses it twice: once to ask "does the fetched instruction need the port again?",
  once to drive the real strobes in EXEC.
- Data address map (same in both designs):

| Offset | Harvard | Shared (absolute = 0x80 + offset) |
|---|---|---|
| 0x00-0x6F | data RAM | 0x80-0xEF data RAM |
| 0x70 | OUT register | 0xF0 OUT register |
| 0x71-0xFF | unmapped, write ignored, read 0 | 0xF1-0xFF and wrap into 0x00-0x7F: blocked |

- **Why block writes to 0x00-0x7F in the shared decoder?** Offset 0x90 + 0x80 wraps to 0x10, which is inside the
  program. Without the block, a program could overwrite its own instructions. P3 tests this.
- **Why is there no decoder on the Harvard instruction side?** Anything shared between the fetch path and the data
  path would bring back the bottleneck we are removing.

## WP3 Harvard core: `harvard_ctrl.v`, `harvard_top.v`

- One cycle per instruction. In the same clock period the PC addresses `instr_rom` (instruction bus) and the
  decoded `addr` field addresses `data_ram` (data bus). Two memories, two address buses.
- Decode is combinational. The only clocked state is `acc`, `done` (here) and the PC (in `pc.v`).
- At the edge that ends a LOAD/ADD, `acc` captures `d_rdata`. A STORE writes `acc` into RAM at the same edge.
- Waveform to show: `i_addr` advances on every edge while `mem_rd` / `mem_wr` are high in the same cycles.

## WP4 Shared baseline: `shared_ctrl.v`, `shared_top.v`

- 2-state FSM, FETCH and EXEC, on ONE port. `m_addr` is the PC in FETCH and `0x80 + ir[7:0]` in EXEC.
- NOP, LDI and HALT complete in FETCH. LOAD, STORE and ADD need EXEC because the port is busy fetching.
- **Why not always do FETCH + EXEC?** That charges the baseline for data accesses it does not need and makes
  the speed-up a fixed 2x by construction. The fair version gives cycles = N + M.
- Waveform to show: `state` toggling 0/1 only around memory instructions, `m_addr` switching between PC values
  and 0x8x addresses.

## WP5 Verification and results: `tb/tb_harvard.v`, `tb/tb_shared.v`, `sim/run_all.sh`, `synth/*.ys`

- Each testbench runs P1, P2, P3 on three copies of the design at once and checks final RAM, OUT, acc,
  the blocked write and the cycle count.
- Cycle counting rule (identical in both): count each rising edge while out of reset and not done. HALT counts.
- `sim/harvard.gtkw` and `sim/shared.gtkw` open GTKWave with the right signals already added:
  `gtkwave sim/harvard.gtkw`.
- Synthesis scripts give generic cell counts only. No Fmax until a real FPGA flow is run (Phase II).
