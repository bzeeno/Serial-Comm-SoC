module gpi 
#(parameter W = 8)
(
    input logic clk,
    input logic reset,
    // slot interface
    input logic cs, read, write,
    input logic [4:0] addr,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // External signal
    input logic [W-1:0] din
);

    logic [W-1:0] rd_data_reg;
    
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            rd_data_reg <= 0;
        else
            rd_data_reg <= din;
    end
    
    assign rd_data[W-1:0] = rd_data_reg;
    assign rd_data[31:W] = 0;

endmodule
