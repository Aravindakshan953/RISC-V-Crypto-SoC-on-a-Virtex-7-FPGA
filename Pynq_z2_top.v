`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.10.2026 10:06:47
// Design Name: 
// Module Name: Pynq_z2_top
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
module rv64_crypto_pynq_top #(
    parameter [63:0]   BUILD_ID      = 64'h5256_3634_4352_5950, // ASCII "RV64CRYP"
    parameter integer  HEARTBEAT_BIT = 25                       // must be 0..26
) (
    input  wire        CLK125MHZ,
    input  wire [3:0]  BTN,
    input  wire [1:0]  SW,
    output wire [3:0]  LED,
    output wire [7:0]  JB
);
 
    // ------------------------------------------------------------------ clocks
    wire clk50;
    wire clk_locked;
 
    clk_50mhz_from_125 u_clkgen (
        .clk125 (CLK125MHZ),
        .reset  (1'b0),
        .clk50  (clk50),
        .locked (clk_locked)
    );
 
    // ------------------------------------------- input synchronisers (2-FF each)
    (* ASYNC_REG = "TRUE" *) reg [1:0] btn0_sync = 2'b00;   // reset button
    (* ASYNC_REG = "TRUE" *) reg [1:0] btn1_sync = 2'b00;   // next byte lane
    (* ASYNC_REG = "TRUE" *) reg [1:0] btn2_sync = 2'b00;   // word select [0]
    (* ASYNC_REG = "TRUE" *) reg [1:0] btn3_sync = 2'b00;   // word select [1]
    (* ASYNC_REG = "TRUE" *) reg [1:0] sw0_sync  = 2'b00;   // LED mode [0]
    (* ASYNC_REG = "TRUE" *) reg [1:0] sw1_sync  = 2'b00;   // LED mode [1]
 
    always @(posedge clk50) begin
        btn0_sync <= {btn0_sync[0], BTN[0]};
        btn1_sync <= {btn1_sync[0], BTN[1]};
        btn2_sync <= {btn2_sync[0], BTN[2]};
        btn3_sync <= {btn3_sync[0], BTN[3]};
        sw0_sync  <= {sw0_sync[0],  SW[0]};
        sw1_sync  <= {sw1_sync[0],  SW[1]};
    end
 
    wire board_reset = btn0_sync[1];
 
    // ---------------------------------------------------------- reset sequencer
    reg [19:0] lock_high_cnt = 20'd0;
    reg [19:0] lock_low_cnt  = 20'd0;
    reg        rst_n_r       = 1'b0;
 
    always @(posedge clk50) begin
        if (clk_locked) begin
            lock_low_cnt <= 20'd0;
            if (!lock_high_cnt[19])
                lock_high_cnt <= lock_high_cnt + 20'd1;
        end else begin
            lock_high_cnt <= 20'd0;
            if (!lock_low_cnt[19])
                lock_low_cnt <= lock_low_cnt + 20'd1;
        end
 
        if (board_reset)
            rst_n_r <= 1'b0;
        else if (lock_low_cnt[19])
            rst_n_r <= 1'b0;
        else if (!rst_n_r && lock_high_cnt[19])
            rst_n_r <= 1'b1;
    end
 
    wire rst_n = rst_n_r;
 
    // ------------------------------------------------- 64-bit RISC-V SoC (yours)
    wire        soc_trap;
    wire        soc_axi_read;
    wire        soc_axi_write;
    wire [63:0] fw_magic;
    wire [63:0] fw_passmask;
    wire [63:0] fw_stage;
    wire [63:0] fw_detail;
 
    riscv_crypto_soc u_soc (
        .clk          (clk50),
        .rst_n        (rst_n),
        .trap_o       (soc_trap),
        .axi_read_o   (soc_axi_read),
        .axi_write_o  (soc_axi_write),
        .fw_magic_o   (fw_magic),
        .fw_passmask_o(fw_passmask),
        .fw_stage_o   (fw_stage),
        .fw_detail_o  (fw_detail)
    );
 
    // ------------------------------------------------------ heartbeat + activity
    reg [26:0] heartbeat_cnt    = 27'd0;
    reg [23:0] activity_stretch = 24'd0;
 
    always @(posedge clk50) begin
        if (!rst_n) begin
            heartbeat_cnt    <= 27'd0;
            activity_stretch <= 24'd0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 27'd1;
            if (soc_axi_read || soc_axi_write)
                activity_stretch <= 24'hffffff;
            else if (activity_stretch != 24'd0)
                activity_stretch <= activity_stretch - 24'd1;
        end
    end
 
    // ---------------------------------------------- firmware viewer (64-bit words)
    // BTN3:BTN2 picks the word, each BTN1 press moves to the next byte lane.
    //   00 = BUILD_ID   01 = fw_magic   10 = fw_stage   11 = fw_detail
    wire [1:0] word_sel = {btn3_sync[1], btn2_sync[1]};
 
    reg [63:0] view_word;
    always @(*) begin
        case (word_sel)
            2'b00:   view_word = BUILD_ID;
            2'b01:   view_word = fw_magic;
            2'b10:   view_word = fw_stage;
            default: view_word = fw_detail;
        endcase
    end
 
    reg        btn1_q    = 1'b0;
    reg [2:0]  lane_sel  = 3'd0;
    reg [19:0] lane_hold = 20'd0;          // ~21 ms lockout against bounce
    wire       lane_edge = btn1_sync[1] & ~btn1_q;
 
    always @(posedge clk50) begin
        btn1_q <= btn1_sync[1];
        if (!rst_n) begin
            lane_sel  <= 3'd0;
            lane_hold <= 20'd0;
        end else if (lane_hold != 20'd0) begin
            lane_hold <= lane_hold - 20'd1;
        end else if (lane_edge) begin
            lane_sel  <= lane_sel + 3'd1;
            lane_hold <= 20'hfffff;
        end
    end
 
    wire [7:0] view_byte = view_word[{lane_sel, 3'b000} +: 8];
 
    // ------------------------------------------------------------------- LEDs
    //   SW1 SW0
    //    0   0  system status   {activity, trap, in-reset, heartbeat}
    //    0   1  fw_passmask[3:0]
    //    1   0  viewer byte, low  nibble
    //    1   1  viewer byte, high nibble
    wire [3:0] led_system = { |activity_stretch, soc_trap, ~rst_n,
                              heartbeat_cnt[HEARTBEAT_BIT] };
    reg  [3:0] led_out;
    always @(*) begin
        case ({sw1_sync[1], sw0_sync[1]})
            2'b00:   led_out = led_system;
            2'b01:   led_out = fw_passmask[3:0];
            2'b10:   led_out = view_byte[3:0];
            default: led_out = view_byte[7:4];
        endcase
    end
    assign LED = led_out;
 
    // --------------------------------------- Pmod JB: scope / logic-analyser pins
    assign JB[0] = clk50;
    assign JB[1] = rst_n;
    assign JB[2] = soc_trap;
    assign JB[3] = soc_axi_read;
    assign JB[4] = soc_axi_write;
    assign JB[5] = heartbeat_cnt[24];
    assign JB[6] = fw_magic[0];
    assign JB[7] = fw_stage[0];
 
endmodule
 
 
// =============================================================================
// 125 MHz -> 50 MHz clock generator (MMCM: VCO = 125 x 8 = 1000 MHz, /20)
// =============================================================================
module clk_50mhz_from_125 (
    input  wire clk125,
    input  wire reset,
    output wire clk50,
    output wire locked
);
`ifdef __ICARUS__
    assign clk50  = clk125;
    assign locked = !reset;
