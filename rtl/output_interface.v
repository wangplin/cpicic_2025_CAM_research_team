`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/21 21:12:25
// Design Name: 
// Module Name: output_interface
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


module output_interface(
    clk, rst, reg_data_o,
    c2d_pkt_vld, c2d_pkt_lkp_rslt, c2d_pkt_odr_id, c2d_pkt_so, c2d_pkt_payload, d2c_pkt_rdy,
    output_busy_0, reg0_wb_valid, reg0_wb_info, reg0_wb_id, reg0_wb_so
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

// 输出buffer的深度
parameter output_buffer_depth = 3;

//---------------------------------------------------------------------------
// derived parameters
//---------------------------------------------------------------------------

// buffer需要的宽度
localparam buffer_width = info_length+order_id+1+data_length;

// payload
localparam payload_start = 0;
localparam payload_end = data_length-1;

// so
localparam so_start = data_length;
localparam so_end = data_length+1-1;

// id
localparam id_start = data_length+1;
localparam id_end = data_length+1+order_id-1;

// info
localparam info_start = data_length+1+order_id;
localparam info_end = data_length+1+order_id+info_length-1;

// 时钟复位
input clk;
input rst;

// C与D的接口信号
output wire                     c2d_pkt_vld;
output wire [info_length-1:0]   c2d_pkt_lkp_rslt;
output wire [order_id-1:0]      c2d_pkt_odr_id;
output wire                     c2d_pkt_so;
output wire [data_length-1:0]   c2d_pkt_payload;

input                           d2c_pkt_rdy;

// writeback与output的接口信号
output wire                 output_busy_0;
input                       reg0_wb_valid;
input   [info_length-1:0]   reg0_wb_info;
input   [order_id-1:0]      reg0_wb_id;
input                       reg0_wb_so;

// 寄存器Outputs接口信号
input   [data_length-1:0]   reg_data_o;

wire full_o,empty_o;
assign output_busy_0 = full_o;

wire [buffer_width-1:0] data_i;
assign data_i = {reg0_wb_info, reg0_wb_id, reg0_wb_so, reg_data_o};

wire [buffer_width-1:0] data_o;
reg rd_en_o;

wire wr_en_o;
assign wr_en_o = reg0_wb_valid && ~full_o;

ext_fifo #( .depth(output_buffer_depth), //fifo 深度2^input_buffer_depth
            .width(buffer_width) //fifo 宽度 en + info + id + SO + payload
) fifo_Tx_o(
    .clk(clk),.rst(rst),
    .wr_data_i(data_i),.wr_en_i(wr_en_o),
    .rd_data_o(data_o),.rd_en_i(rd_en_o),
    .full_o(full_o),.empty_o(empty_o)
    );

always @(*) begin
    rd_en_o = 0;
    if (~empty_o && d2c_pkt_rdy) begin // 当Rx_fifo_busy为高时，暂停传输数据
        rd_en_o = 1;
    end 
end

assign c2d_pkt_vld      = ~empty_o;
assign c2d_pkt_lkp_rslt = data_o[info_end:info_start];
assign c2d_pkt_odr_id   = data_o[id_end:id_start];
assign c2d_pkt_so       = data_o[so_end:so_start];
assign c2d_pkt_payload  = data_o[payload_end:payload_start];

endmodule
