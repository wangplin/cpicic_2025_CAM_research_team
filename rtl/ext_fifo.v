`timescale 1ns / 1ps
module ext_fifo
    #(
        parameter depth = 5,
        parameter width = 34
        )(
        input               clk,
        input               rst,

        input [width-1:0]   wr_data_i,
        input               wr_en_i,

        output [width-1:0]  rd_data_o,
        input               rd_en_i,

        output              full_o,
        output              empty_o
        );

    localparam AW = depth;

    reg [AW:0] write_pointer;
    reg [AW:0] read_pointer;

    wire empty_int = (write_pointer[AW] == read_pointer[AW]);
    wire full_or_empty = (write_pointer[AW-1:0] == read_pointer[AW-1:0]);
     
    assign full_o  = full_or_empty & !empty_int;
    assign empty_o = full_or_empty & empty_int;
    
    always @(posedge clk) begin
        if (rst) begin
            // reset
            write_pointer <= 0;
        end
        else if (wr_en_i) begin
            write_pointer <= write_pointer + 1'd1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            // reset
            read_pointer <= 0;
        end
        else if (rd_en_i) begin
            read_pointer <= read_pointer + 1'd1;
        end
    end

    reg [width-1:0] mem[(1<<AW)-1:0];

    wire [AW-1:0] wr_addr,rd_addr;
    
    assign wr_addr = write_pointer[AW-1:0];
    assign rd_addr =  read_pointer[AW-1:0];

    always @(posedge clk) begin         
        if (wr_en_i) mem[wr_addr] <= wr_data_i;
    end

    reg [width-1:0] rd_data;
    always @(*) begin
        rd_data = empty_o ? 0 : mem[rd_addr];
    end

    assign rd_data_o = rd_data;
    
endmodule
