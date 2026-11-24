# Tiny Tapestation on the Nexys A7

Runs the Tiny Tapestation chip RTL (`../../src`, exactly the files in `info.yaml`) on a
Digilent **Nexys A7** (also sold as the Nexys 4 DDR), with a VGA monitor, a SNES gamepad on
the Tiny Tapeout gamepad PMOD or an NES controller, and audio.

| File | What |
|---|---|
| `tts_fpga_top.v` | `TTS_FPGA_top`: the board wrapper around `tt_um_enjimneering_tts_top` |
| `nexys_a7.xdc` | pin constraints |
| `clk_wiz.tcl` | generates `clk_wiz_0`: 100 MHz board clock to the chip's 25 MHz |
| `build.tcl`, `Makefile` | non-project Vivado build |
| `test_modules/GamepadEmulator.v` | from the Sheffield-TTX FPGA branch: turns button inputs into an NES serial stream. Not part of the build |

## Build

Needs Vivado on `PATH` and Python 3 with PyYAML.

```bash
make bit                          # Nexys A7-100T: build/tts_nexys_a7.bit
make bit PART=xc7a50tcsg324-1     # Nexys A7-50T
```

Then program the board with the Vivado hardware manager (`build/tts_nexys_a7.bit`). Timing
and utilisation reports are in `build/`.

## Connections

| Signal | Pin | On the board |
|---|---|---|
| `CLK` | E3 | 100 MHz oscillator |
| `RST_N` | J15 | switch SW0 (up = run) |
| `R[3:0]`, `G[3:0]`, `B[3:0]`, `H_SYNC`, `V_SYNC` | A3-D8, B11, B12 | VGA port. The chip has 2 bits per colour; each bit drives two of the board's 4 |
| `SNES_PMOD_Latch`, `SNES_PMOD_Clk`, `SNES_PMOD_Data` | D17, E17, F18 | PMOD JA, bottom row (pins 7, 8, 9): the gamepad PMOD |
| `NES_DATA`, `NES_LATCH`, `NES_CLK` | H1, G1, G3 | PMOD JD pins 2, 3, 4: an NES controller wired directly |
| `PWM` | E6 | PMOD JC pin 10: the chip's sound output |
| `aud_sd_o` | D12 | the on-board audio amplifier's shutdown, held high (on) |
| `CONTROLLER_LED[4:0]` | V11-T16 | LEDs 15-11: A, up, down, left, right |
| `test_switchs[2:0]` | R15, M13, L16 | switches; not used by the wrapper |

Check the PMOD pin numbers against Digilent's Nexys A7 master XDC before wiring.

## Known issues

- **Audio pin:** the wrapper's comment says the PWM goes to A11 (the on-board headphone
  jack), but `nexys_a7.xdc` puts it on E6 (PMOD JC). To use the jack, change the `PWM`
  constraint to `A11`.
- **LEDs:** `CONTROLLER_LED` reads signals inside the chip by hierarchical reference
  (`tts.A_out`, ...). Yosys cannot resolve these, and Vivado may not either. If synthesis
  rejects them, delete the `CONTROLLER_LED` assignment and its constraints: the game does
  not need them.
- `clk_wiz_0` makes exactly 25 MHz; 640x480 VGA expects 25.175 MHz, which most monitors
  accept.
