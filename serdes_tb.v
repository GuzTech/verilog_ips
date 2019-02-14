// verilog_ips: serdes_tb
//
// Copyright (C) 2019 Oguz Meteer <info@guztech.nl>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

`default_nettype none
`timescale 1ns / 1ps

module serdes_tb;
  parameter WIDTH = 8;

  reg              i_clk, i_wen;
  reg  [WIDTH-1:0] i_data = WIDTH'h18;
  wire             o_data_ser;
  wire [WIDTH-1:0] o_data_des;
  wire             o_busy;
  wire             o_valid;

  serializer #(WIDTH) ser (
    .i_clk  (i_clk),
    .i_wen  (i_wen),
    .i_data (i_data),
    .o_data (o_data_ser),
    .o_busy (o_busy)
  );

  deserializer #(WIDTH) des (
    .i_clk   (i_clk),
    .i_wen   (o_busy),
    .i_data  (o_data_ser),
    .o_data  (o_data_des),
    .o_valid (o_valid)
  );

`ifdef FORMAL
  cover property (o_valid);

  always @(posedge i_clk)
    if (o_valid)
      assert(i_data == o_data_des);
`endif
endmodule
