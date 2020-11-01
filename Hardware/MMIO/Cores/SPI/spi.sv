module spi (
    input logic clk, reset,
    input logic [15:0] dvsr,
    input logic [7:0] mosi_data,      // data to be shifted out
    input logic start, cpol, cpha, // start, clk polarity, clk phase
    input logic miso,              // master in slave out
    output logic [7:0] miso_data,     // shifted-in data
    output logic done_tick, ready,
    output logic spi_clk,
    output logic mosi               // master out slave in
);

    typedef enum{idle, cpha_delay, drive, sample} state_type;
    state_type state_reg, state_next;

    logic [15:0] clk_count_reg, clk_count_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [7:0] so_reg, so_next; // shift out registers
    logic [7:0] si_reg, si_next; // shift in registers
   
    // Timing
    logic spi_clk_pol0; // Temp spi clk. Assumes polarity is 0
    logic spi_clk_reg, spi_clk_next;
    
    
    /**************************** REGISTERS ****************************/
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
        begin
            state_reg <= idle;
            clk_count_reg <= 16'b0;
            bit_count_reg <= 3'b0;
            so_reg <= 8'b0;
            si_reg <= 8'b0;
            spi_clk_reg <= spi_clk_next;
        end
        else
        begin
            state_reg <= state_next;
            clk_count_reg <= clk_count_next;
            bit_count_reg <= bit_count_next;
            so_reg <= so_next;
            si_reg <= si_next;
            spi_clk_reg <= spi_clk_next;
        end
    end
    /*******************************************************************/
    
    
    /**************************** NEXT STATE LOGIC ****************************/
    always_comb
    begin
        // defaults
        state_next = state_reg;
        clk_count_next = clk_count_reg;
        bit_count_next = bit_count_reg;
        so_next = so_reg;
        si_next = si_reg;
        ready = 1'b0;
        done_tick=1'b0;
        
        case(state_reg)
            idle:
            begin
                ready = 1'b1;
                if(start)
                begin
                    clk_count_next = 'b0;
                    bit_count_next = 'b0;
                    so_next = mosi_data;
                    if(cpha==0)
                        state_next = cpha_delay;
                    else
                        state_next = sample;
                end
            end
            
            cpha_delay:
            begin
                if(clk_count_reg == dvsr)
                begin
//                    state_next = drive;
                    state_next = sample;
//                    so_next = {so_reg[6:0], 1'b0};
                    clk_count_next = 'b0;
                end
                else
                    clk_count_next = clk_count_reg + 1'b1;
            end
            
            sample:
            begin
                if(clk_count_reg == dvsr)
                begin
                    clk_count_next = 'b0;
                    si_next = {si_reg[6:0], miso}; // shift miso into shift-in reg
                    state_next = drive;
                end
                else
                    clk_count_next = clk_count_reg + 1'b1;
            end
            
            drive:
            begin
                if(clk_count_reg == dvsr)
                begin
                    if(bit_count_reg == 7)
                    begin
                        done_tick = 1'b1;
                        state_next = idle;
                    end
                    else
                    begin
                        clk_count_next = 'b0;
                        bit_count_next = bit_count_reg + 1'b1;
                        so_next = {so_reg[6:0], 1'b0};
                        state_next = sample;
                    end
                end
                else
                    clk_count_next = clk_count_reg + 1'b1;
            end
            
        endcase
    end
    /**************************************************************************/
    
    
    /**************************** Timing ****************************/
    assign spi_clk_pol0 = ( (state_next == drive) & (~cpha) ) | ( (state_next == sample) & (cpha) ); // mode 0 or mode 1 
    assign spi_clk_next = (cpol) ? ~spi_clk_pol0 : spi_clk_pol0;    // invert if polarity is 1
    assign spi_clk = spi_clk_reg;                             
    /****************************************************************/
    
    
    /**************************** OUTPUT ****************************/
    assign mosi = so_reg[7]; // shift out MSB of shift reg
    assign miso_data = si_reg;  // data to processor is held in shift-in reg
    /****************************************************************/
endmodule