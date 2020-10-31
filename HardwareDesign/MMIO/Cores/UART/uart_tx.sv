module uart_tx 
#(parameter 
    DATA_BITS = 8, // num of data bits
    STOP_TICKS = 16 // num of stop bits
)
(
    input logic clk, reset,
    input logic tx_start, baud_tick,
    input logic [7:0] din,
    output logic tx_done_tick,
    output logic tx  
);

    // fsm state type
    typedef enum{idle, start, data, stop} state_type;
    
    // signal declaration
    state_type state_reg, state_next;
    logic [3:0] tick_count_reg, tick_count_next; // keeps track of sampling ticks
    logic [2:0] data_count_reg, data_count_next; // keeps track of num of data bits received
    logic [7:0] data_reg, data_next; // where the received data is reconstructed 
    logic tx_reg, tx_next;
    
    
    /**************************** REGISTERS ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            state_reg <= idle;
            tick_count_reg <= 0;
            data_count_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        
        else
        begin
            state_reg <= state_next;
            tick_count_reg <= tick_count_next;
            data_count_reg <= data_count_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    end
    /*******************************************************************/
    
    
    /**************************** NEXT STATE LOGIC ****************************/
    always_comb
    begin
        // Default: keep vals
        state_next = state_reg;
        tick_count_next = tick_count_reg;
        data_count_next = data_count_reg;
        data_next = data_reg;
        tx_done_tick = 1'b0; // Default: 0
        
        case(state_reg)
            idle:
            begin
                tx_next = 1'b1; // hold 1 so uart rx knows that transmission has not started
                if(tx_start)
                begin
                    state_next = start;
                    tick_count_next = 0;
                    data_next = din;
                end
            end
            
            start:
            begin
                tx_next = 1'b0;
                if(baud_tick)
                    if(tick_count_reg == 15)
                    begin
                        state_next = data;
                        tick_count_next = 0;
                        data_count_next = 0;
                    end
                    else
                        tick_count_next = tick_count_reg + 1;
            end
            
            data:
            begin
                tx_next = data_reg[0]; // transmit data (LSB)
                if(baud_tick)
                    if(tick_count_reg == 15)
                    begin
                        tick_count_next = 0;
                        data_next = data_reg >> 1;
                        if( data_count_reg == (DATA_BITS-1) )
                            state_next = stop;
                        else
                            data_count_next = data_count_reg + 1;
                    end
                    else
                        tick_count_next = tick_count_reg + 1;
            end
            
            stop:
            begin
                tx_next = 1'b1;
                if(baud_tick)
                    if( tick_count_reg == (STOP_TICKS-1) )
                    begin
                        state_next = idle;
                        tx_done_tick = 1'b1;
                    end
                    else
                        tick_count_next = tick_count_reg + 1;
            end
        
        endcase
        
    end
    /*************************************************************************/
    
    
    assign tx = tx_reg;

endmodule