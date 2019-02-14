// verilog_ips: stack
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

/*
 * A simple circular stack (LIFO).
 *
 * STACK_WIDTH - The bit width of the words on the stack.
 * STACK_SIZE  - Size of the stack (2 ^ STACK_SIZE words).
 *
 * If push and pop are asserted at the same time, the old
 * TOS (top of stack) value will appear at data_out and
 * the value of data_in will be written to the same
 * position. Just asserting pop would then place the newly
 * written data on the data_out port. 
 */

`default_nettype none

module stack #(
    parameter STACK_WIDTH = 18,
    parameter STACK_SIZE  = 4
) (
  input                        i_clk,
  input                        i_rst,
  input                        i_push,
  input                        i_pop,
  input      [STACK_WIDTH-1:0] i_data,
  output reg [STACK_WIDTH-1:0] o_data
);
  localparam PNTR_BITS = $clog2(STACK_SIZE - 1);
  localparam MAX_VALUE = STACK_SIZE - 1;

  reg [STACK_WIDTH-1:0] int_mem[0:PNTR_BITS-1];
  reg [  PNTR_BITS-1:0] int_stack_ptr = PNTR_BITS'd0;
  reg [  PNTR_BITS-1:0] int_ptr_m     = -PNTR_BITS'd1;

  always @(posedge i_clk) begin
    if (i_rst) begin
      int_stack_ptr <= PNTR_BITS'd0;
      o_data        <= STACK_WIDTH'd0;
    end else begin
      if (i_push) begin                
        if (!i_pop) begin // Just push
          int_mem[int_stack_ptr] <= i_data;
          int_stack_ptr          <= int_stack_ptr + 1'b1;
        end else begin // Push and pop
          int_mem[int_ptr_m] <= i_data;
          o_data             <= int_mem[int_ptr_m];
        end
      end else if (i_pop) begin // Just pop
        int_stack_ptr <= int_ptr_m;
        o_data        <= int_mem[int_ptr_m];
      end
    end 
  end

  always @(*) begin
    // Use 1'b1 and not 1, because 1 is an integer and by default,
    // they are 32 bits. Verilog arithmetic uses the bit width of
    // the largest opererand for the entire expression, meaning 
    // you'll get a truncation warning.
    int_ptr_m = int_stack_ptr - 1'b1;
  end

`ifdef FORMAL
  /*
   * Setup
   */
  reg [1:0] f_past_valids;
  initial f_past_valids = 2'b0;
  wire f_past_valid;
  wire f_past_valid_2;
  assign f_past_valid    = f_past_valids[0];
  assign  f_past_valid_2 = f_past_valids[1];

  always @(posedge i_clk)
    f_past_valids <= {f_past_valids[0], 1'b1};

  /*
   * Reset
   */
  always @(posedge i_clk) begin
    if (!f_past_valid || $past(i_rst)) begin
      assert(int_stack_ptr ==  PNTR_BITS'd0);
      assert(int_ptr_m     == -PNTR_BITS'd1);
    end
  end

  /*
   * Counter
   */
  // Check whether the counter resets back to zero.
  always @(posedge i_clk) begin
    if (f_past_valid && !$past(i_rst)) begin
      // Just pushing
      if ($past(i_push) && !$past(i_pop)) begin
        // Check overflow
        if ($past(int_stack_ptr) == MAX_VALUE)
          assert(int_stack_ptr == PNTR_BITS'd0);
        else
          assert(int_stack_ptr == $past(int_stack_ptr) + 1'b1);
      // Pushing and popping
      end else if ($past(i_push) && $past(i_pop)) begin
        assert($stable(int_stack_ptr));
        assert($stable(int_ptr_m));
      // Just popping
      end else if (!$past(i_push) && $past(i_pop)) begin
        // Check underflow
        if ($past(int_stack_ptr) == PNTR_BITS'd0)
          assert(int_stack_ptr == -PNTR_BITS'd1);
        else
          assert(int_stack_ptr == $past(int_stack_ptr) - 1'b1);
      end
    end
  end

  // Check that the -1 pointer is always one smaller than the stack pointer.
  always @(*)
    assert(int_ptr_m == (int_stack_ptr - PNTR_BITS'd1));

  // Check that the counter is never larger than the maximum counter value.
  always @(*)
    assert(int_stack_ptr <= MAX_VALUE);

  /*
   * Data
   */
  reg  [STACK_WIDTH-1:0] f_data;
  wire f_only_push;
  wire f_only_pop;
  wire f_push_pop;
  assign f_only_push = i_push && !i_pop;
  assign f_only_pop  = !i_push && i_pop;
  assign f_push_pop  = i_push && i_pop;

  // Store 
  always @(posedge i_clk)
    if (i_push)
      f_data <= i_data;

  // Check that if we only push, then the data is stored correctly, and in the
  // correct position as well.
  always @(posedge i_clk) begin
    if (f_past_valid && !$past(i_rst) && $past(f_only_push))
      assert(int_mem[$past(int_stack_ptr)] == $past(i_data));
  end

  // Check that if we only push and then only pop, we get back the value we
  // pushed before.
  always @(posedge i_clk) begin
    // Previous 2 clock cycles should be valid.
    if (f_past_valid_2
    // We have not reset in the previous 2 clock cycles.
    && !$past(i_rst) && !$past(i_rst, 2)
    // We only pushed two clock cycles ago...
    && $past(f_only_push, 2)
    // ...and have only popped the previous clock cycle.
    && $past(f_only_pop))
      // Then the data we pushed before, should be the data we output now.
      assert(o_data == f_data);
  end

  // Check that if we only pop, then the state of the internal memory does not
  // change. We cannot use $stable(int_mem) because the solver gives an error
  // about int_mem mapping to an unexpanded memory.
  genvar k;
  generate for (k = 0; k < STACK_SIZE; k = k + 1) begin
    always @(posedge i_clk)
      if (f_past_valid && !$past(i_rst)
      && $past(f_only_pop) && int_stack_ptr == k)
        assert($stable(int_mem[k]));
    end
  endgenerate

  // Check whether we can retrieve pushed data.
  genvar j;
  generate for (j = 0; j < STACK_SIZE; j = j + 1) begin
    always @(posedge i_clk)
      cover(f_past_valid[j] && $past(i_push, j) && (o_data != STACK_WIDTH'd0) && (o_data == f_data));
    end
  endgenerate
`endif
endmodule
