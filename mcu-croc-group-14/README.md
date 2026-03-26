# Croc MCU

This repository contains the codebase for the **Croc MCU**, extended with a custom 1D convolution hardware accelerator. The project involves integrating the accelerator into the Croc SoC, developing the corresponding RISC-V firmware, validating functionality through simulation, and running a fully open-source RTL-to-GDSII design flow.

The repository provides the RTL of the Croc SoC and its user-domain extension, the firmware and driver framework required to interact with the accelerator, and the scripts used for synthesis and physical design. Development is performed within a Docker-based environment.

> **ATTENTION:** ⚠️ This repository is heavily based on work originally developed at [ETH Zurich](https://www.ethz.ch).  
> Much of the code is adapted from or inspired by existing projects and was not developed from scratch by the authors.

## License
Unless specified otherwise, hardware sources and tool scripts are released under the Solderpad Hardware License 0.51 (see `LICENSE.md`), and software sources are provided under the Apache 2.0 license.
