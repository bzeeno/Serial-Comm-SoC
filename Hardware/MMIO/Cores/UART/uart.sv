module uart
#(parameter
    DATA_BITS = 8,     // num of data bits
    STOP_TICKS = 16, // num of stop bits
    FIFO_W = 2   //num of addr bits
)
(
    input logic clk, reset,
    input logic rd_uart, wr_uart, rx,
    input logic [7:0] w_data,
    input logic [10:0] dvsr,
    output logic tx_full, rx_empty, tx,
    output logic [7:0] rx_data
);

    // signal dec
    logic tick, rx_done_tick, tx_done_tick;
    logic tx_empty, tx_not_empty;
    logic [7:0] tx_fifo_out, rx_data_out;
    
    /**************************** BAUD RATE GENERATOR ****************************/
    baud_gen baud_gen_unit (
        .clk(clk), .reset(reset), 
        .dvsr(dvsr),
        .tick(tick)
    );
    /*****************************************************************************/
    
    
    /**************************** RX ****************************/
    // instantiate uart rx
    uart_rx #(.DATA_BITS(DATA_BITS), .STOP_TICKS(STOP_TICKS)) rx_unit (
        .clk(clk), .reset(reset),
        .rx(rx), .baud_tick(tick),
        .rx_done_tick(rx_done_tick),
        .dout(rx_data_out)
    );
    
    // instantiate rx fifo 
    fifo #(.DATA_WIDTH(DATA_BITS), .ADDR_WIDTH(FIFO_W)) fifo_rx_unit (.*,
        .rd(rd_uart),
        .wr(rx_done_tick),
        .w_data(rx_data_out),
        .empty(rx_empty),
        .full(),
        .r_data(rx_data)
    );
    /************************************************************/
    
    
    /**************************** TX ****************************/
    // instantiate uart tx
    uart_tx #(.DATA_BITS(DATA_BITS), .STOP_TICKS(STOP_TICKS)) tx_unit (
        .clk(clk), .reset(reset),
        .tx_start(tx_not_empty), .baud_tick(tick),
        .din(tx_fifo_out),
        .tx_done_tick(tx_done_tick),
        .tx(tx)  
    );
    
    assign tx_not_empty = ~tx_empty;
    
    // instantiate tx fifo
    fifo #(.DATA_WIDTH(DATA_BITS), .ADDR_WIDTH(FIFO_W)) fifo_tx_unit (.*,
        .rd(tx_done_tick),
        .wr(wr_uart),
        .w_data(w_data),
        .empty(tx_empty),
        .full(tx_full),
        .r_data(tx_fifo_out)
    );
    /************************************************************/
    
endmodule
