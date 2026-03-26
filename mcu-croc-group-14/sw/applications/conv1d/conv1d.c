#include <stdint.h>
#include <limits.h>
#include "conv1d.h"
#include "config.h"
#include "conv_accel.h"


// ---------------------------------------------------------
// SOFTWARE IMPLEMENTATION (Golden Reference)
// ---------------------------------------------------------
void conv1d_sw(const int8_t * const input_data, 
               const int8_t * const filter, 
               int32_t *output_data, 
               const uint32_t input_len, 
               const uint32_t input_ch, 
               const uint32_t output_ch,
               const uint32_t kernel_len,
               const uint32_t stride,
               const uint32_t pad)
{
    // Calculate the length of the input data after padding
    // Note: This is a virtual length for calculation; we don't actually realloc.
    // The logic below handles padding checks dynamically.

    // Calculate the total number of output samples expected
    uint32_t output_len = ((input_len + 2*pad - kernel_len) / stride) + 1;

    // Loop over each output channel (output_ch times)
    for (uint32_t m = 0; m < output_ch; m++) {
        
        // Loop over each output time step
        for (uint32_t o = 0; o < output_len; o++) {
            int32_t accumulated_output = 0;

            // Loop over each input channel
            for (uint32_t n = 0; n < input_ch; n++) {
                
                // Compute the starting index in the input data
                int32_t input_start = (o * stride) - pad;

                int32_t sum = 0;

                // Loop over the kernel elements
                for (uint32_t k_idx = 0; k_idx < kernel_len; k_idx++) {
                    int32_t input_index = input_start + k_idx;
                    int8_t input_value;

                    // Handle padding boundary checks
                    if (input_index < 0 || input_index >= (int32_t)input_len) {
                        input_value = 0;
                    } else {
                        // Access input: [Channel][Time]
                        // Row-major: n * input_len + input_index
                        input_value = input_data[n * input_len + input_index];
                    }

                    // Access filter: [Out][In][Kernel]
                    // Row-major: ((m * input_ch + n) * kernel_len) + k_idx
                    int8_t filter_value = filter[((m * input_ch + n) * kernel_len) + k_idx];

                    // Multiply and accumulate
                    sum += input_value * filter_value;
                }
                accumulated_output += sum;
            }
            // Store result: [OutputCh][Time]
            output_data[m * output_len + o] = accumulated_output;
        }
    }
}

// ---------------------------------------------------------
// HARDWARE IMPLEMENTATION (Accelerator Driver)
// ---------------------------------------------------------
void conv1d_hw(const int8_t * const in_data, 
    const int8_t * const filter, 
    int32_t *output_data, 
    const uint32_t input_len, 
    const uint32_t input_ch, 
    const uint32_t output_ch,
    const uint32_t kernel_len,
    const uint32_t stride, 
    const uint32_t pad,
    const uint32_t tile_len) 
{

    uint32_t total_outputs = (input_len - kernel_len) + 1;


    // 3. Loop over Output Channels
    for (uint32_t k = 0; k < output_ch; k++) {
        const int8_t *current_filter = &filter[k * input_ch * kernel_len];
        
    
        for (uint32_t o = 0; o < total_outputs; o += stride) {
        // A. Setup & Load
        int32_t t_start = o - pad;
        if (t_start < 0) t_start = 0;

        conv1d_setup(input_ch, tile_len, kernel_len);
            
        
        conv1d_load_data(in_data, current_filter, input_ch, tile_len, kernel_len, (uint32_t)t_start, input_len);
            
        conv1d_start(tile_len, input_ch, kernel_len);
        conv1d_wait();

        // B. READ BATCH RESULTS (
        for (int i = 0; i < stride; i++) {

            //Stop if we reached the end of the total signal
            if ((o + i) >= total_outputs) break;

            // Read the i-th result from hardware memory
          
            int32_t res = conv1d_read_result(input_ch, tile_len, kernel_len, i);

            // Store in the correct sequential spot
            output_data[(k * total_outputs) + (o + i)] = res;
        }
    }

    }
}
