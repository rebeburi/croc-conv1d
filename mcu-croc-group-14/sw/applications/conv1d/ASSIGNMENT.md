# Hardware-accelerated 1D convolution

This directory contains an application ([`main.c`](./main.c)) that computes the convolution between $N$ channels of $[1 \times L]$ 8-bit input data arrays and $K$ sets of $N$ $[1 \times 3]$ 8-bit filters. The output of this operation is $K$ channels of $[1 \times (L-2)]$ 32-bit filtered data (assuming no zero-padding and unitary stride for the convolution).

The application runs both a CPU-based implementation of the above algorithm, and a hardware-accelerated version that uses your memory-mapped accelerator to, hopefully, speed up the execution.

The input data and the golden output can be generated and saved in C format inside the `data.h` header file by executing `make` _in this directory_ (or using the `make gen-data` from the repository root directory). You may change the generation parameters (e.g., the size of the input data) by passing the `APP_PARAMS` variable to `make`. For example, to generate $N=16$ input channels, each with $L=128$ data samples, and generate $K=4$ output channels, you may use the following command:

```bash
make APP_PARAMS="--in_len 128 --in_ch 16 --k_num 4"
```

> __Hint:__ take a look at the application [`makefile`](./makefile), [`datagen.py`](./datagen.py), and [`c_gen.py`](./../../common/c_gen.py) to understand how the data generation process works.

After having vendore the conv1d folder, if you try to compile and run the `conv1d` application as it currently is, you will notice that it prints an error on the UART log. This is because the `conv1d_hw()` function called in `main.c` is not implemented yet. To have this function implement the same 1D convolution in `conv1d_sw()` is your main task, as detailed in the following section.

## Assignment

Implement the `conv1d_hw()` function in [`conv1d.c`](./conv1d.c). The function must copy the input data to the accelerator private memory and use the driver you wrote in [`conv_accel.c`](./../../drivers/conv1d/conv_accel.c) to trigger the computation and wait for it to complete.

### Tiling
Because the size of the accelerator's internal buffer is smaller than the input data, the accelerator can only process a small data chunk at once. The process of dividing a large processing workload (e.g., a multi-channel convolution) into multiple, smaller tasks on a subset of the input data is called tiling. You are free to decide how to subdivide the computation, as long as the final result matches the expected one.

> __Hint:__ applying tiling by computing one output channel at a time may seem the most straightforward solution at first glance, trying to reduce the number of data movements is usually a better approach to reduce the overall execution time. How can you make the most out of an input channel copied into the accelerator private memory? Can you compute that input's contribution on multiple output channels before loading a different set of input channels?

### Optional: double buffering
To enhance the overall throughput, the accelerator internal buffer can be pre-loaded with new input data while it is processing the previous input data chunk. This process is called _double buffering_ and it's an effective techniques to keep the execution units of a circuit as busy as possible, instead of having them idling while waiting for new input data to be available. You may modify the accelerator architecture to support double buffering.

> __Hint:__ the memory macros that you are using to implement your accelerator private buffer are single-port, meaning that you cannot write new data while the execution units are reading the previously stored input data. Therefore, to implement double buffering, you may need to instantiate multiple memory banks inside the accelerator, and used them in time multiplexing: the software shall load one of the buffers while the hardware is processing data from the other. Once the first data chunk has been completely consumed, the hardware shall start reading data from the second bank, allowing the software to fill the first bank with the third chunk of data, and so on. The total amount of private memory that you are allowed to instantiate in the accelerator is fixed. Therefore, the size of each buffer when supporting double buffering shall be half the size of the memory that you are allows to use.

### Optional: padding
When processing data, it is usually convenient to force the output data to have the same size of the input data. When computing convolutions, this can usually be achieved by reducing padding the input data with neutral values (e.g., zero or an average value).

By default, you hardware does not pad the input data, therefore resulting in the output channels having less samples than the input ones. As an optional assignment, you are required to modify your software (including the CPU implementation in `conv1d_sw()`) to support padding, so that the number of samples in the output channels is equal to the number of samples in the input channels. 

If you prefer, you may also implement this feature inside your hardware accelerator. In this case, the feature shall be optionally activated by the software (i.e., the driver) by writing a dedicated register inside the accelerator configuration and status registers.

The golden model in `datagen.py` already supports padding, you just have to specify its amount through the `--padding X` option in `APP_PARAMS`.

### Optional: stride
On the contrary, sometimes it is beneficial for the output data channels to have fewer elements than the input ones. One way to achieve this is to move the filter window over the input data by more than one sample at a time, effectively reducing the number of output samples to be produced. The amount of input samples by which the filter is moved each time is called _stride_. In order to process every input sample at least once, the stride shall always be lower than the filter dimension. For example, if the filter dimension is 3 as in this case, the possible stride values can be 1 or 2.

By default, your hardware accelerator implements unitary stride. As an optional assignment, you shall modify your hardware and software (including the CPU implementation in `conv1d_sw()`) to support a stride equal to 2. In the report, explain how this affects the size of the output channels, and discuss what may be the reasons to use a stride higher than one.

The golden model in `datagen.py` already supports arbitrary stride values, you just have to specify its amount through the `--stride X` option in `APP_PARAMS`.
