module spi_core
#(parameter SS_BITS = 1) // slave select bits
(
    input logic clk, reset,
    // slot interface
    input  logic cs, read, write,
    input  logic [4:0] reg_addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // peripheral interface
    input  logic miso,
    output logic spi_clk,
    output logic mosi,
    output logic [SS_BITS-1:0] ss_n
);

    // write signals
    logic write_en;
    logic wr_ss_n, wr_ctrl, wr_data_en; // write enable signals for: slave select, control signals, data 
    
    // read signals
    logic [7:0] miso_data;
    logic spi_ready;
    
    // registers
    logic [SS_BITS-1:0] ss_n_reg; // slave-select 
    logic [15:0] dvsr;  // divisor reg
    logic cpol;         // Clock polarity
    logic cpha;         // Clock phase     
    logic [17:0] ctrl_reg;


    /**************************** REGISTER MAP ****************************/
    assign write_en    = write & cs;
    assign wr_ss_n     = write_en & (reg_addr[1:0] == 2'b01);
    assign wr_ctrl     = write_en & (reg_addr[1:0] == 2'b10);
    assign wr_data_en  = write_en & (reg_addr[1:0] == 2'b11);
    
    assign rd_data = {23'b0,spi_ready,miso_data}; // no decoding, only 1 read register
    /**********************************************************************/
    
    
    /**************************** SPI MASTER ****************************/
    spi spi_master_unit (
        .clk(clk), .reset(reset),
        .dvsr(dvsr),
        .mosi_data(wr_data[7:0]),
        .start(wr_data_en), .cpol(cpol), .cpha(cpha), 
        .miso(miso),              
        .miso_data(miso_data),
        .done_tick(), .ready(spi_ready),
        .spi_clk(spi_clk),
        .mosi(mosi)               
    );
    /********************************************************************/
    
    
    /**************************** REGISTERS ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            ss_n_reg <=   'b1;
            ctrl_reg <= 18'd1028;
        end
        else
        begin
            if(wr_ss_n)
            begin
                ss_n_reg <= wr_data[SS_BITS-1:0];
            end 
            if(wr_ctrl)
            begin
                ctrl_reg <= wr_data[17:0];
            end
        end
    end
    /*******************************************************************/
    
    
    /**************************** SIGNAL ASSIGN ****************************/
    assign ss_n = ss_n_reg;
    assign dvsr = ctrl_reg[15:0];
    assign cpol = ctrl_reg[16];
    assign cpha = ctrl_reg[17];
    /***********************************************************************/

endmodule