`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/09 10:28:36
// Design Name: 
// Module Name: cache_control_multibank
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


module cache_control_multibank(
    clk, rst,
    table_ex_ready_i, table_ex_valid_i, table_ex_info_i, 
    table_ex_id_i, table_ex_so_i, table_ex_data_entry_i, table_ex_rob_entry_i,
    table_ex_ready_o, table_ex_valid_o, table_ex_info_o, 
    table_ex_id_o, table_ex_so_o, table_ex_data_entry_o, table_ex_rob_entry_o,
    c2a_lkp_vld, c2a_lkp_info, c2a_lkp_req_id, a2c_lkp_rdy,
    a2c_lkp_rsp_vld, a2c_lkp_rsp_id, a2c_lkp_rslt
    );

//---------------------------------------------------------------------------
// parameters
//---------------------------------------------------------------------------

// 报文查表边带信息
parameter info_length = 20;

// 报文保序id
parameter order_id = 3;

// 寄存器个数
parameter register_num = 320;

// ROB个数
parameter rob_num = 128;

// 请求者需要的宽度
parameter req_width = 10;

// tag条目个数
parameter tag_num = 32;

// hash表中slot个数
parameter hash_slot_num = 4;

// MSHR条目个数
parameter mshr_entry_num = 64;

// MSHR子条目个数
parameter mshr_subentry_num = 16;

// 输出buffer的深度
parameter buffer_depth = 6;

// c2a buffer的深度
parameter c2a_depth = 3;

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

// MSHR条目个数宽度
localparam mshr_width = clogb(mshr_entry_num);

// bank个数
localparam bank_num = 2;

// bank个数需要的宽度
localparam bank_width = clogb(bank_num);

// req_id中bank_id位置
localparam bank_id_start = 0;
localparam bank_id_end = 0+1-1;

// req_id中mshr条目信息
localparam mshr_start = 1;
localparam mshr_end = 1+mshr_width-1;

// 时钟复位
input clk;
input rst;

// execute与lookup table的接口信号
output wire                         table_ex_ready_i;
input                               table_ex_valid_i;
input   [info_length-1:0]           table_ex_info_i;
input   [order_id-1:0]              table_ex_id_i;
input                               table_ex_so_i;
input   [register_width-1:0]        table_ex_data_entry_i;
input   [rob_width-1:0]             table_ex_rob_entry_i;

input                               table_ex_ready_o;
output wire                         table_ex_valid_o;
output wire [info_length-1:0]       table_ex_info_o;
output wire [order_id-1:0]          table_ex_id_o;
output wire                         table_ex_so_o;
output wire [register_width-1:0]    table_ex_data_entry_o;
output wire [rob_width-1:0]         table_ex_rob_entry_o;

// cache与module A的接口
output wire                     c2a_lkp_vld;
output wire [info_length-1:0]   c2a_lkp_info;
output wire [req_width-1:0]     c2a_lkp_req_id;
input                           a2c_lkp_rdy;

input                           a2c_lkp_rsp_vld;
input   [req_width-1:0]         a2c_lkp_rsp_id;
input   [info_length-1:0]       a2c_lkp_rslt;

reg sel_table_in;
always @(*) begin
    sel_table_in = 0;
    if (table_ex_info_i[0]) begin
        sel_table_in = 1;
    end
end

wire                            table_ex_ready_i0;
wire                            table_ex_valid_i0;
wire    [info_length-2:0]       table_ex_info_i0;
wire    [order_id-1:0]          table_ex_id_i0;
wire                            table_ex_so_i0;
wire    [register_width-1:0]    table_ex_data_entry_i0;
wire    [rob_width-1:0]         table_ex_rob_entry_i0;

wire                            table_ex_ready_o0;
wire                            table_ex_valid_o0;
wire    [info_length-1:0]       table_ex_info_o0;
wire    [order_id-1:0]          table_ex_id_o0;
wire                            table_ex_so_o0;
wire    [register_width-1:0]    table_ex_data_entry_o0;
wire    [rob_width-1:0]         table_ex_rob_entry_o0;

wire                        c2a_lkp_vld_0;
wire    [info_length-2:0]   c2a_lkp_info_0;
wire    [req_width-1:0]     c2a_lkp_req_id_0;
wire                        a2c_lkp_rdy_0;
wire                        a2c_lkp_rsp_vld_0;
wire    [req_width-1:0]     a2c_lkp_rsp_id_0;
wire    [info_length-1:0]   a2c_lkp_rslt_0;


wire                            table_ex_ready_i1;
wire                            table_ex_valid_i1;
wire    [info_length-2:0]       table_ex_info_i1;
wire    [order_id-1:0]          table_ex_id_i1;
wire                            table_ex_so_i1;
wire    [register_width-1:0]    table_ex_data_entry_i1;
wire    [rob_width-1:0]         table_ex_rob_entry_i1;

wire                            table_ex_ready_o1;
wire                            table_ex_valid_o1;
wire    [info_length-1:0]       table_ex_info_o1;
wire    [order_id-1:0]          table_ex_id_o1;
wire                            table_ex_so_o1;
wire    [register_width-1:0]    table_ex_data_entry_o1;
wire    [rob_width-1:0]         table_ex_rob_entry_o1;

wire                        c2a_lkp_vld_1;
wire    [info_length-2:0]   c2a_lkp_info_1;
wire    [req_width-1:0]     c2a_lkp_req_id_1;
wire                        a2c_lkp_rdy_1;
wire                        a2c_lkp_rsp_vld_1;
wire    [req_width-1:0]     a2c_lkp_rsp_id_1;
wire    [info_length-1:0]   a2c_lkp_rslt_1;

wire [bank_num-1:0] rr_table_gnt;
wire [bank_num-1:0] rr_c2a_gnt;

/******************************轮询仲裁器*****************************/
wire [bank_num-1:0] rr_table_req_in, rr_c2a_req_in;
assign rr_table_req_in = table_ex_ready_o ? {table_ex_valid_o1, table_ex_valid_o0} : {bank_num{1'b0}};
assign rr_c2a_req_in = a2c_lkp_rdy ? {c2a_lkp_vld_1, c2a_lkp_vld_0} : {bank_num{1'b0}};

rr_arbiter_base
    #(.N(bank_num), .W(0))
u_rr_table_arbiter_base
    (   .clk(clk), .rst(rst),
        .req_in(rr_table_req_in),
        .grant(rr_table_gnt)
    );

rr_arbiter_base
    #(.N(bank_num), .W(0))
u_rr_c2a_arbiter_base
    (   .clk(clk), .rst(rst),
        .req_in(rr_c2a_req_in),
        .grant(rr_c2a_gnt)
    );

// cache bank0
cache_control
    #(  .info_length(info_length-1),
        .result_length(info_length),
        .order_id(order_id),
        .register_num(register_num),
        .rob_num(rob_num),
        .req_width(req_width),
        .tag_num(tag_num),
        .hash_slot_num(hash_slot_num),
        .mshr_entry_num(mshr_entry_num),
        .mshr_subentry_num(mshr_subentry_num),
        .buffer_depth(buffer_depth),
        .c2a_depth(c2a_depth),
        .BANK_ID(1'b0))
u_cache_control_bank_0
    (   .clk(clk), .rst(rst),
        .table_ex_ready_i(table_ex_ready_i0),
        .table_ex_valid_i(table_ex_valid_i0),
        .table_ex_info_i(table_ex_info_i0),
        .table_ex_id_i(table_ex_id_i0),
        .table_ex_so_i(table_ex_so_i0),
        .table_ex_data_entry_i(table_ex_data_entry_i0),
        .table_ex_rob_entry_i(table_ex_rob_entry_i0),

        .table_ex_ready_o(table_ex_ready_o0),
        .table_ex_valid_o(table_ex_valid_o0),
        .table_ex_info_o(table_ex_info_o0),
        .table_ex_id_o(table_ex_id_o0),
        .table_ex_so_o(table_ex_so_o0),
        .table_ex_data_entry_o(table_ex_data_entry_o0),
        .table_ex_rob_entry_o(table_ex_rob_entry_o0),

        .c2a_lkp_vld(c2a_lkp_vld_0),
        .c2a_lkp_info(c2a_lkp_info_0),
        .c2a_lkp_req_id(c2a_lkp_req_id_0),
        .a2c_lkp_rdy(a2c_lkp_rdy_0),
        .a2c_lkp_rsp_vld(a2c_lkp_rsp_vld_0),
        .a2c_lkp_rsp_id(a2c_lkp_rsp_id_0),
        .a2c_lkp_rslt(a2c_lkp_rslt_0)
    );

// cache bank1
cache_control
    #(  .info_length(info_length-1),
        .result_length(info_length),
        .order_id(order_id),
        .register_num(register_num),
        .rob_num(rob_num),
        .req_width(req_width),
        .tag_num(tag_num),
        .hash_slot_num(hash_slot_num),
        .mshr_entry_num(mshr_entry_num),
        .mshr_subentry_num(mshr_subentry_num),
        .buffer_depth(buffer_depth),
        .c2a_depth(c2a_depth),
        .BANK_ID(1'b1))
u_cache_control_bank_1
    (   .clk(clk), .rst(rst),
        .table_ex_ready_i(table_ex_ready_i1),
        .table_ex_valid_i(table_ex_valid_i1),
        .table_ex_info_i(table_ex_info_i1),
        .table_ex_id_i(table_ex_id_i1),
        .table_ex_so_i(table_ex_so_i1),
        .table_ex_data_entry_i(table_ex_data_entry_i1),
        .table_ex_rob_entry_i(table_ex_rob_entry_i1),

        .table_ex_ready_o(table_ex_ready_o1),
        .table_ex_valid_o(table_ex_valid_o1),
        .table_ex_info_o(table_ex_info_o1),
        .table_ex_id_o(table_ex_id_o1),
        .table_ex_so_o(table_ex_so_o1),
        .table_ex_data_entry_o(table_ex_data_entry_o1),
        .table_ex_rob_entry_o(table_ex_rob_entry_o1),

        .c2a_lkp_vld(c2a_lkp_vld_1),
        .c2a_lkp_info(c2a_lkp_info_1),
        .c2a_lkp_req_id(c2a_lkp_req_id_1),
        .a2c_lkp_rdy(a2c_lkp_rdy_1),
        .a2c_lkp_rsp_vld(a2c_lkp_rsp_vld_1),
        .a2c_lkp_rsp_id(a2c_lkp_rsp_id_1),
        .a2c_lkp_rslt(a2c_lkp_rslt_1)
    );

// output signal
assign table_ex_ready_i = sel_table_in ? table_ex_ready_i1 : table_ex_ready_i0;

assign table_ex_valid_o      = rr_table_gnt[bank_num-1] ? table_ex_valid_o1 : table_ex_valid_o0;
assign table_ex_info_o       = rr_table_gnt[bank_num-1] ? table_ex_info_o1 : table_ex_info_o0;
assign table_ex_id_o         = rr_table_gnt[bank_num-1] ? table_ex_id_o1 : table_ex_id_o0;
assign table_ex_so_o         = rr_table_gnt[bank_num-1] ? table_ex_so_o1 : table_ex_so_o0;
assign table_ex_data_entry_o = rr_table_gnt[bank_num-1] ? table_ex_data_entry_o1 : table_ex_data_entry_o0;
assign table_ex_rob_entry_o  = rr_table_gnt[bank_num-1] ? table_ex_rob_entry_o1 : table_ex_rob_entry_o0;

assign c2a_lkp_vld    = rr_c2a_gnt[bank_num-1] ? c2a_lkp_vld_1 : c2a_lkp_vld_0;
assign c2a_lkp_info   = rr_c2a_gnt[bank_num-1] ? {c2a_lkp_info_1, 1'b1} : {c2a_lkp_info_0, 1'b0};
assign c2a_lkp_req_id = rr_c2a_gnt[bank_num-1] ? (c2a_lkp_req_id_1 << 1) | 'b1 : c2a_lkp_req_id_0 << 1;

// cache bank0
assign table_ex_valid_i0      = ~sel_table_in && table_ex_valid_i;
assign table_ex_info_i0       = table_ex_info_i[info_length-1:1];
assign table_ex_id_i0         = table_ex_id_i;
assign table_ex_so_i0         = table_ex_so_i;
assign table_ex_data_entry_i0 = table_ex_data_entry_i;
assign table_ex_rob_entry_i0  = table_ex_rob_entry_i;

assign table_ex_ready_o0 = rr_table_gnt[0] && table_ex_ready_o;

assign a2c_lkp_rdy_0 = rr_c2a_gnt[0] && a2c_lkp_rdy;

assign a2c_lkp_rsp_vld_0 = a2c_lkp_rsp_id[bank_id_end:bank_id_start] == 0 && a2c_lkp_rsp_vld;
assign a2c_lkp_rsp_id_0  = a2c_lkp_rsp_id >> 1;
assign a2c_lkp_rslt_0    = a2c_lkp_rslt;

// cache bank1
assign table_ex_valid_i1      = sel_table_in && table_ex_valid_i;
assign table_ex_info_i1       = table_ex_info_i[info_length-1:1];
assign table_ex_id_i1         = table_ex_id_i;
assign table_ex_so_i1         = table_ex_so_i;
assign table_ex_data_entry_i1 = table_ex_data_entry_i;
assign table_ex_rob_entry_i1  = table_ex_rob_entry_i;

assign table_ex_ready_o1 = rr_table_gnt[1] && table_ex_ready_o;

assign a2c_lkp_rdy_1 = rr_c2a_gnt[1] && a2c_lkp_rdy;

assign a2c_lkp_rsp_vld_1 = a2c_lkp_rsp_id[bank_id_end:bank_id_start] == 1 && a2c_lkp_rsp_vld;
assign a2c_lkp_rsp_id_1  = a2c_lkp_rsp_id >> 1;
assign a2c_lkp_rslt_1    = a2c_lkp_rslt;
endmodule
