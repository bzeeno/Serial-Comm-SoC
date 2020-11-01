module i2c_core (
    input logic clk, reset,
    // slot interface
    input  logic cs, read, write,
    input  logic [4:0] reg_addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // peripheral interface
    inout  tri sda, // data line
    output tri scl // clock line 
);

    // write signals
    logic write_en, write_dvsr, write_data; 
    
    // signals
    logic [15:0] dvsr_reg;
    logic  [15:0] dvsr;
    logic [8:0] rx_data;
    logic [11:0] cmd_tx_reg; // register to hold command and tx_data
    
    logic  [2:0] cmd;
    logic  [8:0] tx_data;
    
    logic ready, rx_ack;
    

    /**************************** REGISTER MAP ****************************/
    assign write_en    = write & cs;
    assign write_dvsr  = write_en & (reg_addr[1:0] == 2'b01);
    assign write_data  = write_en & (reg_addr[1:0] == 2'b10);
    
    // read 
    assign rd_data = {22'b0, ready, rx_data}; // rx data holds rx data and received acknowledge bit
    /**********************************************************************/


    /**************************** I2C MASTER ****************************/
    i2c_master i2c_master_unit (
        .clk(clk), .reset(reset),
        .tx_data(wr_data[8:0]),           // from master to slave
        .cmd(wr_data[11:9]),              // command
        .dvsr(dvsr),                      // divisor 
        .write_data(write_data),
        .sda(sda),                        // data line
        .scl(scl),                        // clk line
        .ready(ready),                    // ready signal, rx acknowledge bit 
        .rx_data(rx_data)                 // from slave to master
    );
    /********************************************************************/
    
    
    /**************************** REGISTERS ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            dvsr_reg <= 16'd1000; // default to 1000 (1kHz)
        else if(write_dvsr)
            dvsr_reg <= wr_data[15:0];
        else if(write_data)
            cmd_tx_reg <= wr_data[11:0];
    end
    /*******************************************************************/
    
    
    /**************************** SIGNAL ASSIGN ****************************/
    assign dvsr = dvsr_reg[15:0];
    assign cmd = cmd_tx_reg[11:9];
    assign tx_data = cmd_tx_reg[8:0];
    /***********************************************************************/
    
endmodule