`else
    wire clkfb;
    wire clkfb_buf;
    wire clk50_mmcm;
 
    MMCME2_BASE #(
        .BANDWIDTH        ("OPTIMIZED"),
        .CLKFBOUT_MULT_F  (8.000),
        .CLKFBOUT_PHASE   (0.000),
        .CLKIN1_PERIOD    (8.000),
        .CLKOUT0_DIVIDE_F (20.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT0_PHASE    (0.000),
        .CLKOUT1_DIVIDE   (1),
        .CLKOUT2_DIVIDE   (1),
        .CLKOUT3_DIVIDE   (1),
        .CLKOUT4_CASCADE  ("FALSE"),
        .CLKOUT4_DIVIDE   (1),
        .CLKOUT5_DIVIDE   (1),
        .CLKOUT6_DIVIDE   (1),
        .DIVCLK_DIVIDE    (1),
        .REF_JITTER1      (0.010),
        .STARTUP_WAIT     ("FALSE")
    ) u_mmcm (
        .CLKIN1   (clk125),
        .CLKFBIN  (clkfb_buf),
        .RST      (reset),
        .PWRDWN   (1'b0),
        .CLKFBOUT (clkfb),
        .CLKFBOUTB(),
        .CLKOUT0  (clk50_mmcm),
        .CLKOUT0B (),
        .CLKOUT1  (), .CLKOUT1B(),
        .CLKOUT2  (), .CLKOUT2B(),
        .CLKOUT3  (), .CLKOUT3B(),
        .CLKOUT4  (), .CLKOUT5 (), .CLKOUT6 (),
        .LOCKED   (locked)
    );
 
    BUFG u_clkfb_buf (.I(clkfb),      .O(clkfb_buf));
    BUFG u_clk50_buf (.I(clk50_mmcm), .O(clk50));
`endif
endmodule
