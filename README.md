![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/simulation/badge.svg)

# The Tiny Tapestation

A retro games console on a chip: a [Tiny Tapeout](https://tinytapeout.com) project by
SHaRC, the University of Sheffield's chip design team. It plays one game, *Gnome Knight*:
defeat the serpentine dragon terrorising your village with your trusty sword (A button),
dodge its attacks (D-pad), and protect the village's sheep.

The chip reads a SNES gamepad (through the Tiny Tapeout gamepad PMOD) or an NES controller,
draws the game on a VGA monitor at 640x480, and plays sound effects through a PWM audio
output. It runs at 25 MHz in 2x2 tiles of the Tiny Tapeout SKY130 shuttle (`ttsky25b`).

- **Play it in the browser:** the [VGA Playground](https://vga-playground.com) runs the whole
  chip ([simulation/](simulation/README.md)).
- **How it works:** [docs/architecture.md](docs/architecture.md): the modules, the data
  flow, the pinout.
- **Datasheet:** [docs/info.md](docs/info.md) (used by Tiny Tapeout).

## Repository layout

```
src/                    the chip's RTL: exactly the files info.yaml lists (source_files)
  tt_um_Enjimneering_TTS.v   top module tt_um_enjimneering_tts_top
  config.json                LibreLane hardening configuration
info.yaml               Tiny Tapeout project description: top module, sources, tiles, pinout
test/                   cocotb tests on Icarus Verilog
  top/                       the whole chip
  unit/<module>/             one directory per unit test (apu, collector, ppu, receiver, sync)
  Makefile, run_tests        run them; create_test makes a new one
scripts/                Python helpers
  buildsim.py                builds the VGA Playground file from info.yaml
  regress.py, instantiate.py, parse.py, setup_test.py    used by test/run_tests and create_test
simulation/             the generated VGA Playground file (not committed; see its README)
fpga/nexys-a7/          the chip on a Digilent Nexys A7 board (Vivado)
docs/                   the datasheet and the architecture notes
.github/workflows/      gds (harden, precheck, gate-level test, viewer), docs, test, simulation
```

## Testing

Needs Icarus Verilog and Python 3.11+:

```bash
sudo apt-get install -y iverilog
pip install -r test/requirements.txt

cd test
make                        # every test: top level, then each unit
./run_tests sim             # the same through the runner script
./run_tests regress -runs 5 -width 4      # repeated randomised runs in parallel
./create_test -h            # set up a cocotb test for a new module
```

Each test writes its log to `test/<dir>/sim/latest.log`. The `test` workflow runs them on
every push.

## The VGA Playground

```bash
pip install pyyaml
python3 scripts/buildsim.py     # -> simulation/VGA_playground.v
```

Paste the file into [vga-playground.com](https://vga-playground.com). The `simulation`
workflow builds the same file on every push to `main` (artifact `VGA_playground`).

## FPGA

`fpga/nexys-a7/` runs the same RTL on a Nexys A7: `make -C fpga/nexys-a7 bit` with Vivado
on `PATH`. See [its README](fpga/nexys-a7/README.md) for the connections.

## Tiny Tapeout

Every push runs the Tiny Tapeout GDS action (hardening with LibreLane, precheck,
gate-level test and the layout viewer on GitHub Pages) and builds the datasheet.

## Credits

James Ashie Kotey, Bowen Shi, Kwashie Andoh, Anubhav Avinash, Abdulatif Babli, Rupert
Bowen, K Arjunan and Cameron Brizland, with the SHaRC team.

The project began in 2024 in
[Sheffield-TTX](https://github.com/Sheffield-Chip-Design-Team/Sheffield-TTX) (Tiny Tapeout
10). This repository restarted it in November 2025 for the SKY25b shuttle; its RTL
supersedes Sheffield-TTX's.

## License

[Apache-2.0](LICENSE).
