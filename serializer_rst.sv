// verilog_ips: serializer_rst
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

module serializer_rst #(
  parameter DATA_WIDTH = 8
)
(
  input                   i_clk,
  input                   i_rst,
  input                   i_wen,
  input  [DATA_WIDTH-1:0] i_data,
  output                  o_data,
  output                  o_busy
);
  localparam CNTR_BITS = $clog2(DATA_WIDTH - 1);
  localparam MAX_VALUE = DATA_WIDTH - 1;

  reg [CNTR_BITS-1:0]  int_cntr = CNTR_BITS'd0;
  reg [DATA_WIDTH-1:0] int_data;
  reg                  int_busy = 1'b0;

  assign o_busy = int_busy;
  assign o_data = int_data[int_cntr];

  always @(posedge i_clk) begin
    if (i_rst) begin
      int_busy <= 1'b0;
      int_cntr <= CNTR_BITS'd0;
    end else if (!int_busy && i_wen) begin
      int_busy <= 1'b1;
      int_data <= i_data;
      int_cntr <= CNTR_BITS'd0;
    end else if (int_busy) begin
      int_cntr <= int_cntr + 1;

      if (int_cntr == MAX_VALUE) begin
        int_cntr <= CNTR_BITS'd0;
        int_busy <= 1'b0;
      end
    end
  end

`ifdef FORMAL
  /*
   * Setup
   */
  reg f_past_valid;
  initial f_past_valid = 1'b0;
  always @(posedge i_clk)
    f_past_valid <= 1'b1;

  /*
   * Reset
   */
  always @(posedge i_clk) begin
    if (!f_past_valid || $past(i_rst)) begin
      assert(int_cntr == CNTR_BITS'd0);
      assert(int_busy == 1'b0);
    end
  end

  /*
   * Counter
   */
  // Check whether the counter resets back to zero.
  always @(posedge i_clk) begin
    if (f_past_valid && !$past(i_rst) && $past(o_busy)) begin
      if ($past(int_cntr) == MAX_VALUE) begin
        assert(int_cntr == 0);
      end else begin
        assert(int_cntr == ($past(int_cntr) + 1));
     end
    end
  end

  // Check that busy is asserted when we can and do accept input data.
  always @(posedge i_clk)
    if (f_past_valid && !$past(i_rst) && $past(i_wen) && !$past(o_busy))
      assert(o_busy);

  // Check whether the counter is never larger than the maximum counter value.
  always @(posedge i_clk)
    assert(int_cntr <= MAX_VALUE);

  /*
   * Data
   */
  reg [DATA_WIDTH-1:0] f_data;

  // Store the input so that we can later use it for verification.
  always @(posedge i_clk) begin
    if (!i_rst && i_wen && !o_busy) begin
      f_data <= i_data;
    end else if (o_busy)
      f_data <= {1'b0, f_data[DATA_WIDTH-1:1]};
  end

  // Check that when we store input, f_data holds the same data.
  always @(posedge i_clk)
    if (f_past_valid && !$past(i_rst) && $past(i_wen) && !$past(o_busy))
      assert(int_data == f_data);

  // Check whether we have not lost any input data and present it correctly
  // on the output.
  always @(*)
    if (o_busy) begin
      assert(o_data == f_data[0]);
      assert(o_data == int_data[int_cntr]);
    end

  // Check that we store the input data correctly when can accept data.
  always @(posedge i_clk)
    if (f_past_valid && !$past(i_rst) && $past(i_wen) && !$past(o_busy))
      assert(int_data == $past(i_data));

  /*
   * Liveness checks
   */
  // Check whether we can get some output.
  always @(posedge i_clk)
    cover(f_past_valid && !$past(i_rst) && $past(o_busy) && !o_busy);
`endif
endmodule
