`timescale 1ns / 1ps

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
    reg [ STACK_SIZE-1:0] ptr_p;
    reg [ STACK_SIZE-1:0] ptr_m;
    
    // Only used to remove the truncation warnings
    reg [STACK_SIZE*2-1:0] tmp_p;
    reg [31:0]             tmp_m;
    
    always @ (posedge clk) begin
        if (reset) begin
            stack_ptr <= 0;
            data_out  <= 0;
        end else begin
            if (push) begin
                mem[stack_ptr] <= data_in;
                stack_ptr      <= ptr_p;
            end
            
            if (pop) begin
                data_out  <= mem[ptr_m];
                stack_ptr <= ptr_m;
            end
        end 
    end
    
    always @ (*) begin
        // +1 causes an overflow, so the
        // tmp_p reg is one bit larger.
        tmp_p = stack_ptr + 1;
        ptr_p = tmp_p[STACK_SIZE-1:0];
        
        // -1 causes an underflow, and the
        // default arithmetic result size is
        // 32 bits.
        tmp_m = stack_ptr - 1;
        ptr_m = tmp_m[STACK_SIZE-1:0];
    end
endmodule
