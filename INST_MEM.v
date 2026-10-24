`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.10.2026 11:35:20
// Design Name: 
// Module Name: INST_MEM
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

module INST_MEM #(
    parameter ADDR_W    = 6,                 // 2**6 = 64 bytes = 16 instructions
    parameter MEM_BYTES = (1 << ADDR_W)
)(
    input  wire [31:0] PC,
    output wire [31:0] INST_CODE
);

    reg [7:0] mem [0:MEM_BYTES-1];

    wire [ADDR_W-1:0] addr = PC[ADDR_W-1:0];

    // Little-endian instruction fetch
    assign INST_CODE = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};

    // Store one 32-bit word little-endian at a byte address
    task store_word;
        input integer byte_addr;
        input [31:0]  word;
        begin
            mem[byte_addr]     = word[7:0];
            mem[byte_addr + 1] = word[15:8];
            mem[byte_addr + 2] = word[23:16];
            mem[byte_addr + 3] = word[31:24];
        end
    endtask

    // Program is loaded once at time zero, so no reset is needed
    integer i;
    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'h00;

        store_word( 0, 32'h00940333);   // add t1, s0,  s1
        store_word( 4, 32'h413903b3);   // sub t2, s2,  s3
        store_word( 8, 32'h035a02b3);   // mul t0, s4,  s5
        store_word(12, 32'h017b4e33);   // xor t3, s6,  s7
        store_word(16, 32'h019c1eb3);   // sll t4, s8,  s9
        store_word(20, 32'h01bd5f33);   // srl t5, s10, s11
        store_word(24, 32'h00d67fb3);   // and t6, a2,  a3
        store_word(28, 32'h00f768b3);   // or  a7, a4,  a5
    end

endmodule
