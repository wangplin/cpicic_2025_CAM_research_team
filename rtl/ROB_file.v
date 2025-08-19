`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/19 17:18:00
// Design Name: 
// Module Name: ROB_file
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ROB_file(
    clk, rst, 
    wr0_en_i, head_addr_o,
    rd_data_o, wr1_data_i, wr1_addr_i, wr1_en_i, rd1_en_i,
    full_rob_o
    );

//---------------------------------------------------------------------------
// parameters
//---------------------------------------------------------------------------
parameter rob_width = 26;
parameter entry_num = 21;

//---------------------------------------------------------------------------
// derived parameters
//---------------------------------------------------------------------------

function integer clogb(input integer argument);
   integer           i;
   begin
      clogb = 0;
      for(i = argument - 1; i > 0; i = i >> 1)
    clogb = clogb + 1;
   end
endfunction

localparam depth = clogb(entry_num);

input   clk;
input   rst;

// rob与decode的接口
input                   wr0_en_i;
output wire [depth-1:0] head_addr_o;

// rob与wb的接口
input   [rob_width-1:0]     wr1_data_i;
input   [depth-1:0]         wr1_addr_i;
input                       wr1_en_i;
input                       rd1_en_i;
output wire [rob_width-1:0] rd_data_o;

output  full_rob_o;
wire empty_rob_o;

reg [depth:0] tail_pointer;
reg [depth:0] head_pointer;

wire empty_int = (tail_pointer[depth] == head_pointer[depth]);
wire full_or_empty = (tail_pointer[depth-1:0] == head_pointer[depth-1:0]);

assign full_rob_o  = full_or_empty & !empty_int;
assign empty_rob_o = full_or_empty & empty_int;

reg [rob_width-1:0] mem [0:entry_num];

//"initial" will be ignored at implementation
integer i;
initial begin
    for (i=0;i<entry_num;i=i+1) begin
        mem[i] = 0;
    end
end

wire [depth-1:0] wr_addr,rd_addr;

assign wr_addr = tail_pointer[depth-1:0];
assign rd_addr = head_pointer[depth-1:0];

reg [rob_width-1:0] rd_data;
always @(*) begin
    rd_data = empty_rob_o ? 0 : mem[rd_addr];
end

assign rd_data_o = rd_data;

reg rd_en;
always @(*) begin
    rd_en = 0;
    if (rd_data[0] || rd1_en_i) begin
        rd_en = 1;
    end
end

always @(posedge clk) begin

    if (wr1_en_i) begin
        mem[wr1_addr_i] <= wr1_data_i; 
    end

    if (rd_en) begin
        mem[rd_addr] <= 0; // wb每次读都重置条目
    end
end

always @(posedge clk) begin         
    if (wr0_en_i)
        tail_pointer <= tail_pointer + 1'd1;
    if (rd_en)
        head_pointer <= head_pointer + 1'd1;
    if (rst) begin
        head_pointer <= 0;
        tail_pointer <= 0;
    end
end

assign head_addr_o = wr_addr;

endmodule
