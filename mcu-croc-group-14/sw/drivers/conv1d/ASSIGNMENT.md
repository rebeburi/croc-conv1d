# Driver for the 1D convolution accelerator

This directory contains a template for the C driver required to use the convolution engine that you will develop for this laboratory. Your task is to populate it with functions that the application software in `sw/applications/conv1d/main.c` shall call to perform, at least, the following actions:
- __Initialize the accelerator and the driver.__ Before loading data into the accelerator private buffer and trigger its execution by writing its configuration registers, you may want to bring it to a known state and wait for it to be ready to to accept further requests (e.g., waiting for a status bit in the configuration register to be asserted by the hardware to communicate to the software that operations can be offloaded). Similarly, the driver itself may need to initialize some data structures or global variables before other driver functions can be called by the application.

    > __Note:__ the initialization function in the driver does _NOT_ replace the hardware reset propagated to the accelerator when croc is reset.

- __Start the execution.__ This is done by writing the associated bit inside the accelerator configuration and status registers. When this happens, the controller inside the accelerator shall fetch the data that the application software has previously copied into the accelerator's private memory and feed it to the execution units.

- __Wait for the execution to complete.__ After starting the computation (previous point), the application software must wait for the hardware to consume all the input data and produce all the results before proceeding. The driver shall expose a function that, once called, returns only once the accelerator has finished the computation. The driver shall poll a _done_ bit inside the accelerator's status registers.

    > __Hint:__ you may check how interrupts are handled the `cnt` [driver](../cnt/simple_cnt.c).

You are free to use as many functions as you like, implementing any feature that you consider necessary or helpful.

## Assignment

Populate the [`conv_accel.h`](./conv_accel.h) and [`conv_accel.c`](./conv_accel.c) source files with the driver function prototypes and definitions.