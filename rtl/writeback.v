`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/21 09:40:19
// Design Name: 
// Module Name: writeback
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


module writeback(
    clk, rst, addr0_i, rd0_i,
    wb_busy, reg0_ex_valid, reg0_ex_en, reg0_ex_info, 
    reg0_ex_id, reg0_ex_so, reg0_ex_data_entry, reg0_ex_rob_entry,
    output_busy_0, reg0_wb_valid, reg0_wb_info, reg0_wb_id, reg0_wb_so,
    wr1_data_i1, wr1_addr_i1, wr1_en_i1, rd1_en_i1, rd_data_o1,
    wr1_data_i2, wr1_addr_i2, wr1_en_i2, rd1_en_i2, rd_data_o2,
    wr1_data_i3, wr1_addr_i3, wr1_en_i3, rd1_en_i3, rd_data_o3,
    wr1_data_i4, wr1_addr_i4, wr1_en_i4, rd1_en_i4, rd_data_o4,
    wr1_data_i5, wr1_addr_i5, wr1_en_i5, rd1_en_i5, rd_data_o5,
    wr1_data_i6, wr1_addr_i6, wr1_en_i6, rd1_en_i6, rd_data_o6,
    wr1_data_i7, wr1_addr_i7, wr1_en_i7, rd1_en_i7, rd_data_o7
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

// 寄存器个数需要的宽度
localparam register_width = clogb(register_num);

// ROB个数需要的宽度
localparam rob_width = clogb(rob_num);

// ROB的数据宽度
localparam rob_data_length = 1+register_width+info_length+1+1;

// so
localparam so_start = 1;
localparam so_end = 1+1-1;

// info
localparam info_start = 2;
localparam info_end = 2+info_length-1;

// req addr
localparam req_addr_start = 2+info_length;
localparam req_addr_end = 2+info_length+register_width-1;

// 时钟复位
input clk;
input rst;

// execute与writeback的接口信号
output wire                     wb_busy;
input                           reg0_ex_valid;
input                           reg0_ex_en;
input   [info_length-1:0]       reg0_ex_info;
input   [order_id-1:0]          reg0_ex_id;
input                           reg0_ex_so;
input   [register_width-1:0]    reg0_ex_data_entry;
input   [rob_width-1:0]         reg0_ex_rob_entry;

// writeback与output的接口信号
input                           output_busy_0;
output wire                     reg0_wb_valid;
output wire [info_length-1:0]   reg0_wb_info;
output wire [order_id-1:0]      reg0_wb_id;
output wire                     reg0_wb_so;

// wb与req files的接口
// port 0
// Inputs
output wire [register_width-1:0]    addr0_i;
output wire                         rd0_i;

// wb与rob的接口
// rob_1
output wire [rob_data_length-1:0]   wr1_data_i1;
output wire [rob_width-1:0]         wr1_addr_i1;
output wire                         wr1_en_i1;
output wire                         rd1_en_i1;
input   [rob_data_length-1:0]       rd_data_o1;
// rob_2
output wire [rob_data_length-1:0]   wr1_data_i2;
output wire [rob_width-1:0]         wr1_addr_i2;
output wire                         wr1_en_i2;
output wire                         rd1_en_i2;
input   [rob_data_length-1:0]       rd_data_o2;
// rob_3
output wire [rob_data_length-1:0]   wr1_data_i3;
output wire [rob_width-1:0]         wr1_addr_i3;
output wire                         wr1_en_i3;
output wire                         rd1_en_i3;
input   [rob_data_length-1:0]       rd_data_o3;
// rob_4
output wire [rob_data_length-1:0]   wr1_data_i4;
output wire [rob_width-1:0]         wr1_addr_i4;
output wire                         wr1_en_i4;
output wire                         rd1_en_i4;
input   [rob_data_length-1:0]       rd_data_o4;
// rob_5
output wire [rob_data_length-1:0]   wr1_data_i5;
output wire [rob_width-1:0]         wr1_addr_i5;
output wire                         wr1_en_i5;
output wire                         rd1_en_i5;
input   [rob_data_length-1:0]       rd_data_o5;
// rob_6
output wire [rob_data_length-1:0]   wr1_data_i6;
output wire [rob_width-1:0]         wr1_addr_i6;
output wire                         wr1_en_i6;
output wire                         rd1_en_i6;
input   [rob_data_length-1:0]       rd_data_o6;
// rob_7
output wire [rob_data_length-1:0]   wr1_data_i7;
output wire [rob_width-1:0]         wr1_addr_i7;
output wire                         wr1_en_i7;
output wire                         rd1_en_i7;
input   [rob_data_length-1:0]       rd_data_o7;

reg                         wb_valid;
reg                         wb_en;
reg [info_length-1:0]       wb_info;
reg [order_id-1:0]          wb_id;
reg                         wb_so;
reg [register_width-1:0]    wb_data_entry;
reg [rob_width-1:0]         wb_rob_entry;

always @(*) begin
    wb_valid      = 0;
    wb_en         = 0;
    wb_info       = 0;
    wb_id         = 0;
    wb_so         = 0;
    wb_data_entry = 0;
    wb_rob_entry  = 0;
    if (reg0_ex_valid) begin
        wb_valid      = reg0_ex_valid;
        wb_en         = reg0_ex_en;
        wb_info       = reg0_ex_info;
        wb_id         = reg0_ex_id;
        wb_so         = reg0_ex_so;
        wb_data_entry = reg0_ex_data_entry;
        wb_rob_entry  = reg0_ex_rob_entry;
    end
end

wire [6:0] rob_data_ready;

reg [8:0] cnt;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 'b1;
    end else if (~&cnt) begin
        cnt <= cnt + 1; 
    end
end

wire sent_id_0; // order id为0则优先输出
assign sent_id_0 = reg0_ex_valid && ~|wb_id;
/******************************轮询仲裁器*****************************/
wire [1:0] rr_output_req_in; // 选择从wb中发送或者从rob中发送
wire [1:0] rr_output_gnt;
assign rr_output_req_in[0] = sent_id_0 ? 0 : (reg0_ex_valid & ~wb_so); // 可以从wb中输出
assign rr_output_req_in[1] = sent_id_0 ? 0 : (&cnt ? |rob_data_ready : 0); // 可以从rob中输出
rr_arbiter_base
    #(.N(2), .W(16))
u_rr_output_arbiter_base
    (   .clk(clk), .rst(rst),
        .req_in(rr_output_req_in),
        .grant(rr_output_gnt)
    );

wire output_busy;
assign output_busy = output_busy_0;

// 与rob交互
reg [rob_data_length-1:0]   rob_wr_data;
reg [rob_width-1:0]         rob_wr_addr;
reg                         rob_wr_en;
always @(*) begin
    rob_wr_data = 0;
    rob_wr_addr = 0;
    rob_wr_en = 0;
    if (~output_busy && |wb_id) begin
        if (wb_so || rr_output_gnt[1]) begin // 该报文需要排序或者本周期从rob中输出
            rob_wr_data = {1'b1, wb_data_entry, wb_info, wb_so, 1'b0};
        end else begin
            rob_wr_data = 'b1;
        end
        rob_wr_addr = wb_rob_entry;
        rob_wr_en = 1;
    end
end

assign wr1_data_i1 = (wb_id == 3'd1) ? rob_wr_data : 0;
assign wr1_addr_i1 = (wb_id == 3'd1) ? rob_wr_addr : 0;
assign wr1_en_i1   = (wb_id == 3'd1) ? rob_wr_en : 0;

assign wr1_data_i2 = (wb_id == 3'd2) ? rob_wr_data : 0;
assign wr1_addr_i2 = (wb_id == 3'd2) ? rob_wr_addr : 0;
assign wr1_en_i2   = (wb_id == 3'd2) ? rob_wr_en : 0;

assign wr1_data_i3 = (wb_id == 3'd3) ? rob_wr_data : 0;
assign wr1_addr_i3 = (wb_id == 3'd3) ? rob_wr_addr : 0;
assign wr1_en_i3   = (wb_id == 3'd3) ? rob_wr_en : 0;

assign wr1_data_i4 = (wb_id == 3'd4) ? rob_wr_data : 0;
assign wr1_addr_i4 = (wb_id == 3'd4) ? rob_wr_addr : 0;
assign wr1_en_i4   = (wb_id == 3'd4) ? rob_wr_en : 0;

assign wr1_data_i5 = (wb_id == 3'd5) ? rob_wr_data : 0;
assign wr1_addr_i5 = (wb_id == 3'd5) ? rob_wr_addr : 0;
assign wr1_en_i5   = (wb_id == 3'd5) ? rob_wr_en : 0;

assign wr1_data_i6 = (wb_id == 3'd6) ? rob_wr_data : 0;
assign wr1_addr_i6 = (wb_id == 3'd6) ? rob_wr_addr : 0;
assign wr1_en_i6   = (wb_id == 3'd6) ? rob_wr_en : 0;

assign wr1_data_i7 = (wb_id == 3'd7) ? rob_wr_data : 0;
assign wr1_addr_i7 = (wb_id == 3'd7) ? rob_wr_addr : 0;
assign wr1_en_i7   = (wb_id == 3'd7) ? rob_wr_en : 0;


assign rob_data_ready[0] = rd_data_o1[rob_data_length-1];
assign rob_data_ready[1] = rd_data_o2[rob_data_length-1];
assign rob_data_ready[2] = rd_data_o3[rob_data_length-1];
assign rob_data_ready[3] = rd_data_o4[rob_data_length-1];
assign rob_data_ready[4] = rd_data_o5[rob_data_length-1];
assign rob_data_ready[5] = rd_data_o6[rob_data_length-1];
assign rob_data_ready[6] = rd_data_o7[rob_data_length-1];

wire [6:0] rob_grant;
reg arbiter_valid;

rr_arbiter #(
    .N(7))
rob_arbiter (
    .clk(clk), .rst(rst),
    .req_in(rob_data_ready),
    .arbiter_valid(arbiter_valid),
    .grant(rob_grant)
    );

reg [rob_data_length-1:0]   rob_rd_data;
reg [6:0] rob_rd_en;
reg rob_valid;
reg [order_id-1:0] rob_id;
always @(*) begin
    rob_rd_data = 0;
    rob_rd_en   = 0;
    rob_valid   = 0;
    rob_id      = 0;
    arbiter_valid = 0;
    if (~output_busy && rr_output_gnt[1]) begin
        arbiter_valid = 1;
        rob_rd_en = rob_grant;
        if (rob_grant[0]) begin // 数据准备好了
            rob_rd_data  = rd_data_o1;
            rob_valid    = 1;
            rob_id       = 3'd1;
        end else if (rob_grant[1]) begin
            rob_rd_data  = rd_data_o2;
            rob_valid    = 1;
            rob_id       = 3'd2;
        end else if (rob_grant[2]) begin
            rob_rd_data  = rd_data_o3;
            rob_valid    = 1;
            rob_id       = 3'd3;
        end else if (rob_grant[3]) begin
            rob_rd_data  = rd_data_o4;
            rob_valid    = 1;
            rob_id       = 3'd4;
        end else if (rob_grant[4]) begin
            rob_rd_data  = rd_data_o5;
            rob_valid    = 1;
            rob_id       = 3'd5;
        end else if (rob_grant[5]) begin
            rob_rd_data  = rd_data_o6;
            rob_valid    = 1;
            rob_id       = 3'd6;
        end else if (rob_grant[6]) begin
            rob_rd_data  = rd_data_o7;
            rob_valid    = 1;
            rob_id       = 3'd7;
        end
    end
end

assign rd1_en_i1 = rob_rd_en[0];
assign rd1_en_i2 = rob_rd_en[1];
assign rd1_en_i3 = rob_rd_en[2];
assign rd1_en_i4 = rob_rd_en[3];
assign rd1_en_i5 = rob_rd_en[4];
assign rd1_en_i6 = rob_rd_en[5];
assign rd1_en_i7 = rob_rd_en[6];

// 与寄存器文件交互
reg [register_width-1:0]    reg_addr;
reg                         reg_rd;
always @(*) begin
    reg_addr = 0;
    reg_rd = 0;
    if (~output_busy) begin
        if (rr_output_gnt[0] || sent_id_0) begin
            reg_addr = wb_data_entry;
            reg_rd = 1;
        end else if (rr_output_gnt[1]) begin
            reg_addr = rob_rd_data[req_addr_end:req_addr_start];
            reg_rd = 1;
        end
    end
end

assign addr0_i = reg_addr;
assign rd0_i   = reg_rd;

reg                         wb_valid_q;
reg [order_id-1:0]          wb_id_q;
reg                         wb_so_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        wb_valid_q <= 0;
        wb_id_q    <= 0;
        wb_so_q    <= 0;
    end else if (output_busy) begin
        wb_valid_q <= wb_valid_q;
        wb_id_q    <= wb_id_q;
        wb_so_q    <= wb_so_q;
    end else if (rr_output_gnt[0] || sent_id_0) begin
        wb_valid_q <= 1;
        wb_id_q    <= wb_id;
        wb_so_q    <= wb_so;
    end else if (rr_output_gnt[1]) begin
        wb_valid_q <= 1;
        wb_id_q    <= rob_id;
        wb_so_q    <= rob_rd_data[so_end:so_start];
    end else begin
        wb_valid_q <= 0;
        wb_id_q    <= 0;
        wb_so_q    <= 0;
    end
end

reg [info_length-1:0]   wb_info_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        wb_info_q <= 0;
    end else if (output_busy) begin
        wb_info_q <= wb_info_q;
    end else if (rr_output_gnt[0] || sent_id_0) begin
        wb_info_q <= wb_info;
    end else if (rr_output_gnt[1]) begin
        wb_info_q <= rob_rd_data[info_end:info_start];
    end else begin
        wb_info_q <= 0;
    end
end

assign wb_busy = output_busy_0;
assign reg0_wb_valid = wb_valid_q;
assign reg0_wb_info = wb_info_q;
assign reg0_wb_id = wb_id_q;
assign reg0_wb_so = wb_so_q;


endmodule
