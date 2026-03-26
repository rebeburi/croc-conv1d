#include "conv1d.h"
#define pulp_write32(addr, val) (*((volatile uint32_t *)(addr)) = (val))
#define pulp_read32(addr)       (*((volatile uint32_t *)(addr)))

// --- ADDRESS MAPPING ---
#define CONV1D_REG_BASE   0x20021000
#define CONV1D_MEM_BASE   0x20010000

#define REG_CTRL_OFFSET   0x00
#define REG_PTR_OFFSET    0x04
#define REG_STATUS_OFFSET 0x08

void conv_accel_init(void) {
    // 1. Clear the Control Register
    // This ensures the START bit is 0 (stopping the accelerator) 
    // and clears any configuration (tile size, etc).
    pulp_write32(CONV1D_REG_BASE + REG_CTRL_OFFSET, 0x00);

    // 2. Clear the Status Register
    // Write 1 to Bit 1 to acknowledge 
    // any pending "DONE" interrupts from previous runs.
    pulp_write32(CONV1D_REG_BASE + REG_STATUS_OFFSET, 0x02); 
}

void conv1d_setup(uint32_t input_ch, uint32_t tile_len, uint32_t kernel_len) {
    // 1. Calculate Byte Offsets for the internal SRAM sections
    uint32_t input_base_b   = 0x0000;
    uint32_t weight_base_b  = input_base_b  + (input_ch * tile_len);
    uint32_t output_base_b  = weight_base_b + (input_ch * kernel_len);

    // 2. Convert to Word Indices (Address >> 2) for the HW Pointer Register
    uint32_t input_idx  = input_base_b  >> 2;
    uint32_t weight_idx = weight_base_b >> 2;
    uint32_t output_idx = output_base_b >> 2;

    // 3. Pack: [OUTPUT(22:16) | WEIGHT(14:8) | INPUT(6:0)]
    uint32_t ptr_val = 0;
    ptr_val |= (input_idx  & 0x7F) << 0;
    ptr_val |= (weight_idx & 0x7F) << 8;
    ptr_val |= (output_idx & 0x7F) << 16;

    pulp_write32(CONV1D_REG_BASE + REG_PTR_OFFSET, ptr_val);
}

void conv1d_load_data(const int8_t *in, const int8_t *weights, 
                      uint32_t input_ch, uint32_t tile_len, uint32_t kernel_len, 
                      uint32_t t_offset, uint32_t input_len_full) {
    
    uint32_t input_base_b  = 0x0000;
    uint32_t weight_base_b = input_base_b + (input_ch * tile_len);
    uint32_t groups        = input_ch / 4; // e.g., 16/4 = 4 words per time step

    // --- LOAD INPUTS ---
    uint32_t total_input_words = groups * tile_len;
    
    for (uint32_t i = 0; i < total_input_words; i++) {
        uint32_t t_idx = i / groups; // Time index within the tile (0..15)
        uint32_t g_idx = i % groups; // Channel Group (0..3)
        uint32_t packed_val = 0;
        
        for (int b = 0; b < 4; b++) {
            int ch = (g_idx * 4) + b;
            uint32_t src_idx = (ch * input_len_full) + (t_offset + t_idx);
            int8_t val = in[src_idx];
            
            packed_val |= ((uint8_t)val) << (b * 8);
        }
        pulp_write32(CONV1D_MEM_BASE + input_base_b + (i * 4), packed_val);
    }

    // --- LOAD WEIGHTS ---

    uint32_t total_weight_words = groups * kernel_len;

    for (uint32_t i = 0; i < total_weight_words; i++) {
        uint32_t k_tap = i / groups; // Kernel Tap (0..4)
        uint32_t g_idx = i % groups; // Channel Group (0..3)
        uint32_t packed_val = 0;
        
        for (int b = 0; b < 4; b++) {
            int ch = (g_idx * 4) + b;
            uint32_t src_idx = (ch * kernel_len) + k_tap;
            int8_t val = weights[src_idx];
            
            packed_val |= ((uint8_t)val) << (b * 8);
        }
        pulp_write32(CONV1D_MEM_BASE + weight_base_b + (i * 4), packed_val);
    }
}

void conv1d_start(uint32_t tile_size, uint32_t input_ch, uint32_t kernel_len) {
    uint32_t ctrl_val = 1; // START bit
    ctrl_val |= (tile_size   & 0x7F) << 1;
    ctrl_val |= (input_ch    & 0x3F) << 8;
    ctrl_val |= (kernel_len  & 0x0F) << 14;

    pulp_write32(CONV1D_REG_BASE + REG_CTRL_OFFSET, ctrl_val);
}

void conv1d_wait() {
    while(1) {
        volatile uint32_t status = pulp_read32(CONV1D_REG_BASE + REG_STATUS_OFFSET);
        if ((status >> 1) & 0x1) break; // Check Bit 1 (DONE)
    }
    // Clear Done (Bit 1) and Start (Bit 0)
    pulp_write32(CONV1D_REG_BASE + REG_STATUS_OFFSET, 0x02);
    pulp_write32(CONV1D_REG_BASE + REG_CTRL_OFFSET, 0x00);
}

int32_t conv1d_read_result(uint32_t input_ch, uint32_t tile_len, uint32_t kernel_len, int index) {
    // Dynamic calculation matching setup()
    uint32_t input_size_b  = input_ch * tile_len;
    uint32_t weight_size_b = input_ch * kernel_len;
    
    uint32_t output_base_b = input_size_b + weight_size_b;
    
    uint32_t read_addr = CONV1D_MEM_BASE + output_base_b + (index * 4);

    return pulp_read32(read_addr);
}