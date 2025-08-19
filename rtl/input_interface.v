`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/18 20:23:26
// Design Name: 
// Module Name: input_interface
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


module input_interface(
    clk, rst, b2c_pkt_vld, b2c_pkt_lkp_en, b2c_pkt_lkp_info,
    b2c_pkt_odr_id, b2c_pkt_so, b2c_pkt_payload, c2b_pkt_rdy,
    fifo_1_out, rd_1, full_1, empty_1, fifo_2_out, rd_2, full_2, empty_2,
    fifo_3_out, rd_3, full_3, empty_3
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

// 输入buffer的深度
parameter input_buffer_depth = 3;

// issue buffer的深度
parameter issue_buffer_depth = 3;

//---------------------------------------------------------------------------
// derived parameters
//---------------------------------------------------------------------------

// buffer需要的宽度
localparam buffer_width = 1+info_length+order_id+1+data_length;

// 时钟复位
input clk;
input rst;

// B与C的接口信号
input                       b2c_pkt_vld;
input                       b2c_pkt_lkp_en;
input   [info_length-1:0]   b2c_pkt_lkp_info;
input   [order_id-1:0]      b2c_pkt_odr_id;
input                       b2c_pkt_so;
input   [data_length-1:0]   b2c_pkt_payload;

output wire                 c2b_pkt_rdy;

// interface与decode的接口信号
output wire [buffer_width-1:0]  fifo_1_out;
input                           rd_1;
output wire                     full_1;
output wire                     empty_1;

output wire [buffer_width-1:0]  fifo_2_out;
input                           rd_2;
output wire                     full_2;
output wire                     empty_2;

output wire [buffer_width-1:0]  fifo_3_out;
input                           rd_3;
output wire                     full_3;
output wire                     empty_3;

wire full_i,empty_i;
assign c2b_pkt_rdy = ~full_i;

wire [buffer_width-1:0] data_i;
assign data_i = {b2c_pkt_lkp_en, b2c_pkt_lkp_info, b2c_pkt_odr_id, b2c_pkt_so, b2c_pkt_payload};

wire [buffer_width-1:0] data_o;
reg rd_en_i;

wire wr_en_i;
assign wr_en_i = (c2b_pkt_rdy && b2c_pkt_vld);

ext_fifo #( .depth(input_buffer_depth), //fifo 深度2^input_buffer_depth
            .width(buffer_width) //fifo 宽度 en + info + id + SO + payload
) fifo_Rx_i(
    .clk(clk),.rst(rst),
    .wr_data_i(data_i),.wr_en_i(wr_en_i),
    .rd_data_o(data_o),.rd_en_i(rd_en_i),
    .full_o(full_i),.empty_o(empty_i)
    );

wire Rx_fifo_busy;

always @(*) begin
    rd_en_i = 1'b0;
    if (~empty_i && ~Rx_fifo_busy) begin // 当Rx_fifo_busy为高时，暂停传输数据
        rd_en_i = 1'b1;
    end 
end

wire lkp_en;
assign lkp_en = data_o[buffer_width-1];

wire [order_id-1:0] odr_id;
assign odr_id = data_o[data_length+order_id:data_length+1];

// FIFO_1: en为0且id为0的事务
reg wr_1;
reg [buffer_width-1:0] fifo_1_in;

ext_fifo #( .depth(issue_buffer_depth), //fifo 深度2^issue_buffer_depth
            .width(buffer_width) //fifo 宽度
)fifo_1(
    .clk(clk),.rst(rst),
    .wr_data_i(fifo_1_in),.wr_en_i(wr_1),
    .rd_data_o(fifo_1_out),.rd_en_i(rd_1),
    .full_o(full_1),.empty_o(empty_1)
    );

always @(*) begin
    fifo_1_in = {buffer_width{1'b0}};
    wr_1 = 1'b0;
    if (lkp_en == 0 && odr_id == 0 && rd_en_i) begin
        fifo_1_in = data_o;
        wr_1 = 1'b1;
    end
end

// FIFO_2: en为1且id为0的事务
reg wr_2;
reg [buffer_width-1:0] fifo_2_in;

ext_fifo #( .depth(issue_buffer_depth), //fifo 深度2^issue_buffer_depth
            .width(buffer_width) //fifo 宽度
)fifo_2(
    .clk(clk),.rst(rst),
    .wr_data_i(fifo_2_in),.wr_en_i(wr_2),
    .rd_data_o(fifo_2_out),.rd_en_i(rd_2),
    .full_o(full_2),.empty_o(empty_2)
    );

always @(*) begin
    fifo_2_in = {buffer_width{1'b0}};
    wr_2 = 1'b0;
    if (lkp_en == 1'b1 && odr_id == {order_id{1'b0}} && rd_en_i) begin
        fifo_2_in = data_o;
        wr_2 = 1'b1;
    end
end

// FIFO_3: id不为0的事务
reg wr_3;
reg [buffer_width-1:0] fifo_3_in;

ext_fifo #( .depth(issue_buffer_depth), //fifo 深度2^issue_buffer_depth
            .width(buffer_width) //fifo 宽度
)fifo_3(
    .clk(clk),.rst(rst),
    .wr_data_i(fifo_3_in),.wr_en_i(wr_3),
    .rd_data_o(fifo_3_out),.rd_en_i(rd_3),
    .full_o(full_3),.empty_o(empty_3)
    );

always @(*) begin
    fifo_3_in = {buffer_width{1'b0}};
    wr_3 = 1'b0;
    if (odr_id != 0 && rd_en_i) begin
        fifo_3_in = data_o;
        wr_3 = 1'b1;
    end
end

assign Rx_fifo_busy = full_1 | full_2 | full_3;

endmodule
