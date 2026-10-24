`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 10:46:13
// Design Name: 
// Module Name: CNTRL_64Bit
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

module CNTRL_64Bit (
    input  wire [6:0] FUNCT7,
    input  wire [2:0] FUNCT3,
    input  wire [6:0] OPCODE,
    output reg  [3:0] ALU_CNTRL,
    output reg        REG_WRITE
);

    //--------------------------------------------------------------------------
    // Encodings
    //--------------------------------------------------------------------------
    localparam [6:0] OP_RTYPE = 7'b0110011;

    localparam [2:0] F3_ADD_SUB = 3'd0;
    localparam [2:0] F3_SLL     = 3'd1;
    localparam [2:0] F3_MUL     = 3'd2;   // custom encoding (SLT in standard RISC-V)
    localparam [2:0] F3_XOR     = 3'd4;
    localparam [2:0] F3_SRL     = 3'd5;
    localparam [2:0] F3_OR      = 3'd6;
    localparam [2:0] F3_AND     = 3'd7;

    localparam [6:0] F7_ADD = 7'b0000000;
    localparam [6:0] F7_SUB = 7'b0100000;

    localparam [3:0] ALU_AND = 4'b0000;
    localparam [3:0] ALU_OR  = 4'b0001;
    localparam [3:0] ALU_ADD = 4'b0010;
    localparam [3:0] ALU_SLL = 4'b0011;
    localparam [3:0] ALU_SUB = 4'b0100;
    localparam [3:0] ALU_SRL = 4'b0101;
    localparam [3:0] ALU_MUL = 4'b0110;
    localparam [3:0] ALU_XOR = 4'b0111;

    //--------------------------------------------------------------------------
    // Decode logic
    // Defaults are assigned first so every output is driven on every path
    // (no latches are inferred).
    //--------------------------------------------------------------------------
    always @(*) begin
        ALU_CNTRL = ALU_AND;
        REG_WRITE = 1'b0;

        if (OPCODE == OP_RTYPE) begin
            REG_WRITE = 1'b1;

            case (FUNCT3)
                F3_ADD_SUB: begin
                    case (FUNCT7)
                        F7_ADD:  ALU_CNTRL = ALU_ADD;
                        F7_SUB:  ALU_CNTRL = ALU_SUB;
                        default: REG_WRITE = 1'b0;   // illegal funct7
                    endcase
                end
                F3_SLL:  ALU_CNTRL = ALU_SLL;
                F3_MUL:  ALU_CNTRL = ALU_MUL;
                F3_XOR:  ALU_CNTRL = ALU_XOR;
                F3_SRL:  ALU_CNTRL = ALU_SRL;
                F3_OR:   ALU_CNTRL = ALU_OR;
                F3_AND:  ALU_CNTRL = ALU_AND;
                default: REG_WRITE = 1'b0;           // unsupported funct3
            endcase
        end
    end

endmodule
