`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/23 15:24:13
// Design Name: 
// Module Name: cache_control
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


module cache_control(
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

// 报文结果信息
parameter result_length = 20;

// 报文保序id
parameter order_id = 3;

// 寄存器个数
parameter register_num = 32;

// ROB个数
parameter rob_num = 16;

// 请求者需要的宽度
parameter req_width = 10;

// tag条目个数
parameter tag_num = 32;

// hash表中slot个数
parameter hash_slot_num = 2;

// MSHR条目个数
parameter mshr_entry_num = 64;

// MSHR子条目个数
parameter mshr_subentry_num = 1;

// 输出buffer的深度
parameter buffer_depth = 3;

// c2a buffer的深度
parameter c2a_depth = 3;

// bank id
parameter BANK_ID = 1'b0;

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

// tag条目个数宽度
parameter tag_width = clogb(tag_num);

// tag信息长度
localparam tag_length = info_length + result_length;

// MSHR条目个数宽度
localparam mshr_width = clogb(mshr_entry_num);

// c2a信息长度
localparam c2a_length = info_length + mshr_width;

// MSHR子条目个数宽度
localparam mshr_subentry_width = clogb(mshr_subentry_num);

// MSHR entry长度
localparam mshr_entry_length = info_length+result_length+(1+order_id+1+register_width+rob_width)*mshr_subentry_num;

// MSHR subentry长度
localparam mshr_subentry_length = 1+order_id+1+register_width+rob_width;

// buffer需要的宽度
localparam buffer_width = result_length+order_id+1+register_width+rob_width;

// MSHR中resule的start
localparam mshr_resule_start = (1+order_id+1+register_width+rob_width)*mshr_subentry_num;

// MSHR中resule的end
localparam mshr_resule_end = result_length+(1+order_id+1+register_width+rob_width)*mshr_subentry_num-1;

// MSHR中tag的start
localparam mshr_tag_start = result_length+(1+order_id+1+register_width+rob_width)*mshr_subentry_num;

// MSHR中tag的end
localparam mshr_tag_end = info_length+result_length+(1+order_id+1+register_width+rob_width)*mshr_subentry_num-1;

// rob_width
localparam rob_width_start = 0;
localparam rob_width_end = rob_width-1;

// register_width
localparam register_width_start = rob_width;
localparam register_width_end = rob_width+register_width-1;

// so
localparam so_start = rob_width+register_width;
localparam so_end = rob_width+register_width+1-1;

// id
localparam id_start = rob_width+register_width+1;
localparam id_end = rob_width+register_width+1+order_id-1;

// result_length
localparam result_start = rob_width+register_width+1+order_id;
localparam result_end = rob_width+register_width+1+order_id+result_length-1;

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
output wire [result_length-1:0]     table_ex_info_o;
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
input   [result_length-1:0]     a2c_lkp_rslt;

reg                         cache_valid;
reg [info_length-1:0]       cache_info;
reg [order_id-1:0]          cache_id;
reg                         cache_so;
reg [register_width-1:0]    cache_data_entry;
reg [rob_width-1:0]         cache_rob_entry;
always @(*) begin
    cache_valid      = 1'b0;
    cache_info       = {info_length{1'b0}};
    cache_id         = {order_id{1'b0}};
    cache_so         = 1'b0;
    cache_data_entry = {register_width{1'b0}};
    cache_rob_entry  = {rob_width{1'b0}};
    if (table_ex_valid_i) begin
        cache_valid      = table_ex_valid_i;
        cache_info       = table_ex_info_i;
        cache_id         = table_ex_id_i;
        cache_so         = table_ex_so_i;
        cache_data_entry = table_ex_data_entry_i;
        cache_rob_entry  = table_ex_rob_entry_i;
    end
end

reg [2:0]   sel_se;
reg         search0_busy;
reg         search1_busy;
reg         search2_busy;
wire search0_reset, search1_reset, search2_reset;

always @(*) begin
    sel_se = 3'b0;
    if (cache_valid) begin
        if (~search0_busy || search0_reset) begin
            sel_se = 3'b100;
        end else if (~search1_busy || search1_reset) begin
            sel_se = 3'b101;
        end else if (~search2_busy || search2_reset) begin
            sel_se = 3'b110;
        end
    end
end

// search0信号
reg [info_length-1:0]       search0_info;
reg [order_id-1:0]          search0_id;
reg                         search0_so;
reg [register_width-1:0]    search0_data_entry;
reg [rob_width-1:0]         search0_rob_entry;

wire    [tag_length-1:0]    search0_tag_result;
wire                        search0_exist;
wire                        search0_end;

reg [result_length-1:0]   search0_tag_result_q;
reg                     search0_exist_q;
reg                     search0_end_q;

wire search0_exist_flag, search0_end_flag;
assign search0_exist_flag = search0_exist || search0_exist_q;
assign search0_end_flag = search0_end || search0_end_q;

wire [result_length-1:0] search0_tag_result_temp;
assign search0_tag_result_temp = search0_tag_result_q | search0_tag_result[result_length-1:0];

reg search0_valid;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search0_valid <= 1'b0;
    end else if (sel_se == 3'b100) begin
        search0_valid <= 1'b1;
    end else begin
        search0_valid <= 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search0_busy <= 1'b0;
    end else if (sel_se == 3'b100) begin
        search0_busy <= 1'b1;
    end else if (search0_reset) begin
        search0_busy <= 1'b0;
    end else begin
        search0_busy <= search0_busy;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search0_tag_result_q <= {result_length{1'b0}};
        search0_exist_q      <= 1'b0;
        search0_end_q        <= 1'b0;
    end else if (search0_reset) begin
        search0_tag_result_q <= {result_length{1'b0}};
        search0_exist_q      <= 1'b0;
        search0_end_q        <= 1'b0;
    end else if (search0_end) begin
        search0_tag_result_q <= search0_tag_result[result_length-1:0];
        search0_exist_q      <= search0_exist;
        search0_end_q        <= search0_end;
    end else begin
        search0_tag_result_q <= search0_tag_result_q;
        search0_exist_q      <= search0_exist_q;
        search0_end_q        <= search0_end_q;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search0_info       <= {info_length{1'b0}};
        search0_id         <= {order_id{1'b0}};
        search0_so         <= 1'b0;
        search0_data_entry <= {register_width{1'b0}};
        search0_rob_entry  <= {rob_width{1'b0}};
    end else if (sel_se == 3'b100) begin
        search0_info       <= cache_info;
        search0_id         <= cache_id;
        search0_so         <= cache_so;
        search0_data_entry <= cache_data_entry;
        search0_rob_entry  <= cache_rob_entry;
    end else if (search0_reset) begin
        search0_info       <= {info_length{1'b0}};
        search0_id         <= {order_id{1'b0}};
        search0_so         <= 1'b0;
        search0_data_entry <= {register_width{1'b0}};
        search0_rob_entry  <= {rob_width{1'b0}};
    end else begin
        search0_info       <= search0_info;
        search0_id         <= search0_id;
        search0_so         <= search0_so;
        search0_data_entry <= search0_data_entry;
        search0_rob_entry  <= search0_rob_entry;
    end
end

// search1信号
reg [info_length-1:0]       search1_info;
reg [order_id-1:0]          search1_id;
reg                         search1_so;
reg [register_width-1:0]    search1_data_entry;
reg [rob_width-1:0]         search1_rob_entry;

wire    [tag_length-1:0]    search1_tag_result;
wire                        search1_exist;
wire                        search1_end;

reg [result_length-1:0]   search1_tag_result_q;
reg                     search1_exist_q;
reg                     search1_end_q;

wire search1_exist_flag, search1_end_flag;
assign search1_exist_flag = search1_exist || search1_exist_q;
assign search1_end_flag = search1_end || search1_end_q;

wire [result_length-1:0] search1_tag_result_temp;
assign search1_tag_result_temp = search1_tag_result_q | search1_tag_result[result_length-1:0];

reg search1_valid;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search1_valid <= 1'b0;
    end else if (sel_se == 3'b101) begin
        search1_valid <= 1'b1;
    end else if (search0_valid) begin
        search1_valid <= search1_valid;
    end else begin
        search1_valid <= 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search1_busy <= 1'b0;
    end else if (sel_se == 3'b101) begin
        search1_busy <= 1'b1;
    end else if (search1_reset) begin
        search1_busy <= 1'b0;
    end else begin
        search1_busy <= search1_busy;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search1_tag_result_q <= {result_length{1'b0}};
        search1_exist_q      <= 1'b0;
        search1_end_q        <= 1'b0;
    end else if (search1_reset) begin
        search1_tag_result_q <= {result_length{1'b0}};
        search1_exist_q      <= 1'b0;
        search1_end_q        <= 1'b0;
    end else if (search1_end) begin
        search1_tag_result_q <= search1_tag_result[result_length-1:0];
        search1_exist_q      <= search1_exist;
        search1_end_q        <= search1_end;
    end else begin
        search1_tag_result_q <= search1_tag_result_q;
        search1_exist_q      <= search1_exist_q;
        search1_end_q        <= search1_end_q;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search1_info       <= {info_length{1'b0}};
        search1_id         <= {order_id{1'b0}};
        search1_so         <= 1'b0;
        search1_data_entry <= {register_width{1'b0}};
        search1_rob_entry  <= {rob_width{1'b0}};
    end else if (sel_se == 3'b101) begin
        search1_info       <= cache_info;
        search1_id         <= cache_id;
        search1_so         <= cache_so;
        search1_data_entry <= cache_data_entry;
        search1_rob_entry  <= cache_rob_entry;
    end else if (search1_reset) begin
        search1_info       <= {info_length{1'b0}};
        search1_id         <= {order_id{1'b0}};
        search1_so         <= 1'b0;
        search1_data_entry <= {register_width{1'b0}};
        search1_rob_entry  <= {rob_width{1'b0}};
    end else begin
        search1_info       <= search1_info;
        search1_id         <= search1_id;
        search1_so         <= search1_so;
        search1_data_entry <= search1_data_entry;
        search1_rob_entry  <= search1_rob_entry;
    end
end

// search2信号
reg [info_length-1:0]       search2_info;
reg [order_id-1:0]          search2_id;
reg                         search2_so;
reg [register_width-1:0]    search2_data_entry;
reg [rob_width-1:0]         search2_rob_entry;

wire    [tag_length-1:0]    search2_tag_result;
wire                        search2_exist;
wire                        search2_end;

reg [result_length-1:0]   search2_tag_result_q;
reg                     search2_exist_q;
reg                     search2_end_q;

wire search2_exist_flag, search2_end_flag;
assign search2_exist_flag = search2_exist || search2_exist_q;
assign search2_end_flag = search2_end || search2_end_q;

wire [result_length-1:0] search2_tag_result_temp;
assign search2_tag_result_temp = search2_tag_result_q | search2_tag_result[result_length-1:0];

reg search2_valid;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search2_valid <= 1'b0;
    end else if (sel_se == 3'b110) begin
        search2_valid <= 1'b1;
    end else if (search0_valid || search1_valid) begin
        search2_valid <= search2_valid;
    end else begin
        search2_valid <= 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search2_busy <= 1'b0;
    end else if (sel_se == 3'b110) begin
        search2_busy <= 1'b1;
    end else if (search2_reset) begin
        search2_busy <= 1'b0;
    end else begin
        search2_busy <= search2_busy;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search2_tag_result_q <= {result_length{1'b0}};
        search2_exist_q      <= 1'b0;
        search2_end_q        <= 1'b0;
    end else if (search2_reset) begin
        search2_tag_result_q <= {result_length{1'b0}};
        search2_exist_q      <= 1'b0;
        search2_end_q        <= 1'b0;
    end else if (search2_end) begin
        search2_tag_result_q <= search2_tag_result[result_length-1:0];
        search2_exist_q      <= search2_exist;
        search2_end_q        <= search2_end;
    end else begin
        search2_tag_result_q <= search2_tag_result_q;
        search2_exist_q      <= search2_exist_q;
        search2_end_q        <= search2_end_q;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        search2_info       <= {info_length{1'b0}};
        search2_id         <= {order_id{1'b0}};
        search2_so         <= 1'b0;
        search2_data_entry <= {register_width{1'b0}};
        search2_rob_entry  <= {rob_width{1'b0}};
    end else if (sel_se == 3'b110) begin
        search2_info       <= cache_info;
        search2_id         <= cache_id;
        search2_so         <= cache_so;
        search2_data_entry <= cache_data_entry;
        search2_rob_entry  <= cache_rob_entry;
    end else if (search2_reset) begin
        search2_info       <= {info_length{1'b0}};
        search2_id         <= {order_id{1'b0}};
        search2_so         <= 1'b0;
        search2_data_entry <= {register_width{1'b0}};
        search2_rob_entry  <= {rob_width{1'b0}};
    end else begin
        search2_info       <= search2_info;
        search2_id         <= search2_id;
        search2_so         <= search2_so;
        search2_data_entry <= search2_data_entry;
        search2_rob_entry  <= search2_rob_entry;
    end
end

// insert信号
reg [tag_length-1:0] insert_data;
reg insert_valid;
wire insert_end;
// wire insert_error;

// tag table
wire                        search_i;
wire    [info_length-1:0]   search_data_i;
wire    [tag_length-1:0]    search_data_o;
wire                        search_exist_o;
wire                        search_end_o;

wire                        insert_i;
wire    [tag_length-1:0]    insert_data_i;
wire                        insert_end_o;

assign search_i      = search0_valid || search1_valid || search2_valid;
assign search_data_i =  search0_valid ? search0_info : (
                        search1_valid ? search1_info : (
                        search2_valid ? search2_info : {info_length{1'b0}}
                        ));
assign search0_end        = search_data_o[tag_length-1:result_length] == search0_info ? search_end_o : 1'b0;
assign search0_exist      = search_data_o[tag_length-1:result_length] == search0_info ? search_exist_o : 1'b0;
assign search0_tag_result = search_data_o[tag_length-1:result_length] == search0_info ? search_data_o : {result_length{1'b0}};
assign search1_end        = search_data_o[tag_length-1:result_length] == search1_info ? search_end_o : 1'b0;
assign search1_exist      = search_data_o[tag_length-1:result_length] == search1_info ? search_exist_o : 1'b0;
assign search1_tag_result = search_data_o[tag_length-1:result_length] == search1_info ? search_data_o : {result_length{1'b0}};
assign search2_end        = search_data_o[tag_length-1:result_length] == search2_info ? search_end_o : 1'b0;
assign search2_exist      = search_data_o[tag_length-1:result_length] == search2_info ? search_exist_o : 1'b0;
assign search2_tag_result = search_data_o[tag_length-1:result_length] == search2_info ? search_data_o : {result_length{1'b0}};

assign insert_i      = insert_valid;
assign insert_data_i = insert_data;
assign insert_end    = insert_end_o;

multi_hash_top
    #(  .SN(hash_slot_num),
        .HW(tag_width),
        .DW(info_length),
        .RW(result_length),
        .TW(0),
        .BANK_ID(BANK_ID))
u_multi_hash_top
    (   .clk(clk), .rst_n(~rst),
        .search_a_i(search_i), 
        .search_a_data_i(search_data_i), 
        .search_a_result_o(search_data_o), 
        .search_a_exist_o(search_exist_o),
        .search_a_end_o(search_end_o),

        .insert_i(insert_i),
        .insert_data_i({insert_data_i[result_length-1:0],insert_data_i[tag_length-1:result_length]}),
        .insert_end_o(insert_end_o)
    );

// MSHR 
reg [mshr_entry_length-1:0]     mshr_ram [0:mshr_entry_num];
reg [mshr_entry_num-1:0]        mshr_valid;
wire    [mshr_entry_num-1:0]    mshr_valid_temp;
assign mshr_valid_temp = ~mshr_valid & (~(~mshr_valid - 1));

wire    [mshr_subentry_num-1:0] mshr_subentry_valid_0, mshr_subentry_valid_1, mshr_subentry_valid_2;
wire    [mshr_subentry_num-1:0] mshr_subentry_temp;

reg [mshr_width-1:0]        replace_addr_0, replace_addr_1, replace_addr_2;

reg                             wr_mshr_0;
reg [mshr_width-1:0]            addr_mshr_0;
reg [info_length+mshr_subentry_length-1:0]     data_mshr_0;

wire    [mshr_entry_num-1:0]    mshr_hit_0;
wire    [mshr_entry_num-1:0]    mshr_hit_1;
wire    [mshr_entry_num-1:0]    mshr_hit_2;
generate
    genvar h;
    for (h=0; h<mshr_entry_num; h=h+1) begin
        assign mshr_hit_0[h] = (mshr_valid[h] && search0_busy) ? 
                            (mshr_ram[h][mshr_tag_end:mshr_tag_start] == search0_info)
                            : 1'b0;

        assign mshr_hit_1[h] = (mshr_valid[h] && search1_busy) ? 
                            (mshr_ram[h][mshr_tag_end:mshr_tag_start] == search1_info)
                            : 1'b0;

        assign mshr_hit_2[h] = (mshr_valid[h] && search2_busy) ? 
                            (mshr_ram[h][mshr_tag_end:mshr_tag_start] == search2_info)
                            : 1'b0;
    end
endgenerate

generate
    genvar se;
    for (se=0; se<mshr_subentry_num; se=se+1) begin
        assign mshr_subentry_valid_0[se] = mshr_ram[replace_addr_0][mshr_subentry_length*(se+1)-1];

        assign mshr_subentry_valid_1[se] = mshr_ram[replace_addr_1][mshr_subentry_length*(se+1)-1];  

        assign mshr_subentry_valid_2[se] = mshr_ram[replace_addr_2][mshr_subentry_length*(se+1)-1];                        
    end
endgenerate

wire mshr_miss_all_0, mshr_miss_all_1, mshr_miss_all_2;
assign mshr_miss_all_0 = ~(|mshr_hit_0);
assign mshr_miss_all_1 = ~(|mshr_hit_1);
assign mshr_miss_all_2 = ~(|mshr_hit_2);

// 可替换为查找表
integer i0;
always @(*) begin
    replace_addr_0 = {mshr_width{1'b0}};
    if (~mshr_miss_all_0) begin
        for (i0=0; i0<mshr_entry_num; i0=i0+1) begin : mshr_onehot_to_binary_1
            if (mshr_hit_0[i0]) begin
                replace_addr_0 = i0;
            end
        end
    end else begin
        for (i0=0; i0<mshr_entry_num ; i0=i0+1) begin : onehot_to_binary_1
            if (mshr_valid_temp[i0]) begin
                replace_addr_0 = i0;
            end
        end
    end
end
integer i3;
always @(*) begin
    replace_addr_1 = {mshr_width{1'b0}};
    if (~mshr_miss_all_1) begin
        for (i3=0; i3<mshr_entry_num; i3=i3+1) begin : mshr_onehot_to_binary_2
            if (mshr_hit_1[i3]) begin
                replace_addr_1 = i3;
            end
        end
    end else begin
        for (i3=0; i3<mshr_entry_num ; i3=i3+1) begin : onehot_to_binary_2
            if (mshr_valid_temp[i3]) begin
                replace_addr_1 = i3;
            end
        end
    end
end
integer i5;
always @(*) begin
    replace_addr_2 = {mshr_width{1'b0}};
    if (~mshr_miss_all_2) begin
        for (i5=0; i5<mshr_entry_num; i5=i5+1) begin : mshr_onehot_to_binary_3
            if (mshr_hit_2[i5]) begin
                replace_addr_2 = i5;
            end
        end
    end else begin
        for (i5=0; i5<mshr_entry_num ; i5=i5+1) begin : onehot_to_binary_3
            if (mshr_valid_temp[i5]) begin
                replace_addr_2 = i5;
            end
        end
    end
end

reg [2:0] sel_mshr_se;
wire full_c2a;
always @(*) begin
    wr_mshr_0   = 1'b0;
    addr_mshr_0 = {mshr_width{1'b0}};
    data_mshr_0 = {(info_length+mshr_subentry_length){1'b0}};
    sel_mshr_se = 3'b0;
    if (~full_c2a) begin // A空闲并且MSHR有空位
        if (search0_end_flag && ~search0_exist_flag && ((mshr_miss_all_0 && |mshr_valid_temp) || (~mshr_miss_all_0 && ~&mshr_subentry_valid_0))) begin
            wr_mshr_0   = 1'b1;
            addr_mshr_0 = replace_addr_0;
            data_mshr_0 = {search0_info, 1'b1, search0_id, search0_so, search0_data_entry, search0_rob_entry};
            sel_mshr_se = 3'b100;
        end else if (search1_end_flag && ~search1_exist_flag && ((mshr_miss_all_1 && |mshr_valid_temp) || (~mshr_miss_all_1 && ~&mshr_subentry_valid_1))) begin
            wr_mshr_0   = 1'b1;
            addr_mshr_0 = replace_addr_1;
            data_mshr_0 = {search1_info, 1'b1, search1_id, search1_so, search1_data_entry, search1_rob_entry};
            sel_mshr_se = 3'b101;
        end else if (search2_end_flag && ~search2_exist_flag && ((mshr_miss_all_2 && |mshr_valid_temp) || (~mshr_miss_all_2 && ~&mshr_subentry_valid_2))) begin
            wr_mshr_0   = 1'b1;
            addr_mshr_0 = replace_addr_2;
            data_mshr_0 = {search2_info, 1'b1, search2_id, search2_so, search2_data_entry, search2_rob_entry};
            sel_mshr_se = 3'b110;
        end
    end
end

assign mshr_subentry_temp = sel_mshr_se[2] ? (
                            sel_mshr_se[1:0] == 2'b00 ? 
                            ~mshr_subentry_valid_0 & (~(~mshr_subentry_valid_0-1'b1)) : (
                            sel_mshr_se[1:0] == 2'b01 ? 
                            ~mshr_subentry_valid_1 & (~(~mshr_subentry_valid_1-1'b1)) : 
                            ~mshr_subentry_valid_2 & (~(~mshr_subentry_valid_2-1'b1))
                            )) : {mshr_subentry_num{1'b0}};

reg                     wr_mshr_1;
reg [mshr_width-1:0]    addr_mshr_1;
reg [result_length-1:0] data_mshr_1;
always @(*) begin
    wr_mshr_1   = 1'b0;
    addr_mshr_1 = {mshr_width{1'b0}};
    data_mshr_1 = {result_length{1'b0}};
    if (a2c_lkp_rsp_vld) begin
        wr_mshr_1   = 1'b1;
        addr_mshr_1 = a2c_lkp_rsp_id[mshr_width-1:0];
        data_mshr_1 = a2c_lkp_rslt[result_length-1:0];
    end
end

wire rd_mshr;

reg [mshr_width-1:0] rd_addr_mshr;
reg [mshr_width-1:0] rd_addr_mshr_q;

reg [mshr_width-1:0] insert_addr_mshr;
reg [mshr_width-1:0] insert_addr_mshr_q;

reg [mshr_entry_num-1:0] data_ready;
reg [mshr_entry_num-1:0] mshr_ins_comp;
wire [mshr_entry_num-1:0] mshr_reset_flag;

wire [mshr_subentry_num-1:0] sel_sent_subentry_temp;
generate
    genvar m1;
    for (m1=0; m1<mshr_entry_num; m1=m1+1) begin : mshr_entey
        genvar sm1;
        for (sm1=0; sm1<mshr_subentry_num; sm1=sm1+1) begin : mshr_subentry
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-1] <= 1'b0;
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-1] <= 1'b0;
                end else if (addr_mshr_0 == m1 && mshr_subentry_temp[sm1]) begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-1] <= data_mshr_0[mshr_subentry_length-1];
                end else if (rd_addr_mshr_q == m1 && rd_mshr && sel_sent_subentry_temp[sm1]) begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-1] <= 1'b0;
                end else begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-1] <= mshr_ram[m1][mshr_subentry_length*(sm1+1)-1];
                end
            end

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-2:mshr_subentry_length*sm1] <= {(mshr_subentry_length-1){1'b0}};
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-2:mshr_subentry_length*sm1] <= {(mshr_subentry_length-1){1'b0}};
                end else if (addr_mshr_0 == m1 && mshr_subentry_temp[sm1]) begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-2:mshr_subentry_length*sm1] <= data_mshr_0[mshr_subentry_length-2:0];
                end else begin
                    mshr_ram[m1][mshr_subentry_length*(sm1+1)-2:mshr_subentry_length*sm1] <= mshr_ram[m1][mshr_subentry_length*(sm1+1)-2:mshr_subentry_length*sm1];
                end
            end
        end
        if (m1 == 0) begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= {(mshr_resule_end-mshr_resule_start+1){1'b0}};
                    data_ready[m1] <= 1'b0;
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= {(mshr_resule_end-mshr_resule_start+1){1'b0}};
                    data_ready[m1] <= 1'b0;
                end else if (addr_mshr_1 == m1 && wr_mshr_1) begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= data_mshr_1;
                    data_ready[m1] <= 1'b1;
                end else begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= mshr_ram[m1][mshr_resule_end:mshr_resule_start];
                    data_ready[m1] <= data_ready[m1];
                end
            end

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= {(mshr_tag_end-mshr_tag_start+1){1'b0}};
                    mshr_valid[m1] <= 0;
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= {(mshr_tag_end-mshr_tag_start+1){1'b0}};
                    mshr_valid[m1] <= 0;
                end else if (addr_mshr_0 == m1 && wr_mshr_0) begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= data_mshr_0[info_length+mshr_subentry_length-1:mshr_subentry_length];
                    mshr_valid[m1] <= 1;
                end else begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= mshr_ram[m1][mshr_tag_end:mshr_tag_start];
                    mshr_valid[m1] <= mshr_valid[m1];
                end
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= {(mshr_resule_end-mshr_resule_start+1){1'b0}};
                    data_ready[m1] <= 1'b0;
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= {(mshr_resule_end-mshr_resule_start+1){1'b0}};
                    data_ready[m1] <= 1'b0;
                end else if (addr_mshr_1 == m1) begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= data_mshr_1;
                    data_ready[m1] <= 1'b1;
                end else begin
                    mshr_ram[m1][mshr_resule_end:mshr_resule_start] <= mshr_ram[m1][mshr_resule_end:mshr_resule_start];
                    data_ready[m1] <= data_ready[m1];
                end
            end

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    // reset
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= {(mshr_tag_end-mshr_tag_start+1){1'b0}};
                    mshr_valid[m1] <= 1'b0;
                end else if (mshr_reset_flag[m1]) begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= {(mshr_tag_end-mshr_tag_start+1){1'b0}};
                    mshr_valid[m1] <= 1'b0;
                end else if (addr_mshr_0 == m1) begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= data_mshr_0[info_length+mshr_subentry_length-1:mshr_subentry_length];
                    mshr_valid[m1] <= 1'b1;
                end else begin
                    mshr_ram[m1][mshr_tag_end:mshr_tag_start] <= mshr_ram[m1][mshr_tag_end:mshr_tag_start];
                    mshr_valid[m1] <= mshr_valid[m1];
                end
            end
        end

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                // reset
                mshr_ins_comp[m1] <= 1'b0;
            end else if (mshr_reset_flag[m1]) begin
                mshr_ins_comp[m1] <= 1'b0;
            end else if (insert_addr_mshr_q == m1 && insert_end) begin
                mshr_ins_comp[m1] <= 1'b1;
            end
        end
    end
endgenerate

wire [mshr_subentry_num-1:0] mshr_subentry_ready_temp [0:mshr_entry_num-1];
wire [mshr_entry_num-1:0] mshr_subentry_ready;
generate
    genvar sr1;
    for (sr1=0; sr1<mshr_entry_num; sr1=sr1+1) begin : sel_mshr_ready_entry
        genvar sr2;
        for (sr2=0; sr2<mshr_subentry_num; sr2=sr2+1) begin : sel_mshr_ready_subentry
            assign mshr_subentry_ready_temp[sr1][sr2] = mshr_ram[sr1][mshr_subentry_length*(sr2+1)-1];
        end
        assign mshr_subentry_ready[sr1] = |mshr_subentry_ready_temp[sr1];
    end
endgenerate

generate
    genvar rs1;
    for (rs1=0; rs1<mshr_entry_num; rs1=rs1+1) begin : sel_mshr_reset_entry
        assign mshr_reset_flag[rs1] =   mshr_ins_comp[rs1] && 
                                        ((wr_mshr_0 && addr_mshr_0 != rs1) || ~wr_mshr_0) && 
                                        ~mshr_subentry_ready[rs1];
    end
endgenerate

wire [mshr_entry_num-1:0] sent_data_ready;
assign sent_data_ready = data_ready & mshr_subentry_ready;

wire [mshr_entry_num-1:0] data_ready_temp;
assign data_ready_temp = sent_data_ready & (~(sent_data_ready-1));
// 可替换为查找表
integer i1;
always @(*) begin
    rd_addr_mshr = {mshr_width{1'b0}};
    for (i1=0; i1<mshr_entry_num; i1=i1+1) begin : mshr_ready_onehot_to_binary
        if (data_ready_temp[i1]) begin
            rd_addr_mshr = i1;
        end
    end
end

reg sent_data_busy;
always @(*) begin
    sent_data_busy = 1'b0;
    if (|data_ready_temp) begin
        sent_data_busy = 1'b1;
    end
end

always @(*) begin
    rd_addr_mshr_q = {mshr_width{1'b0}};
    if (|data_ready_temp) begin
        rd_addr_mshr_q = rd_addr_mshr;
    end
end

reg [mshr_entry_length-1:0] data_mshr_o;
always @(*) begin
    data_mshr_o = {mshr_entry_length{1'b0}};
    if (|data_ready_temp) begin
        data_mshr_o = mshr_ram[rd_addr_mshr];
    end
end

wire [mshr_subentry_num-1:0] sel_sent_subentry;

assign sel_sent_subentry_temp = sel_sent_subentry & (~(sel_sent_subentry-1'b1));

reg [mshr_subentry_length-2:0] sent_data_subentry;
generate
    genvar ss;
    for (ss=0; ss<mshr_subentry_num; ss=ss+1) begin : sel_data_subentry
        assign sel_sent_subentry[ss] = data_mshr_o[mshr_subentry_length*(ss+1)-1];
    end
endgenerate

// 可替换为查找表
integer i4;
always @(*) begin
    sent_data_subentry = {(mshr_subentry_length-1){1'b0}};
    for (i4=0; i4<mshr_subentry_num; i4=i4+1) begin : sent_data_subentry_onehot_to_binary
        if (sel_sent_subentry_temp[i4]) begin
            sent_data_subentry = data_mshr_o[mshr_subentry_length*(i4+1)-2 -: (mshr_subentry_length-1)];
        end
    end
end

wire [mshr_entry_num-1:0] mshr_need_insert;
assign mshr_need_insert = ~mshr_ins_comp & data_ready;

wire [mshr_entry_num-1:0] mshr_need_insert_temp;
assign mshr_need_insert_temp = mshr_need_insert & (~(mshr_need_insert-1));
// 可替换为查找表
integer i2;
always @(*) begin
    insert_addr_mshr = {mshr_width{1'b0}};
    for (i2=0; i2<mshr_entry_num; i2=i2+1) begin : mshr_ins_comp_onehot_to_binary
        if (mshr_need_insert_temp[i2]) begin
            insert_addr_mshr = i2;
        end
    end
end

reg insert_busy;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        insert_busy <= 1'b0;
    end else if (insert_end) begin
        insert_busy <= 1'b0;
    end else if (|mshr_need_insert_temp) begin
        insert_busy <= 1'b1;
    end else begin
        insert_busy <= insert_busy;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        insert_addr_mshr_q <= {mshr_width{1'b0}};
    end else if (|mshr_need_insert_temp) begin
        if (~insert_busy) begin
            insert_addr_mshr_q <= insert_addr_mshr;
        end else begin
            insert_addr_mshr_q <= insert_addr_mshr_q;
        end
    end else begin
        insert_addr_mshr_q <= {mshr_width{1'b0}};
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        insert_data  <= {tag_length{1'b0}};
        insert_valid <= 1'b0;
    end else if (|mshr_need_insert_temp && ~insert_busy) begin
        insert_data  <= mshr_ram[insert_addr_mshr][mshr_tag_end:mshr_resule_start];
        insert_valid <= 1'b1;
    end else begin
        insert_data  <= {tag_length{1'b0}};
        insert_valid <= 1'b0;
    end
end

wire empty_c2a;

wire [c2a_length-1:0] data_c2a_i;
assign data_c2a_i = (   (sel_mshr_se == 3'b100 && mshr_miss_all_0) || 
                        (sel_mshr_se == 3'b101 && mshr_miss_all_1) ||
                        (sel_mshr_se == 3'b110 && mshr_miss_all_2)) ? 
                        {data_mshr_0[mshr_subentry_length+info_length-1:mshr_subentry_length], addr_mshr_0} : {c2a_length{1'b0}};

wire [c2a_length-1:0] data_c2a_o;
reg rd_en_c2a_o;
always @(*) begin
    rd_en_c2a_o = 1'b0;
    if (~empty_c2a && a2c_lkp_rdy) begin
        rd_en_c2a_o = 1'b1;
    end
end

wire wr_en_c2a_o;
assign wr_en_c2a_o = (  (sel_mshr_se == 3'b100 && mshr_miss_all_0) || 
                        (sel_mshr_se == 3'b101 && mshr_miss_all_1) ||
                        (sel_mshr_se == 3'b110 && mshr_miss_all_2)) ? wr_mshr_0 : 1'b0;

ext_fifo #( .depth(c2a_depth), //fifo 深度2^c2a_depth
            .width(c2a_length) //fifo 宽度 info + mshr_width
) c2a_fifo(
    .clk(clk),.rst(rst),
    .wr_data_i(data_c2a_i),.wr_en_i(wr_en_c2a_o),
    .rd_data_o(data_c2a_o),.rd_en_i(rd_en_c2a_o),
    .full_o(full_c2a),.empty_o(empty_c2a)
    );

assign c2a_lkp_vld = ~empty_c2a;
assign c2a_lkp_info = data_c2a_o[c2a_length-1:mshr_width];
assign c2a_lkp_req_id [mshr_width-1:0] = data_c2a_o[mshr_width-1:0];
assign c2a_lkp_req_id [req_width-1:mshr_width] = 0;

// 判断从data ram中读出的数据是哪个请求
reg [2:0] search_flag;
always @(*) begin
    search_flag = 3'b0;
    if (search0_exist_flag) begin
        search_flag = 3'b100;
    end else if (search1_exist_flag) begin
        search_flag = 3'b101;
    end else if (search2_exist_flag) begin
        search_flag = 3'b110;
    end
end

reg [2:0] sel_output;
always @(*) begin
    sel_output = 3'b0;
    if (search_flag == 3'b100 && search0_busy) begin
        sel_output = 3'b101;
    end else if (search_flag == 3'b101 && search1_busy) begin
        sel_output = 3'b110;
    end else if (search_flag == 3'b110 && search2_busy) begin
        sel_output = 3'b111;
    end else if (sent_data_busy) begin
        sel_output = 3'b100;
    end
end

wire full_o,empty_o;

wire [buffer_width-1:0] data_i;
assign data_i = sel_output[2] ? (
                sel_output[1:0] == 2'b00 ? {data_mshr_o[mshr_resule_end:mshr_resule_start], sent_data_subentry} : (
                sel_output[1:0] == 2'b01 ? {search0_tag_result_temp, search0_id, search0_so, search0_data_entry, search0_rob_entry} : (
                sel_output[1:0] == 2'b10 ? {search1_tag_result_temp, search1_id, search1_so, search1_data_entry, search1_rob_entry} : (
                                        {search2_tag_result_temp, search2_id, search2_so, search2_data_entry, search2_rob_entry}
                )))) : {buffer_width{1'b0}};

wire [buffer_width-1:0] data_o;
reg rd_en_o;
always @(*) begin
    rd_en_o = 1'b0;
    if (table_ex_ready_o && ~empty_o) begin
        rd_en_o = 1'b1;
    end
end

wire wr_en_o;
assign wr_en_o = ~full_o && sel_output[2];

assign search0_reset = (wr_en_o && sel_output == 3'b101) || (sel_mshr_se == 3'b100);
assign search1_reset = (wr_en_o && sel_output == 3'b110) || (sel_mshr_se == 3'b101);
assign search2_reset = (wr_en_o && sel_output == 3'b111) || (sel_mshr_se == 3'b110);
assign rd_mshr = wr_en_o && sel_output == 3'b100;

ext_fifo #( .depth(buffer_depth), //fifo 深度2^input_buffer_depth
            .width(buffer_width) //fifo 宽度 info + id + so + register_width + rob_width
) fifo_o(
    .clk(clk),.rst(rst),
    .wr_data_i(data_i),.wr_en_i(wr_en_o),
    .rd_data_o(data_o),.rd_en_i(rd_en_o),
    .full_o(full_o),.empty_o(empty_o)
    );

assign table_ex_ready_i = (~search0_busy || search0_reset) || (~search1_busy || search1_reset) || (~search2_busy || search2_reset);
assign table_ex_valid_o      = ~empty_o;
assign table_ex_info_o       = data_o[result_end:result_start];
assign table_ex_id_o         = data_o[id_end:id_start];
assign table_ex_so_o         = data_o[so_end:so_start];
assign table_ex_data_entry_o = data_o[register_width_end:register_width_start];
assign table_ex_rob_entry_o  = data_o[rob_width_end:rob_width_start];

endmodule
