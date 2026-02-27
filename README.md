# FPGA Digital Synthesizer

A polyphonic digital sound synthesizer implemented on the Terasic DE1-SoC board using Verilog HDL.  
Supports **multiple waveforms**, **octave shifting**, **envelope control (attack/release)**, and **PS/2 keyboard input** used as a MIDI-style controller.

**Note**  
Video Demostration available on YouTube. Link available in 'About' section of this page.

**Update**
Code files made unavailable due to project policies at the University of Toronto

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

 ## Instructions Manual
Follow the following steps to implement, test and run this program on your FPGA board.
1. Download .v files in src folder repository
2. Create a Quartus Prime project and select your FPGA board
3. Import the v files for the project
4. Import the correct pin assignments for your specific FPGA board
5. Compile the program
6. Run through the Quartus Programmer
7. Connect a PS/2 keyboard to the PS/2 input
8. Connect a speaker to the audio-out pin on the board

After completing these steps, you should have a working digital synthesizer

## Controls

**Musical Keyboard:**
'A' to ';' keys represent the white keys on the piano, 'W','E','T','Y','U','O','P' represent the black keys on the piano

**Octave shift:**
Press 'Z' to lower the piano by one octave.
Press 'X' to raise the piano by one octave.

**Waveform Selection and Mixer**
Press KEY1 to view selected waveforms and mix on the hex displays.    
HEX5 & HEX4 represent waveform 1.    
HEX1 & HEX0 represent waveform 2.  
HEX3 & HEX2 represent mix percentage.  
Available waveforms are:  
 - Saw Wave (00)  
 - Pulse Wave (01)  
 - Triangle Wave (10)  
 - Square Wave (11)  

Press 'left' and 'right' arrows to cycle through selected waveform 1  
Press 'up' and 'down' arrows to cycle through selected waveform 2  

Control mix with '-' & '+' keys. (100 will only play waveform 2, 0 will only play waveform 1. Mix between)  

**ASR Modulation**  
Press KEY2 to view ASR values on the hex displays.  
HEX5 & HEX4 represent attack time (hex number is a tenth of the attack time. 10 will be 100ms, 20 will be 200ms etc)  
HEX3 & HEX2 represent sustain level (volume percentage)  
HEX1 & HEX0 represent release time(hex number is a tenth of the release time. 10 will be 100ms, 20 will be 200ms etc)  

Press 'Insert' & 'Delete' keys to adjust attack time.  
Press 'Home' & 'End' keys to adjust sustain level.  
Press 'Pg Up' & 'Pg Down' keys to adjust release time.  

**Reset**  
Press KEY0 to reset all values to their default state  


