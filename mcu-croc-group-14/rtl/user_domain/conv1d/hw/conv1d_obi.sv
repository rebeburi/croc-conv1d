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
// File: conv1d_obi.sv
// Author(s):
//   Luigi Giuffrida
// Date: 07/11/2024
// Description: OBI bus wrapper for the conv1d accelerator

module conv1d_obi (
  input logic clk_i,
  input logic rst_ni,

  // OBI interface (counter value)
  /* verilator lint_off UNUSED */  // TODO: Remove this line when the signal is used 
  /* verilator lint_off UNDRIVEN */  // TODO: Remove this line when the signal is driven
  input  croc_pkg::sbr_obi_req_t obi_req_i,
  output croc_pkg::sbr_obi_rsp_t obi_rsp_o,

  // Register Interface (configuration registers)
  input  conv1d_reg_pkg::reg_req_t  reg_req_i,
  output conv1d_reg_pkg::reg_rsp_t  reg_rsp_o,

  // Conv1d completion interrupt
  output logic done_int_o  // interrupt to host system
);

  // INTERNAL SIGNALS
  // ----------------
  // Bus request and response


  // Registers <--> Hardware interface
  //EDIT
  wire [31:0] ctrl_reg;  // Control params (Start, Size, etc.)
  wire [31:0] ptr_reg;   // Memory Pointers
  wire [31:0] status_reg;
  assign done_int_o = status_reg[1];
  //EDIT

  // --------------
  // CONV1D MODULE
  // --------------
  // conv1d instance
  conv1d u_conv1d (
    .clk_i (clk_i),
    .rst_ni(rst_ni),

    .mem_req_i(obi_req_i),
    .mem_rsp_o(obi_rsp_o),

    // TODO: Define the conv1d accelerator interface and connect it to the obi wrapper
    //EDIT 
    .ctrl_reg_i   (ctrl_reg),
    .ptr_reg_i    (ptr_reg),
    .status_reg_o (status_reg)
    //EDIT
  );

  // -----------------
  // CONTROL REGISTERS
  // -----------------

  // Control registers
  conv1d_control_reg u_conv1d_control_reg (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .req_i    (reg_req_i),
    .rsp_o    (reg_rsp_o),

        // TODO: Connect the control registers to the conv1d accelerator
    //EDIT 
    .ctrl_reg_o   (ctrl_reg),
    .ptr_reg_o    (ptr_reg),
    .status_reg_i (status_reg)
    //EDIT
  );

  // ----------
  // ASSERTIONS
  // ----------
`ifndef SYNTHESIS
  initial begin
    // TODO: Add assertions if needed
  end
`endif  /* SYNTHESIS */
endmodule
