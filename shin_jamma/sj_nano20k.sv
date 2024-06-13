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
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
    output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
    output [1:0] O_sdram_ba,        // two banks
    output [3:0] O_sdram_dqm,       // 32/4

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
  always @(posedge clk) begin
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
      clk_p5 <= ~clock_p5;
      clk_cnt <= (clk_cnt == 9) ? 0 : clk_cnt+1;
  end

  assign clk_p = clk_cnt[3] | (clk_cnt[2] & clk_cnt[0]) | (clk_cnt[2] & clk_cnt[1]);
  assign clock50MHz = clk_cnt[3] | (clk_cnt[2:0] == 3'b011) | (clk_cnt[2:0] = 3'b100);
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
  
  vg videogame(
  .clock50MHz_i(clock50MHz),
  .resetn_i(resetn),
  .p1_select_i(p1[0]),
  .p1_start_i(p1[3]),
  .p1_up_i(p1[4]),
  .p1_down_i(p1[6]),
  .p1_left_i(p1[7]),
  .p1_right_i(p1[5]),
  .p1_button1_i(p1[13]),
  .p1_button2_i(p1[14]),
  .p1_button3_i(p1[12]),
  .p1_button4_i(p1[15]),
  .p1_button5_i(p1[0]|p1[2]),
  .p1_button6_i(p1[1]|p1[3]),
  .p2_select_i(p2[0]),
  .p2_start_i(p2[3]),
  .p2_up_i(p2[4]),
  .p2_down_i(p2[6]),
  .p2_left_i(p2[7]),
  .p2_right_i(p2[5]),
  .p2_button1_i(p2[13]),
  .p2_button2_i(p2[14]),
  .p2_button3_i(p2[12]),
  .p2_button4_i(p2[15]),
  .p2_button5_i(p2[0]|p2[2]),
  .p2_button6_i(p2[1]|p2[3]),
  .switch_i(0),
  .wb_data_i(0),
  .wb_ack_i(0),
  .dmi_req_valid_i(0),
  .dmi_req_address_i(0),
  .dmi_req_data_i(0),
  .dmi_req_op_i(0),
  .dmi_rsp_ready_i(0),
  .v_r_o(),
  .v_g_o(),
  .v_b_o(),
  .v_vs_o(),
  .v_hs_o(),
  .v_clk_o(),
  .v_x_o(),
  .v_y_o(),
  .v_de_o(),
  .a_left_o(),
  .a_right_o(),
  .a_clk_o(),
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
  dualshock_controller #(.FREQ(21_600_000)) ds1 (
    .clk(clock50MHz), .I_RSTn(1'b1),
    .O_psCLK(joystick_clk), .O_psSEL(joystick_cs), .O_psTXD(joystick_mosi),
    .I_psRXD(joystick_miso),
    .O_RXD_1(p1[15:8]), .O_RXD_2(p1[7:0]), .O_RXD_3(),
    .O_RXD_4(), .O_RXD_5(), .O_RXD_6()
  );

  dualshock_controller #(.FREQ(21_600_000)) ds2 (
    .clk(clock50MHz), .I_RSTn(1'b1),
    .O_psCLK(joystick_clk2), .O_psSEL(joystick_cs2), .O_psTXD(joystick_mosi2),
    .I_psRXD(joystick_miso2),
    .O_RXD_1(p2[15:8]), .O_RXD_2(p2[7:0]), .O_RXD_3(),
    .O_RXD_4(), .O_RXD_5(), .O_RXD_6()
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
defparam rpll_inst.DEVICE = "GW2AR-18";

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


