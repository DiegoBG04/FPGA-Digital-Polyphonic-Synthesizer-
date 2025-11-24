# FPGA Digital Synthesizer

A polyphonic digital sound synthesizer implemented on the Terasic DE1-SoC board using Verilog HDL.  
Supports multiple waveforms, octave shifting, envelope control (attack/release), and PS/2 keyboard input used as a MIDI-style controller.

---

## Features

- 🎹 **Polyphony** – play multiple notes at once
- 🎛 **Waveforms** – square, saw, triangle, noise (replace with what you actually have)
- ⏱ **Octave control** – shift notes up/down via switches
- 📈 **ADSR-style envelope** – attack / sustain / release shaping
- ⌨️ **PS/2 keyboard input** – map keys to musical notes
- 🔊 **Audio output** – I²S audio codec on the DE1-SoC

---

## Hardware & Tools

- **Board:** Terasic DE1-SoC (Cyclone V)
- **Language:** Verilog HDL
- **Tools:** Intel Quartus Prime, ModelSim
- **Peripherals:**
  - PS/2 keyboard
  - On-board audio codec / line-out

---

## Repository Structure

```text
.
├── src/                 # Verilog source code
│   ├── synth_top.v      # Top-level module
│   ├── waveform_generator.v
│   ├── synth_controller.v
│   ├── key_to_tick_converter.v
│   └── sound_modules/   # Mixers, envelope, etc.
├── report/
│   └── FPGA_Synth_Report.pdf
├── midi-parser/         # (or ps2-controller/) support code if applicable
├── LICENSE
└── README.md
