`default_nettype none

module deserializer #(
  parameter DATA_WIDTH = 8
)
(
  input                   i_clk,
  input                   i_wen,
  input                   i_data,
  output [DATA_WIDTH-1:0] o_data,
  output                  o_valid
);
  localparam CNTR_BITS = $clog2(DATA_WIDTH - 1);
  localparam MAX_VALUE = DATA_WIDTH - 1;

  reg [CNTR_BITS-1:0]  int_cntr  = CNTR_BITS'd0;
  reg [DATA_WIDTH-1:0] int_data;
  reg                  int_valid = 1'b0;

  assign o_valid = int_valid;
  assign o_data  = int_data;

  always @(posedge i_clk) begin
    int_valid <= 0;

    if (i_wen) begin
      int_data[int_cntr] <= i_data;
      int_cntr           <= int_cntr + 1;

      if (int_cntr == MAX_VALUE) begin
        int_cntr  <= 0;
        int_valid <= 1'b1;
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
   * Counter
   */
  // Check whether the counter resets back to zero.
  always @(posedge i_clk) begin
    if (f_past_valid && $past(i_wen)) begin
      if ($past(int_cntr) == MAX_VALUE) begin
        assert(int_cntr == 0);
      end else begin
        assert(int_cntr == ($past(int_cntr) + 1));
      end
    end
  end

  // Check whether the counter is never larger than the maximum counter value.
  always @(posedge i_clk)
    assert(int_cntr <= MAX_VALUE);

  /*
   * Data
   */
  reg [DATA_WIDTH-1:0] f_data;

  // Create a shift register to verify the actual implementation.
  always @(posedge i_clk) begin
    if (i_wen) begin
      f_data <= {i_data, f_data[DATA_WIDTH-1:1]};
    end
  end

  // During induction, assertions are treated as assumptions for the first N
  // steps of the solver, and then treated as assertions for step N + 1. We need
  // These assertions to make sure that during induction, o_data and f_data have
  // the same data. The base case actually checks if these assertions hold. 
  genvar k;
  generate for (k = 1; k < DATA_WIDTH; k = k + 1) begin
    always @(*)
      if (int_cntr == k)
        assert(o_data[k-1:0] == f_data[DATA_WIDTH-1:DATA_WIDTH-k]);
    end
  endgenerate

  // Check whether we have not lost any input data
  // and present it correctly on the output.
  always @(posedge i_clk) begin
    if (o_valid) begin
      assert(o_data == f_data);
    end
  end

  // Check whether the bit we wrote in the previous
  // clock cycle is stored in the data register. 
  always @(posedge i_clk) begin
    if (f_past_valid && $past(i_wen)) begin
      assert(int_data[$past(int_cntr)] == $past(i_data));
    end
  end

  // Check whether we can get some output.
//  cover property (int_valid == 1'b1);
  always @(posedge i_clk)
    cover(int_valid);
`endif
endmodule
