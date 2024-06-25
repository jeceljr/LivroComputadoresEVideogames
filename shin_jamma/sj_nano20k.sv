// Shin JAMMA para Sipeed Tang Nano 20K
// (c) 2024 Jecel Mattos de Assumpção Jr
// módulos copiados do Nestang de nand2mario

module sj_nano20k(
    input sys_clk,
    // input sys_resetn,
    // input d7,
    // Button S1
    input s1,

    // UART
    input UART_RXD,
    output UART_TXD,

    // LEDs
    output [1:0] led,

    // SDRAM
    //output O_sdram_clk,
    //output O_sdram_cke,
    //output O_sdram_cs_n,            // chip select
    //output O_sdram_cas_n,           // columns address select
    //output O_sdram_ras_n,           // row address select
    //output O_sdram_wen_n,           // write enable
    //inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
    //output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
    //output [1:0] O_sdram_ba,        // two banks
    //output [3:0] O_sdram_dqm,       // 32/4

    // MicroSD
    output sd_clk,
    inout sd_cmd,      // MOSI
    input  sd_dat0,     // MISO
    output sd_dat1,     // 1
    output sd_dat2,     // 1
    output sd_dat3,     // 1
    
    // Dualshock game controller
    output joystick_clk,
    output joystick_mosi,
    input joystick_miso,
    output reg joystick_cs,
    output joystick_clk2,
    output joystick_mosi2,
    input joystick_miso2,
    output reg joystick_cs2,

    // USB
    inout usbdm,
    inout usbdp,
    inout usbdm2,
    inout usbdp2,
//    output clk_usb,

    // HDMI TX
    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// saidas ainda não implementadas
  assign UART_TXD = 0;
  assign O_sdram_addr = 11'd0;
  assign O_sdram_ba = 2'd0;
  assign O_sdram_dqm = 4'd0;
  assign sd_clk = 0;
  assign sd_dat1 = 0;
  assign sd_dat2 = 0;
  assign sd_dat3 = 0;


  reg sys_resetn = 0;
  reg [7:0] reset_cnt = 255;      // reset for 255 cycles before start everything
  always @(posedge sys_clk) begin
      reset_cnt <= reset_cnt == 0 ? 0 : reset_cnt - 1;
      if (reset_cnt == 0)
          sys_resetn <= ~s1;
  end

  // HDMI domain clocks
  wire clock50MHz;
  wire clk_p;     // 640x480 pixel clock: 25.2 MHz
  reg clk_p5;    // 5x pixel clock: 126 MHz
  wire clk_p10;   // 10x pixel clock: 252 MHz (27 * 28 / 3)
  wire pll_lock;

  Gowin_rPLL_hdmi pll_hdmi (
    .clkin(sys_clk),
    .clkout(clk_p10),
    .lock(pll_lock)
  );

  reg [3:0] clk_cnt;
  always@(posedge clk_p10) begin
      clk_p5 <= ~clk_p5;
      clk_cnt <= (clk_cnt == 9) ? 0 : clk_cnt+1;
  end

  assign clk_p = clk_cnt[3] | (clk_cnt[2] & clk_cnt[0]) | (clk_cnt[2] & clk_cnt[1]);
  assign clock50MHz = clk_cnt[3] | (clk_cnt[2:0] == 3'b011) | (clk_cnt[2:0] == 3'b100);
//0000 00
//0001 00
//0010 00
//0011 01
//0100 01
//0101 10
//0110 10
//0111 10
//1000 11
//1001 11

  wire [15:0] p1;
  wire [15:0] p2;

// HDMI output.
  wire[2:0] tmds;

//HDMI input
  reg clk_audio;
  wire [23:0] rgb;     // actual RGB output
  wire [15:0] audio_sample_word_L;
  wire [15:0] audio_sample_word_R;
  wire [9:0] cx;
  wire [9:0] cy;

  reg [10:0] audio_divider;
  always @(posedge clock50MHz)
  begin
     if (audio_divider != 524 )
         audio_divider <= audio_divider + 1;
     else begin
         audio_divider <= 0;
         clk_audio <= ~clk_audio; // 48000 Hz
     end
  end
  
  wire a_clk;
  reg [15:0] a_samp0L;
  reg [15:0] a_samp0R;
  reg [15:0] a_samp1L;
  reg [15:0] a_samp1R;
  always @(posedge v_clk) // de uma região de relógio para outra
  begin
      a_samp0L <= audio_sample_word_L;
      a_samp0R <= audio_sample_word_R;
      a_samp1L <= a_samp0L;
      a_samp1R <= a_samp0R;
  end

  // debug via LEDs
  wire v_clk;
  //assign led[0] = p1[5];
  //assign led[1] = p1[7];
  assign led[0] = audio_sample_word_L == 0; 
  
  vg videogame(
  .clock50MHz_i(clock50MHz),
  .resetn_i(sys_resetn),
  .p1_select_i(~p1[0]),
  .p1_start_i(~p1[3]),
  .p1_up_i(~p1[4]),
  .p1_down_i(~p1[6]),
  .p1_left_i(~p1[7]),
  .p1_right_i(~p1[5]),
  .p1_button1_i(~p1[13]),
  .p1_button2_i(~p1[14]),
  .p1_button3_i(~p1[12]),
  .p1_button4_i(~p1[15]),
  .p1_button5_i(~p1[0]|~p1[2]),
  .p1_button6_i(~p1[1]|~p1[3]),
  .p2_select_i(~p2[0]),
  .p2_start_i(~p2[3]),
  .p2_up_i(~p2[4]),
  .p2_down_i(~p2[6]),
  .p2_left_i(~p2[7]),
  .p2_right_i(~p2[5]),
  .p2_button1_i(~p2[13]),
  .p2_button2_i(~p2[14]),
  .p2_button3_i(~p2[12]),
  .p2_button4_i(~p2[15]),
  .p2_button5_i(~p2[0]|~p2[2]),
  .p2_button6_i(~p2[1]|~p2[3]),
  .switch_i(0),
  .wb_data_i(0),
  .wb_ack_i(0),
  .dmi_req_valid_i(0),
  .dmi_req_address_i(0),
  .dmi_req_data_i(0),
  .dmi_req_op_i(0),
  .dmi_rsp_ready_i(0),
  .v_r_o(rgb[23:16]),
  .v_g_o(rgb[15:8]),
  .v_b_o(rgb[7:0]),
  .v_vs_o(),
  .v_hs_o(),
  .v_clk_o(v_clk),
  .v_x_o(cx),
  .v_y_o(cy),
  .v_de_o(),
  .a_left_o(audio_sample_word_L),
  .a_right_o(audio_sample_word_R),
  .a_clk_o(a_clk),
  .led_o(),
  .seg_o(),
  .wb_adr_o(),
  .wb_dat_o(),
  .wb_we_o(),
  .wb_sel_o(),
  .wb_stb_o(),
  .wb_cyc_o(),
  .dmi_req_ready_o(),
  .dmi_rsp_valid_o(),
  .dmi_rsp_data_o(),
  .dmi_rsp_op_o()
  );

//  dualshock buttons:  0:(L D R U St R3 L3 Se)  1:(□ X O △ R1 L1 R2 L2)
//                         7 6 5 4 3  2  1  0       1514131211 10 9  8
  dualshock_controller #(.FREQ(50_000_000)) ds1 (
    .clk(clock50MHz), .I_RSTn(1'b1),
    .O_psCLK(joystick_clk), .O_psSEL(joystick_cs), .O_psTXD(joystick_mosi),
    .I_psRXD(joystick_miso),
    .O_RXD_1(p1[7:0]), .O_RXD_2(p1[15:8]), .O_RXD_3(),
    .O_RXD_4(), .O_RXD_5(), .O_RXD_6()
  );

  dualshock_controller #(.FREQ(50_000_000)) ds2 (
    .clk(clock50MHz), .I_RSTn(1'b1),
    .O_psCLK(joystick_clk2), .O_psSEL(joystick_cs2), .O_psTXD(joystick_mosi2),
    .I_psRXD(joystick_miso2),
    .O_RXD_1(p2[7:0]), .O_RXD_2(p2[15:8]), .O_RXD_3(),
    .O_RXD_4(), .O_RXD_5(), .O_RXD_6()
  );

wire [23:0] testrgb;
//assign testrgb = (cx[3] | cy[3]) ? 24'hFFFFFF : 24'h000000;
assign testrgb = ((((cx[0] & (cy[4:2] == 3'b000)) |
                    (cx[1] & (cy[4:2] == 3'b001)) |
                    (cx[2] & (cy[4:2] == 3'b010)) |
                    (cx[3] & (cy[4:2] == 3'b011)) |
                    (cx[4] & (cy[4:2] == 3'b100)) |
                    (cx[5] & (cy[4:2] == 3'b101)) |
                    (cx[6] & (cy[4:2] == 3'b110)) |
                    (cx[7] & (cy[4:2] == 3'b111))) & ~cx[8]) |
                  (((cy[0] & (cx[4:2] == 3'b000)) |
                    (cy[1] & (cx[4:2] == 3'b001)) |
                    (cy[2] & (cx[4:2] == 3'b010)) |
                    (cy[3] & (cx[4:2] == 3'b011)) |
                    (cy[4] & (cx[4:2] == 3'b100)) |
                    (cy[5] & (cx[4:2] == 3'b101)) |
                    (cy[6] & (cx[4:2] == 3'b110)) |
                    (cy[7] & (cx[4:2] == 3'b111))) & cx[8] &
                     (cy != 10'd0))
                 ) ? 24'hFFFFFF : 24'h000000; 

hdmi #( .VIDEO_ID_CODE(1), //640x480
        .DVI_OUTPUT(0), 
        .VIDEO_REFRESH_RATE(60.0),
        .IT_CONTENT(1),
        .AUDIO_RATE(48000), 
        .AUDIO_BIT_WIDTH(16),
        .START_X(0),
        .START_Y(0) )

  hdmi( .clk_pixel_x5(clk_p5), 
        .clk_pixel(v_clk),//.clk_pixel(clk_p), 
        .clk_audio(clk_audio),
        .rgb((cy != 10'd0) ? rgb : 24'h000000), 
        .reset(~sys_resetn),
        .audio_sample_word({a_samp1L,a_samp1R}),
        .tmds(tmds), 
        .tmds_clock(),//(tmdsClk),
        .cx(cx), 
        .cy(cy) );

// Gowin LVDS output buffer
  ELVDS_OBUF tmds_bufds [3:0] (
    .I({clk_p, tmds}),
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
  );

endmodule // sj_nano20k

module Gowin_rPLL_hdmi (clkout, lock, clkin);

output clkout;
output lock;
input clkin;

wire clkoutp_o;
wire clkoutd_o;
wire clkoutd3_o;
wire gw_gnd;

assign gw_gnd = 1'b0;

rPLL rpll_inst (
    .CLKOUT(clkout),
    .LOCK(lock),
    .CLKOUTP(clkoutp_o),
    .CLKOUTD(clkoutd_o),
    .CLKOUTD3(clkoutd3_o),
    .RESET(gw_gnd),
    .RESET_P(gw_gnd),
    .CLKIN(clkin),
    .CLKFB(gw_gnd),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam rpll_inst.FCLKIN = "27";
defparam rpll_inst.DYN_IDIV_SEL = "false";
defparam rpll_inst.IDIV_SEL = 2; // 10x@640x480, 252 = 27 * 28 / 3
defparam rpll_inst.DYN_FBDIV_SEL = "false";
defparam rpll_inst.FBDIV_SEL = 27;   // 10x@640x480
defparam rpll_inst.DYN_ODIV_SEL = "false";
defparam rpll_inst.ODIV_SEL = 2;
defparam rpll_inst.PSDA_SEL = "0000";
defparam rpll_inst.DYN_DA_EN = "true";
defparam rpll_inst.DUTYDA_SEL = "1000";
defparam rpll_inst.CLKOUT_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUTP_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUT_DLY_STEP = 0;
defparam rpll_inst.CLKOUTP_DLY_STEP = 0;
defparam rpll_inst.CLKFB_SEL = "internal";
defparam rpll_inst.CLKOUT_BYPASS = "false";
defparam rpll_inst.CLKOUTP_BYPASS = "false";
defparam rpll_inst.CLKOUTD_BYPASS = "false";
defparam rpll_inst.DYN_SDIV_SEL = 2;
defparam rpll_inst.CLKOUTD_SRC = "CLKOUT";
defparam rpll_inst.CLKOUTD3_SRC = "CLKOUT";
defparam rpll_inst.DEVICE = "GW2AR-18C";

endmodule //Gowin_rPLL

//-------------------------------------------------------------------
//                                                          
// PLAYSTATION CONTROLLER(DUALSHOCK TYPE) INTERFACE TOP          
//                                                          
// Version : 2.00                                           
//                                                          
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved  
//                                                          
// Important !                                              
//                                                          
// This program is freeware for non-commercial use.         
// An author does no guarantee about this program.          
// You can use this under your own risk.                    
// 
// 2003.10.30          It is optimized . by K Degawa 
// 2023.12 nand2mario: rewrite without ripple clocks to improve stability
//                     remove fine-grained vibration control as we don't use it                                                   
//-------------------------------------------------------------------

// Protocol: https://store.curiousinventor.com/guides/PS2/
// - Full duplex (command and data at the same time)
// - On negedge of clock, the line start to change. 
//   On posedge, values are read. 
// - Command   0x01 0x42(cmd) 0x00   0x00        0x00
//   Data      0xFF 0x41      0x5A   0xFF(btns)  0xFF(btns)
//                    ^- mode + # of words

//--------- SIMULATION ---------------------------------------------- 
//`define	SIMULATION_1	
//
// Poll controller status every 2^Timer clock cycles
// 125Khz / 2^11 = 61Hz
//
// SONY PLAYSTATION® CONTROLLER INFORMATION
// https://gamesx.com/controldata/psxcont/psxcont.htm
//
// "The DS4 stock polling rate is 250Hz 3-4 ms compared to the SN30 which is 67-75Hz 13-18 ms"
// https://www.reddit.com/r/8bitdo/comments/u8z3ag/has_anyone_managed_to_get_their_controllers/
`ifdef SIMULATION_1
`define Timer_siz 18  
`else
`define Timer_siz 11
`endif

module dualshock_controller #(
   parameter    FREQ             // frequency of `clk`
) (
   input        clk,             // Any main clock faster than 1Mhz 
   input        I_RSTn,          //  MAIN RESET

   output       O_psCLK,         //  psCLK CLK OUT
   output       O_psSEL,         //  psSEL OUT       
   output       O_psTXD,         //  psTXD OUT
   input        I_psRXD,         //  psRXD IN

   output reg [7:0] O_RXD_1,         //  RX DATA 1 (8bit)
   output reg [7:0] O_RXD_2,         //  RX DATA 2 (8bit)
   output reg [7:0] O_RXD_3,         //  RX DATA 3 (8bit)
   output reg [7:0] O_RXD_4,         //  RX DATA 4 (8bit)
   output reg [7:0] O_RXD_5,         //  RX DATA 5 (8bit)
   output reg [7:0] O_RXD_6          //  RX DATA 6 (8bit) 
);

reg I_CLK;          // SPI clock at 125Khz 
                    // some cheap controllers cannot handle the nominal 250Khz
reg R_CE, F_CE;     // rising and falling edge pulses of I_CLK

localparam CLK_DELAY = FREQ / 125_000 / 2;
reg [$clog2(CLK_DELAY)-1:0] clk_cnt;

// Generate I_CLK, F_CE, R_CE
always @(posedge clk) begin
    clk_cnt <= clk_cnt + 1;
    R_CE <= 0;
    F_CE <= 0;
    if (clk_cnt == CLK_DELAY-1) begin
        I_CLK <= ~I_CLK;
        R_CE <= ~I_CLK;
        F_CE <= I_CLK;
        clk_cnt <= 0;
    end
end

wire   W_type = 1'b1;        // DIGITAL PAD 0, ANALOG PAD 1
wire   [3:0] W_byte_cnt;
wire   W_RXWT;
wire   W_TXWT;
wire   W_TXEN;
reg    [7:0]W_TXD_DAT;
wire   [7:0]W_RXD_DAT;

ps_pls_gan pls(
   .clk(clk), .R_CE(R_CE), .I_CLK(I_CLK), .I_RSTn(I_RSTn), .I_TYPE(W_type), 
   .O_RXWT(W_RXWT), .O_TXWT(W_TXWT), 
   .O_TXEN(W_TXEN), .O_psCLK(O_psCLK), 
   .O_psSEL(O_psSEL), .O_byte_cnt(W_byte_cnt), .Timer()
); 

ps_txd txd(
   .clk(clk), .F_CE(F_CE), .I_RSTn(I_RSTn),
   .I_WT(W_TXWT), .I_EN(W_TXEN), .I_TXD_DAT(W_TXD_DAT), .O_psTXD(O_psTXD)
);

ps_rxd rxd(
   .clk(clk), .R_CE(R_CE), .I_RSTn(I_RSTn),	
   .I_WT(W_RXWT), .I_psRXD(I_psRXD), .O_RXD_DAT(W_RXD_DAT)
);

// TX command generation
always @* begin
    case(W_byte_cnt)
     0:   W_TXD_DAT = 8'h01;
     1:   W_TXD_DAT = 8'h42;
     3:   W_TXD_DAT = 8'h00;       // or vibration command
     4:   W_TXD_DAT = 8'h00;       // or vibration command
    default: W_TXD_DAT = 8'h00;
    endcase
end

// RX data decoding

reg W_RXWT_r;

always @(posedge clk) begin
    W_RXWT_r <= W_RXWT;
    if (~W_RXWT && W_RXWT_r) begin  // record received value one cycle after RXWT
        case (W_byte_cnt)
         3: O_RXD_1 <= W_RXD_DAT;
         4: O_RXD_2 <= W_RXD_DAT;
         5: O_RXD_3 <= W_RXD_DAT;
         6: O_RXD_4 <= W_RXD_DAT;
         7: O_RXD_5 <= W_RXD_DAT;
         8: O_RXD_6 <= W_RXD_DAT;
         default:;
        endcase
    end
end

endmodule


// timing signal generation module
module ps_pls_gan(
    input clk,
    input R_CE,
    input I_CLK,
    input I_RSTn,
    input I_TYPE,

    output O_RXWT,              // pulse to input RX byte
    output O_TXWT,              // pulse to output TX byte
    output O_TXEN,
    output O_psCLK,             // SPI clock to send to controller
    output O_psSEL,             // 0: active 
    output reg [3:0] O_byte_cnt,// index for byte received
    output reg [`Timer_siz-1:0] Timer   // increment on rising edge of I_CLK
);

parameter Timer_size = `Timer_siz;

reg RXWT, TXWT;
reg psCLK_gate;                 // 0: send I_CLK on wire
reg psSEL;          

// increment timer on I_CLK rising edge
always @(posedge clk) begin
    if (~I_RSTn) 
        Timer <= 0;
    else if (R_CE) 
        Timer <= Timer+1;
end

always @(posedge clk) begin
    if (~I_RSTn) begin
        psCLK_gate <= 1;
        RXWT     <= 0;
        TXWT     <= 0;
    end else begin
        TXWT <= 0;
        RXWT <= 0;
        if (R_CE) begin
            case (Timer[4:0])
             9:  TXWT <= 1;         // pulse to set byte to send
             12: psCLK_gate <= 0;   // send 8 cycles of clock: 
             20: begin
                    psCLK_gate <= 1;   // 13,14,15,16,17,18,19,20
                    RXWT <= 1;         // pulse to get received byte
                end
            default:;
            endcase
        end
    end
end

always @(posedge clk) begin
    if (~I_RSTn)
        psSEL <= 1;
    else if (R_CE) begin	
        if (Timer == 0)
            psSEL <= 0;
        else if ((I_TYPE == 0)&&(Timer == 158)) // end of byte 4
            psSEL <= 1;
        else if ((I_TYPE == 1)&&(Timer == 286)) // end of byte 9
            psSEL <= 1;
    end
end

always @(posedge clk) begin             // update O_byte_cnt
    if (!I_RSTn)
        O_byte_cnt <= 0;
    else if (R_CE) begin
        if (Timer == 0)
            O_byte_cnt <= 0;
        else begin 
            if (Timer[4:0] == 31) begin         // received a byte
                if (I_TYPE == 0 && O_byte_cnt == 5)
                    O_byte_cnt <= O_byte_cnt;
                else if (I_TYPE == 1 && O_byte_cnt == 9)
                    O_byte_cnt <= O_byte_cnt;
                else
                    O_byte_cnt <= O_byte_cnt + 4'd1;
            end    
        end
    end
end

assign O_psCLK = psCLK_gate | I_CLK | psSEL;
assign O_psSEL = psSEL;
assign O_RXWT  = ~psSEL & RXWT;
assign O_TXWT  = ~psSEL & TXWT;
assign O_TXEN  = ~psSEL & ~psCLK_gate;

endmodule

// receiver
module ps_rxd(
   input            clk,
   input            R_CE,       // one bit is transmitted on rising edge
   input            I_RSTn,	
   input            I_WT,       // pulse to output byte to O_RXD_DAT
   input            I_psRXD,
   output reg [7:0] O_RXD_DAT
);

reg     [7:0]   sp;

always @(posedge clk)
    if (~I_RSTn) begin
        sp <= 1;
        O_RXD_DAT <= 1;
    end else begin
        if (R_CE)         // posedge I_CLK
            sp <= { I_psRXD, sp[7:1]};
        if (I_WT)     
            O_RXD_DAT <= sp;
    end

endmodule

// transmitter
module ps_txd (
   input       clk,
   input       F_CE,       // transmit on falling edge of I_CLK
   input       I_RSTn,
   input       I_WT,       // pulse to load data to transmit
   input       I_EN,       // 1 to do transmission
   input [7:0] I_TXD_DAT,  // byte to transmit, lowest bit first
   output  reg O_psTXD     // output pin
);

reg   [7:0] ps;            // data buffer

always @(posedge clk) begin
   if (~I_RSTn) begin 
      O_psTXD <= 1;
      ps      <= 0;
   end else begin
      if (I_WT)
         ps  <= I_TXD_DAT;
      if (F_CE) begin       // bit is sent on falling edge of I_CLK
         if (I_EN) begin
            O_psTXD <= ps[0];
            ps      <= {1'b1, ps[7:1]};
         end else begin
            O_psTXD <= 1'd1;
            ps  <= ps;
         end
      end 
   end 	
end

endmodule

// Implementation of HDMI Spec v1.4a
// By Sameer Puri https://github.com/sameer

// Modificado para servir para Shin JAMMA

module hdmi 
#(
    // Defaults to 640x480 which should be supported by almost if not all HDMI sinks.
    // See README.md or CEA-861-D for enumeration of video id codes.
    // Pixel repetition, interlaced scans and other special output modes are not implemented (yet).
    parameter int VIDEO_ID_CODE = 1,

    // The IT content bit indicates that image samples are generated in an ad-hoc
    // manner (e.g. directly from values in a framebuffer, as by a PC video
    // card) and therefore aren't suitable for filtering or analog
    // reconstruction.  This is probably what you want if you treat pixels
    // as "squares".  If you generate a properly bandlimited signal or obtain
    // one from elsewhere (e.g. a camera), this can be turned off.
    //
    // This flag also tends to cause receivers to treat RGB values as full
    // range (0-255).
    parameter bit IT_CONTENT = 1'b1,

    // Defaults to minimum bit lengths required to represent positions.
    // Modify these parameters if you have alternate desired bit lengths.
    parameter int BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
    parameter int BIT_HEIGHT = VIDEO_ID_CODE == 16 ? 11: 10,

    // A true HDMI signal sends auxiliary data (i.e. audio, preambles) which prevents it from being parsed by DVI signal sinks.
    // HDMI signal sinks are fortunately backwards-compatible with DVI signals.
    // Enable this flag if the output should be a DVI signal. You might want to do this to reduce resource usage or if you're only outputting video.
    parameter bit DVI_OUTPUT = 1'b0,

    // **All parameters below matter ONLY IF you plan on sending auxiliary data (DVI_OUTPUT == 1'b0)**

    // Specify the refresh rate in Hz you are using for audio calculations
    parameter real VIDEO_REFRESH_RATE = 59.94,

    // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
    // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
    // Note that sinks may not support rates above 48 kHz.
    parameter int AUDIO_RATE = 44100,

    // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
    parameter int AUDIO_BIT_WIDTH = 16,

    // Some HDMI sinks will show the source product description below to users (i.e. in a list of inputs instead of HDMI 1, HDMI 2, etc.).
    // If you care about this, change it below.
    parameter bit [8*8-1:0] VENDOR_NAME = {"Unknown", 8'd0}, // Must be 8 bytes null-padded 7-bit ASCII
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = {"FPGA", 96'd0}, // Must be 16 bytes null-padded 7-bit ASCII
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h00, // See README.md or CTA-861-G for the list of valid codes

    // Starting screen coordinate when module comes out of reset.
    //
    // Setting these to something other than (0, 0) is useful when positioning
    // an external video signal within a larger overall frame (e.g.
    // letterboxing an input video signal). This allows you to synchronize the
    // negative edge of reset directly to the start of the external signal
    // instead of to some number of clock cycles before.
    //
    // You probably don't need to change these parameters if you are
    // generating a signal from scratch instead of processing an
    // external signal.
    parameter int START_X = 0,
    parameter int START_Y = 0
)
(
    input logic clk_pixel_x5,
    input logic clk_pixel,
    input logic clk_audio,
    // synchronous reset back to 0,0
    input logic reset,
    input logic [23:0] rgb,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],

    // These outputs go to your HDMI port
    output logic [2:0] tmds,
    output logic tmds_clock,
    
    // All outputs below this line stay inside the FPGA
    // They are used (by you) to pick the color each pixel should have
    // i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
    //output logic [BIT_WIDTH-1:0] cx = START_X,
    //output logic [BIT_HEIGHT-1:0] cy = START_Y,
    input logic [11:0] cx,
    input logic [11:0] cy,

    // The screen is at the upper left corner of the frame.
    // 0,0 = 0,0 in video
    // the frame includes extra space for sending auxiliary data
    output logic [BIT_WIDTH-1:0] frame_width,
    output logic [BIT_HEIGHT-1:0] frame_height,
    output logic [BIT_WIDTH-1:0] screen_width,
    output logic [BIT_HEIGHT-1:0] screen_height
);

localparam int NUM_CHANNELS = 3;
logic hsync;
logic vsync;

logic [BIT_WIDTH-1:0] hsync_pulse_start, hsync_pulse_size;
logic [BIT_HEIGHT-1:0] vsync_pulse_start, vsync_pulse_size;
logic invert;

// See CEA-861-D for more specifics formats described below.
generate
    case (VIDEO_ID_CODE)
        1:
        begin
            assign frame_width = 800;
            assign frame_height = 525;
            assign screen_width = 640;
            assign screen_height = 480;
            assign hsync_pulse_start = 16;
            assign hsync_pulse_size = 96;
            assign vsync_pulse_start = 10;
            assign vsync_pulse_size = 2;
            assign invert = 1;
            end
        2, 3:
        begin
            assign frame_width = 858;
            assign frame_height = 525;
            assign screen_width = 720;
            assign screen_height = 480;
            assign hsync_pulse_start = 16;
            assign hsync_pulse_size = 62;
            assign vsync_pulse_start = 9;
            assign vsync_pulse_size = 6;
            assign invert = 1;
            end
        4:
        begin
            assign frame_width = 1650;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync_pulse_start = 110;
            assign hsync_pulse_size = 40;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        16, 34:
        begin
            assign frame_width = 2200;
            assign frame_height = 1125;
            assign screen_width = 1920;
            assign screen_height = 1080;
            assign hsync_pulse_start = 88;
            assign hsync_pulse_size = 44;
            assign vsync_pulse_start = 4;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        17, 18:
        begin
            assign frame_width = 864;
            assign frame_height = 625;
            assign screen_width = 720;
            assign screen_height = 576;
            assign hsync_pulse_start = 12;
            assign hsync_pulse_size = 64;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 1;
        end
        19:
        begin
            assign frame_width = 1980;
            assign frame_height = 750;
            assign screen_width = 1280;
            assign screen_height = 720;
            assign hsync_pulse_start = 440;
            assign hsync_pulse_size = 40;
            assign vsync_pulse_start = 5;
            assign vsync_pulse_size = 5;
            assign invert = 0;
        end
        95, 105, 97, 107:
        begin
            assign frame_width = 4400;
            assign frame_height = 2250;
            assign screen_width = 3840;
            assign screen_height = 2160;
            assign hsync_pulse_start = 176;
            assign hsync_pulse_size = 88;
            assign vsync_pulse_start = 8;
            assign vsync_pulse_size = 10;
            assign invert = 0;
        end
    endcase
endgenerate

always_comb begin
    hsync <= invert ^ (cx >= screen_width + hsync_pulse_start && cx < screen_width + hsync_pulse_start + hsync_pulse_size);
    // vsync pulses should begin and end at the start of hsync, so special
    // handling is required for the lines on which vsync starts and ends
    if (cy == screen_height + vsync_pulse_start - 1)
        vsync <= invert ^ (cx >= screen_width + hsync_pulse_start);
    else if (cy == screen_height + vsync_pulse_start + vsync_pulse_size - 1)
        vsync <= invert ^ (cx < screen_width + hsync_pulse_start);
    else
        vsync <= invert ^ (cy >= screen_height + vsync_pulse_start && cy < screen_height + vsync_pulse_start + vsync_pulse_size);
end

localparam real VIDEO_RATE = (VIDEO_ID_CODE == 1 ? 25.2E6
    : VIDEO_ID_CODE == 2 || VIDEO_ID_CODE == 3 ? 27.027E6
    : VIDEO_ID_CODE == 4 ? 74.25E6
    : VIDEO_ID_CODE == 16 ? 148.5E6
    : VIDEO_ID_CODE == 17 || VIDEO_ID_CODE == 18 ? 27E6
    : VIDEO_ID_CODE == 19 ? 74.25E6
    : VIDEO_ID_CODE == 34 ? 74.25E6
    : VIDEO_ID_CODE == 95 || VIDEO_ID_CODE == 105 || VIDEO_ID_CODE == 97 || VIDEO_ID_CODE == 107 ? 594E6
    : 0) * (VIDEO_REFRESH_RATE == 59.94 || VIDEO_REFRESH_RATE == 29.97 ? 1000.0/1001.0 : 1); // https://groups.google.com/forum/#!topic/sci.engr.advanced-tv/DQcGk5R_zsM

// Wrap-around pixel position counters indicating the pixel to be generated by the user in THIS clock and sent out in the NEXT clock.
//always_ff @(posedge clk_pixel)
//begin
//    if (reset)
//    begin
//        cx <= BIT_WIDTH'(START_X);
//        cy <= BIT_HEIGHT'(START_Y);
//    end
//    else
//    begin
//        cx <= cx == frame_width-1'b1 ? BIT_WIDTH'(0) : cx + 1'b1;
//        cy <= cx == frame_width-1'b1 ? cy == frame_height-1'b1 ? (scrolly ? BIT_HEIGHT'(1) :BIT_HEIGHT'(0)) : cy + 1'b1 : cy;
//    end
//end

// See Section 5.2
logic video_data_period = 0;
always_ff @(posedge clk_pixel)
begin
    if (reset)
        video_data_period <= 0;
    else
        video_data_period <= cx < screen_width && cy < screen_height;
end

logic [2:0] mode = 3'd1;
logic [23:0] video_data = 24'd0;
logic [5:0] control_data = 6'd0;
logic [11:0] data_island_data = 12'd0;

generate
    if (!DVI_OUTPUT)
    begin: true_hdmi_output
        logic video_guard = 1;
        logic video_preamble = 0;
        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                video_guard <= 1;
                video_preamble <= 0;
            end
            else
            begin
                video_guard <= cx >= frame_width - 2 && cx < frame_width && (cy == frame_height - 1 || cy < screen_height - 1 /* no VG at end of last line */);
                video_preamble <= cx >= frame_width - 10 && cx < frame_width - 2 && (cy == frame_height - 1 || cy < screen_height - 1 /* no VP at end of last line */);
            end
        end

        // See Section 5.2.3.1
        int max_num_packets_alongside;
        logic [4:0] num_packets_alongside;
        always_comb
        begin
            max_num_packets_alongside = (frame_width - screen_width  /* VD period */ - 2 /* V guard */ - 8 /* V preamble */ - 4 /* Min V control period */ - 2 /* DI trailing guard */ - 2 /* DI leading guard */ - 8 /* DI premable */ - 4 /* Min DI control period */) / 32;
            if (max_num_packets_alongside > 18)
                num_packets_alongside = 5'd18;
            else
                num_packets_alongside = 5'(max_num_packets_alongside);
        end

        logic data_island_period_instantaneous;
        assign data_island_period_instantaneous = num_packets_alongside > 0 && cx >= screen_width + 14 && cx < screen_width + 14 + num_packets_alongside * 32;
        logic packet_enable;
        assign packet_enable = data_island_period_instantaneous && 5'(cx + screen_width + 18) == 5'd0;

        logic data_island_guard = 0;
        logic data_island_preamble = 0;
        logic data_island_period = 0;
        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                data_island_guard <= 0;
                data_island_preamble <= 0;
                data_island_period <= 0;
            end
            else
            begin
                data_island_guard <= num_packets_alongside > 0 && (
                    (cx >= screen_width + 12 && cx < screen_width + 14) /* leading guard */ || 
                    (cx >= screen_width + 14 + num_packets_alongside * 32 && cx < screen_width + 14 + num_packets_alongside * 32 + 2) /* trailing guard */
                );
                data_island_preamble <= num_packets_alongside > 0 && cx >= screen_width + 4 && cx < screen_width + 12;
                data_island_period <= data_island_period_instantaneous;
            end
        end

        // See Section 5.2.3.4
        logic [23:0] header;
        logic [55:0] sub [3:0];
        logic video_field_end;
        assign video_field_end = cx == screen_width - 1'b1 && cy == screen_height - 1'b1;
        logic [4:0] packet_pixel_counter;
        packet_picker #(
            .VIDEO_ID_CODE(VIDEO_ID_CODE),
            .VIDEO_RATE(VIDEO_RATE),
            .IT_CONTENT(IT_CONTENT),
            .AUDIO_RATE(AUDIO_RATE),
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .VENDOR_NAME(VENDOR_NAME),
            .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
            .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
        ) packet_picker (.clk_pixel(clk_pixel), .clk_audio(clk_audio), .reset(reset), .video_field_end(video_field_end), .packet_enable(packet_enable), .packet_pixel_counter(packet_pixel_counter), .audio_sample_word(audio_sample_word), .header(header), .sub(sub));
        logic [8:0] packet_data;
        packet_assembler packet_assembler (.clk_pixel(clk_pixel), .reset(reset), .data_island_period(data_island_period), .header(header), .sub(sub), .packet_data(packet_data), .counter(packet_pixel_counter));


        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                mode <= 3'd2;
                video_data <= 24'd0;
                control_data = 6'd0;
                data_island_data <= 12'd0;
            end
            else
            begin
                mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
                video_data <= rgb;
                control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
                data_island_data[11:4] <= packet_data[8:1];
                data_island_data[3] <= cx != 0;
                data_island_data[2] <= packet_data[0];
                data_island_data[1:0] <= {vsync, hsync};
            end
        end
    end
    else // DVI_OUTPUT = 1
    begin
        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                mode <= 3'd0;
                video_data <= 24'd0;
                control_data <= 6'd0;
            end
            else
            begin
                mode <= video_data_period ? 3'd1 : 3'd0;
                video_data <= rgb;
                control_data <= {4'b0000, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
            end
        end
    end
endgenerate

// All logic below relates to the production and output of the 10-bit TMDS code.
logic [9:0] tmds_internal [NUM_CHANNELS-1:0] /* verilator public_flat */ ;
genvar i;
generate
    // TMDS code production.
    for (i = 0; i < NUM_CHANNELS; i++)
    begin: tmds_gen
        tmds_channel #(.CN(i)) tmds_channel (.clk_pixel(clk_pixel), .video_data(video_data[i*8+7:i*8]), .data_island_data(data_island_data[i*4+3:i*4]), .control_data(control_data[i*2+1:i*2]), .mode(mode), .tmds(tmds_internal[i]));
    end
endgenerate

serializer #(.NUM_CHANNELS(NUM_CHANNELS), .VIDEO_RATE(VIDEO_RATE)) serializer(.clk_pixel(clk_pixel), .clk_pixel_x5(clk_pixel_x5), .reset(reset), .tmds_internal(tmds_internal), .tmds(tmds), .tmds_clock(tmds_clock));

endmodule

// Implementation of HDMI packet choice logic.
// By Sameer Puri https://github.com/sameer

module packet_picker
#(
    parameter int VIDEO_ID_CODE = 4,
    parameter real VIDEO_RATE = 0,
    parameter bit IT_CONTENT = 1'b0,
    parameter int AUDIO_BIT_WIDTH = 0,
    parameter int AUDIO_RATE = 0,
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0
)
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic reset,
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// Connect the current packet type's data to the output.
logic [7:0] packet_type = 8'd0;
logic [23:0] headers [255:0];
logic [55:0] subs [255:0] [3:0];
assign header = headers[packet_type];
assign sub[0] = subs[packet_type][0];
assign sub[1] = subs[packet_type][1];
assign sub[2] = subs[packet_type][2];
assign sub[3] = subs[packet_type][3];

// NULL packet
// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Null Packet Header and all bytes of the Null Packet Body."
`ifdef MODEL_TECH
assign headers[0] = {8'd0, 8'd0, 8'd0}; assign subs[0] = '{56'd0, 56'd0, 56'd0, 56'd0};
`else
assign headers[0] = {8'dX, 8'dX, 8'd0};
assign subs[0][0] = 56'dX;
assign subs[0][1] = 56'dX;
assign subs[0][2] = 56'dX;
assign subs[0][3] = 56'dX;
`endif

// Audio Clock Regeneration Packet
logic clk_audio_counter_wrap;
audio_clock_regeneration_packet #(.VIDEO_RATE(VIDEO_RATE), .AUDIO_RATE(AUDIO_RATE)) audio_clock_regeneration_packet (.clk_pixel(clk_pixel), .clk_audio(clk_audio), .clk_audio_counter_wrap(clk_audio_counter_wrap), .header(headers[1]), .sub(subs[1]));

// Audio Sample packet
localparam bit [3:0] SAMPLING_FREQUENCY = AUDIO_RATE == 32000 ? 4'b0011
    : AUDIO_RATE == 44100 ? 4'b0000
    : AUDIO_RATE == 88200 ? 4'b1000
    : AUDIO_RATE == 176400 ? 4'b1100
    : AUDIO_RATE == 48000 ? 4'b0010
    : AUDIO_RATE == 96000 ? 4'b1010
    : AUDIO_RATE == 192000 ? 4'b1110
    : 4'bXXXX;
localparam int AUDIO_BIT_WIDTH_COMPARATOR = AUDIO_BIT_WIDTH < 20 ? 20 : AUDIO_BIT_WIDTH == 20 ? 25 : AUDIO_BIT_WIDTH < 24 ? 24 : AUDIO_BIT_WIDTH == 24 ? 29 : -1;
localparam bit [2:0] WORD_LENGTH = 3'(AUDIO_BIT_WIDTH_COMPARATOR - AUDIO_BIT_WIDTH);
localparam bit WORD_LENGTH_LIMIT = AUDIO_BIT_WIDTH <= 20 ? 1'b0 : 1'b1;

logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_transfer [1:0];
logic audio_sample_word_transfer_control = 1'd0;
logic clk_audio_old;
always_ff @(posedge clk_pixel)
begin
    clk_audio_old <= clk_audio;
    if (clk_audio & ~clk_audio_old) begin
        audio_sample_word_transfer <= audio_sample_word;
        audio_sample_word_transfer_control <= !audio_sample_word_transfer_control;
    end
end

logic [1:0] audio_sample_word_transfer_control_synchronizer_chain = 2'd0;
always_ff @(posedge clk_pixel)
    audio_sample_word_transfer_control_synchronizer_chain <= {audio_sample_word_transfer_control, audio_sample_word_transfer_control_synchronizer_chain[1]};

logic sample_buffer_current = 1'b0;
logic [1:0] samples_remaining = 2'd0;
logic [23:0] audio_sample_word_buffer [1:0] [3:0] [1:0];
logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_transfer_mux [1:0];
always_comb
begin
    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1])
        audio_sample_word_transfer_mux = audio_sample_word_transfer;
    else
        audio_sample_word_transfer_mux = '{audio_sample_word_buffer[sample_buffer_current][samples_remaining][1][23:(24-AUDIO_BIT_WIDTH)], audio_sample_word_buffer[sample_buffer_current][samples_remaining][0][23:(24-AUDIO_BIT_WIDTH)]};
end

logic sample_buffer_used = 1'b0;
logic sample_buffer_ready = 1'b0;

always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_ready <= 1'b0;

    if (audio_sample_word_transfer_control_synchronizer_chain[0] ^ audio_sample_word_transfer_control_synchronizer_chain[1])
    begin
        audio_sample_word_buffer[sample_buffer_current][samples_remaining][0] <=  24'(audio_sample_word_transfer_mux[0])<<(24-AUDIO_BIT_WIDTH);
        audio_sample_word_buffer[sample_buffer_current][samples_remaining][1] <=  24'(audio_sample_word_transfer_mux[1])<<(24-AUDIO_BIT_WIDTH);
        if (samples_remaining == 2'd3)
        begin
            samples_remaining <= 2'd0;
            sample_buffer_ready <= 1'b1;
            sample_buffer_current <= !sample_buffer_current;
        end
        else
            samples_remaining <= samples_remaining + 1'd1;
    end
end

logic [23:0] audio_sample_word_packet [3:0] [1:0];
logic [3:0] audio_sample_word_present_packet;

logic [7:0] frame_counter = 8'd0;
int k;
always_ff @(posedge clk_pixel)
begin
    if (reset)
    begin
        frame_counter <= 8'd0;
    end
    else if (packet_pixel_counter == 5'd31 && packet_type == 8'h02) // Keep track of current IEC 60958 frame
    begin
        frame_counter = frame_counter + 8'd4;
        if (frame_counter >= 8'd192)
            frame_counter = frame_counter - 8'd192;
    end
end
audio_sample_packet #(.SAMPLING_FREQUENCY(SAMPLING_FREQUENCY), .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})) audio_sample_packet (.frame_counter(frame_counter), .valid_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .user_data_bit('{2'b00, 2'b00, 2'b00, 2'b00}), .audio_sample_word(audio_sample_word_packet), .audio_sample_word_present(audio_sample_word_present_packet), .header(headers[2]), .sub(subs[2]));


auxiliary_video_information_info_frame #(
    .VIDEO_ID_CODE(7'(VIDEO_ID_CODE)),
    .IT_CONTENT(IT_CONTENT)
) auxiliary_video_information_info_frame(.header(headers[130]), .sub(subs[130]));


source_product_description_info_frame #(.VENDOR_NAME(VENDOR_NAME), .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION), .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)) source_product_description_info_frame(.header(headers[131]), .sub(subs[131]));


audio_info_frame audio_info_frame(.header(headers[132]), .sub(subs[132]));


// "A Source shall always transmit... [an InfoFrame] at least once per two Video Fields"
logic audio_info_frame_sent = 1'b0;
logic auxiliary_video_information_info_frame_sent = 1'b0;
logic source_product_description_info_frame_sent = 1'b0;
logic last_clk_audio_counter_wrap = 1'b0;
always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_used <= 1'b0;

    if (reset || video_field_end)
    begin
        audio_info_frame_sent <= 1'b0;
        auxiliary_video_information_info_frame_sent <= 1'b0;
        source_product_description_info_frame_sent <= 1'b0;
        packet_type <= 8'dx;
    end
    else if (packet_enable)
    begin
        if (last_clk_audio_counter_wrap ^ clk_audio_counter_wrap)
        begin
            packet_type <= 8'd1;
            last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
        end
        else if (sample_buffer_ready)
        begin
            packet_type <= 8'd2;
            audio_sample_word_packet <= audio_sample_word_buffer[!sample_buffer_current];
            audio_sample_word_present_packet <= 4'b1111;
            sample_buffer_used <= 1'b1;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else if (!auxiliary_video_information_info_frame_sent)
        begin
            packet_type <= 8'h82;
            auxiliary_video_information_info_frame_sent <= 1'b1;
        end
        else if (!source_product_description_info_frame_sent)
        begin
            packet_type <= 8'h83;
            source_product_description_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;
    end
end

endmodule

// Implementation of HDMI packet ECC calculation.
// By Sameer Puri https://github.com/sameer

module packet_assembler (
    input logic clk_pixel,
    input logic reset,
    input logic data_island_period,
    input logic [23:0] header, // See Table 5-8 Packet Types
    input logic [55:0] sub [3:0],
    output logic [8:0] packet_data, // See Figure 5-4 Data Island Packet and ECC Structure
    output logic [4:0] counter = 5'd0
);

// 32 pixel wrap-around counter. See Section 5.2.3.4 for further information.
always_ff @(posedge clk_pixel)
begin
    if (reset)
        counter <= 5'd0;
    else if (data_island_period)
        counter <= counter + 5'd1;
end
// BCH packets 0 to 3 are transferred two bits at a time, see Section 5.2.3.4 for further information.
wire [5:0] counter_t2 = {counter, 1'b0};
wire [5:0] counter_t2_p1 = {counter, 1'b1};

// Initialize parity bits to 0
logic [7:0] parity [4:0] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};

wire [63:0] bch [3:0];
assign bch[0] = {parity[0], sub[0]};
assign bch[1] = {parity[1], sub[1]};
assign bch[2] = {parity[2], sub[2]};
assign bch[3] = {parity[3], sub[3]};
wire [31:0] bch4 = {parity[4], header};
assign packet_data = {bch[3][counter_t2_p1], bch[2][counter_t2_p1], bch[1][counter_t2_p1], bch[0][counter_t2_p1], bch[3][counter_t2], bch[2][counter_t2], bch[1][counter_t2], bch[0][counter_t2], bch4[counter]};

// See Figure 5-5 Error Correction Code generator. Generalization of a CRC with binary BCH.
// See https://web.archive.org/web/20190520020602/http://hamsterworks.co.nz/mediawiki/index.php/Minimal_HDMI#Computing_the_ECC for an explanation of the implementation.
// See https://en.wikipedia.org/wiki/BCH_code#Systematic_encoding:_The_message_as_a_prefix for further information.
function automatic [7:0] next_ecc;
input [7:0] ecc, next_bch_bit;
begin
    next_ecc = (ecc >> 1) ^ ((ecc[0] ^ next_bch_bit) ? 8'b10000011 : 8'd0);
end
endfunction

logic [7:0] parity_next [4:0];

// The parity needs to be calculated 2 bits at a time for blocks 0 to 3.
// There's 56 bits being sent 2 bits at a time over TMDS channels 1 & 2, so the parity bits wouldn't be ready in time otherwise.
logic [7:0] parity_next_next [3:0];

genvar i;
generate
    for(i = 0; i < 5; i++)
    begin: parity_calc
        if (i == 4)
            assign parity_next[i] = next_ecc(parity[i], header[counter]);
        else
        begin
            assign parity_next[i] = next_ecc(parity[i], sub[i][counter_t2]);
            assign parity_next_next[i] = next_ecc(parity_next[i], sub[i][counter_t2_p1]);
        end
    end
endgenerate

always_ff @(posedge clk_pixel)
begin
    if (reset)
        parity <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
    else if (data_island_period)
    begin
        if (counter < 5'd28) // Compute ECC only on subpacket data, not on itself
        begin
            parity[3:0] <= parity_next_next;
            if (counter < 5'd24) // Header only has 24 bits, whereas subpackets have 56 and 56 / 2 = 28.
                parity[4] <= parity_next[4];
        end
        else if (counter == 5'd31)
            parity <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0}; // Reset ECC for next packet
    end
    else
        parity <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
end

endmodule

// Implementation of HDMI Spec v1.4a Section 5.4: Encoding, Section 5.2.2.1: Video Guard Band, Section 5.2.3.3: Data Island Guard Bands.
// By Sameer Puri https://github.com/sameer

module tmds_channel
#(
    // TMDS Channel number.
    // There are only 3 possible channel numbers in HDMI 1.4a: 0, 1, 2.
    parameter int CN = 0
)
(
    input logic clk_pixel,
    input logic [7:0] video_data,
    input logic [3:0] data_island_data,
    input logic [1:0] control_data,
    input logic [2:0] mode,  // Mode select (0 = control, 1 = video, 2 = video guard, 3 = island, 4 = island guard)
    output logic [9:0] tmds = 10'b1101010100
);

// See Section 5.4.4.1
// Below is a direct implementation of Figure 5-7, using the same variable names.

logic signed [4:0] acc = 5'sd0;

logic [8:0] q_m;
logic [9:0] q_out;
logic [9:0] video_coding;
assign video_coding = q_out;

logic [3:0] N1D;
logic signed [4:0] N1q_m07;
logic signed [4:0] N0q_m07;
always_comb
begin
    N1D = video_data[0] + video_data[1] + video_data[2] + video_data[3] + video_data[4] + video_data[5] + video_data[6] + video_data[7];
    case(q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])
        4'b0000: N1q_m07 = 5'sd0;
        4'b0001: N1q_m07 = 5'sd1;
        4'b0010: N1q_m07 = 5'sd2;
        4'b0011: N1q_m07 = 5'sd3;
        4'b0100: N1q_m07 = 5'sd4;
        4'b0101: N1q_m07 = 5'sd5;
        4'b0110: N1q_m07 = 5'sd6;
        4'b0111: N1q_m07 = 5'sd7;
        4'b1000: N1q_m07 = 5'sd8;
        default: N1q_m07 = 5'sd0;
    endcase
    N0q_m07 = 5'sd8 - N1q_m07;
end

logic signed [4:0] acc_add;

integer i;

always_comb
begin
    if (N1D > 4'd4 || (N1D == 4'd4 && video_data[0] == 1'd0))
    begin
        q_m[0] = video_data[0];
        for(i = 0; i < 7; i++)
            q_m[i + 1] = q_m[i] ~^ video_data[i + 1];
        q_m[8] = 1'b0;
    end
    else
    begin
        q_m[0] = video_data[0];
        for(i = 0; i < 7; i++)
            q_m[i + 1] = q_m[i] ^ video_data[i + 1];
        q_m[8] = 1'b1;
    end
    if (acc == 5'sd0 || (N1q_m07 == N0q_m07))
    begin
        if (q_m[8])
        begin
            acc_add = N1q_m07 - N0q_m07;
            q_out = {~q_m[8], q_m[8], q_m[7:0]};
        end
        else
        begin
            acc_add = N0q_m07 - N1q_m07;
            q_out = {~q_m[8], q_m[8], ~q_m[7:0]};
        end
    end
    else
    begin
        if ((acc > 5'sd0 && N1q_m07 > N0q_m07) || (acc < 5'sd0 && N1q_m07 < N0q_m07))
        begin
            q_out = {1'b1, q_m[8], ~q_m[7:0]};
            acc_add = (N0q_m07 - N1q_m07) + (q_m[8] ? 5'sd2 : 5'sd0);
        end
        else
        begin
            q_out = {1'b0, q_m[8], q_m[7:0]};
            acc_add = (N1q_m07 - N0q_m07) - (~q_m[8] ? 5'sd2 : 5'sd0);
        end
    end
end

always_ff @(posedge clk_pixel) acc <= mode != 3'd1 ? 5'sd0 : acc + acc_add;

// See Section 5.4.2
logic [9:0] control_coding;
always_comb
begin
    unique case(control_data)
        2'b00: control_coding = 10'b1101010100;
        2'b01: control_coding = 10'b0010101011;
        2'b10: control_coding = 10'b0101010100;
        2'b11: control_coding = 10'b1010101011;
    endcase
end

// See Section 5.4.3
logic [9:0] terc4_coding;
always_comb
begin
    unique case(data_island_data)
        4'b0000 : terc4_coding = 10'b1010011100;
        4'b0001 : terc4_coding = 10'b1001100011;
        4'b0010 : terc4_coding = 10'b1011100100;
        4'b0011 : terc4_coding = 10'b1011100010;
        4'b0100 : terc4_coding = 10'b0101110001;
        4'b0101 : terc4_coding = 10'b0100011110;
        4'b0110 : terc4_coding = 10'b0110001110;
        4'b0111 : terc4_coding = 10'b0100111100;
        4'b1000 : terc4_coding = 10'b1011001100;
        4'b1001 : terc4_coding = 10'b0100111001;
        4'b1010 : terc4_coding = 10'b0110011100;
        4'b1011 : terc4_coding = 10'b1011000110;
        4'b1100 : terc4_coding = 10'b1010001110;
        4'b1101 : terc4_coding = 10'b1001110001;
        4'b1110 : terc4_coding = 10'b0101100011;
        4'b1111 : terc4_coding = 10'b1011000011;
    endcase
end

// See Section 5.2.2.1
logic [9:0] video_guard_band;
generate
    if (CN == 0 || CN == 2)
        assign video_guard_band = 10'b1011001100;
    else
        assign video_guard_band = 10'b0100110011;
endgenerate

// See Section 5.2.3.3
logic [9:0] data_guard_band;
generate
    if (CN == 1 || CN == 2)
        assign data_guard_band = 10'b0100110011;
    else
        assign data_guard_band = control_data == 2'b00 ? 10'b1010001110
            : control_data == 2'b01 ? 10'b1001110001
            : control_data == 2'b10 ? 10'b0101100011
            : 10'b1011000011;
endgenerate

// Apply selected mode.
always @(posedge clk_pixel)
begin
    case (mode)
        3'd0: tmds <= control_coding;
        3'd1: tmds <= video_coding;
        3'd2: tmds <= video_guard_band;
        3'd3: tmds <= terc4_coding;
        3'd4: tmds <= data_guard_band;
    endcase
end

endmodule

`define GW_IDE

module serializer
#(
    parameter int NUM_CHANNELS = 3,
    parameter real VIDEO_RATE
)
(
    input logic clk_pixel,
    input logic clk_pixel_x5,
    input logic reset,
    input logic [9:0] tmds_internal [NUM_CHANNELS-1:0],
    output logic [2:0] tmds,
    output logic tmds_clock
);

`ifndef VERILATOR
    `ifdef SYNTHESIS
        `ifndef ALTERA_RESERVED_QIS
            // https://www.xilinx.com/support/documentation/user_guides/ug471_7Series_SelectIO.pdf
            logic tmds_plus_clock [NUM_CHANNELS:0];
            assign tmds_plus_clock = '{tmds_clock, tmds[2], tmds[1], tmds[0]};
            logic [9:0] tmds_internal_plus_clock [NUM_CHANNELS:0];
            assign tmds_internal_plus_clock = '{10'b0000011111, tmds_internal[2], tmds_internal[1], tmds_internal[0]};
            logic [1:0] cascade [NUM_CHANNELS:0];

            // this is requried for OSERDESE2 to work
            logic internal_reset = 1'b1;
            always @(posedge clk_pixel)
            begin
                internal_reset <= 1'b0;
            end
            genvar i;
            generate
                for (i = 0; i <= NUM_CHANNELS; i++)
                begin: xilinx_serialize
                    OSERDESE2 #(
                        .DATA_RATE_OQ("DDR"),
                        .DATA_RATE_TQ("SDR"),
                        .DATA_WIDTH(10),
                        .SERDES_MODE("MASTER"),
                        .TRISTATE_WIDTH(1),
                        .TBYTE_CTL("FALSE"),
                        .TBYTE_SRC("FALSE")
                    ) primary (
                        .OQ(tmds_plus_clock[i]),
                        .OFB(),
                        .TQ(),
                        .TFB(),
                        .SHIFTOUT1(),
                        .SHIFTOUT2(),
                        .TBYTEOUT(),
                        .CLK(clk_pixel_x5),
                        .CLKDIV(clk_pixel),
                        .D1(tmds_internal_plus_clock[i][0]),
                        .D2(tmds_internal_plus_clock[i][1]),
                        .D3(tmds_internal_plus_clock[i][2]),
                        .D4(tmds_internal_plus_clock[i][3]),
                        .D5(tmds_internal_plus_clock[i][4]),
                        .D6(tmds_internal_plus_clock[i][5]),
                        .D7(tmds_internal_plus_clock[i][6]),
                        .D8(tmds_internal_plus_clock[i][7]),
                        .TCE(1'b0),
                        .OCE(1'b1),
                        .TBYTEIN(1'b0),
                        .RST(reset || internal_reset),
                        .SHIFTIN1(cascade[i][0]),
                        .SHIFTIN2(cascade[i][1]),
                        .T1(1'b0),
                        .T2(1'b0),
                        .T3(1'b0),
                        .T4(1'b0)
                    );
                    OSERDESE2 #(
                        .DATA_RATE_OQ("DDR"),
                        .DATA_RATE_TQ("SDR"),
                        .DATA_WIDTH(10),
                        .SERDES_MODE("SLAVE"),
                        .TRISTATE_WIDTH(1),
                        .TBYTE_CTL("FALSE"),
                        .TBYTE_SRC("FALSE")
                    ) secondary (
                        .OQ(),
                        .OFB(),
                        .TQ(),
                        .TFB(),
                        .SHIFTOUT1(cascade[i][0]),
                        .SHIFTOUT2(cascade[i][1]),
                        .TBYTEOUT(),
                        .CLK(clk_pixel_x5),
                        .CLKDIV(clk_pixel),
                        .D1(1'b0),
                        .D2(1'b0),
                        .D3(tmds_internal_plus_clock[i][8]),
                        .D4(tmds_internal_plus_clock[i][9]),
                        .D5(1'b0),
                        .D6(1'b0),
                        .D7(1'b0),
                        .D8(1'b0),
                        .TCE(1'b0),
                        .OCE(1'b1),
                        .TBYTEIN(1'b0),
                        .RST(reset || internal_reset),
                        .SHIFTIN1(1'b0),
                        .SHIFTIN2(1'b0),
                        .T1(1'b0),
                        .T2(1'b0),
                        .T3(1'b0),
                        .T4(1'b0)
                    );
                end
            endgenerate
        `endif
    `elsif GW_IDE
        OSER10 gwSer0( 
            .Q( tmds[ 0 ] ),
            .D0( tmds_internal[ 0 ][ 0 ] ),
            .D1( tmds_internal[ 0 ][ 1 ] ),
            .D2( tmds_internal[ 0 ][ 2 ] ),
            .D3( tmds_internal[ 0 ][ 3 ] ),
            .D4( tmds_internal[ 0 ][ 4 ] ),
            .D5( tmds_internal[ 0 ][ 5 ] ),
            .D6( tmds_internal[ 0 ][ 6 ] ),
            .D7( tmds_internal[ 0 ][ 7 ] ),
            .D8( tmds_internal[ 0 ][ 8 ] ),
            .D9( tmds_internal[ 0 ][ 9 ] ),
            .PCLK( clk_pixel ),
            .FCLK( clk_pixel_x5 ),
            .RESET( reset ) );

        OSER10 gwSer1( 
          .Q( tmds[ 1 ] ),
          .D0( tmds_internal[ 1 ][ 0 ] ),
          .D1( tmds_internal[ 1 ][ 1 ] ),
          .D2( tmds_internal[ 1 ][ 2 ] ),
          .D3( tmds_internal[ 1 ][ 3 ] ),
          .D4( tmds_internal[ 1 ][ 4 ] ),
          .D5( tmds_internal[ 1 ][ 5 ] ),
          .D6( tmds_internal[ 1 ][ 6 ] ),
          .D7( tmds_internal[ 1 ][ 7 ] ),
          .D8( tmds_internal[ 1 ][ 8 ] ),
          .D9( tmds_internal[ 1 ][ 9 ] ),
          .PCLK( clk_pixel ),
          .FCLK( clk_pixel_x5 ),
          .RESET( reset ) );

        OSER10 gwSer2( 
          .Q( tmds[ 2 ] ),
          .D0( tmds_internal[ 2 ][ 0 ] ),
          .D1( tmds_internal[ 2 ][ 1 ] ),
          .D2( tmds_internal[ 2 ][ 2 ] ),
          .D3( tmds_internal[ 2 ][ 3 ] ),
          .D4( tmds_internal[ 2 ][ 4 ] ),
          .D5( tmds_internal[ 2 ][ 5 ] ),
          .D6( tmds_internal[ 2 ][ 6 ] ),
          .D7( tmds_internal[ 2 ][ 7 ] ),
          .D8( tmds_internal[ 2 ][ 8 ] ),
          .D9( tmds_internal[ 2 ][ 9 ] ),
          .PCLK( clk_pixel ),
          .FCLK( clk_pixel_x5 ),
          .RESET( reset ) );
          
        assign tmds_clock = clk_pixel;
  
    `else
        logic [9:0] tmds_reversed [NUM_CHANNELS-1:0];
        genvar i, j;
        generate
            for (i = 0; i < NUM_CHANNELS; i++)
            begin: tmds_rev
                for (j = 0; j < 10; j++)
                begin: tmds_rev_channel
                    assign tmds_reversed[i][j] = tmds_internal[i][9-j];
                end
            end
        endgenerate
        `ifdef MODEL_TECH
            logic [3:0] position = 4'd0;
            always_ff @(posedge clk_pixel_x5)
            begin
                tmds <= {tmds_reversed[2][position], tmds_reversed[1][position], tmds_reversed[0][position]};
                tmds_clock <= position >= 4'd5;
                position <= position == 4'd9 ? 4'd0 : position + 1'd1;
            end
            always_ff @(negedge clk_pixel_x5)
            begin
                tmds <= {tmds_reversed[2][position], tmds_reversed[1][position], tmds_reversed[0][position]};
                tmds_clock <= position >= 4'd5;
                position <= position == 4'd9 ? 4'd0 : position + 1'd1;
            end
        `else
            `ifdef ALTERA_RESERVED_QIS
                altlvds_tx	ALTLVDS_TX_component (
                    .tx_in ({10'b1111100000, tmds_reversed[2], tmds_reversed[1], tmds_reversed[0]}),
                    .tx_inclock (clk_pixel_x5),
                    .tx_out ({tmds_clock, tmds[2], tmds[1], tmds[0]}),
                    .tx_outclock (),
                    .pll_areset (1'b0),
                    .sync_inclock (1'b0),
                    .tx_coreclock (),
                    .tx_data_reset (reset),
                    .tx_enable (1'b1),
                    .tx_locked (),
                    .tx_pll_enable (1'b1),
                    .tx_syncclock (clk_pixel));
                defparam
                    ALTLVDS_TX_component.center_align_msb = "UNUSED",
                    ALTLVDS_TX_component.common_rx_tx_pll = "OFF",
                    ALTLVDS_TX_component.coreclock_divide_by = 1,
                    // ALTLVDS_TX_component.data_rate = "800.0 Mbps",
                    ALTLVDS_TX_component.deserialization_factor = 10,
                    ALTLVDS_TX_component.differential_drive = 0,
                    ALTLVDS_TX_component.enable_clock_pin_mode = "UNUSED",
                    ALTLVDS_TX_component.implement_in_les = "OFF",
                    ALTLVDS_TX_component.inclock_boost = 0,
                    ALTLVDS_TX_component.inclock_data_alignment = "EDGE_ALIGNED",
                    ALTLVDS_TX_component.inclock_period = int'(10000000.0 / (VIDEO_RATE * 10.0)),
                    ALTLVDS_TX_component.inclock_phase_shift = 0,
                    // ALTLVDS_TX_component.intended_device_family = "Cyclone V",
                    ALTLVDS_TX_component.lpm_hint = "CBX_MODULE_PREFIX=altlvds_tx_inst",
                    ALTLVDS_TX_component.lpm_type = "altlvds_tx",
                    ALTLVDS_TX_component.multi_clock = "OFF",
                    ALTLVDS_TX_component.number_of_channels = 4,
                    // ALTLVDS_TX_component.outclock_alignment = "EDGE_ALIGNED",
                    // ALTLVDS_TX_component.outclock_divide_by = 1,
                    // ALTLVDS_TX_component.outclock_duty_cycle = 50,
                    // ALTLVDS_TX_component.outclock_multiply_by = 1,
                    // ALTLVDS_TX_component.outclock_phase_shift = 0,
                    // ALTLVDS_TX_component.outclock_resource = "Dual-Regional clock",
                    ALTLVDS_TX_component.output_data_rate = int'(VIDEO_RATE * 10.0),
                    ALTLVDS_TX_component.pll_compensation_mode = "AUTO",
                    ALTLVDS_TX_component.pll_self_reset_on_loss_lock = "OFF",
                    ALTLVDS_TX_component.preemphasis_setting = 0,
                    // ALTLVDS_TX_component.refclk_frequency = "20.000000 MHz",
                    ALTLVDS_TX_component.registered_input = "OFF",
                    ALTLVDS_TX_component.use_external_pll = "ON",
                    ALTLVDS_TX_component.use_no_phase_shift = "ON",
                    ALTLVDS_TX_component.vod_setting = 0,
                    ALTLVDS_TX_component.clk_src_is_pll = "off";
                `else
                    // We don't know what the platform is so the best bet is an IP-less implementation.
                    // Shift registers are loaded with a set of values from tmds_channels every clk_pixel.
                    // They are shifted out on clk_pixel_x5 by the time the next set is loaded.
                    logic [9:0] tmds_shift [NUM_CHANNELS-1:0] = '{10'd0, 10'd0, 10'd0};

                    logic tmds_control = 1'd0;
                    always_ff @(posedge clk_pixel)
                        tmds_control <= !tmds_control;

                    logic [3:0] tmds_control_synchronizer_chain = 4'd0;
                    always_ff @(posedge clk_pixel_x5)
                        tmds_control_synchronizer_chain <= {tmds_control, tmds_control_synchronizer_chain[3:1]};

                    logic load;
                    assign load = tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0];
                    logic [9:0] tmds_mux [NUM_CHANNELS-1:0];
                    always_comb
                    begin
                        if (load)
                            tmds_mux = tmds_internal;
                        else
                            tmds_mux = tmds_shift;
                    end

                    // See Section 5.4.1
                    for (i = 0; i < NUM_CHANNELS; i++)
                    begin: tmds_shifting
                        always_ff @(posedge clk_pixel_x5)
                            tmds_shift[i] <= load ? tmds_mux[i] : tmds_shift[i] >> 2;
                    end

                    logic [9:0] tmds_shift_clk_pixel = 10'b0000011111;
                    always_ff @(posedge clk_pixel_x5)
                        tmds_shift_clk_pixel <= load ? 10'b0000011111 : {tmds_shift_clk_pixel[1:0], tmds_shift_clk_pixel[9:2]};

                    logic [NUM_CHANNELS-1:0] tmds_shift_negedge_temp;
                    for (i = 0; i < NUM_CHANNELS; i++)
                    begin: tmds_driving
                        always_ff @(posedge clk_pixel_x5)
                        begin
                            tmds[i] <= tmds_shift[i][0];
                            tmds_shift_negedge_temp[i] <= tmds_shift[i][1];
                        end
                        always_ff @(negedge clk_pixel_x5)
                            tmds[i] <= tmds_shift_negedge_temp[i];
                    end
                    logic tmds_clock_negedge_temp;
                    always_ff @(posedge clk_pixel_x5)
                    begin
                        tmds_clock <= tmds_shift_clk_pixel[0];
                        tmds_clock_negedge_temp <= tmds_shift_clk_pixel[1];
                    end
                    always_ff @(negedge clk_pixel_x5)
                        tmds_clock <= tmds_shift_negedge_temp;

                `endif
        `endif
    `endif
`endif
endmodule

// Implementation of HDMI audio clock regeneration packet
// By Sameer Puri https://github.com/sameer

// See HDMI 1.4b Section 5.3.3
module audio_clock_regeneration_packet
#(
    parameter real VIDEO_RATE = 25.2E6,
    parameter int AUDIO_RATE = 48e3
)
(
    input logic clk_pixel,
    input logic clk_audio,
    output logic clk_audio_counter_wrap = 0,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// See Section 7.2.3, values derived from "Other" row in Tables 7-1, 7-2, 7-3.
localparam bit [19:0] N = AUDIO_RATE % 125 == 0 ? 20'(16 * AUDIO_RATE / 125) : AUDIO_RATE % 225 == 0 ? 20'(32 * AUDIO_RATE / 225) : 20'(AUDIO_RATE * 16 / 125);

localparam int CLK_AUDIO_COUNTER_WIDTH = $clog2(N / 128);
localparam bit [CLK_AUDIO_COUNTER_WIDTH-1:0] CLK_AUDIO_COUNTER_END = CLK_AUDIO_COUNTER_WIDTH'(N / 128 - 1);
logic [CLK_AUDIO_COUNTER_WIDTH-1:0] clk_audio_counter = CLK_AUDIO_COUNTER_WIDTH'(0);
logic internal_clk_audio_counter_wrap = 1'd0;

logic clk_audio_old;
// always_ff @(posedge clk_audio)
always_ff @(posedge clk_pixel)
begin
    clk_audio_old <= clk_audio;
    if (clk_audio & ~clk_audio_old) begin
        if (clk_audio_counter == CLK_AUDIO_COUNTER_END)
        begin
            clk_audio_counter <= CLK_AUDIO_COUNTER_WIDTH'(0);
            internal_clk_audio_counter_wrap <= !internal_clk_audio_counter_wrap;
        end
        else
            clk_audio_counter <= clk_audio_counter + 1'd1;
    end
end

logic [1:0] clk_audio_counter_wrap_synchronizer_chain = 2'd0;
always_ff @(posedge clk_pixel)
    clk_audio_counter_wrap_synchronizer_chain <= {internal_clk_audio_counter_wrap, clk_audio_counter_wrap_synchronizer_chain[1]};

localparam bit [19:0] CYCLE_TIME_STAMP_COUNTER_IDEAL = 20'(int'(VIDEO_RATE * int'(N) / 128 / AUDIO_RATE));
localparam int CYCLE_TIME_STAMP_COUNTER_WIDTH = $clog2(20'(int'(real'(CYCLE_TIME_STAMP_COUNTER_IDEAL) * 1.1))); // Account for 10% deviation in audio clock

logic [19:0] cycle_time_stamp = 20'd0;
logic [CYCLE_TIME_STAMP_COUNTER_WIDTH-1:0] cycle_time_stamp_counter = CYCLE_TIME_STAMP_COUNTER_WIDTH'(0);
always_ff @(posedge clk_pixel)
begin
    if (clk_audio_counter_wrap_synchronizer_chain[1] ^ clk_audio_counter_wrap_synchronizer_chain[0])
    begin
        cycle_time_stamp_counter <= CYCLE_TIME_STAMP_COUNTER_WIDTH'(0);
        cycle_time_stamp <= {(20-CYCLE_TIME_STAMP_COUNTER_WIDTH)'(0), cycle_time_stamp_counter + CYCLE_TIME_STAMP_COUNTER_WIDTH'(1)};
        clk_audio_counter_wrap <= !clk_audio_counter_wrap;
    end
    else
        cycle_time_stamp_counter <= cycle_time_stamp_counter + CYCLE_TIME_STAMP_COUNTER_WIDTH'(1);
end

// "An HDMI Sink shall ignore bytes HB1 and HB2 of the Audio Clock Regeneration Packet header."
`ifdef MODEL_TECH
assign header = {8'd0, 8'd0, 8'd1};
`else
assign header = {8'dX, 8'dX, 8'd1};
`endif

// "The four Subpackets each contain the same Audio Clock regeneration Subpacket."
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: same_packet
        assign sub[i] = {N[7:0], N[15:8], {4'd0, N[19:16]}, cycle_time_stamp[7:0], cycle_time_stamp[15:8], {4'd0, cycle_time_stamp[19:16]}, 8'd0};
    end
endgenerate

endmodule

// Implementation of HDMI audio sample packet
// By Sameer Puri https://github.com/sameer

// Unless otherwise specified, all "See X" references will refer to the HDMI v1.4a specification.

// See Section 5.3.4
// 2-channel L-PCM or IEC 61937 audio in IEC 60958 frames with consumer grade IEC 60958-3.
module audio_sample_packet 
#(
    // A thorough explanation of the below parameters can be found in IEC 60958-3 5.2, 5.3.

    // 0 = Consumer, 1 = Professional
    parameter bit GRADE = 1'b0,

    // 0 = LPCM, 1 = IEC 61937 compressed
    parameter bit SAMPLE_WORD_TYPE = 1'b0,

    // 0 = asserted, 1 = not asserted
    parameter bit COPYRIGHT_NOT_ASSERTED = 1'b1,

    // 000 = no pre-emphasis, 001 = 50μs/15μs pre-emphasis
    parameter bit [2:0] PRE_EMPHASIS = 3'b000,

    // Only one valid value
    parameter bit [1:0] MODE = 2'b00,

    // Set to all 0s for general device.
    parameter bit [7:0] CATEGORY_CODE = 8'd0,

    // TODO: not really sure what this is...
    // 0 = "Do no take into account"
    parameter bit [3:0] SOURCE_NUMBER = 4'd0,

    // 0000 = 44.1 kHz
    parameter bit [3:0] SAMPLING_FREQUENCY = 4'b0000,

    // Normal accuracy: +/- 1000 * 10E-6 (00), High accuracy +/- 50 * 10E-6 (01)
    parameter bit [1:0] CLOCK_ACCURACY = 2'b00,

    // 3-bit representation of the number of bits to subtract (except 101 is actually subtract 0) with LSB first, followed by maxmium length of 20 bits (0) or 24 bits (1)
    parameter bit [3:0] WORD_LENGTH = 0,

    // Frequency prior to conversion in a consumer playback system. 0000 = not indicated.
    parameter bit [3:0] ORIGINAL_SAMPLING_FREQUENCY = 4'b0000,

    // 2-channel = 0, >= 3-channel = 1
    parameter bit LAYOUT = 1'b0

)
(
    input logic [7:0] frame_counter,
    // See IEC 60958-1 4.4 and Annex A. 0 indicates the signal is suitable for decoding to an analog audio signal.
    input logic [1:0] valid_bit [3:0],
    // See IEC 60958-3 Section 6. 0 indicates that no user data is being sent
    input logic [1:0] user_data_bit [3:0],
    input logic [23:0] audio_sample_word [3:0] [1:0],
    input logic [3:0] audio_sample_word_present,
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// Left/right channel for stereo audio
logic [3:0] CHANNEL_LEFT = 4'd1;
logic [3:0] CHANNEL_RIGHT = 4'd2;

localparam bit [7:0] CHANNEL_STATUS_LENGTH = 8'd192;
// See IEC 60958-1 5.1, Table 2
logic [192-1:0] channel_status_left;
assign channel_status_left = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_LEFT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};
logic [CHANNEL_STATUS_LENGTH-1:0] channel_status_right;
assign channel_status_right = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_RIGHT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};


// See HDMI 1.4a Table 5-12: Audio Sample Packet Header.
assign header[19:12] = {4'b0000, {3'b000, LAYOUT}};
assign header[7:0] = 8'd2;
logic [1:0] parity_bit [3:0];
logic [7:0] aligned_frame_counter [3:0];
genvar i;
generate
    for (i = 0; i < 4; i++)
    begin: sample_based_assign
        always_comb
        begin
            if (8'(frame_counter + i) >= CHANNEL_STATUS_LENGTH)
                aligned_frame_counter[i] = 8'(frame_counter + i - CHANNEL_STATUS_LENGTH);
            else
                aligned_frame_counter[i] = 8'(frame_counter + i);
        end
        assign header[23 - (3-i)] = aligned_frame_counter[i] == 8'd0 && audio_sample_word_present[i];
        assign header[11 - (3-i)] = audio_sample_word_present[i];
        assign parity_bit[i][0] = ^{channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0], audio_sample_word[i][0]};
        assign parity_bit[i][1] = ^{channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], audio_sample_word[i][1]};
        // See HDMI 1.4a Table 5-13: Audio Sample Subpacket.
        always_comb
        begin
            if (audio_sample_word_present[i])
                sub[i] = {{parity_bit[i][1], channel_status_right[aligned_frame_counter[i]], user_data_bit[i][1], valid_bit[i][1], parity_bit[i][0], channel_status_left[aligned_frame_counter[i]], user_data_bit[i][0], valid_bit[i][0]}, audio_sample_word[i][1], audio_sample_word[i][0]};
            else
            `ifdef MODEL_TECH
                sub[i] = 56'd0;
            `else
                sub[i] = 56'dx;
            `endif
        end
    end
endgenerate

endmodule

// Implementation of HDMI Auxiliary Video InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See Section 8.2.1
module auxiliary_video_information_info_frame
#(
    parameter bit [1:0] VIDEO_FORMAT = 2'b00, // 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
    parameter bit ACTIVE_FORMAT_INFO_PRESENT = 1'b0, // Not valid
    parameter bit [1:0] BAR_INFO = 2'b00, // Not valid
    parameter bit [1:0] SCAN_INFO = 2'b00, // No data
    parameter bit [1:0] COLORIMETRY = 2'b00, // No data
    parameter bit [1:0] PICTURE_ASPECT_RATIO = 2'b00, // No data, See CEA-CEB16 for more information about Active Format Description processing.
    parameter bit [3:0] ACTIVE_FORMAT_ASPECT_RATIO = 4'b1000, // Not valid unless ACTIVE_FORMAT_INFO_PRESENT = 1'b1, then Same as picture aspect ratio
    parameter bit IT_CONTENT = 1'b0, //  The IT content bit indicates when picture content is composed according to common IT practice (i.e. without regard to Nyquist criterion) and is unsuitable for analog reconstruction or filtering. When the IT content bit is set to 1, downstream processors should pass pixel data unfiltered and without analog reconstruction.
    parameter bit [2:0] EXTENDED_COLORIMETRY = 3'b000, // Not valid unless COLORIMETRY = 2'b11. The extended colorimetry bits, EC2, EC1, and EC0, describe optional colorimetry encoding that may be applicable to some implementations and are always present, whether their information is valid or not (see CEA 861-D Section 7.5.5).
    parameter bit [1:0] RGB_QUANTIZATION_RANGE = 2'b00, // Default. Displays conforming to CEA-861-D accept both a limited quantization range of 220 levels (16 to 235) anda full range of 256 levels (0 to 255) when receiving video with RGB color space (see CEA 861-D Sections 5.1, Section 5.2, Section 5.3 and Section 5.4). By default, RGB pixel data values should be assumed to have the limited range when receiving a CE video format, and the full range when receiving an IT format. The quantization bits allow the source to override this default and to explicitly indicate the current RGB quantization range.
    parameter bit [1:0] NON_UNIFORM_PICTURE_SCALING = 2'b00, // None. The Nonuniform Picture Scaling bits shall be set if the source device scales the picture or has determined that scaling has been performed in a specific direction.
    parameter int VIDEO_ID_CODE = 4, // Same as the one from the HDMI module
    parameter bit [1:0] YCC_QUANTIZATION_RANGE = 2'b00, // 00 = Limited, 01 = Full
    parameter bit [1:0] CONTENT_TYPE = 2'b00, // No data, becomes Graphics if IT_CONTENT = 1'b1.
    parameter bit [3:0] PIXEL_REPETITION = 4'b0000 // None
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);


localparam bit [4:0] LENGTH = 5'd13;
localparam bit [7:0] VERSION = 8'd2;
localparam bit [6:0] TYPE = 7'd2;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[13] + packet_bytes[12] + packet_bytes[11] + packet_bytes[10] + packet_bytes[9] + packet_bytes[8] + packet_bytes[7] + packet_bytes[6] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);
assign packet_bytes[1] = {1'b0, VIDEO_FORMAT, ACTIVE_FORMAT_INFO_PRESENT, BAR_INFO, SCAN_INFO};
assign packet_bytes[2] = {COLORIMETRY, PICTURE_ASPECT_RATIO, ACTIVE_FORMAT_ASPECT_RATIO};
assign packet_bytes[3] = {IT_CONTENT, EXTENDED_COLORIMETRY, RGB_QUANTIZATION_RANGE, NON_UNIFORM_PICTURE_SCALING};
assign packet_bytes[4] = {1'b0, 7'(VIDEO_ID_CODE)};
assign packet_bytes[5] = {YCC_QUANTIZATION_RANGE, CONTENT_TYPE, PIXEL_REPETITION};

genvar i;
generate
    if (BAR_INFO != 2'b00) // Assign values to bars if BAR_INFO says they are valid.
    begin
        assign packet_bytes[6] = 8'hff;
        assign packet_bytes[7] = 8'hff;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'hff;
        assign packet_bytes[11] = 8'hff;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end else begin
        assign packet_bytes[6] = 8'h00;
        assign packet_bytes[7] = 8'h00;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'h00;
        assign packet_bytes[11] = 8'h00;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end
    for (i = 14; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate

endmodule

// Implementation of HDMI SPD InfoFrame packet.
// By Sameer Puri https://github.com/sameer

// See CEA-861-D Section 6.5 page 72 (84 in PDF)
module source_product_description_info_frame
#(
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

localparam bit [4:0] LENGTH = 5'd25;
localparam bit [7:0] VERSION = 8'd1;
localparam bit [6:0] TYPE = 7'd3;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[25] + packet_bytes[24] + packet_bytes[23] + packet_bytes[22] + packet_bytes[21] + packet_bytes[20] + packet_bytes[19] + packet_bytes[18] + packet_bytes[17] + packet_bytes[16] + packet_bytes[15] + packet_bytes[14] + packet_bytes[13] + packet_bytes[12] + packet_bytes[11] + packet_bytes[10] + packet_bytes[9] + packet_bytes[8] + packet_bytes[7] + packet_bytes[6] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);


byte vendor_name [0:7];
byte product_description [0:15];

genvar i;
generate
    for (i = 0; i < 8; i++)
    begin: vendor_to_bytes
        assign vendor_name[i] = VENDOR_NAME[(7-i+1)*8-1:(7-i)*8];
    end
    for (i = 0; i < 16; i++)
    begin: product_to_bytes
        assign product_description[i] = PRODUCT_DESCRIPTION[(15-i+1)*8-1:(15-i)*8];
    end

    for (i = 1; i < 9; i++)
    begin: pb_vendor
        assign packet_bytes[i] = vendor_name[i - 1] == 8'h30 ? 8'h00 : vendor_name[i - 1];
    end
    for (i = 9; i < LENGTH; i++)
    begin: pb_product
        assign packet_bytes[i] = product_description[i - 9] == 8'h30 ? 8'h00 : product_description[i - 9];
    end
    assign packet_bytes[LENGTH] = SOURCE_DEVICE_INFORMATION;
    for (i = 26; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate

endmodule

// Implementation of HDMI audio info frame
// By Sameer Puri https://github.com/sameer

// See Section 8.2.2
module audio_info_frame
#(
    parameter bit [2:0] AUDIO_CHANNEL_COUNT = 3'd1, // 2 channels. See CEA-861-D table 17 for details.
    parameter bit [7:0] CHANNEL_ALLOCATION = 8'h00, // Channel 0 = Front Left, Channel 1 = Front Right (0-indexed)
    parameter bit DOWN_MIX_INHIBITED = 1'b0, // Permitted or no information about any assertion of this. The DM_INH field is to be set only for DVD-Audio applications.
    parameter bit [3:0] LEVEL_SHIFT_VALUE = 4'd0, // 4-bit unsigned number from 0dB up to 15dB, used for downmixing.
    parameter bit [1:0] LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL = 2'b00 // No information, LFE = bass-only info < 120Hz, used in Dolby Surround.
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

// NOTE—HDMI requires the coding type, sample size and sample frequency fields to be set to 0 ("Refer to Stream Header") as these items are carried in the audio stream
localparam bit [3:0] AUDIO_CODING_TYPE = 4'd0; // Refer to stream header.
localparam bit [2:0] SAMPLING_FREQUENCY = 3'd0; // Refer to stream header.
localparam bit [1:0] SAMPLE_SIZE = 2'd0; // Refer to stream header.

localparam bit [4:0] LENGTH = 5'd10;
localparam bit [7:0] VERSION = 8'd1;
localparam bit [6:0] TYPE = 7'd4;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);
assign packet_bytes[1] = {AUDIO_CODING_TYPE, 1'b0, AUDIO_CHANNEL_COUNT};
assign packet_bytes[2] = {3'd0, SAMPLING_FREQUENCY, SAMPLE_SIZE};
assign packet_bytes[3] = 8'd0;
assign packet_bytes[4] = CHANNEL_ALLOCATION;
assign packet_bytes[5] = {DOWN_MIX_INHIBITED, LEVEL_SHIFT_VALUE, 1'b0, LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL};

genvar i;
generate
    for (i = 6; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i++)
    begin: pb_to_sub
        assign sub[i] = {packet_bytes[6 + i*7], packet_bytes[5 + i*7], packet_bytes[4 + i*7], packet_bytes[3 + i*7], packet_bytes[2 + i*7], packet_bytes[1 + i*7], packet_bytes[0 + i*7]};
    end
endgenerate
endmodule
