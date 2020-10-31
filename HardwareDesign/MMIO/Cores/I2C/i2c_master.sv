module i2c_master (
    input  logic clk, reset,
    input  logic [8:0] tx_data,            // from master to slave
    input  logic [2:0] cmd,                // command
    input  logic [15:0] dvsr,              // divisor 
    input  logic write_data,
    inout  tri sda,                        // data line
    output tri scl,                        // clk line
    output logic ready,                    // ready signal, rx acknowledge bit 
    output logic [8:0] rx_data             // from slave to master
);

    /**************************** Commands ****************************/
    localparam START   = 3'b000;
    localparam TX      = 3'b001;
    localparam RX      = 3'b010;
    localparam RESTART = 3'b011;
    localparam STOP    = 3'b100;
    /******************************************************************/

    /**************************** States ****************************/
    typedef enum { idle, start1, start2, start3, data1, data2, data3, data4, state_change, delay, restart, stop, stop2 } state_type;
    state_type state_reg, state_next;
    /****************************************************************/

    /**************************** Declarations ****************************/
    logic ready_internal;
    logic [2:0] cmd_reg, cmd_next;
    logic [8:0] tx_reg, tx_next;   // transmit data 
    logic [8:0] rx_reg, rx_next;   // received data and ack bit
    logic [15:0] count_reg, count_next; // counter for scl
    logic [15:0] quarter_clk, half_clk;
    logic data_process; // boolean 1 if inside data1, 2, 3, or 4
    logic rx_bool; // if receiving bit(s)
    logic sda_reg, sda_next; // sda register
    logic scl_reg, scl_next; // scl register
    logic [3:0] bit_count_reg, bit_count_next;
      
    assign quarter_clk = dvsr;      // 1/4 a clock period
    assign half_clk    = dvsr << 1; // 1/2 a clock period
    /**********************************************************************/

    /**************************** Registers ****************************/  
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            tx_reg <= 0;
            rx_reg <= 0;
            sda_reg <= 1'b1;
            scl_reg <= 1'b1; 
            count_reg <= 0;
            bit_count_reg <= 0;
            cmd_reg <= 0;
            state_reg <= idle;
        end
        else
        begin
            tx_reg <= tx_next;
            rx_reg <= rx_next;
            sda_reg <= sda_next;
            scl_reg <= scl_next;
            count_reg <= count_next;
            bit_count_reg <= bit_count_next;
            cmd_reg <= cmd_next;
            state_reg <= state_next;
        end
    end
    /*******************************************************************/


    /**************************** FSM ****************************/
    always_comb
    begin
        state_next = state_reg;
        tx_next = tx_reg;
        rx_next = rx_reg;
        cmd_next = cmd_reg;
        sda_next = 1'b1;
        scl_next = 1'b1;
        count_next = count_reg + 1; // increment counter every time
        bit_count_next = bit_count_reg;
        data_process = 1'b0;
        ready_internal = 1'b0;
                
        case(state_reg)
            idle:
            begin
                ready_internal = 1'b1;
                sda_next = 1'b1; 
                scl_next = 1'b1;
                if(write_data && (cmd == START))
                begin
                    count_next = 0;
                    state_next = start1;
                end
            end

            start1:
            begin
                sda_next = 1'b0;
                scl_next = 1'b1;
                if(count_reg == half_clk)
                begin
                    count_next = 0;
                    state_next = start2;
                end
            end
            start2:
            begin
                sda_next = 1'b0;
                scl_next = 1'b0;
                if(count_reg == quarter_clk)
                begin
                    count_next = 0;
                    state_next = state_change;
                end
            end

            state_change:
            begin
                ready_internal = 1'b1;
                sda_next = 1'b0;
                scl_next = 1'b0;
                
                if(write_data)
                begin
                    cmd_next = cmd;
                    count_next = 0;
                    case (cmd)
                        TX, RX:
                        begin
                            bit_count_next = 0;
                            tx_next = tx_data; // transmit data
                            state_next = data1;
                        end

                        STOP:
                        begin
                            state_next = stop;
                        end
                        
                        RESTART, START:
                        begin
                            state_next = restart;
                        end
                    endcase
                end
            end

            data1:
            begin
                data_process = 1'b1;
                sda_next = tx_reg[8]; // set MSB of tx reg as next sda output
                scl_next = 0;
                if(count_reg == quarter_clk)
                begin
                    count_next = 0;
                    state_next = data2;
                end
            end
            data2:
            begin
                data_process = 1'b1;
                sda_next = tx_reg[8]; // set MSB of tx reg as next sda output
                scl_next = 1'b1;
                if(count_reg == quarter_clk)
                begin
                    count_next = 0;
                    state_next = data3;     
                    rx_next = {rx_reg[7:0], sda}; // shift in from sda line
                end
            end
            data3:
            begin
                data_process = 1'b1;
                sda_next = tx_reg[8]; // set MSB of tx reg as next sda output
                scl_next = 1'b1;
                if(count_reg == quarter_clk)
                begin
                    count_next = 0;
                    state_next = data4;
                end
            end
            data4:
            begin
                data_process = 1'b1;
                sda_next = tx_reg[8]; // set MSB of tx reg as next sda output
                scl_next = 1'b0;
                if(count_reg == quarter_clk)
                begin
                    count_next = 0;
                    if(bit_count_reg == 8)
                    begin
                        state_next = state_change;
                    end
                    else
                    begin
                        tx_next = tx_reg << 1; // shift tx data reg
                        bit_count_next = bit_count_reg + 1; // increment bit counter
                        state_next = data1;
                    end 
                end
            end
            
            restart:
            begin
                sda_next = 1'b1;
                scl_next = 1'b1;
                if(count_reg == half_clk)
                begin
                    count_next = 0;
                    state_next = start1;
                end
            end

            stop:
            begin
                data_process = 1'b0;
                sda_next = 1'b0;
                scl_next = 1'b1;
                if(count_reg == quarter_clk)
                    state_next = stop2;
            end
            
            default: // stop2
            begin
                if(count_reg == half_clk)
                    state_next = idle;
            end

        endcase
    end
    /*************************************************************/


    /**************************** Output ****************************/
    assign ready = ready_internal;
    // sda and scl lines
    assign rx_bool = (data_process && (cmd_reg == RX) && (bit_count_reg < 8)) || (data_process && (cmd_reg == TX) && (bit_count_reg==8)); // receiving bit(s) if in data process AND in the process of receiving a byte OR if done transmitting and receiving ack bit
    assign sda = (rx_bool || sda_reg) ? 1'bz : 1'b0; // if receiving: z; If not receiving, then sda gets sda_reg
    assign scl = (scl_reg) ? 1'bz : 1'b0;
    // received data
    assign rx_data = rx_reg[8:0];
    /****************************************************************/

endmodule

