# Croc SoC – Conv1D Accelerator Integration

## Overview

This repository builds upon the **Croc MCU / Croc SoC** platform.
The majority of the base architecture, infrastructure, and supporting framework were already developed by the original authors.

This work focuses on extending the system by integrating a **multichannel 1D convolution (Conv1D) hardware accelerator** into the existing SoC.

---

## Contributions

The main contributions of this project include:

* Integration of a **Conv1D hardware accelerator** into the Croc SoC
* Development of the required **software stack**, including:

  * Device driver
  * RISC-V firmware support
* Functional validation against a **software reference implementation**
* Performance evaluation of the accelerator within the system

---

## Design Flow

The extended design was taken through a complete **RTL-to-GDSII flow**, including:

* **Synthesis** using Yosys
* **Place & Route** using OpenROAD

The flow produces reports for:

* Area
* Power
* Timing

---

## Acknowledgment

This repository is largely based on prior work on the Croc MCU / SoC platform.

> ⚠️ Most of the original system design and infrastructure were not developed as part of this work.
> The primary contribution of this project is the integration and evaluation of the Conv1D accelerator.

---

## License

Unless specified otherwise, hardware sources and tool scripts follow the Solderpad Hardware License 0.51, and software components are released under the Apache 2.0 license.
