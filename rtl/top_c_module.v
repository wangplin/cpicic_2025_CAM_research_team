`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/02 14:06:59
// Design Name: 
// Module Name: top_c_module
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


module top_c_module(
    clk, rst_n,
    b2c_pkt_vld, b2c_pkt_lkp_en, b2c_pkt_lkp_info, b2c_pkt_odr_id, b2c_pkt_so, b2c_pkt_payload, c2b_pkt_rdy,
    c2a_lkp_vld, c2a_lkp_info, c2a_lkp_req_id, a2c_lkp_rdy, a2c_lkp_rsp_vld, a2c_lkp_rsp_id, a2c_lkp_rslt,
    c2d_pkt_vld, c2d_pkt_lkp_rslt, c2d_pkt_odr_id, c2d_pkt_so, c2d_pkt_payload, d2c_pkt_rdy
    );

//---------------------------------------------------------------------------
// parameters
//---------------------------------------------------------------------------

// 报文查表边带信息
parameter info_length = 20;

// 报文保序id
parameter order_id = 3;

// 报文数据长度
parameter data_length = 512;

// 请求者需要的宽度
parameter req_width = 10;

// 输入buffer的深度
parameter input_buffer_depth = 1;

// issue buffer的深度
parameter issue_buffer_depth = 2;

// 寄存器个数
parameter register_num = 320;

// ROB个数
parameter rob_num = 128;

// tag条目个数
parameter tag_num = 32;

// hash表中slot个数
parameter hash_slot_num = 4;

// MSHR条目个数
parameter mshr_entry_num = 64;

// MSHR子条目个数
parameter mshr_subentry_num = 16; 

// cache control输出buffer的深度
parameter buffer_depth = 6; 

// c2a buffer的深度
parameter c2a_depth = 3;

// 输出buffer的深度
parameter output_buffer_depth = 1;
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

// buffer需要的宽度
localparam buffer_width = 1+info_length+order_id+1+data_length;

// 寄存器个数需要的宽度
localparam register_width = clogb(register_num);

// ROB个数需要的宽度
localparam rob_width = clogb(rob_num);

// ROB的数据宽度
localparam rob_data_length = 1+register_width+info_length+1+1;

// 时钟复位
input clk;
input rst_n;

// B与C的接口信号
input                       b2c_pkt_vld;
input                       b2c_pkt_lkp_en;
input   [info_length-1:0]   b2c_pkt_lkp_info;
input   [order_id-1:0]      b2c_pkt_odr_id;
input                       b2c_pkt_so;
input   [data_length-1:0]   b2c_pkt_payload;
output wire                 c2b_pkt_rdy;

// A与C的接口信号
output wire                     c2a_lkp_vld;
output wire [info_length-1:0]   c2a_lkp_info;
output wire [req_width-1:0]     c2a_lkp_req_id;
input                           a2c_lkp_rdy;

input                           a2c_lkp_rsp_vld;
input   [req_width-1:0]         a2c_lkp_rsp_id;
input   [info_length-1:0]       a2c_lkp_rslt;

// C与D的接口信号
output wire                     c2d_pkt_vld;
output wire [info_length-1:0]   c2d_pkt_lkp_rslt;
output wire [order_id-1:0]      c2d_pkt_odr_id;
output wire                     c2d_pkt_so;
output wire [data_length-1:0]   c2d_pkt_payload;
input                           d2c_pkt_rdy;


// input interface
wire rst;
assign rst = ~rst_n;
// signal
wire [buffer_width-1:0]  fifo_1_out;
wire                     rd_1;
wire                     full_1;
wire                     empty_1;
wire [buffer_width-1:0]  fifo_2_out;
wire                     rd_2;
wire                     full_2;
wire                     empty_2;
wire [buffer_width-1:0]  fifo_3_out;
wire                     rd_3;
wire                     full_3;
wire                     empty_3;

input_interface 
    #(  .info_length(info_length),
        .order_id(order_id),
        .data_length(data_length),
        .input_buffer_depth(input_buffer_depth),
        .issue_buffer_depth(issue_buffer_depth))
u_input_interface
    (   .clk(clk), .rst(rst),
        .b2c_pkt_vld(b2c_pkt_vld),
        .b2c_pkt_lkp_en(b2c_pkt_lkp_en),
        .b2c_pkt_lkp_info(b2c_pkt_lkp_info),
        .b2c_pkt_odr_id(b2c_pkt_odr_id),
        .b2c_pkt_so(b2c_pkt_so),
        .b2c_pkt_payload(b2c_pkt_payload),
        .c2b_pkt_rdy(c2b_pkt_rdy),

        .fifo_1_out(fifo_1_out), .rd_1(rd_1), .full_1(full_1), .empty_1(empty_1),
        .fifo_2_out(fifo_2_out), .rd_2(rd_2), .full_2(full_2), .empty_2(empty_2),
        .fifo_3_out(fifo_3_out), .rd_3(rd_3), .full_3(full_3), .empty_3(empty_3)
    );

// decode
// signal
// decode与execute的接口信号
wire                         reg0_ex_busy0;
wire                         reg0_ex_busy1;
wire                         reg0_decode_valid;
wire                         reg0_decode_en;
wire [info_length-1:0]       reg0_decode_info;
wire [order_id-1:0]          reg0_decode_id;
wire                         reg0_decode_so;
wire [register_width-1:0]    reg0_decode_data_entry;
wire [rob_width-1:0]         reg0_decode_rob_entry;

// decode与reg files的接口信号
wire    [register_width-1:0]    addr1_i;
wire    [data_length-1:0]       data1_i;
wire                            wr1_i;
wire                            full_reg_o;
wire    [register_num-1:0]      register_valid_o;

// decode与rob files的接口信号
// rob_1
wire                    wr0_en_i1;
wire    [rob_width-1:0] head_addr_o1;
wire                    full_rob_o1;
// rob_2
wire                    wr0_en_i2;
wire    [rob_width-1:0] head_addr_o2;
wire                    full_rob_o2;
// rob_3
wire                    wr0_en_i3;
wire    [rob_width-1:0] head_addr_o3;
wire                    full_rob_o3;
// rob_4
wire                    wr0_en_i4;
wire    [rob_width-1:0] head_addr_o4;
wire                    full_rob_o4;
// rob_5
wire                    wr0_en_i5;
wire    [rob_width-1:0] head_addr_o5;
wire                    full_rob_o5;
// rob_6
wire                    wr0_en_i6;
wire    [rob_width-1:0] head_addr_o6;
wire                    full_rob_o6;
// rob_7
wire                    wr0_en_i7;
wire    [rob_width-1:0] head_addr_o7;
wire                    full_rob_o7;

decode
    #(  .info_length(info_length),
        .order_id(order_id),
        .data_length(data_length),
        .register_num(register_num),
        .rob_num(rob_num))
u_decode
    (   .clk(clk), .rst(rst),
        .fifo_1_out(fifo_1_out), .rd_1(rd_1), .empty_1(empty_1),
        .fifo_2_out(fifo_2_out), .rd_2(rd_2), .empty_2(empty_2),
        .fifo_3_out(fifo_3_out), .rd_3(rd_3), .empty_3(empty_3),

        .reg0_ex_busy0(reg0_ex_busy0),
        .reg0_ex_busy1(reg0_ex_busy1),
        .reg0_decode_valid(reg0_decode_valid),
        .reg0_decode_en(reg0_decode_en),
        .reg0_decode_info(reg0_decode_info),
        .reg0_decode_id(reg0_decode_id),
        .reg0_decode_so(reg0_decode_so),
        .reg0_decode_data_entry(reg0_decode_data_entry),
        .reg0_decode_rob_entry(reg0_decode_rob_entry),

        .addr1_i(addr1_i),
        .data1_i(data1_i),
        .wr1_i(wr1_i),
        .full_reg_o(full_reg_o),
        .register_valid_o(register_valid_o),

        .wr0_en_i1(wr0_en_i1), .head_addr_o1(head_addr_o1), .full_rob_o1(full_rob_o1),
        .wr0_en_i2(wr0_en_i2), .head_addr_o2(head_addr_o2), .full_rob_o2(full_rob_o2),
        .wr0_en_i3(wr0_en_i3), .head_addr_o3(head_addr_o3), .full_rob_o3(full_rob_o3),
        .wr0_en_i4(wr0_en_i4), .head_addr_o4(head_addr_o4), .full_rob_o4(full_rob_o4),
        .wr0_en_i5(wr0_en_i5), .head_addr_o5(head_addr_o5), .full_rob_o5(full_rob_o5),
        .wr0_en_i6(wr0_en_i6), .head_addr_o6(head_addr_o6), .full_rob_o6(full_rob_o6),
        .wr0_en_i7(wr0_en_i7), .head_addr_o7(head_addr_o7), .full_rob_o7(full_rob_o7)
    );

// execute
// signal
// execute与lookup table的接口信号
wire                            table_ex_ready_i;
wire                            table_ex_valid_i;
wire    [info_length-1:0]       table_ex_info_i;
wire    [order_id-1:0]          table_ex_id_i;
wire                            table_ex_so_i;
wire    [register_width-1:0]    table_ex_data_entry_i;
wire    [rob_width-1:0]         table_ex_rob_entry_i;

wire                            table_ex_ready_o;
wire                            table_ex_valid_o;
wire    [info_length-1:0]       table_ex_info_o;
wire    [order_id-1:0]          table_ex_id_o;
wire                            table_ex_so_o;
wire    [register_width-1:0]    table_ex_data_entry_o;
wire    [rob_width-1:0]         table_ex_rob_entry_o;

// execute与writeback的接口信号
wire                         wb_busy;
wire                         reg0_ex_valid;
wire                         reg0_ex_en;
wire [info_length-1:0]       reg0_ex_info;
wire [order_id-1:0]          reg0_ex_id;
wire                         reg0_ex_so;
wire [register_width-1:0]    reg0_ex_data_entry;
wire [rob_width-1:0]         reg0_ex_rob_entry;

execute
    #(  .info_length(info_length),
        .order_id(order_id),
        .register_num(register_num),
        .rob_num(rob_num))
u_execute
    (   .clk(clk), .rst(rst),
        .reg0_ex_busy0(reg0_ex_busy0),
        .reg0_ex_busy1(reg0_ex_busy1),
        .reg0_decode_valid(reg0_decode_valid),
        .reg0_decode_en(reg0_decode_en),
        .reg0_decode_info(reg0_decode_info),
        .reg0_decode_id(reg0_decode_id),
        .reg0_decode_so(reg0_decode_so),
        .reg0_decode_data_entry(reg0_decode_data_entry),
        .reg0_decode_rob_entry(reg0_decode_rob_entry),

        .table_ex_ready_i(table_ex_ready_i),
        .table_ex_valid_i(table_ex_valid_i),
        .table_ex_info_i(table_ex_info_i),
        .table_ex_id_i(table_ex_id_i),
        .table_ex_so_i(table_ex_so_i),
        .table_ex_data_entry_i(table_ex_data_entry_i),
        .table_ex_rob_entry_i(table_ex_rob_entry_i),

        .table_ex_ready_o(table_ex_ready_o),
        .table_ex_valid_o(table_ex_valid_o),
        .table_ex_info_o(table_ex_info_o),
        .table_ex_id_o(table_ex_id_o),
        .table_ex_so_o(table_ex_so_o),
        .table_ex_data_entry_o(table_ex_data_entry_o),
        .table_ex_rob_entry_o(table_ex_rob_entry_o),

        .wb_busy(wb_busy),
        .reg0_ex_valid(reg0_ex_valid),
        .reg0_ex_en(reg0_ex_en),
        .reg0_ex_info(reg0_ex_info),
        .reg0_ex_id(reg0_ex_id),
        .reg0_ex_so(reg0_ex_so),
        .reg0_ex_data_entry(reg0_ex_data_entry),
        .reg0_ex_rob_entry(reg0_ex_rob_entry)
    );

// cache_control

cache_control_multibank
    #(  .info_length(info_length),
        .order_id(order_id),
        .register_num(register_num),
        .rob_num(rob_num),
        .req_width(req_width),
        .tag_num(tag_num),
        .hash_slot_num(hash_slot_num),
        .mshr_entry_num(mshr_entry_num),
        .mshr_subentry_num(mshr_subentry_num),
        .buffer_depth(buffer_depth),
        .c2a_depth(c2a_depth))
u_cache_control
    (   .clk(clk), .rst(rst),
        .table_ex_ready_i(table_ex_ready_i),
        .table_ex_valid_i(table_ex_valid_i),
        .table_ex_info_i(table_ex_info_i),
        .table_ex_id_i(table_ex_id_i),
        .table_ex_so_i(table_ex_so_i),
        .table_ex_data_entry_i(table_ex_data_entry_i),
        .table_ex_rob_entry_i(table_ex_rob_entry_i),

        .table_ex_ready_o(table_ex_ready_o),
        .table_ex_valid_o(table_ex_valid_o),
        .table_ex_info_o(table_ex_info_o),
        .table_ex_id_o(table_ex_id_o),
        .table_ex_so_o(table_ex_so_o),
        .table_ex_data_entry_o(table_ex_data_entry_o),
        .table_ex_rob_entry_o(table_ex_rob_entry_o),

        .c2a_lkp_vld(c2a_lkp_vld),
        .c2a_lkp_info(c2a_lkp_info),
        .c2a_lkp_req_id(c2a_lkp_req_id),
        .a2c_lkp_rdy(a2c_lkp_rdy),
        .a2c_lkp_rsp_vld(a2c_lkp_rsp_vld),
        .a2c_lkp_rsp_id(a2c_lkp_rsp_id),
        .a2c_lkp_rslt(a2c_lkp_rslt)
    );

// writeback
// signal
// writeback与output的接口信号
wire                     output_busy_0;
wire                     reg0_wb_valid;
wire [info_length-1:0]   reg0_wb_info;
wire [order_id-1:0]      reg0_wb_id;
wire                     reg0_wb_so;

// wb与req files的接口
// port 0
// Inputs
wire [register_width-1:0]    addr0_i;
wire                         rd0_i;

// wb与rob的接口
// rob_1
wire    [rob_data_length-1:0]   wr1_data_i1;
wire    [rob_width-1:0]         wr1_addr_i1;
wire                            wr1_en_i1;
wire                            rd1_en_i1;
wire    [rob_data_length-1:0]   rd_data_o1;
// rob_2
wire    [rob_data_length-1:0]   wr1_data_i2;
wire    [rob_width-1:0]         wr1_addr_i2;
wire                            wr1_en_i2;
wire                            rd1_en_i2;
wire    [rob_data_length-1:0]   rd_data_o2;
// rob_3
wire    [rob_data_length-1:0]   wr1_data_i3;
wire    [rob_width-1:0]         wr1_addr_i3;
wire                            wr1_en_i3;
wire                            rd1_en_i3;
wire    [rob_data_length-1:0]   rd_data_o3;
// rob_4
wire    [rob_data_length-1:0]   wr1_data_i4;
wire    [rob_width-1:0]         wr1_addr_i4;
wire                            wr1_en_i4;
wire                            rd1_en_i4;
wire    [rob_data_length-1:0]   rd_data_o4;
// rob_5
wire    [rob_data_length-1:0]   wr1_data_i5;
wire    [rob_width-1:0]         wr1_addr_i5;
wire                            wr1_en_i5;
wire                            rd1_en_i5;
wire    [rob_data_length-1:0]   rd_data_o5;
// rob_6
wire    [rob_data_length-1:0]   wr1_data_i6;
wire    [rob_width-1:0]         wr1_addr_i6;
wire                            wr1_en_i6;
wire                            rd1_en_i6;
wire    [rob_data_length-1:0]   rd_data_o6;
// rob_7
wire    [rob_data_length-1:0]   wr1_data_i7;
wire    [rob_width-1:0]         wr1_addr_i7;
wire                            wr1_en_i7;
wire                            rd1_en_i7;
wire    [rob_data_length-1:0]   rd_data_o7;

writeback
    #(  .info_length(info_length),
        .order_id(order_id),
        .data_length(data_length),
        .register_num(register_num),
        .rob_num(rob_num))
u_writeback
    (   .clk(clk), .rst(rst),
        .wb_busy(wb_busy),
        .reg0_ex_valid(reg0_ex_valid),
        .reg0_ex_en(reg0_ex_en),
        .reg0_ex_info(reg0_ex_info),
        .reg0_ex_id(reg0_ex_id),
        .reg0_ex_so(reg0_ex_so),
        .reg0_ex_data_entry(reg0_ex_data_entry),
        .reg0_ex_rob_entry(reg0_ex_rob_entry),

        .output_busy_0(output_busy_0),
        .reg0_wb_valid(reg0_wb_valid),
        .reg0_wb_info(reg0_wb_info),
        .reg0_wb_id(reg0_wb_id),
        .reg0_wb_so(reg0_wb_so),

        .addr0_i(addr0_i),
        .rd0_i(rd0_i),

        .wr1_data_i1(wr1_data_i1), .wr1_addr_i1(wr1_addr_i1), .wr1_en_i1(wr1_en_i1), .rd1_en_i1(rd1_en_i1), .rd_data_o1(rd_data_o1),
        .wr1_data_i2(wr1_data_i2), .wr1_addr_i2(wr1_addr_i2), .wr1_en_i2(wr1_en_i2), .rd1_en_i2(rd1_en_i2), .rd_data_o2(rd_data_o2),
        .wr1_data_i3(wr1_data_i3), .wr1_addr_i3(wr1_addr_i3), .wr1_en_i3(wr1_en_i3), .rd1_en_i3(rd1_en_i3), .rd_data_o3(rd_data_o3),
        .wr1_data_i4(wr1_data_i4), .wr1_addr_i4(wr1_addr_i4), .wr1_en_i4(wr1_en_i4), .rd1_en_i4(rd1_en_i4), .rd_data_o4(rd_data_o4),
        .wr1_data_i5(wr1_data_i5), .wr1_addr_i5(wr1_addr_i5), .wr1_en_i5(wr1_en_i5), .rd1_en_i5(rd1_en_i5), .rd_data_o5(rd_data_o5),
        .wr1_data_i6(wr1_data_i6), .wr1_addr_i6(wr1_addr_i6), .wr1_en_i6(wr1_en_i6), .rd1_en_i6(rd1_en_i6), .rd_data_o6(rd_data_o6),
        .wr1_data_i7(wr1_data_i7), .wr1_addr_i7(wr1_addr_i7), .wr1_en_i7(wr1_en_i7), .rd1_en_i7(rd1_en_i7), .rd_data_o7(rd_data_o7)
    );

// output interface
// signal
// 寄存器Outputs接口信号
wire [data_length-1:0] reg_data_o;

output_interface
    #(  .info_length(info_length),
        .order_id(order_id),
        .data_length(data_length),
        .output_buffer_depth(output_buffer_depth))
u_output_interface
    (   .clk(clk), .rst(rst),
        .c2d_pkt_vld(c2d_pkt_vld),
        .c2d_pkt_lkp_rslt(c2d_pkt_lkp_rslt),
        .c2d_pkt_odr_id(c2d_pkt_odr_id),
        .c2d_pkt_so(c2d_pkt_so),
        .c2d_pkt_payload(c2d_pkt_payload),
        .d2c_pkt_rdy(d2c_pkt_rdy),

        .output_busy_0(output_busy_0),
        .reg0_wb_valid(reg0_wb_valid),
        .reg0_wb_info(reg0_wb_info),
        .reg0_wb_id(reg0_wb_id),
        .reg0_wb_so(reg0_wb_so),

        .reg_data_o(reg_data_o)
    );

// ROB files

// rob_1
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_1
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i1),
        .head_addr_o(head_addr_o1),
        .full_rob_o(full_rob_o1),
        
        .wr1_data_i(wr1_data_i1),
        .wr1_addr_i(wr1_addr_i1),
        .wr1_en_i(wr1_en_i1),
        .rd1_en_i(rd1_en_i1),
        .rd_data_o(rd_data_o1)
    );

// rob_2
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_2
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i2),
        .head_addr_o(head_addr_o2),
        .full_rob_o(full_rob_o2),
        
        .wr1_data_i(wr1_data_i2),
        .wr1_addr_i(wr1_addr_i2),
        .wr1_en_i(wr1_en_i2),
        .rd1_en_i(rd1_en_i2),
        .rd_data_o(rd_data_o2)
    );

// rob_3
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_3
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i3),
        .head_addr_o(head_addr_o3),
        .full_rob_o(full_rob_o3),
        
        .wr1_data_i(wr1_data_i3),
        .wr1_addr_i(wr1_addr_i3),
        .wr1_en_i(wr1_en_i3),
        .rd1_en_i(rd1_en_i3),
        .rd_data_o(rd_data_o3)
    );

// rob_4
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_4
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i4),
        .head_addr_o(head_addr_o4),
        .full_rob_o(full_rob_o4),
        
        .wr1_data_i(wr1_data_i4),
        .wr1_addr_i(wr1_addr_i4),
        .wr1_en_i(wr1_en_i4),
        .rd1_en_i(rd1_en_i4),
        .rd_data_o(rd_data_o4)
    );

// rob_5
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_5
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i5),
        .head_addr_o(head_addr_o5),
        .full_rob_o(full_rob_o5),
        
        .wr1_data_i(wr1_data_i5),
        .wr1_addr_i(wr1_addr_i5),
        .wr1_en_i(wr1_en_i5),
        .rd1_en_i(rd1_en_i5),
        .rd_data_o(rd_data_o5)
    );

// rob_6
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_6
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i6),
        .head_addr_o(head_addr_o6),
        .full_rob_o(full_rob_o6),
        
        .wr1_data_i(wr1_data_i6),
        .wr1_addr_i(wr1_addr_i6),
        .wr1_en_i(wr1_en_i6),
        .rd1_en_i(rd1_en_i6),
        .rd_data_o(rd_data_o6)
    );

// rob_7
ROB_file
    #(  .rob_width(rob_data_length),
        .entry_num(rob_num))
u_ROB_file_7
    (   .clk(clk), .rst(rst),
        .wr0_en_i(wr0_en_i7),
        .head_addr_o(head_addr_o7),
        .full_rob_o(full_rob_o7),
        
        .wr1_data_i(wr1_data_i7),
        .wr1_addr_i(wr1_addr_i7),
        .wr1_en_i(wr1_en_i7),
        .rd1_en_i(rd1_en_i7),
        .rd_data_o(rd_data_o7)
    );

// register files

register_file
    #(  .data_length(data_length),
        .register_num(register_num))
u_register_file
    (   .clk(clk), .rst(rst),
        .addr0_i(addr0_i),
        .rd0_i(rd0_i),

        .addr1_i(addr1_i),
        .data1_i(data1_i),
        .wr1_i(wr1_i),
        .full_reg_o(full_reg_o),
        .register_valid_o(register_valid_o),

        .reg_data_o(reg_data_o)
    );

endmodule
