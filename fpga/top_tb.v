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

`timescale 1 us / 1 ns

module top_tb();

//-- Baudrate for the simulation
// Baud = 250 000Hz; convert to picoseconds
localparam BAUDRATE = 4;

// Break time - 88us
localparam  BREAKTIME = 360;

//-- clock tics needed for sending one serial package
localparam SERIAL_PACK = (BAUDRATE * 10);

//-- Time between two characters
localparam WAIT = (BAUDRATE * 4);

//-- Number of slots in the simulated packets - lower for faster sim
localparam DMX_PACKET_LEN = 12;

//----------------------------------------
//-- Task to produce an 88uS DMX Break
//-- 88uS = 1408 cycles at 16MHz
//----------------------------------------
task send_break;
  begin
    rx <= 0;
    #BREAKTIME
    rx <= 1;
  end
endtask

//----------------------------------------
//-- Task for sending a character in serial
//----------------------------------------
  task send_char;
    input [7:0] char;
  begin
    rx <= 0;                   //-- Send the Start bit
    #BAUDRATE rx <= char[0];   //-- Bit 0
    #BAUDRATE rx <= char[1];   //-- Bit 1
    #BAUDRATE rx <= char[2];   //-- Bit 2
    #BAUDRATE rx <= char[3];   //-- Bit 3
    #BAUDRATE rx <= char[4];   //-- Bit 4
    #BAUDRATE rx <= char[5];   //-- Bit 5
    #BAUDRATE rx <= char[6];   //-- Bit 6
    #BAUDRATE rx <= char[7];   //-- Bit 7
    #BAUDRATE rx <= 1;         //-- stop bit
    #BAUDRATE rx <= 1;         //-- Wait until the bits stop is sent
  end
  endtask

//-- System clock
reg clk = 0;

//-- Wire connected to the rx port for transmiting to the receiver
reg rx = 1;

//-- For connecting the leds
wire led;

reg clk_48mhz = 0;

//-- Instantiate the entity to test
top #(.BAUDRATE(BAUDRATE))
  dut(
    .clk(clk),
    .rx(rx),
    .LED(led),
    .USBP(USBP),            // USBP
    .USBN(USBN),            // USBN
    .USBPU(USBPU),           // USB Pullup
    .clk_48mhz(clk_48mhz)
  );

//-- Clock generator
// Clock rate 16MHz = 0.625 x 10ns
always
  # 0.03125 clk <= ~clk;

// Simulate 48MHz PLL clock for USB
always
  # 0.0208 clk_48mhz <= ~clk_48mhz;

reg[10:0] i;

initial begin

  //-- File where to store the simulation
  $dumpfile(`"`VCD_OUTPUT`");
  $dumpvars(0, top_tb);


  //-- Sent some DMX
  //-- Start Code
  #BAUDRATE    send_char(8'h00);
  for (i = 0; i < DMX_PACKET_LEN; i = i+1) begin
   	  	#WAIT        send_char(i);
 	end
  #1000 //-- Interpacket
  send_break();
  #BAUDRATE    send_char(8'h00);
  #WAIT        send_char(8'h01);
  #WAIT        send_char(8'h02);
  #WAIT        send_char(8'h03);
  #WAIT        send_char(8'h04);
  #WAIT        send_char(8'h05);
  #WAIT        send_char(8'h06);
  #WAIT        send_char(8'h07);
  #WAIT        send_char(8'h08);
  #WAIT        send_char(8'h09);
  #WAIT        send_char(8'h0a);
  #WAIT        send_char(8'h0b);
  #WAIT        send_char(8'h0c);
  #WAIT        send_char(8'h0d);
  #WAIT        send_char(8'h0e);
  #WAIT        send_char(8'h0f);
  send_break();

  #(WAIT * 4) $display("END of the simulation");
  $finish;
end

endmodule
