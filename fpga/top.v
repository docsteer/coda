//  CODA - the Completely Open DMX Analyzer
//
// Copyright 2016 Tom Barthel-Steer
// http://www.tomsteer.net
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module top (
        input wire clk,         //-- System clock
        input wire rx,          //-- Serial input
        output wire tx,         //-- Serial output
        output wire tx_en,      //-- Serial transmit enable
        output wire LED,             //-- Red leds
        inout  USBP,            // USBP
        inout  USBN,            // USBN
        output USBPU,           // USB Pullup
        output PIN_22
        `ifdef simulation
          ,input clk_48mhz
        `endif
       );


////////////////////////////////////////////////////////////////////////////////
//-- Generate 48MHz clock for the USB
////////////////////////////////////////////////////////////////////////////////
wire clk_48mhz;
`ifndef simulation
SB_PLL40_CORE #(
 .DIVR(4'b0000),
 .DIVF(7'b0101111),
 .DIVQ(3'b100),
 .FILTER_RANGE(3'b001),
 .FEEDBACK_PATH("SIMPLE"),
 .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
 .FDA_FEEDBACK(4'b0000),
 .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
 .FDA_RELATIVE(4'b0000),
 .SHIFTREG_DIV_MODE(2'b00),
 .PLLOUT_SELECT("GENCLK"),
 .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
 .REFERENCECLK(clk),
 .PLLOUTCORE(clk_48mhz),
 .RESETB(1'b1),
 .BYPASS(1'b0)
);
`endif


  wire [7:0] usb_uart_di;
  reg [7:0] r_usb_uart_di;
  wire [7:0] usb_uart_do;
  wire usb_uart_re, usb_uart_we;
  wire usb_uart_wait;
  wire usb_uart_ready;
  reg blink_counter = 1'b1;
  reg r_LED;
  reg r_UsbUartWe2 = 1'b0;

  // Generate reset signal
  reg [5:0] usb_reset_cnt = 0;
  wire usb_resetn = &usb_reset_cnt;
  reg state = 0;

  always @(posedge clk_48mhz) usb_reset_cnt <= usb_reset_cnt + !usb_resetn;

parameter s_IDLE = 2'b00;
parameter s_HIGHNIBBLE = 2'b01;
parameter s_PREPLOWNIBBLE = 2'b10;
parameter s_LOWNIBBLE = 2'b11;

reg r_OutputState = 0;

  always @(posedge clk_48mhz)
  begin
    // Blink the LED with alternate packets based on break
    // to indicate valid incoming DMX
    if(breakdet && state==0)
    begin
      blink_counter <= blink_counter + 1;
      r_LED <= blink_counter;
    end
    else
    begin
      if(!breakdet) state <= 0;
    end
  end

  // usb uart

    wire usb_p_tx;
    wire usb_n_tx;
    wire usb_p_rx;
    wire usb_n_rx;
    wire usb_tx_en;
    wire usb_p_in;
    wire usb_n_in;

assign usb_uart_di = r_usb_uart_di;

`ifndef simulation
  usb_uart uart (
    .clk_48mhz  (clk_48mhz),
    .resetn     (usb_resetn),

    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),

    .uart_we  (usb_uart_we),
    .uart_re  (usb_uart_re),
    .uart_di  (usb_uart_di),
    .uart_do  (usb_uart_do),
    .uart_wait(usb_uart_wait),
    .uart_ready(usb_uart_ready)
  );


  assign USBPU = 1'b1;
  assign LED = usb_uart_ready;//r_LED;

  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbp
  (
    .PACKAGE_PIN(USBP),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_p_tx),
    .D_IN_0(usb_p_in)
  );

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbn
  (
    .PACKAGE_PIN(USBN),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_n_tx),
    .D_IN_0(usb_n_in)
  );
`endif

assign tx = 1'b0;
assign tx_en = 1'b0;

// drive USB pull-up resistor to '0' to disable USB
assign USBPU = 0;

//-- Received character signal
wire rcv;


// enable
reg enabl = 1;

// Break detect
wire breakdet;

parameter c_CLKS_PER_BIT = 64;

//-- Receiver unit instantation
wire [7:0] r_DMX_rx;
uart_rx  #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) RX0
      (
       .i_Clock(clk),           //-- System clock
       .i_Rx_Serial(rx),        //-- Serial input
       .o_Rx_DV(rcv),           //-- Character received notification (1)
       .o_Rx_Byte(r_DMX_rx),     //-- Character received
       .o_Rx_Break(breakdet)
      );


// DMX processor instantiation
dmx_rx DMX_RX
(
  .i_Clock(clk_48mhz),
  .i_Rx_DataReady(rcv),
  .i_RxData(r_DMX_rx),
  .i_RxBreak(breakdet),
  .i_usbReady(~usb_uart_ready),
  .o_dataReady(usb_uart_we),
  .o_data(usb_uart_di)
  );


endmodule
