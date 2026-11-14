#!/bin/sh
# Phase II: place-and-route both designs on a Lattice ECP5-25F (CABGA256) and report Fmax.
# Needs yosys (0.33 used) and nextpnr-ecp5 (0.6 used): apt install yosys nextpnr-ecp5,
# or the OSS CAD Suite on macOS. Run from the repository root:  sh synth/run_fpga.sh
# Fmax depends on the placement seed, so each design is routed with 5 seeds.
set -e
mkdir -p synth/reports
for d in harvard shared; do
  yosys -q -s synth/fpga_${d}_ecp5.ys > synth/reports/${d}_yosys.log
  for s in 1 2 3 4 5; do
    nextpnr-ecp5 --25k --package CABGA256 --freq 50 --lpf-allow-unconstrained \
      --seed $s --json synth/reports/${d}_ecp5.json > synth/reports/${d}_pnr_seed$s.log 2>&1
    # the last "Max frequency" line is the post-route figure
    echo "$d seed $s: $(grep 'Max frequency' synth/reports/${d}_pnr_seed$s.log | tail -1 | sed 's/.*: //')"
  done
done
