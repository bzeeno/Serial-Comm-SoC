module fifo
#(parameter
    DATA_WIDTH = 8,
    ADDR_WIDTH = 4
)
(
    input  logic clk, reset,
    input  logic rd, wr,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic empty, full, 
    output logic [DATA_WIDTH-1:0] r_data 
);

    // signal dec
    logic [ADDR_WIDTH-1:0] w_addr, r_addr;
    logic wr_en, full_temp;
    
    // wr_en only if fifo not full
    assign wr_en = wr && ~full_temp;
    assign full = full_temp;
    
    // instantiate fifo ctrl unit
    fifo_ctrl #(.ADDR_WIDTH(ADDR_WIDTH)) ctrl_unit (.*, .full(full_temp));
    
    // instantiate reg file
    reg_file #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) reg_unit (.*);

endmodule
