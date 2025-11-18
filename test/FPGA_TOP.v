// Module : Tiny Tapestation FPGA Interface

module TTS_FPGA_top (
    // System Signals
    input  wire          CLK,            // PIN E3 (100 MHZ Clk)
    input  wire          RST_N,          // PIN J15 
    // Controller Signals
    input  wire          NES_DATA,       // PIN H1 
    input  wire          SNES_PMOD_Data,
    input  wire          SNES_PMOD_Latch,
    input  wire          SNES_PMOD_Clk,
    
    input wire   [2:0]       test_switchs,
    
    output wire          NES_LATCH,      // PIN G1
    output wire          NES_CLK,        // PIN G3
    output wire [4:0] CONTROLLER_LED ,
    // VGA signals
    output wire  [3:0]   R,              // PINS: A4 C5 B4 A3
    output wire  [3:0]   G,              // PINS: A6 B6 A5 C6
    output wire  [3:0]   B,              // PINS: D8 D7 C7 B7
    output wire          H_SYNC,         // PIN B11
    output wire          V_SYNC,         // PIN B12
    // Audio Signals
    output wire          PWM,            // PIN A11 (Headphone Jack)
    output wire          aud_sd_o
);
    assign aud_sd_o = 1'b1; 

    wire R_LO, R_HI, G_LO, G_HI, B_LO, B_HI; // RGB Output Signals (VGA)
    
    wire [7:0] uio_out_bus;
    
    wire PWM_ori;
    assign PWM = PWM_ori? 1'b1:1'b0;

    assign uio_out_bus = {PWM_ori,4'b0000, NES_LATCH, NES_CLK, 1'b0};
    
    wire clk;
    clk_wiz_0 clk_div(
    .reset(1'b0),
    .clk_in1(CLK),
    .clk_out1(clk)
    );
   
    /* Make sure the name is consistent with the current iteration of the chip! */
    tt_um_enjimneering_tts_top tts ( // Make sure the i/o pinout is accurate according to the spec!
        .ui_in    ({1'b0, SNES_PMOD_Data, SNES_PMOD_Clk, SNES_PMOD_Latch,1'b1,2'b00, NES_DATA}),    
        .uo_out   ({H_SYNC, B_LO, G_LO, R_LO, V_SYNC, B_HI, G_HI, R_HI}), 
        .uio_in   ({8'b0000_0000}),   
        .uio_out  (uio_out_bus),    
        .uio_oe   ({8'b0000_0111}),                      
        .ena      (1),                                   
        .clk      (clk),      
        .rst_n    (RST_N)
    );
    
    assign R[1:0] =  {R_LO, R_LO};
    assign R[3:2] =  {R_HI, R_HI};
    assign G[1:0] =  {G_LO, G_LO};
    assign G[3:2] =  {G_HI, G_HI};
    assign B[1:0] =  {B_LO, B_LO};
    assign B[3:2] =  {B_HI, B_HI};
    

    assign CONTROLLER_LED = {tts.A_out, tts.up_out, tts.down_out, tts.left_out, tts.right_out};
    
   
endmodule
