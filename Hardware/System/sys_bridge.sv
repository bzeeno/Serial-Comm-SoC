module sys_bridge
#(parameter BRIDGE_BASE=32'hc000_0000)
(
    // microblaze mcs io bus
    input  logic io_read_strobe,
    input  logic io_write_strobe,
    input  logic io_addr_strobe,
    input  logic [3:0] io_byte_enable,
    input  logic [31:0] io_address,
    input  logic [31:0] io_write_data,
    output logic [31:0] io_read_data, 
    output logic io_ready,
    // System bus
    output logic sys_rd,
    output logic sys_wr,
    output logic sys_mmio_cs,
    output logic [20:0] sys_addr,
    output logic [31:0] sys_wr_data,
    input  logic [31:0] sys_rd_data
);

    // signal declaration
    logic bridge_en;
    
    // Address decoding
    assign bridge_en = (io_address[31:24] == BRIDGE_BASE[31:24]); // set bridge_en to 1 if io_address contains correct bridge base address
    assign sys_addr = io_address[22:2]; // address used to determine slot and register
    assign sys_mmio_cs = ( bridge_en && io_address[23] == 0 );
    // control line
    assign sys_rd = io_read_strobe;
    assign sys_wr = io_write_strobe;
    assign io_ready = 1; // not used 
    // data line
    assign sys_wr_data = io_write_data;
    assign io_read_data = sys_rd_data;
   
endmodule
