# VGA Playground simulation

`VGA_playground.v` is the whole Tiny Tapestation in one Verilog file, for the
[VGA Playground](https://vga-playground.com): paste it in to play the game in the browser.

It is generated, not edited by hand, and not committed:

- **Download it** from the latest run of the
  [simulation workflow](../../../actions/workflows/simulation.yml) (artifact `VGA_playground`),
  which builds it on every push to `main`.
- **Or build it locally:** `python3 scripts/buildsim.py` (needs PyYAML) writes
  `simulation/VGA_playground.v`.

`scripts/buildsim.py` concatenates exactly the files in `info.yaml` `source_files`, in that
order, and renames the top module (`tt_um_enjimneering_tts_top`) to `tt_um_vga_example`,
the name the playground expects. So it always matches the RTL Tiny Tapeout builds.
