# Verilog-Digital-Design

# Verilog Digital Design Projects

This repository contains a collection of digital logic circuits designed and verified in Verilog using EDA Playground for simulation.

---

## 1. UART (Universal Asynchronous Receiver-Transmitter)

### Project Summary
This project is a complete implementation of a UART communication protocol in Verilog. It includes a transmitter module (`uart_tx`) and a receiver module (`uart_rx`) that work together to send and receive data serially. The design was verified with a Verilog testbench in a loopback configuration.

This project demonstrates a strong understanding of:
* Finite State Machines (FSMs) for protocol management.
* Serial communication principles.
* Timing and synchronization using baud rate generation.
* Hardware verification and debugging.

### Features
* **Protocol:** 8-N-1 (8 Data Bits, No Parity, 1 Stop Bit)
* **Baud Rate:** Parameterized (tested at 9600 baud with a 50MHz clock)
* **Modules:** Independent Transmitter and Receiver
* **Verification:** Loopback testbench that sends and verifies multiple data bytes.

### Simulation Waveform
Here is a screenshot from the EPWave simulation, showing a successful transmission of the character 'H' (0x48). You can clearly see the low start bit, the 8 data bits (`00010010` in reverse order), and the high stop bit on the `o_tx_serial` line.

<img width="1877" height="787" alt="Screenshot 2025-10-08 004846" src="https://github.com/user-attachments/assets/423c9314-45c6-47e2-b36e-7e3bdb49fd1f" />



### Live Simulation
view the code and run the simulation live on EDA Playground using the following link:

[**View on EDA Playground**](<INSERT_YOUR_SAVED_EDA_PLAYGROUND_URL_HERE>)

---
