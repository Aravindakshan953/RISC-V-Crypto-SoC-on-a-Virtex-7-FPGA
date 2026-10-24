`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 13:13:13
// Design Name: 
// Module Name: PROCESSOR_64Bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PROCESSOR_64Bit #(
    parameter INST_WIDTH = 64,
    parameter REG_ADDR_W = 5
)(
    input  wire CLK,
    input  wire RST,
    output wire ZERO
);

    //--------------------------------------------------------------------------
    // Instruction field positions (single source of truth for the encoding)
    //--------------------------------------------------------------------------
    localparam [5:0] RS1_LSB    = 6'd56;
    localparam [5:0] FUNCT7_LSB = 6'd48;
    localparam [5:0] RS2_LSB    = 6'd40;
    localparam [5:0] FUNCT3_LSB = 6'd32;
    localparam [5:0] RD_LSB     = 6'd24;
    localparam [5:0] OPCODE_LSB = 6'd16;

    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    wire [INST_WIDTH-1:0] inst_code;
    wire [3:0]            alu_ctrl;
    wire                  reg_write_en;

    // Decoded instruction fields
    wire [REG_ADDR_W-1:0] rs1_addr = inst_code[RS1_LSB    +: REG_ADDR_W];
    wire [REG_ADDR_W-1:0] rs2_addr = inst_code[RS2_LSB    +: REG_ADDR_W];
    wire [REG_ADDR_W-1:0] rd_addr  = inst_code[RD_LSB     +: REG_ADDR_W];
    wire [6:0]            funct7   = inst_code[FUNCT7_LSB +: 7];
    wire [2:0]            funct3   = inst_code[FUNCT3_LSB +: 3];
    wire [6:0]            opcode   = inst_code[OPCODE_LSB +: 7];

    //--------------------------------------------------------------------------
    // Instruction fetch unit
    // TODO: switch to named ports once IFU_64Bit's port names are confirmed.
    //--------------------------------------------------------------------------
    IFU_64Bit u_ifu (
        CLK,
        RST,
        inst_code
    );

    //--------------------------------------------------------------------------
    // Control unit
    //--------------------------------------------------------------------------
    CNTRL_64Bit u_control (
        .FUNCT7    (funct7),
        .FUNCT3    (funct3),
        .OPCODE    (opcode),
        .ALU_CNTRL (alu_ctrl),
        .REG_WRITE (reg_write_en)
    );

    //--------------------------------------------------------------------------
    // Datapath (register file + ALU)
    //--------------------------------------------------------------------------
    Datapath_64Bit u_datapath (
        .READ_REG_NUM1 (rs1_addr),
        .READ_REG_NUM2 (rs2_addr),
        .WRITE_REG     (rd_addr),
        .ALU_CNTRL     (alu_ctrl),
        .REG_WRITE     (reg_write_en),
        .CLK           (CLK),
        .RST           (RST),
        .ZERO_FLG      (ZERO)
    );

endmodule

`default_nettype wire
