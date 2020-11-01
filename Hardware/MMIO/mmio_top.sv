`include "io_map.svh"
module mmio_top 
#(
    parameter N_SW  = 8,
              N_LED = 8
)
(
    input logic clk,
    input logic reset,
    // FPro Bus
    input logic mmio_cs,
    input logic mmio_wr,
    input logic mmio_rd,
    input logic [20:0] mmio_addr,
    input logic [31:0] mmio_wr_data,
    output logic [31:0] mmio_rd_data,
    // switches and LEDs
    input logic [N_SW-1:0] sw,
    output logic [N_LED-1:0] led,
    // uart
    input logic rx,
    output logic tx,
    // spi
    input logic miso,
    output logic spi_clk,
    output logic mosi,
    output logic ss_n,
    // i2c
    output tri scl,
    inout tri sda
);

    // signal declarations
    logic [63:0] mem_rd_array;
    logic [63:0] mem_wr_array;
    logic [63:0] cs_array;
    logic [4:0]  reg_addr_array [63:0];
    logic [31:0] rd_data_array [63:0];
    logic [31:0] wr_data_array [63:0];
    
    /**************************** MMIO CONTROLLER ****************************/
    mmio_controller ctrl_unit (
        .clk(clk),
        .reset(reset),
        // Fpro Bus
        .mmio_cs(mmio_cs),
        .mmio_wr(mmio_wr),
        .mmio_rd(mmio_rd),
        .mmio_addr(mmio_addr),
        .mmio_wr_data(mmio_wr_data),
        .mmio_rd_data(mmio_rd_data),
        // slots
        .slot_cs_array(cs_array),
        .slot_mem_rd_array(mem_rd_array),
        .slot_mem_wr_array(mem_wr_array),
        .slot_reg_addr_array(reg_addr_array),
        .slot_wr_data_array(wr_data_array),
        .slot_rd_data_array(rd_data_array) 
    );
    /*************************************************************************/
    
    
    /**************************** I/O SLOTS ****************************/
    // slot 0 system timer
    timer timer_slot0 (
        .clk(clk),
        .reset(reset),
        // slot interface
        .cs(cs_array[`S0_SYS_TIMER]), 
        .read(mem_rd_array[`S0_SYS_TIMER]), 
        .write(mem_wr_array[`S0_SYS_TIMER]),
        .addr(reg_addr_array[`S0_SYS_TIMER]),
        .wr_data(wr_data_array[`S0_SYS_TIMER]),
        .rd_data(rd_data_array[`S0_SYS_TIMER])
    );
    
    // slot 1 UART
    uart_core uart_slot1 (
        .clk(clk),
        .reset(reset),
        // slot interface
        .cs(cs_array[`S1_UART1]), 
        .read(mem_rd_array[`S1_UART1]), 
        .write(mem_wr_array[`S1_UART1]),
        .reg_addr(reg_addr_array[`S1_UART1]),
        .wr_data(wr_data_array[`S1_UART1]),
        .rd_data(rd_data_array[`S1_UART1]),
        .tx(tx),
        .rx(rx)
    );
    
    // slot 2 GPO
    gpo #(.W(N_LED)) gpo_slot2 (
        .clk(clk),
        .reset(reset),
        // slot interface
        .cs(cs_array[`S2_LED]), 
        .read(mem_rd_array[`S2_LED]), 
        .write(mem_wr_array[`S2_LED]),
        .addr(reg_addr_array[`S2_LED]),
        .wr_data(wr_data_array[`S2_LED]),
        .rd_data(rd_data_array[`S2_LED]),
        // output to led
        .dout(led)
    );

    // slot 3 GPI 
    gpi #(.W(N_SW)) gpi_slot3 (
        .clk(clk),
        .reset(reset),
        // slot interface
        .cs(cs_array[`S3_SW]), 
        .read(mem_rd_array[`S3_SW]), 
        .write(mem_wr_array[`S3_SW]),
        .addr(reg_addr_array[`S3_SW]),
        .wr_data(wr_data_array[`S3_SW]),
        .rd_data(rd_data_array[`S3_SW]),
        // External signal
        .din(sw)
    );
    
    // slot 4 SPI
    spi_core #(.SS_BITS(1)) spi_slot4 (
        .clk(clk), .reset(reset),
        // slot interface
        .cs(cs_array[`S4_SPI]), 
        .read(mem_rd_array[`S4_SPI]), 
        .write(mem_wr_array[`S4_SPI]),
        .reg_addr(reg_addr_array[`S4_SPI]),
        .wr_data(wr_data_array[`S4_SPI]),
        .rd_data(rd_data_array[`S4_SPI]),
        // peripheral interface
        .miso(miso),
        .spi_clk(spi_clk),
        .mosi(mosi),
        .ss_n(ss_n)
    );
    
    // slot 5 I2C
    i2c_core i2c_slot5 (
        .clk(clk), .reset(reset),
        // slot interface
        .cs(cs_array[`S5_I2C]), 
        .read(mem_rd_array[`S5_I2C]), 
        .write(mem_wr_array[`S5_I2C]),
        .reg_addr(reg_addr_array[`S5_I2C]),
        .wr_data(wr_data_array[`S5_I2C]),
        .rd_data(rd_data_array[`S5_I2C]),
        // peripheral interface
        .sda(sda), // data line
        .scl(scl) // clock line 
    );
    
    /*******************************************************************/
    

    /**************************** UNUSED I/O SLOTS ****************************/
    generate
        genvar i;
        for (i=6; i<64; i = i+1) 
        begin: unused_slot_gen
            assign rd_data_array[i] = 32'hffffffff;
        end
    endgenerate
    /**************************************************************************/

endmodule
