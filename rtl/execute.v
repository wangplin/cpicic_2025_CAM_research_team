`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/19 21:32:28
// Design Name: 
// Module Name: execute
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


module execute(
    clk, rst,
    reg0_ex_busy0, reg0_ex_busy1, reg0_decode_valid, reg0_decode_en, reg0_decode_info, 
    reg0_decode_id, reg0_decode_so, reg0_decode_data_entry, reg0_decode_rob_entry,
    table_ex_ready_i, table_ex_valid_i, table_ex_info_i, 
    table_ex_id_i, table_ex_so_i, table_ex_data_entry_i, table_ex_rob_entry_i,
    table_ex_ready_o, table_ex_valid_o, table_ex_info_o, 
    table_ex_id_o, table_ex_so_o, table_ex_data_entry_o, table_ex_rob_entry_o,
    wb_busy, reg0_ex_valid, reg0_ex_en, reg0_ex_info, 
    reg0_ex_id, reg0_ex_so, reg0_ex_data_entry, reg0_ex_rob_entry
    );

//---------------------------------------------------------------------------
// parameters
//---------------------------------------------------------------------------

// 报文查表边带信息
parameter info_length = 20;

// 报文保序id
parameter order_id = 3;

// 寄存器个数
parameter register_num = 32;

// ROB个数
parameter rob_num = 16;

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

// 寄存器个数需要的宽度
localparam register_width = clogb(register_num);

// ROB个数需要的宽度
localparam rob_width = clogb(rob_num);

// 时钟复位
input clk;
input rst;

// decode与execute的接口信号
// register0
output wire                     reg0_ex_busy0;
output wire                     reg0_ex_busy1;
input                           reg0_decode_valid;
input                           reg0_decode_en;
input   [info_length-1:0]       reg0_decode_info;
input   [order_id-1:0]          reg0_decode_id;
input                           reg0_decode_so;
input   [register_width-1:0]    reg0_decode_data_entry;
input   [rob_width-1:0]         reg0_decode_rob_entry;

// execute与lookup table的接口信号
input                               table_ex_ready_i;
output wire                         table_ex_valid_i;
output wire [info_length-1:0]       table_ex_info_i;
output wire [order_id-1:0]          table_ex_id_i;
output wire                         table_ex_so_i;
output wire [register_width-1:0]    table_ex_data_entry_i;
output wire [rob_width-1:0]         table_ex_rob_entry_i;

output wire                         table_ex_ready_o;
input                               table_ex_valid_o;
input   [info_length-1:0]           table_ex_info_o;
input   [order_id-1:0]              table_ex_id_o;
input                               table_ex_so_o;
input   [register_width-1:0]        table_ex_data_entry_o;
input   [rob_width-1:0]             table_ex_rob_entry_o;

// execute与writeback的接口信号
input                               wb_busy;
output wire                         reg0_ex_valid;
output wire                         reg0_ex_en;
output wire [info_length-1:0]       reg0_ex_info;
output wire [order_id-1:0]          reg0_ex_id;
output wire                         reg0_ex_so;
output wire [register_width-1:0]    reg0_ex_data_entry;
output wire [rob_width-1:0]         reg0_ex_rob_entry;

reg                         ex_valid;
reg                         ex_en;
reg [info_length-1:0]       ex_info;
reg [order_id-1:0]          ex_id;
reg                         ex_so;
reg [register_width-1:0]    ex_data_entry;
reg [rob_width-1:0]         ex_rob_entry;
always @(*) begin
    ex_valid      = 0;
    ex_en         = 0;
    ex_info       = 0;
    ex_id         = 0;
    ex_so         = 0;
    ex_data_entry = 0;
    ex_rob_entry  = 0;
    if (reg0_decode_valid) begin
        ex_valid      = reg0_decode_valid;
        ex_en         = reg0_decode_en;
        ex_info       = reg0_decode_info;
        ex_id         = reg0_decode_id;
        ex_so         = reg0_decode_so;
        ex_data_entry = reg0_decode_data_entry;
        ex_rob_entry  = reg0_decode_rob_entry;
    end
end

assign table_ex_valid_i      = ex_en && table_ex_ready_i;
assign table_ex_info_i       = ex_info;
assign table_ex_id_i         = ex_id;
assign table_ex_so_i         = ex_so;
assign table_ex_data_entry_i = ex_data_entry;
assign table_ex_rob_entry_i  = ex_rob_entry;

reg                         ex_valid_q;
reg [info_length-1:0]       ex_info_q;
reg [order_id-1:0]          ex_id_q;
reg                         ex_so_q;
reg [register_width-1:0]    ex_data_entry_q;
reg [rob_width-1:0]         ex_rob_entry_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        ex_valid_q      <= 0;
        ex_info_q       <= 0;
        ex_id_q         <= 0;
        ex_so_q         <= 0;
        ex_data_entry_q <= 0;
        ex_rob_entry_q  <= 0;
    end else if (wb_busy) begin
        ex_valid_q      <= ex_valid_q     ;
        ex_info_q       <= ex_info_q      ;
        ex_id_q         <= ex_id_q        ;
        ex_so_q         <= ex_so_q        ;
        ex_data_entry_q <= ex_data_entry_q;
        ex_rob_entry_q  <= ex_rob_entry_q ;
    end else if (ex_valid && ex_en == 0) begin
        ex_valid_q      <= ex_valid;
        ex_info_q       <= ex_info;
        ex_id_q         <= ex_id;
        ex_so_q         <= ex_so;
        ex_data_entry_q <= ex_data_entry;
        ex_rob_entry_q  <= ex_rob_entry;
    end else begin
        ex_valid_q      <= 0;
        ex_info_q       <= 0;
        ex_id_q         <= 0;
        ex_so_q         <= 0;
        ex_data_entry_q <= 0;
        ex_rob_entry_q  <= 0;
    end
end

reg [1:0] arbiter;
always @(*) begin
    arbiter = 0;
    if (~wb_busy) begin
        if (ex_valid_q) begin
            arbiter = 2'b10;
        end else if (table_ex_valid_o) begin
            arbiter = 2'b11;
        end  
    end
end

assign reg0_ex_busy1 = ~table_ex_ready_i;
assign reg0_ex_busy0 = wb_busy;

assign table_ex_ready_o = ~(wb_busy || ex_valid_q);

assign reg0_ex_valid      = arbiter[1] ? (arbiter[0] ? table_ex_valid_o : ex_valid_q) : 0;
assign reg0_ex_en         = arbiter[1] ? (arbiter[0] ? 1 : 0) : 0;
assign reg0_ex_info       = arbiter[1] ? (arbiter[0] ? table_ex_info_o : ex_info_q) : 0;
assign reg0_ex_id         = arbiter[1] ? (arbiter[0] ? table_ex_id_o : ex_id_q) : 0;
assign reg0_ex_so         = arbiter[1] ? (arbiter[0] ? table_ex_so_o : ex_so_q) : 0;
assign reg0_ex_data_entry = arbiter[1] ? (arbiter[0] ? table_ex_data_entry_o : ex_data_entry_q) : 0;
assign reg0_ex_rob_entry  = arbiter[1] ? (arbiter[0] ? table_ex_rob_entry_o : ex_rob_entry_q) : 0;







endmodule
