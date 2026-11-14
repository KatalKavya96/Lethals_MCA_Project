# IEEE report: Project 9

- `report.pdf`: compiled report (IEEEtran conference format, 8 pages)
- `report.tex`: LaTeX source (`pdflatex report.tex`, run twice)
- `figures/`: every figure as PDF (used by LaTeX), PNG (300 dpi) and SVG
- `figures/src/`: TikZ sources for the diagrams. Rebuild one with `cd figures/src && sh wrap.sh block_harvard`
- `scripts/figs.py`: regenerates the waveform, bus-occupancy and chart figures from `sim/*.vcd`. Run `sh sim/run_all.sh` from the repo root first, then run `python3 scripts/figs.py` from `report/`

Every number in the report comes from `sh sim/run_all.sh` (Icarus Verilog 12) and Yosys 0.33
(`synth/*.ys`, plus `flatten; ltp -noff` for logic depth).
