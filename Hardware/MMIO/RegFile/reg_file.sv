module reg_file
#(parameter 
    DATA_WIDTH = 8, // Num of data bits
    ADDR_WIDTH = 2 // num of addr bits
)
(
    input logic clk,
    input logic wr_en,
    input logic [ADDR_WIDTH-1:0] w_addr, r_addr,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data 
);

    // signal declaration
    logic [DATA_WIDTH-1:0] array_reg [0:2**ADDR_WIDTH-1]; // array of 2**addr_width rows X  data_width cols 

    // write op
    always_ff @(posedge clk)
        if(wr_en)
            array_reg[w_addr] <= w_data;
    
    // read op
    assign r_data = array_reg[r_addr];

endmodule
