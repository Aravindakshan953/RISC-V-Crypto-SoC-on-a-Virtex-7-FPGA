`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 10:35:12
// Design Name: 
// Module Name: ALU_64
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


module ALU_64(
    input [63:0] IN1,IN2, 
    input[3:0] ALU_CNTRL,
    output reg [63:0] ALU_RSLT,
    output reg ZERO_FLAG
    );
    
    always @(*)
    begin
        // Operating based on control input
        case(ALU_CNTRL)

        4'b0000: ALU_RSLT = IN1&IN2;
        4'b0001: ALU_RSLT = IN1|IN2;
        4'b0010: ALU_RSLT = IN1+IN2;
        4'b0100: ALU_RSLT = IN1-IN2;
        4'b1000: begin 
            if(IN1 < IN2)
            ALU_RSLT = 1;
            else
            ALU_RSLT = 0;
        end
        4'b0011: ALU_RSLT = IN1<<IN2;
        4'b0101: ALU_RSLT = IN1>>IN2;
        4'b0110: ALU_RSLT = IN1*IN2;
        4'b0111: ALU_RSLT = IN1^IN2;

        endcase

        // Setting Zero_flag if ALU_result is zero
        if (ALU_RSLT == 0)
            ZERO_FLAG = 1'b1;
        else
            ZERO_FLAG = 1'b0;
        
    end
endmodule
