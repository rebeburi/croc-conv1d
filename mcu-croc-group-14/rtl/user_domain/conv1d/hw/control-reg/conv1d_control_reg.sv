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
// File: conv1d_control_reg.sv
// Author(s):
//   Michele Caon
// Date: 07/11/2024
// Description: Conv1d control register wrapper

module conv1d_control_reg (
  input  logic                      clk_i,
  input  logic                      rst_ni,
  /* verilator lint_off UNUSED */  // TODO: Remove this line when the signal is used
  /* verilator lint_off UNDRIVEN */  // TODO: Remove this line when the signal is driven
  // Register interface
  input  conv1d_reg_pkg::reg_req_t  req_i,   // from host system
  output conv1d_reg_pkg::reg_rsp_t rsp_o,    // to host system

  // TODO: Add here the interface from the registers to the accelerator
  // EDIT
  output logic [31:0] ctrl_reg_o,  // Control (Start, Size, Ch, Kernel)
  output logic [31:0] ptr_reg_o,   // Pointers (Input, Weight, Output)
  input  logic [31:0] status_reg_i
  // EDIT
);
  // INTERNAL SIGNALS
  // ----------------
  // Registers <--> Accelerator
  conv1d_control_reg_pkg::conv1d_control_reg2hw_t reg2hw;
  conv1d_control_reg_pkg::conv1d_control_hw2reg_t hw2reg;


  // EDIT
  assign hw2reg.status.running.d = status_reg_i[0];
  assign hw2reg.status.done.d    = status_reg_i[1];
  assign hw2reg.status.running.de = 1'b1; 
  assign hw2reg.status.done.de    = 1'b1;
  assign ctrl_reg_o[0]     = reg2hw.control.start.q;
  assign ctrl_reg_o[7:1]   = reg2hw.control.tile_size.q;
  assign ctrl_reg_o[13:8]  = reg2hw.control.input_ch.q;
  assign ctrl_reg_o[17:14] = reg2hw.control.kernel_len.q;
  assign ctrl_reg_o[31:18] = '0; // Unused/Reserved bits

  // -- Pointers Register (Offset 0x04) --
  // Mapping struct fields to the 32-bit 'ptr_reg_o' bus
  assign ptr_reg_o[6:0]    = reg2hw.pointers.input_ptr.q;
  assign ptr_reg_o[7]      = 1'b0; // Padding
  assign ptr_reg_o[14:8]   = reg2hw.pointers.weight_ptr.q;
  assign ptr_reg_o[15]     = 1'b0; // Padding
  assign ptr_reg_o[22:16]  = reg2hw.pointers.output_ptr.q;
  assign ptr_reg_o[31:23]  = '0;   // Unused/Reserved bits
  //EDIT 
  // -----------------
  // CONTROL REGISTERS
  // -----------------

  // Registers top module
  conv1d_control_reg_top #(
    .reg_req_t(conv1d_reg_pkg::reg_req_t),
    .reg_rsp_t(conv1d_reg_pkg::reg_rsp_t)
  ) u_conv1d_control_reg_top (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .reg_req_i(req_i),
    .reg_rsp_o(rsp_o),
    .reg2hw   (reg2hw),
    .hw2reg   (hw2reg),
    .devmode_i(1'b0)
  );


endmodule
