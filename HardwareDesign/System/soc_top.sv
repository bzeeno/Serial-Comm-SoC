module soc_top
#(parameter BRIDGE_BASE=32'hc000_0000)
(
    input logic clk,
    input logic reset,
    // switches and LEDs
    input logic [15:0] sw,
    output logic [15:0] led,
    // uart
    input logic rx,
    output logic tx,
    // spi
    input logic miso,
    output logic spi_clk,
    output logic mosi,
    output logic accel_ss_n,
    // ic2
    output tri scl,
    inout tri sda
);

    // MCS IO Bus
    logic io_addr_strobe;
    logic io_read_strobe;
    logic io_write_strobe;
    logic [3:0] io_byte_enable;
    logic [31:0] io_address;
    logic [31:0] io_write_data;
    logic [31:0] io_read_data;
    logic io_ready;
    // soc system bus
    logic sys_mmio_cs;
    logic sys_wr;
    logic sys_rd;
    logic [20:0] sys_addr;
    logic [31:0] sys_wr_data;
    logic [31:0] sys_rd_data;
    
    // Instantiate microblaze mcs`
    cpu cpu_unit (
        .Clk(clk),                          // input wire Clk
        .Reset(reset),                      // input wire Reset
        .IO_addr_strobe(io_addr_strobe),    // output wire IO_addr_strobe
        .IO_address(io_address),            // output wire [31 : 0] IO_address
        .IO_byte_enable(io_byte_enable),    // output wire [3 : 0] IO_byte_enable
        .IO_read_data(io_read_data),        // input wire [31 : 0] IO_read_data
        .IO_read_strobe(io_read_strobe),    // output wire IO_read_strobe
        .IO_ready(io_ready),                // input wire IO_ready
        .IO_write_data(io_write_data),      // output wire [31 : 0] IO_write_data
        .IO_write_strobe(io_write_strobe)   // output wire IO_write_strobe
    );
    
    // instantiate bridge 
    sys_bridge #(.BRIDGE_BASE(BRIDGE_BASE)) bridge_unit (
        // microblaze mcs io bus
        .io_read_strobe(io_read_strobe),
        .io_write_strobe(io_write_strobe),
        .io_addr_strobe(io_addr_strobe),
        .io_byte_enable(io_byte_enable),
        .io_address(io_address),
        .io_write_data(io_write_data),
        .io_read_data(io_read_data), 
        .io_ready(io_ready),
        // System bus
        .sys_rd(sys_rd),
        .sys_wr(sys_wr),
        .sys_mmio_cs(sys_mmio_cs),
        .sys_addr(sys_addr),
        .sys_wr_data(sys_wr_data),
        .sys_rd_data(sys_rd_data)
    );
    
    // instantiate io subsystem
    mmio_top #(.N_SW(16), .N_LED(16)) mmio_unit (
        .clk(clk),                 
        .reset(reset),                                    
        .mmio_cs(sys_mmio_cs),
        .mmio_wr(sys_wr),
        .mmio_rd(sys_rd),             
        .mmio_addr(sys_addr),    
        .mmio_wr_data(sys_wr_data), 
        .mmio_rd_data(sys_rd_data),           
        .sw(sw),       
        .led(led),                     
        .rx(rx),                  
        .tx(tx),
        .miso(miso),
        .spi_clk(spi_clk),
        .mosi(mosi),
        .ss_n(accel_ss_n),
        .scl(scl),
        .sda(sda)                  
    );
    
endmodule
