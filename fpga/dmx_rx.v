//////////////////////////////////////////////////////////////////////
// DMX Reciever
// Recieves data and break info from UART and converts it
// to a two byte word. Format is :
// First byte: Status. 0xbb = break, 00 = data
// Second byte: data from the packet
//

module dmx_rx
  (
   input        i_Clock,
   input        i_Rx_DataReady,
   input [7:0]  i_RxData,
   input        i_RxBreak,
   input        i_usbReady,
   output       o_dataReady,
   output [7:0] o_data
   );

   parameter s_IDLE           = 3'b000;
   parameter s_HIGHNIBBLE     = 3'b001;
   parameter s_WAITLOWNIBBLE  = 3'b010;
   parameter s_PREPLOWNIBBLE  = 3'b011;
   parameter s_LOWNIBBLE      = 3'b100;
   parameter s_USBWAIT        = 3'b101;

   reg[2:0] r_OutputState = 0;
   reg      r_dataReady = 0;
   reg[7:0] r_data = 0;
   reg r_rxData = 0;

     always @(posedge i_Clock)
     begin
     r_rxData <= i_Rx_DataReady;

       case(r_OutputState)
       s_IDLE:
         begin
           r_dataReady <= 1'b0;
           if(r_rxData)
           begin
               r_data <= 8'h00;
               if(i_usbReady)
                  r_OutputState <= s_HIGHNIBBLE;
               else
                 r_OutputState <= s_USBWAIT;
           end


           if(i_RxBreak)
           begin
             r_data <= 8'hbb;
             if(i_usbReady)
                r_OutputState <= s_HIGHNIBBLE;
             else
               r_OutputState <= s_USBWAIT;
           end
         end

         s_USBWAIT:
         begin
          if(i_usbReady)
            r_OutputState <= s_HIGHNIBBLE;
         end


         s_HIGHNIBBLE:
         begin
           r_dataReady <= 1'b1;
           r_OutputState <= s_PREPLOWNIBBLE;
         end

         s_PREPLOWNIBBLE:
         begin
           r_dataReady <= 1'b0;
           r_data <= i_RxData;
           r_OutputState <= s_WAITLOWNIBBLE;
         end

         s_WAITLOWNIBBLE:
         begin
          r_OutputState <= s_LOWNIBBLE;
         end

         s_LOWNIBBLE:
         begin
           r_dataReady <= 1'b1;
           r_OutputState <= s_IDLE;
         end
       endcase
       end

       assign o_dataReady = r_dataReady;
       assign o_data = r_data;
endmodule
