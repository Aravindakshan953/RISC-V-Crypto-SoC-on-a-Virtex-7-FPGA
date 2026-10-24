`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 11:24:14
// Design Name: 
// Module Name: IFU_64Bit
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

module IFU_64Bit #(
    parameter PC_WIDTH   = 32,
    parameter INST_WIDTH = 64,
    parameter PC_STEP    = INST_WIDTH / 16
)(
    input  wire                  CLK,
    input  wire                  RST,
    output wire [INST_WIDTH-1:0] INST_CODE
);

    //--------------------------------------------------------------------------
    // Program counter
    //--------------------------------------------------------------------------
    reg [PC_WIDTH-1:0] pc;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            pc <= {PC_WIDTH{1'b0}};
        else
            pc <= pc + PC_STEP;
    end

    //--------------------------------------------------------------------------
    // Instruction memory
    // TODO: switch to named ports once INST_MEM's port names are confirmed.
    // Current order: address, reset, instruction out
    //--------------------------------------------------------------------------
    INST_MEM u_inst_mem (
        .PC(pc),
        .INST_CODE(INST_CODE)
    );

endmodule
