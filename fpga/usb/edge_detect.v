// TinyFPGA USB Code
// From https://github.com/lawrie/tiny_usb_examples/tree/master/usb

module rising_edge_detector ( 
  input clk,
  input in,
  output out
);
  reg in_q;

  always @(posedge clk) begin
    in_q <= in;
  end

  assign out = !in_q && in;
endmodule

module falling_edge_detector ( 
  input clk,
  input in,
  output out
);
  reg in_q;

  always @(posedge clk) begin
    in_q <= in;
  end

  assign out = in_q && !in;
endmodule
