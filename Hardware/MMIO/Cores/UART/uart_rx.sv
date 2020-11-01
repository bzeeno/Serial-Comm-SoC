module uart_rx
#(parameter 
    DATA_BITS = 8, // num of data bits
    STOP_TICKS = 16 // num of stop bits
)
(
    input logic clk, reset,
    input logic rx, baud_tick,
    output logic rx_done_tick,
    output logic [7:0] dout
);

    // fsm state type
    typedef enum{idle, start, data, stop} state_type;
    
    // signal declarations
    state_type state_reg, state_next;
    logic [3:0] tick_count_reg, tick_count_next; // keeps track of sampling ticks
    logic [2:0] data_count_reg, data_count_next; // keeps track of num of data bits received
    logic [7:0] data_reg, data_next; // where the received data is reconstructed 
    
    /**************************** REGISTERS ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            state_reg <= idle;
            tick_count_reg <= 0;
            data_count_reg <= 0;
            data_reg <= 0;
        end
        
        else
        begin
            state_reg <= state_next;
            tick_count_reg <= tick_count_next;
            data_count_reg <= data_count_next;
            data_reg <= data_next;
        end
        
    end
    /*******************************************************************/
    
    
     /**************************** NEXT STATE LOGIC ****************************/
    always_comb
    begin
        // Default: Keep previous vals
        state_next = state_reg;
        tick_count_next = tick_count_reg;
        data_count_next = data_count_reg;
        data_next = data_reg;
        rx_done_tick = 1'b0; // Default done signal to 0
        
        case(state_reg)
            idle:
            begin
                if(~rx) // start when rx is set to 0
                begin
                    state_next = start; // set next state to start
                    tick_count_next = 0; // set counter to 0
                end
            end
            
            start:
            begin
                if(baud_tick)
                begin
                    if(tick_count_reg == 7)
                    begin
                        state_next = data;
                        tick_count_next = 0; // reset counter
                        data_count_next = 0; // initialize data_count to 0
                    end
                    else
                        tick_count_next = tick_count_reg + 1; // increment tick_count
                end
            end
            
            data:
            begin
                if(baud_tick)
                begin
                    if(tick_count_reg == 15)
                    begin
                        tick_count_next = 0; // reset counter
                        data_next = {rx, data_reg[7:1]}; // shift data_reg to the right and put rx to MSB
                        
                        if(data_count_reg == (DATA_BITS-1)) // if we've reached the end of data
                            state_next = stop;
                        else
                            data_count_next = data_count_reg + 1; // increment data count
                    end
                    else
                        tick_count_next = tick_count_reg + 1; // increment tick count 
                end
            end
            
            stop:
            begin
                if(baud_tick)
                begin
                    if( tick_count_reg == (STOP_TICKS-1) )
                    begin
                        state_next = idle;
                        rx_done_tick = 1'b1;
                    end
                    else
                        tick_count_next = tick_count_reg + 1;
                end
            end
        endcase
        
    end
    /*************************************************************************/
    

    assign dout = data_reg; // output is in data_reg

endmodule
