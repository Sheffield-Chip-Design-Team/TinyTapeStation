<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

TapeStation is played using a SNES or NES controller connected to the gamepad peripheral. The gamepad peripheral reads the controller’s digital inputs and exposes them to the core, which maps buttons to game actions and supports standard retro layouts and simple remapping. 

The Console has a single pre-loaded game called 'Gnome Knight'. The aim of Gnome Knight is to defeat a serepentine dragon terrorising your village. With your trusty sword, smite the dragon (A button) and avoid his cunning attacks (D-pad) to protect the village's sheep and restore peace to the land.


The combination of authentic controller input, low‑latency VGA video, and discrete sound output provides a complete retro gaming experience!

## How to test

- Connect the SNES/NES controller to the gamepad PMOD port.  
- Connect the VGA peripheral cable to a monitor.  
- Connect audio output from the sound peripheral to speakers or an amp.  
- Power the system; the core detects peripherals, and uses the controller inputs for play.  

## External hardware

- **Controller**, one of:
  - a SNES-compatible gamepad on the [Gamepad PMOD](https://github.com/psychogenic/gamepad-pmod) (`ui[4]` latch, `ui[5]` clock, `ui[6]` data);
  - an NES controller wired directly: data to `ui[0]`, clock from `uio[1]`, latch from `uio[2]`.

  The SNES gamepad is used when it is present, the NES controller otherwise.
- **Display:** a VGA monitor through the [Tiny VGA PMOD](https://github.com/mole99/tiny-vga) on the `uo` pins.
- **Sound:** an amplifier or speaker on `uio[7]` (PWM), for example through an RC low-pass filter or an audio PMOD.

See [architecture.md](architecture.md) for the full pinout and how the chip works.
The VGA peripheral outputs 640x480, 60fps video at to any compatible monitor. 
The audio peripheral provides analogue audio (mono/stereo) to an on-board buzzer or 3.5mm headphone jack.
