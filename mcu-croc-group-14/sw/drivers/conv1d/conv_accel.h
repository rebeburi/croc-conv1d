#ifndef _CONV1D_DRIVER_H_
#define _CONV1D_DRIVER_H_

#include <stdint.h>

/**
 * Configures the accelerator's internal register pointers.
 * Should be called before starting the accelerator.
 */
void conv1d_setup(uint32_t input_ch, uint32_t tile_len, uint32_t kernel_len);

/**
 * Loads a chunk of data (Tile) from main memory into the accelerator's private SRAM.
 * * @param in           Pointer to the start of the Input array (Channel-Major).
 * @param weights      Pointer to the start of the current Filter set.
 * @param input_ch     Total input channels (e.g., 16).
 * @param tile_len     Length of the tile to load (e.g., 16).
 * @param kernel_len   Length of the kernel (e.g., 5).
 * @param t_offset     The time index in the main array to start loading from.
 * @param input_len_full The total length of one input channel (for stride calc).
 */
void conv1d_load_data(const int8_t *in, const int8_t *weights, 
                      uint32_t input_ch, uint32_t tile_len, uint32_t kernel_len, 
                      uint32_t t_offset, uint32_t input_len_full);

/**
 * Trigger the accelerator execution.
 */
void conv1d_start(uint32_t tile_size, uint32_t input_ch, uint32_t kernel_len);

/**
 * Polls the status register until the accelerator finishes.
 */
void conv1d_wait();

/**
 * Reads the first valid result word from the accelerator's output buffer.
 * (Since Stride ~ Tile Size, we only get 1 valid result per run).
 */
int32_t conv1d_read_result();
void conv_accel_init(void);
#endif