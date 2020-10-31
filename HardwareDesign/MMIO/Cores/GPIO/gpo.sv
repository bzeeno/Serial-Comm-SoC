module gpo 
#(parameter W=8)
(
    input logic clk,
    input logic reset,
    // slot interface
    input logic cs, read, write,
    input logic [4:0] addr,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // output
    output logic [W-1:0] dout
);

    logic [W-1:0] reg_buffer; // register buffer to hold wr_data
    logic wr_en; // write enable signal
    
    always_ff @(posedge clk, posedge reset)
    begin
    if(reset)
        reg_buffer <= 0;
    else if(wr_en)
        reg_buffer <= wr_data[W-1:0];
    end
    
    assign dout = reg_buffer; // output 
    assign wr_en = cs && write; // wr enable if chip selected and write asserted
    
    assign rd_data = 0; // hardwire 0 to read data
    
endmodule
