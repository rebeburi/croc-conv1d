// File: conv1d_core.sv
module conv1d_core #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned ADDR_WIDTH = 7   // 512 Bytes = 128 Words (2^7)
)(
    input  logic                    clk,
    input  logic                    rst_n,

    // Interface from Control Registers (Split into Control and Pointers)
    input  logic [31:0]             ctrl_reg_i, 
    input  logic [31:0]             ptr_reg_i,
    output logic [31:0]             status_reg_o,

    // Interface to SRAM
    output logic                    core_sram_req_o,
    output logic                    core_sram_we_o,
    output logic [3:0]              core_sram_be_o,
    output logic [ADDR_WIDTH-1:0]   core_sram_addr_o,
    output logic [DATA_WIDTH-1:0]   core_sram_wdata_o,
    input  logic [DATA_WIDTH-1:0]   core_sram_data_in
);

    // ========================================================================
    // 1. SIGNAL UNPACKING
    // ========================================================================
    logic        start_cmd;
    logic [6:0]  cfg_tile_size;
    logic [5:0]  cfg_input_ch;
    logic [3:0]  cfg_kernel_len;

    // Full 7-bit pointers (Direct mapping, no shifting needed)
    logic [ADDR_WIDTH-1:0]  cfg_input_base;   
    logic [ADDR_WIDTH-1:0]  cfg_weight_base;
    logic [ADDR_WIDTH-1:0]  cfg_out_base;



    // Unpack Control Register
    assign start_cmd       = ctrl_reg_i[0];
    assign cfg_tile_size   = ctrl_reg_i[7:1];
    assign cfg_input_ch    = ctrl_reg_i[13:8];
    assign cfg_kernel_len  = ctrl_reg_i[17:14];

    // Unpack Pointers Register
    assign cfg_input_base  = ptr_reg_i[6:0];
    assign cfg_weight_base = ptr_reg_i[14:8];
    assign cfg_out_base    = ptr_reg_i[22:16];

    // Calculate Stride safely: (Input_Ch / 4)
    logic [ADDR_WIDTH-1:0] stride;
    assign stride = {2'b00, cfg_input_ch} >> 2;

    // Registered Pointers
    logic [ADDR_WIDTH-1:0] input_base_ptr_q, input_base_ptr_d;
    logic [ADDR_WIDTH-1:0] input_curr_ptr_q, input_curr_ptr_d;
    logic [ADDR_WIDTH-1:0] weight_curr_ptr_q, weight_curr_ptr_d;

    // ========================================================================
    // 2. FSM & DATAPATH (Updated for 7-bit addressing)
    // ========================================================================
    typedef enum logic [2:0] {
        IDLE, INIT_CALC, LOAD_WEIGHT, LOAD_INPUT, CALC_ACCUM, WRITE_OUT, NEXT_PIXEL, DONE
    } state_t;

    state_t state_q, state_d;
    logic running_flag, done_flag;
    assign status_reg_o = {30'd0, done_flag, running_flag};

    logic [31:0] weight_reg_q, weight_reg_d;
    logic signed [31:0] acc_q, acc_d;
    
    // Counters
    logic [6:0] cnt_out_t_q, cnt_out_t_d;
    logic [3:0] cnt_k_q, cnt_k_d;
    logic [4:0] cnt_ch_q, cnt_ch_d;

    // Math Components
    logic signed [7:0]  op_a [3:0];
    logic signed [7:0]  op_b [3:0];
    logic signed [15:0] prod [3:0];
    logic signed [31:0] sum_stage1 [1:0]; 
    logic signed [31:0] sum_stage2;
    logic signed [31:0] adder_acc_out;

    // Unpacking
    assign op_a[0] = core_sram_data_in[7:0];    assign op_b[0] = weight_reg_q[7:0];
    assign op_a[1] = core_sram_data_in[15:8];   assign op_b[1] = weight_reg_q[15:8];
    assign op_a[2] = core_sram_data_in[23:16];  assign op_b[2] = weight_reg_q[23:16];
    assign op_a[3] = core_sram_data_in[31:24];  assign op_b[3] = weight_reg_q[31:24];

    // Instantiation
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_mults
            multiplier #( .WIDTH(8) ) u_mult ( .a(op_a[i]), .b(op_b[i]), .p(prod[i]) );
        end
    endgenerate

    adder #( .WIDTH(32) ) u_add_01  ( .a({{16{prod[0][15]}}, prod[0]}), .b({{16{prod[1][15]}}, prod[1]}), .s(sum_stage1[0]) );
    adder #( .WIDTH(32) ) u_add_23  ( .a({{16{prod[2][15]}}, prod[2]}), .b({{16{prod[3][15]}}, prod[3]}), .s(sum_stage1[1]) );
    adder #( .WIDTH(32) ) u_add_all ( .a(sum_stage1[0]), .b(sum_stage1[1]), .s(sum_stage2) );
    adder #( .WIDTH(32) ) u_acc     ( .a(acc_q), .b(sum_stage2), .s(adder_acc_out) );

    // ========================================================================
    // CONTROL LOGIC
    // ========================================================================
    always_comb begin
        state_d         = state_q;
        acc_d           = acc_q;
        weight_reg_d    = weight_reg_q;
        cnt_out_t_d     = cnt_out_t_q;
        cnt_k_d         = cnt_k_q;
        cnt_ch_d        = cnt_ch_q;
        // Pointers Default (Hold value)
        input_base_ptr_d  = input_base_ptr_q;
        input_curr_ptr_d  = input_curr_ptr_q;
        weight_curr_ptr_d = weight_curr_ptr_q;

        core_sram_req_o   = 1'b0;
        core_sram_we_o    = 1'b0;
        core_sram_be_o    = 4'b1111;
        core_sram_addr_o  = '0;
        core_sram_wdata_o = '0;
        
        running_flag      = 1'b1; 
        done_flag         = 1'b0;

        case (state_q)
            IDLE: begin
                running_flag = 1'b0;
                done_flag = 1'b0;
                cnt_out_t_d = '0;
                cnt_k_d     = '0;
                cnt_ch_d    = '0;
                acc_d       = '0;
                if (start_cmd) begin
                    state_d = INIT_CALC;
                    cnt_out_t_d = '0;
                    // Latch Base Pointer from Register
                    input_base_ptr_d = cfg_input_base;
                end
            end

            INIT_CALC: begin
                acc_d     = '0;
                cnt_k_d   = '0;
                cnt_ch_d  = '0; 
                
                input_curr_ptr_d  = input_base_ptr_q;
                weight_curr_ptr_d = cfg_weight_base;
                state_d   = LOAD_WEIGHT;
            end

            LOAD_WEIGHT: begin
                core_sram_req_o  = 1'b1;
                // ADDRESS CALCULATION: Base + (k * (Ch/4)) + (ch_group)
                core_sram_addr_o  = weight_curr_ptr_q; // USE POINTER (No Math)
                weight_curr_ptr_d = weight_curr_ptr_q + 1; // Increment
                state_d = LOAD_INPUT;
            end

            LOAD_INPUT: begin
                weight_reg_d = core_sram_data_in; // Latch weights
                core_sram_req_o  = 1'b1;
                core_sram_addr_o  = input_curr_ptr_q; // USE POINTER (No Math)
                input_curr_ptr_d  = input_curr_ptr_q + 1; // Increment
                state_d = CALC_ACCUM;
            end

            CALC_ACCUM: begin
                acc_d = adder_acc_out; // Store Sum
                
                // Loop: Channel Groups
                if (cnt_ch_q < (stride - 1)) begin
                    cnt_ch_d = cnt_ch_q + 1;
                    state_d  = LOAD_WEIGHT;
                end 
                // Loop: Kernel
                else if (cnt_k_q < cfg_kernel_len - 1) begin
                    cnt_k_d  = cnt_k_q + 1;
                    cnt_ch_d = '0;
                    state_d  = LOAD_WEIGHT;
                end 
                else begin
                    state_d = WRITE_OUT;
                end
            end

            WRITE_OUT: begin
                core_sram_req_o   = 1'b1;
                core_sram_we_o    = 1'b1;
                core_sram_addr_o  = cfg_out_base + cnt_out_t_q;
                core_sram_wdata_o = acc_q;
                state_d = NEXT_PIXEL;
            end

            NEXT_PIXEL: begin
                if (cnt_out_t_q < cfg_tile_size - cfg_kernel_len) begin
                    cnt_out_t_d = cnt_out_t_q + 1;
                    // Slide Window: Base Pointer jumps by STRIDE
                    input_base_ptr_d = input_base_ptr_q + stride;
                    state_d = INIT_CALC;
                end else begin
                    state_d = DONE;
                end
            end

            DONE: begin
                running_flag = 1'b0;
                done_flag    = 1'b1;
                if (!start_cmd) state_d = IDLE;
            end
        endcase
    end

    // Sequential Process
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q           <= IDLE;
            acc_q             <= '0;
            weight_reg_q      <= '0;
            cnt_out_t_q       <= '0;
            cnt_k_q           <= '0;
            cnt_ch_q          <= '0;
            input_base_ptr_q  <= '0;
            input_curr_ptr_q  <= '0;
            weight_curr_ptr_q <= '0;
        end else begin
            state_q           <= state_d;
            acc_q             <= acc_d;
            weight_reg_q      <= weight_reg_d;
            cnt_out_t_q       <= cnt_out_t_d;
            cnt_k_q           <= cnt_k_d;
            cnt_ch_q          <= cnt_ch_d;
            input_base_ptr_q  <= input_base_ptr_d;
            input_curr_ptr_q  <= input_curr_ptr_d;
            weight_curr_ptr_q <= weight_curr_ptr_d;
        end
    end
endmodule