/*
A simple circular stack (LIFO).

STACK_WIDTH - The bit width of the words on the stack.
STACK_SIZE  - Size of the stack (2 ^ STACK_SIZE words).

If push and pop are asserted at the same time, the old
TOS (top of stack) value will appear at data_out and
the value of data_in will be written to the same
position. Just asserting pop would then place the newly
written data on the data_out port. 
*/

module stack #(
    parameter STACK_WIDTH = 18,
    parameter STACK_SIZE  = 4
) (
    input                        clk,
    input                        reset,
    input                        push,
    input                        pop,
    input      [STACK_WIDTH-1:0] data_in,
    output reg [STACK_WIDTH-1:0] data_out
);

    reg [STACK_WIDTH-1:0] mem[0:2**STACK_SIZE-1];
    reg [ STACK_SIZE-1:0] stack_ptr;
    reg [ STACK_SIZE-1:0] ptr_m;
    
    always @ (posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            data_out  <= 0;
        end else begin
            if (push && !pop) begin
                mem[stack_ptr] <= data_in;
                stack_ptr      <= stack_ptr + 1'b1;
            end else if (pop && !push) begin
                data_out  <= mem[ptr_m];
                stack_ptr <= stack_ptr - 1'b1;
            end else if (push && pop) begin
                data_out   <= mem[ptr_m];
                mem[ptr_m] <= data_in;
            end
        end 
    end
    
    always @ (*) begin
        // Use 1'b1 and not 1, because 1 is
        // an integer and by default, they
        // are 32 bits. Verilog arithmetic
        // uses the bit width of the largest
        // opererand for the entire expression,
        // meaning you'll get a truncation
        // warning.
        ptr_m = stack_ptr - 1'b1;
    end
endmodule
