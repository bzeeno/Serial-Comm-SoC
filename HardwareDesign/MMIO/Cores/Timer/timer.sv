module timer (
    input logic clk,
    input logic reset,
    // slot interface
    input logic cs, read, write,
    input logic [4:0] addr,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data
);

    logic [47:0] count_reg;
    logic ctrl_reg;
    logic wr_en, clear, go;
    
    // counter
    // if reset or clear: count_reg <= 0
    // else if go: increment count_reg
    always_ff @(posedge clk, posedge reset)
    begin
        if(reset)
            count_reg <= 0;
        else if (clear)
            count_reg <= 0;
            else if (go)
                count_reg <= count_reg + 1;
    end

    // control register 
    always_ff @(posedge clk, posedge reset)
    begin
        if (reset)
            ctrl_reg <= 0;
        else if (wr_en)
            ctrl_reg <= wr_data[0];
    end
    
    // internal signals
    assign wr_en = write && cs && (addr[1:0] == 2'b10);
    assign clear = wr_en && wr_data[1];
    assign go = ctrl_reg; // go holds ctrl_reg value
    // read interface for slot
    assign rd_data = (addr[0] == 0) ? count_reg[31:0] : {16'h0000, count_reg[47:32]};

endmodule
