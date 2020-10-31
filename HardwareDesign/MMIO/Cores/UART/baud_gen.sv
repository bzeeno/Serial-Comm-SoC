module baud_gen(
    input logic clk, reset,
    input logic [10:0] dvsr,
    output logic tick    
);

    // declarations
    logic [10:0] r_reg, r_next;
    
    // register
    always_ff @(posedge clk, posedge reset)
        if(reset)
            r_reg <= 0;
        else
            r_reg <= r_next;
    
    // next state logic 
    assign r_next = (r_reg == dvsr) ? 0 : r_reg + 1;
    // output tick
    assign tick = (r_reg==1);

endmodule
