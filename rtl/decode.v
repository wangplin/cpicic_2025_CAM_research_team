`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/18 21:35:59
// Design Name: 
// Module Name: decode
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


module decode(
    clk, rst,
    fifo_1_out, rd_1, empty_1, fifo_2_out, rd_2, empty_2,
    fifo_3_out, rd_3, empty_3,
    reg0_ex_busy0, reg0_ex_busy1, reg0_decode_valid, reg0_decode_en, reg0_decode_info, 
    reg0_decode_id, reg0_decode_so, reg0_decode_data_entry, reg0_decode_rob_entry,
    addr1_i, data1_i, wr1_i, full_reg_o, register_valid_o,
    wr0_en_i1, head_addr_o1, full_rob_o1,
    wr0_en_i2, head_addr_o2, full_rob_o2,
    wr0_en_i3, head_addr_o3, full_rob_o3,
    wr0_en_i4, head_addr_o4, full_rob_o4,
    wr0_en_i5, head_addr_o5, full_rob_o5,
    wr0_en_i6, head_addr_o6, full_rob_o6,
    wr0_en_i7, head_addr_o7, full_rob_o7
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

// buffer需要的宽度
localparam buffer_width = 1+info_length+order_id+1+data_length;

// 寄存器个数需要的宽度
localparam register_width = clogb(register_num);

// ROB个数需要的宽度
localparam rob_width = clogb(rob_num);

// ROB的数据宽度
localparam rob_data_length = 1+register_width+info_length+1+1;

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

// en
localparam en_start = data_length+1+order_id+info_length;
localparam en_end = data_length+1+order_id+info_length+1-1;

// 时钟复位
input clk;
input rst;

// interface与decode的接口信号
input   [buffer_width-1:0]  fifo_1_out;
output wire                 rd_1;
input                       empty_1;

input   [buffer_width-1:0]  fifo_2_out;
output wire                 rd_2;
input                       empty_2;

input   [buffer_width-1:0]  fifo_3_out;
output wire                 rd_3;
input                       empty_3;

// decode与execute的接口信号
// register0
input                               reg0_ex_busy0;
input                               reg0_ex_busy1;
output wire                         reg0_decode_valid;
output wire                         reg0_decode_en;
output wire [info_length-1:0]       reg0_decode_info;
output wire [order_id-1:0]          reg0_decode_id;
output wire                         reg0_decode_so;
output wire [register_width-1:0]    reg0_decode_data_entry;
output wire [rob_width-1:0]         reg0_decode_rob_entry;

// decode与reg files的接口信号
output wire [register_width-1:0]    addr1_i;
output wire [data_length-1:0]       data1_i;
output wire                         wr1_i;
input                               full_reg_o;
input   [register_num-1:0]          register_valid_o;

// decode与rob files的接口信号
// rob_1
output wire                         wr0_en_i1;
input   [rob_width-1:0]             head_addr_o1;
input                               full_rob_o1;
// rob_2
output wire                         wr0_en_i2;
input   [rob_width-1:0]             head_addr_o2;
input                               full_rob_o2;
// rob_3
output wire                         wr0_en_i3;
input   [rob_width-1:0]             head_addr_o3;
input                               full_rob_o3;
// rob_4
output wire                         wr0_en_i4;
input   [rob_width-1:0]             head_addr_o4;
input                               full_rob_o4;
// rob_5
output wire                         wr0_en_i5;
input   [rob_width-1:0]             head_addr_o5;
input                               full_rob_o5;
// rob_6
output wire                         wr0_en_i6;
input   [rob_width-1:0]             head_addr_o6;
input                               full_rob_o6;
// rob_7
output wire                         wr0_en_i7;
input   [rob_width-1:0]             head_addr_o7;
input                               full_rob_o7;

wire      decode_busy_q; // 表示该周期decode_q需要保持
reg [2:0] arbiter;
always @(*) begin
    arbiter = 3'b0;
    if (~full_reg_o && ~decode_busy_q) begin // 可以分配寄存器
        if (~empty_1) begin
            if (~reg0_ex_busy0) begin
                arbiter = 3'b100;
            end
        end else if (~empty_2) begin
            if (~reg0_ex_busy1) begin
                arbiter = 3'b101;
            end
        end else if (~empty_3) begin
            if (~reg0_ex_busy1 && ~reg0_ex_busy0) begin
                if ((~full_rob_o1 && fifo_3_out[id_end:id_start] == 1) ||
                    (~full_rob_o2 && fifo_3_out[id_end:id_start] == 2) ||
                    (~full_rob_o3 && fifo_3_out[id_end:id_start] == 3) ||
                    (~full_rob_o4 && fifo_3_out[id_end:id_start] == 4) ||
                    (~full_rob_o5 && fifo_3_out[id_end:id_start] == 5) ||
                    (~full_rob_o6 && fifo_3_out[id_end:id_start] == 6) ||
                    (~full_rob_o7 && fifo_3_out[id_end:id_start] == 7)
                    ) begin
                    arbiter = 3'b110;
                end
            end
        end
    end
end

reg                     decode_en;
reg [info_length-1:0]   decode_info;
reg [order_id-1:0]      decode_order_id;
reg                     decode_so;
reg [data_length-1:0]   decode_payload;

always @(*) begin
    decode_en       = 1'b0;
    decode_info     = {info_length{1'b0}};
    decode_order_id = {order_id{1'b0}};
    decode_so       = 1'b0;
    decode_payload  = {data_length{1'b0}};
    if (arbiter[2]) begin // fifo有效
        if (arbiter[1:0] == 2'b00) begin // fifo_1
            decode_en       = fifo_1_out[en_end:en_start];
            decode_info     = fifo_1_out[info_end:info_start];
            decode_order_id = fifo_1_out[id_end:id_start];
            decode_so       = fifo_1_out[so_end:so_start];
            decode_payload  = fifo_1_out[payload_end:payload_start];
        end else if (arbiter[1:0] == 2'b01) begin
            decode_en       = fifo_2_out[en_end:en_start];
            decode_info     = fifo_2_out[info_end:info_start];
            decode_order_id = fifo_2_out[id_end:id_start];
            decode_so       = fifo_2_out[so_end:so_start];
            decode_payload  = fifo_2_out[payload_end:payload_start];
        end else begin
            decode_en       = fifo_3_out[en_end:en_start];
            decode_info     = fifo_3_out[info_end:info_start];
            decode_order_id = fifo_3_out[id_end:id_start];
            decode_so       = fifo_3_out[so_end:so_start];
            decode_payload  = fifo_3_out[payload_end:payload_start];
        end
    end
end

reg                     decode_valid_q;
reg                     decode_en_q;
reg [info_length-1:0]   decode_info_q;
reg [order_id-1:0]      decode_order_id_q;
reg                     decode_so_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        decode_valid_q    <= 1'b0;
        decode_en_q       <= 1'b0;
        decode_info_q     <= {info_length{1'b0}};
        decode_order_id_q <= {order_id{1'b0}};
        decode_so_q       <= 1'b0;
    end else if (   (reg0_ex_busy0 && decode_en_q == 0) || 
                    (reg0_ex_busy1 && decode_en_q == 1)) begin
        decode_valid_q    <= decode_valid_q   ;
        decode_en_q       <= decode_en_q      ;
        decode_info_q     <= decode_info_q    ;
        decode_order_id_q <= decode_order_id_q;
        decode_so_q       <= decode_so_q      ;
    end else if (arbiter[2]) begin // 该周期可以发射
        decode_valid_q    <= 1;
        decode_en_q       <= decode_en;
        decode_info_q     <= decode_info;
        decode_order_id_q <= decode_order_id;
        decode_so_q       <= decode_so;
    end else begin
        decode_valid_q    <= 1'b0;
        decode_en_q       <= 1'b0;
        decode_info_q     <= {info_length{1'b0}};
        decode_order_id_q <= {order_id{1'b0}};
        decode_so_q       <= 1'b0;
    end
end

assign decode_busy_q = (reg0_ex_busy0 && decode_en_q == 0) || (reg0_ex_busy1 && decode_en_q == 1);

assign rd_1 = arbiter == 3'b100;
assign rd_2 = arbiter == 3'b101;
assign rd_3 = arbiter == 3'b110;

assign reg0_decode_valid = decode_valid_q;
assign reg0_decode_en    = decode_en_q;
assign reg0_decode_info  = decode_info_q;
assign reg0_decode_id    = decode_order_id_q;
assign reg0_decode_so    = decode_so_q;

//**********************************
// 与register files交互
//**********************************

// 挑选写入的地址

reg [register_width-1:0] select_entry;
// 可替换为查找表
integer i0;
always @(*) begin
    select_entry = {register_width{1'b0}};
    if (~full_reg_o) begin
        for (i0=0; i0<register_num ; i0=i0+1) begin : onehot_to_binary_1
            if (register_valid_o[i0]) begin
                select_entry = i0;
            end
        end
    end
end

reg [register_width-1:0]    reg_addr;
reg [data_length-1:0]       reg_data;
reg                         reg_wr;

always @(*) begin
    reg_addr = {register_width{1'b0}};
    reg_data = {data_length{1'b0}};
    reg_wr   = 1'b0;
    if (arbiter[2]) begin // 该周期允许发射
        reg_addr = select_entry;
        reg_data = decode_payload;
        reg_wr   = 1'b1;
    end
end

assign addr1_i = reg_addr;
assign data1_i = reg_data;
assign wr1_i   = reg_wr;

reg [register_width-1:0]    reg_addr_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        reg_addr_q <= {register_width{1'b0}};
    end else if (   (reg0_ex_busy0 && decode_en_q == 1'b0) || 
                    (reg0_ex_busy1 && decode_en_q == 1'b1)) begin
        reg_addr_q <= reg_addr_q;
    end
    else begin
        reg_addr_q <= reg_addr;
    end
end

assign reg0_decode_data_entry = reg_addr_q;

//**********************************
// 与rob files交互
//**********************************

reg [rob_width-1:0]         rob_addr;
// reg [rob_data_length-1:0]   rob_data;
reg                         rob_wr;

always @(*) begin
    rob_wr   = 1'b0;
    if (arbiter[1]) begin
        rob_wr   = 1'b1;
    end
end

always @(*) begin
    rob_addr = {rob_width{1'b0}};
    if (arbiter[1]) begin
        if (decode_order_id == 3'd1) begin
            rob_addr = head_addr_o1;
        end else if (decode_order_id == 3'd2) begin
            rob_addr = head_addr_o2;
        end else if (decode_order_id == 3'd3) begin
            rob_addr = head_addr_o3;
        end else if (decode_order_id == 3'd4) begin
            rob_addr = head_addr_o4;
        end else if (decode_order_id == 3'd5) begin
            rob_addr = head_addr_o5;
        end else if (decode_order_id == 3'd6) begin
            rob_addr = head_addr_o6;
        end else if (decode_order_id == 3'd7) begin
            rob_addr = head_addr_o7;
        end
    end
end

assign wr0_en_i1   = (decode_order_id == 3'd1) ? rob_wr : 1'b0;

assign wr0_en_i2   = (decode_order_id == 3'd2) ? rob_wr : 1'b0;

assign wr0_en_i3   = (decode_order_id == 3'd3) ? rob_wr : 1'b0;

assign wr0_en_i4   = (decode_order_id == 3'd4) ? rob_wr : 1'b0;

assign wr0_en_i5   = (decode_order_id == 3'd5) ? rob_wr : 1'b0;

assign wr0_en_i6   = (decode_order_id == 3'd6) ? rob_wr : 1'b0;

assign wr0_en_i7   = (decode_order_id == 3'd7) ? rob_wr : 1'b0;

reg [rob_width-1:0]         rob_addr_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        rob_addr_q <= {rob_width{1'b0}};
    end else if (   (reg0_ex_busy0 && decode_en_q == 0) || 
                    (reg0_ex_busy1 && decode_en_q == 1)) begin
        rob_addr_q <= rob_addr_q;
    end
    else begin
        rob_addr_q <= rob_addr;
    end
end

assign reg0_decode_rob_entry = rob_addr_q;

endmodule
