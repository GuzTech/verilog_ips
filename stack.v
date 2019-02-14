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
    parameter STACK_SIZE  = 1
) (
  input                        i_clk,
  input                        i_rst,
  input                        i_push,
  input                        i_pop,
  input      [STACK_WIDTH-1:0] i_data,
  output reg [STACK_WIDTH-1:0] o_data
);
  reg [STACK_WIDTH-1:0] int_mem[0:2**STACK_SIZE-1];
  reg [ STACK_SIZE-1:0] int_stack_ptr;
  reg [ STACK_SIZE-1:0] int_ptr_m;

  always @(posedge i_clk) begin
    if (i_rst) begin
      int_stack_ptr <= STACK_SIZE'd0;
      int_data_out  <= STACK_WIDTH'd0;
    end else begin
      if (i_push) begin                
        if (!i_pop) begin // Just push
          int_mem[int_stack_ptr] <= i_data;
          int_stack_ptr          <= int_stack_ptr + 1'b1;
        end else begin // Push and pop
          o_data             <= int_mem[int_ptr_m];
          int_mem[int_ptr_m] <= i_data;
        end
      end else if (i_pop) begin // Just pop
        o_data        <= int_mem[int_ptr_m];
        int_stack_ptr <= int_ptr_m;
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
endmodule
