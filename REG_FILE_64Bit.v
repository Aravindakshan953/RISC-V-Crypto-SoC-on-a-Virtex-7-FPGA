`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 13:49:45
// Design Name: 
// Module Name: REG_FILE_64Bit
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

//==============================================================================
// Module      : REG_FILE_64Bit
// Description : 32 x DATA_WIDTH general-purpose register file with two
//               asynchronous read ports and one synchronous write port.
//
// Behavior    : - x0 is hardwired to zero: reads return 0, writes are ignored.
//               - On reset every register is loaded with its own index
//                 (x5 = 5, x6 = 6, ...) so a test program produces
//                 non-trivial results without extra setup. For a production
//                 core, reset to zero or leave registers unreset.
//==============================================================================

module REG_FILE_64Bit #(
    parameter DATA_WIDTH = 64,
    parameter REG_ADDR_W = 5,
    parameter NUM_REGS   = (1 << REG_ADDR_W)
)(
    input  wire [REG_ADDR_W-1:0] READ_REG_NUM1,
    input  wire [REG_ADDR_W-1:0] READ_REG_NUM2,
    input  wire [REG_ADDR_W-1:0] WRITE_REG,
    input  wire [DATA_WIDTH-1:0] WRITE_DATA,
    output wire [DATA_WIDTH-1:0] READ_DATA1,
    output wire [DATA_WIDTH-1:0] READ_DATA2,
    input  wire                  REG_WRITE,
    input  wire                  CLK,
    input  wire                  RST
);

    reg [DATA_WIDTH-1:0] reg_mem [0:NUM_REGS-1];
    integer i;

    // Single driver for reg_mem: reset and write live in one process
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                reg_mem[i] <= i;
        end
        else if (REG_WRITE && (WRITE_REG != {REG_ADDR_W{1'b0}})) begin
            reg_mem[WRITE_REG] <= WRITE_DATA;
        end
    end

    // Asynchronous reads; x0 always reads as zero
    assign READ_DATA1 = (READ_REG_NUM1 == {REG_ADDR_W{1'b0}}) ? {DATA_WIDTH{1'b0}} : reg_mem[READ_REG_NUM1];
    assign READ_DATA2 = (READ_REG_NUM2 == {REG_ADDR_W{1'b0}}) ? {DATA_WIDTH{1'b0}} : reg_mem[READ_REG_NUM2];

endmodule
