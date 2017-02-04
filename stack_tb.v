`timescale 1ns / 1ps

module stack_tb;
    parameter WIDTH = 18;
    parameter SIZE  = 1;
    
    reg              clk, reset, push, pop;
    reg  [WIDTH-1:0] data_in;
    wire [WIDTH-1:0] data_out;
    
    integer i;

    stack #(WIDTH, SIZE) DUT (
        .clk      (clk),
        .reset    (reset),
        .push     (push),
        .pop      (pop),
        .data_in  (data_in),
        .data_out (data_out)
    );
    
    initial begin
        // Dump waves
        $dumpfile("dump.vcd");
        $dumpvars(1, stack_tb);
        
        clk = 1'b1;
        reset = 1'b1;
        push = 1'b0;
        pop = 1'b0;
        data_in = 18'b0;
        
        toggle_clk;
        toggle_clk;
        reset = 1'b0;
        toggle_clk;
        
        $display("reset ptr: %h", DUT.stack_ptr);
        for (i = 0; i < 2**SIZE; i = i + 1) begin
//            $display("%h %h", i, DUT.stack_mem[i]);
        end
        
        push = 1'b1;
        data_in = 18'b010101010101010101;
        toggle_clk;
        
        $display("1 ptr: %h", DUT.stack_ptr);
        for (i = 0; i < 2**SIZE; i = i + 1) begin
//            $display("%h %h", i, DUT.stack_mem[i]);
        end
        
        data_in = 18'b101010101010101010;
        toggle_clk;
        
        $display("2 ptr: %h", DUT.stack_ptr);
        for (i = 0; i < 2**SIZE; i = i + 1) begin
//            $display("%h %h", i, DUT.stack_mem[i]);
        end
        
        data_in = 18'b000100010001000100;
        toggle_clk;
        
        $display("3 ptr: %h", DUT.stack_ptr);
        for (i = 0; i < 2**SIZE; i = i + 1) begin
//            $display("%h %h", i, DUT.stack_mem[i]);
        end
        
        data_in = 18'b111011101110111011;
        toggle_clk;
        
        $display("4 ptr: %h", DUT.stack_ptr);
        for (i = 0; i < 2**SIZE; i = i + 1) begin
//            $display("%h %h", i, DUT.stack_mem[i]);
        end
        
        push = 1'b0;
        pop = 1'b1;
        toggle_clk;
        
        pop = 1'b0;
        toggle_clk;
        
        pop = 1'b1;
        toggle_clk;
        toggle_clk;
        toggle_clk;
        toggle_clk;
        toggle_clk;
        toggle_clk;
        
        push = 1'b1;
        data_in = 18'b111100001111000011;
        toggle_clk;
        push = 1'b0;
        toggle_clk;
        toggle_clk;
        toggle_clk;
        $finish;
    end
    
    task toggle_clk;
    begin
        #1 clk = ~clk;
        #1 clk = ~clk;
    end
    endtask
endmodule
