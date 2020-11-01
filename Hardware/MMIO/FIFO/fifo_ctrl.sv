module fifo_ctrl
#(parameter ADDR_WIDTH=4)
(
    input  logic clk, reset,
    input  logic rd, wr,
    output logic empty, full,
    output logic [ADDR_WIDTH-1:0] w_addr, r_addr 
);

    // signal declaration
    logic [ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next, w_ptr_succ;
    logic [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next, r_ptr_succ;
    logic empty_reg, empty_next;
    logic full_reg, full_next;
    
    // registers
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            empty_reg <= 1'b1;
            full_reg <= 1'b0;
        end
        
        else
        begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            empty_reg <= empty_next;
            full_reg <= full_next;
        end
    end
    
    always_comb
    begin
        // increment wr and rd succ registers
        w_ptr_succ = w_ptr_reg + 1;
        r_ptr_succ = r_ptr_reg + 1;
        // Default Vals
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        empty_next = empty_reg;
        full_next = full_reg;
        
        unique case({wr,rd})
            2'b01: // read
                if(~empty_reg)
                begin
                    r_ptr_next = r_ptr_succ; // increment read pointer 
                    full_next = 1'b0;
                    if(r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1; // empty if next read ptr points to current write ptr
                end
            2'b10: // write
                if(~full_reg)
                begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if(w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1; // full if next write pointer points to current read pointer
                end
            2'b11: // read and write
            begin
                r_ptr_next = r_ptr_succ;
                w_ptr_next = w_ptr_succ;
            end
            
            default: ;// no op
               
        endcase
        
    end
    
    assign empty = empty_reg;
    assign full = full_reg;
    assign w_addr = w_ptr_reg;
    assign r_addr = r_ptr_reg;
    
endmodule
