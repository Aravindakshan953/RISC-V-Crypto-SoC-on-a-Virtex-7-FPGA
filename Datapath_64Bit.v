`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 11:00:24
// Design Name: 
// Module Name: Datapath_64Bit
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

module Datapath_64Bit #(
    parameter DATA_WIDTH = 64,
    parameter REG_ADDR_W = 5
)(
    input  wire [REG_ADDR_W-1:0] READ_REG_NUM1,
    input  wire [REG_ADDR_W-1:0] READ_REG_NUM2,
    input  wire [REG_ADDR_W-1:0] WRITE_REG,
    input  wire [3:0]            ALU_CNTRL,
    input  wire                  REG_WRITE,
    input  wire                  CLK,
    input  wire                  RST,
    output wire                  ZERO_FLG
);

    //--------------------------------------------------------------------------
    // Internal data signals
    //--------------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] rs1_data;
    wire [DATA_WIDTH-1:0] rs2_data;
    wire [DATA_WIDTH-1:0] alu_result;

    //--------------------------------------------------------------------------
    // Register file
    // TODO: switch to named ports once REG_FILE_64Bit's port names are confirmed.
    // Current order: rs1 addr, rs2 addr, rd addr, write data,
    //                rs1 data, rs2 data, write enable, clk, rst
    //--------------------------------------------------------------------------
    REG_FILE_64Bit u_reg_file (
        READ_REG_NUM1,
        READ_REG_NUM2,
        WRITE_REG,
        alu_result,
        rs1_data,
        rs2_data,
        REG_WRITE,
        CLK,
        RST
    );

    //--------------------------------------------------------------------------
    // ALU
    // TODO: switch to named ports once ALU_64's port names are confirmed.
    // Current order: operand A, operand B, control, result, zero flag
    //--------------------------------------------------------------------------
    ALU_64 u_alu (
        rs1_data,
        rs2_data,
        ALU_CNTRL,
        alu_result,
        ZERO_FLG
    );

endmodule
