# Tiny Tapestation architecture

How the chip is put together: the modules, how data flows between them, and how it meets
the Tiny Tapeout pins. The source of truth is `src/` and `info.yaml`; this page describes
the release RTL.

## At a glance

| | |
|---|---|
| Top module | `tt_um_enjimneering_tts_top` (`src/tt_um_Enjimneering_TTS.v`) |
| Clock | 25 MHz (`info.yaml` `clock_hz`): the 640x480 VGA pixel clock |
| Size | 2x2 Tiny Tapeout tiles, SKY130 (`ttsky25b`) |
| Inputs | a SNES gamepad on the Tiny Tapeout gamepad PMOD, or an NES controller |
| Outputs | VGA (2 bits per colour, Tiny VGA PMOD pinout), PWM audio |

## Data flow

```
 ui_in ──► NESTest_Top ──► InputCollector ──► PlayerLogic ─────┐
 (pads)    gamepad/NES      once per frame      player, sword   │
           receivers                                            ▼
                                     DragonTarget ──► DragonHead ──► DragonBody
                                     (where to go)    (move head)     (7 segments)
                                            ▲                              │
                                       rng (sheep position)                │
                                            │                              ▼
                       CollisionDetector ◄──┴── positions of player, sword, sheep, dragon
                       (sword/dragon, player/dragon, sheep/dragon)
                                 │
                 ┌───────────────┼──────────────────┐
                 ▼               ▼                  ▼
              Hearts       APU_trigger ──► AudioProcessingUnit ──► uio_out[7] (PWM)
              (lives)      (sound events)  (saw, noise, square)
                 │
 sync_generator ─┴──► PictureProcessingUnit (+ SpriteROM) ──► uo_out (VGA)
 (hsync, vsync, x, y,  up to 15 sprites on a tile grid
  frame_end)
```

The game logic advances once per frame. `sync_generator` raises `frame_end` at the end of
each frame; the top level delays it by two cycles (`player_trigger`, then
`collector_trigger`), so the input collector samples the controller, then the player and
dragon logic update, before the next frame is drawn.

When the player runs out of lives, `auto_rst_n` falls and resets the whole game.

## Modules

Every module is used (checked with `yosys hierarchy`). Several files hold more than one
module, and some module names differ from their file names:

| File | Module(s) | Does |
|---|---|---|
| `tt_um_Enjimneering_TTS.v` | `tt_um_enjimneering_tts_top` | the top: wiring, the frame timer, the pin mapping |
| `NESTest_Top.v` | `NESTest_Top`, `NES_Reciever`, `gamepad_pmod_single`, `gamepad_pmod_decoder`, `gamepad_pmod_driver` | reads an NES controller (drives its latch and clock) and the SNES gamepad PMOD; uses the SNES pad when present, the NES pad otherwise |
| `InputCollector.v` | `InputCollector` | turns the buttons into per-frame pressed and released events |
| `Player.v` | `PlayerLogic` | the player's position, facing and sword |
| `Heart.v` | `Hearts` | the player's lives, and the "player hurt" signal |
| `DragonTarget.v` | `DragonTarget` | chooses where the dragon heads: the player or the sheep |
| `DragonHead.v` | `DragonHead` | moves the dragon's head towards its target |
| `DragonBody.v` | `DragonBody` | the seven body segments following the head; grows when it eats a sheep, shrinks when hit |
| `RNG.v` | `rng` | a pseudo-random number generator for the sheep's position |
| `CollisionDetector.v` | `CollisionDetector`, `Comparator` | sword/dragon, player/dragon and sheep/dragon collisions |
| `Sync.v` | `sync_generator` | VGA timing: `hsync`, `vsync`, the pixel counters, `frame_end` |
| `PPU.v` | `PictureProcessingUnit` | the picture processing unit: draws up to 15 entities (`entity_1`..`entity_15`, 18 bits each) |
| `SpriteROM.v` | `SpriteROM` | the sprites' bitmaps, with rotation and flipping |
| `APUTrigger.v` | `APU_trigger` | turns collisions into sound events |
| `APU.v` | `AudioProcessingUnit` | the audio processing unit: saw, noise and square voices mixed to one PWM bit |
| `Oscillator.v` | `Osc_Counter` | the APU's oscillator |

## Pinout

From `info.yaml`:

| Pin | Signal | Pin | Signal |
|---|---|---|---|
| `ui[0]` | NES controller data | `uo[0]` | R high bit |
| `ui[4]` | SNES PMOD latch | `uo[1]` | G high bit |
| `ui[5]` | SNES PMOD clock | `uo[2]` | B high bit |
| `ui[6]` | SNES PMOD data | `uo[3]` | VSYNC |
| `uio[1]` | NES controller clock (output) | `uo[4]` | R low bit |
| `uio[2]` | NES controller latch (output) | `uo[5]` | G low bit |
| `uio[7]` | PWM audio (output) | `uo[6]` | B low bit |
| | | `uo[7]` | HSYNC |

`uo` follows the Tiny VGA PMOD pinout; `ui[4:6]` follow the Tiny Tapeout gamepad PMOD.

## Where it runs

| Target | How |
|---|---|
| The chip | Tiny Tapeout GDS action (`.github/workflows/gds.yaml`), `src/config.json` |
| A browser | the VGA Playground: `scripts/buildsim.py` ([simulation/](../simulation/README.md)) |
| An FPGA | Digilent Nexys A7: [fpga/nexys-a7/](../fpga/nexys-a7/README.md) |
| Simulation | cocotb on Icarus Verilog: `test/` |
