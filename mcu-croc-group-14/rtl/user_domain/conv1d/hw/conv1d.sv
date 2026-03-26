// Copyright 2024 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: conv1d.sv
// Author(s):
//   Luigi Giuffrida
//   Michele Caon
// Date: 08/11/2024
// Description: conv1d accelerator top module

module conv1d (
  /* verilator lint_off UNUSED */  // TODO: Remove this line when the signal is used
  input logic clk_i,
  input logic rst_ni,

  // Interface towards internal memory
  input  croc_pkg::sbr_obi_req_t mem_req_i,
  output croc_pkg::sbr_obi_rsp_t mem_rsp_o,

  // TODO: add here other interface signals (e.g., from the config. registers)
  // ADDED 
  output logic [31:0] status_reg_o,
  input  logic [31:0] ctrl_reg_i,  // Control (Start, Size, Ch, Kernel)
  input  logic [31:0] ptr_reg_i    // Pointers (Input, Weight, Output)
  // ADDED
);
  // PARAMETERS
  localparam int unsigned NumWords = 32'd128;  // DO NOT CHANGE THIS!
  localparam int unsigned AddrWidth = (NumWords > 32'd1) ? unsigned'($clog2(NumWords)) : 32'd1;
  // ADDED
  localparam int unsigned DATA_WIDTH = 32'd32;
  // ADDED

  // INTERNAL SIGNALS
  // ----------------
  // Memory multiplexer signals
  conv1d_sram_pkg::sram_req_t int_mem_req, ext_mem_req, mem_req;
  conv1d_sram_pkg::sram_rsp_t mem_rsp;
  logic                       ext_mem_gnt;

  // ---------------------
  // INTERNAL ARCHITECTURE
  // ---------------------
  // TODO: write here your code, you are encouraged to use a hierarchical (but not too hierarchical) approach.
  // The internal memory available to the accelerator as a data buffer has been
  // already instantiated below.

  // ADDED 
  // 1. Define signals to connect the Core to the Mux
  wire                   core_req;
  wire                   core_we;
  wire [3:0]             core_be;
  wire [AddrWidth-1:0]   core_addr;
  wire [31:0]            core_wdata;

  // 2. Instantiate the Core
  conv1d_core #(
      .DATA_WIDTH(32),
      .ADDR_WIDTH(AddrWidth)
  ) u_conv1d_core (
      .clk              (clk_i),
      .rst_n            (rst_ni),
      
      // Registers
      .ctrl_reg_i       (ctrl_reg_i),
      .ptr_reg_i        (ptr_reg_i),
      .status_reg_o     (status_reg_o),
      
      // Memory Interface
      .core_sram_req_o  (core_req),
      .core_sram_we_o   (core_we),
      .core_sram_be_o   (core_be),
      .core_sram_addr_o (core_addr),
      .core_sram_wdata_o(core_wdata),
      .core_sram_data_in(mem_rsp.rdata) // Feedback data from memory
  );

  // 3. Connect Core signals to the Internal Memory Request struct
  // Note: We shift the address by 2 bits because the memory bus expects Byte Addresses,
  // but our core works with Word Addresses.
  assign int_mem_req.req   = core_req;
  assign int_mem_req.we    = core_we;
  assign int_mem_req.be    = core_be;
  // Convert 7-bit word index to byte address (shift left by 2)
  assign int_mem_req.addr  = {23'd0, core_addr, 2'b00}; 
  assign int_mem_req.wdata = core_wdata;
  

  // Internal memory
  // ---------------
  // Internal memory request multiplexer
  // Because the same, single-port memory must be accessed both through the
  // GR-HEEP bus (host CPU/DMA) and by the accelerator internal hardware, a
  // multiplexer is used to arbitrate between the two.
  // TODO: change the following assignment to be low when the internal memory is
  // being used by the accelerator, so that external requests are not granted npr
  // propagated to the memory instance.
  // 4. Arbitrate Priority
  // If the Core is requesting memory (core_req == 1), we block the External bus.
  assign ext_mem_gnt = ~core_req;

  // Internal memory multiplexer
  always_comb begin : mem_req_mux
    if (ext_mem_gnt) begin
      mem_req = ext_mem_req;
    end else begin
      mem_req = int_mem_req;
    end
  end

  // OBI to SRAM bridge
  obi_sram_shim #(
    .ObiCfg    (croc_pkg::SbrObiCfg),
    .obi_req_t (croc_pkg::sbr_obi_req_t),
    .obi_rsp_t (croc_pkg::sbr_obi_rsp_t)
  ) u_obi_bridge (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .obi_req_i (mem_req_i),
    .obi_rsp_o (mem_rsp_o),
    .req_o     (ext_mem_req.req),
    .we_o      (ext_mem_req.we),
    .addr_o    (ext_mem_req.addr),
    .wdata_o   (ext_mem_req.wdata),
    .be_o      (ext_mem_req.be),
    .gnt_i     (ext_mem_gnt),
    .rdata_i   (mem_rsp.rdata)
  );

  // Internal memory instance
  // NOTE: you may choose to instantiate two internal memories, each half the
  // size of this one (i.e., 64 words as the first parameter) to implement
  // double buffering.
  conv1d_sram_wrapper #(
    .NUM_WORDS (NumWords),
    .DATA_WIDTH(32'd32)
  ) u_internal_mem (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .req_i  (mem_req.req),
    .we_i   (mem_req.we),
    .addr_i (mem_req.addr[AddrWidth+1:2]),
    .wdata_i(mem_req.wdata),
    .be_i   (mem_req.be),
    .rdata_o(mem_rsp.rdata)
  );

endmodule
