module uart_core
#(parameter FIFO_DEPTH_BIT=8) // addr bits of fifo
(
    input  logic clk,
    input  logic reset,
    // slot interface
    input  logic cs,
    input  logic read,
    input  logic write,
    input  logic [4:0] reg_addr,
    input  logic [31:0] wr_data,
    output logic [31:0] rd_data,
    // uart
    output logic tx,
    input  logic rx
);

    // signal dec
    logic wr_uart, rd_uart, wr_dvsr;
    logic tx_full, rx_empty;
    logic [10:0] dvsr_reg;
    logic [7:0] rx_data;
    logic ctrl_reg;
    
    /**************************** UART ****************************/
    uart #(.DATA_BITS(8), .STOP_TICKS(16), .FIFO_W(FIFO_DEPTH_BIT)) uart_unit (
        .clk(clk), .reset(reset),
        .rd_uart(rd_uart), .wr_uart(wr_uart), .rx(rx),
        .w_data(wr_data[7:0]),
        .dvsr(dvsr_reg),
        .tx_full(tx_full), .rx_empty(rx_empty), .tx(tx),
        .rx_data(rx_data)
    );
    /**************************************************************/
    
    
    /**************************** DIVISOR REG ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            dvsr_reg <= 0;
        else if (wr_dvsr)
            dvsr_reg <= wr_data[10:0]; 
    end
    /*********************************************************************/
    
    /**************************** DECODE LOGIC ****************************/
    assign wr_dvsr = ( write && cs && (reg_addr[1:0] == 2'b01) );
    assign wr_uart = ( write && cs && (reg_addr[1:0] == 2'b10) );
    assign rd_uart = ( write && cs && (reg_addr[1:0] == 2'b11) );
    
    // slot read interface
    assign rd_data = {22'h000000, tx_full, rx_empty, rx_data};
    /**********************************************************************/
    
endmodule
