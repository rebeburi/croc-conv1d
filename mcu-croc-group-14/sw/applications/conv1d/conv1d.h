#ifndef CONV1D_HH_
#define CONV1D_HH_

#include <stdint.h>

void conv1d_hw(const int8_t * const in_data, 
               const int8_t * const filter, 
               int32_t *output_data, 
               const uint32_t input_len, 
               const uint32_t input_ch, 
               const uint32_t output_ch,
               const uint32_t kernel_len,
               const uint32_t stride,
               const uint32_t pad,
               const uint32_t tile_len);


void conv1d_sw(const int8_t * const input_data, 
               const int8_t * const filter, 
               int32_t *output_data, 
               const uint32_t input_len, 
               const uint32_t input_ch, 
               const uint32_t output_ch,
               const uint32_t kernel_len,
               const uint32_t stride,
               const uint32_t pad);

#endif