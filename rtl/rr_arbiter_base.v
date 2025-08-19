`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/10 16:42:17
// Design Name: 
// Module Name: rr_arbiter_base
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


module rr_arbiter_base #(
    parameter  N = 2, // 仲裁输入的位宽
    parameter  W = 0  // 请求低位的权重
    )(
    // system signals
    input               clk,
    input               rst,
    // signal
    input   [N-1:0]     req_in, // 需要仲裁的请求
    output wire [N-1:0] grant   // one-hot输出仲裁结果
    );

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

    reg [N-1:0] last_req;
    wire[2*N-1:0] double_req = {req_in,req_in};
    wire[2*N-1:0] double_gnt = double_req & ~(double_req - last_req);

    

    assign grant = double_gnt[N-1:0] | double_gnt[2*N-1:N];

    generate
        if (W == 0) begin : without_weight
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    last_req <= 'b1;
                end else if (|req_in) begin
                    last_req <= {grant[N-2:0], grant[N-1]}; 
                end
            end
        end else begin : with_weight
            localparam cnt_width = clogb(W);
            reg [cnt_width-1:0] weight_cnt;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    weight_cnt <= 0;
                end else if (grant != 'b1) begin
                    weight_cnt <= 0;
                end else if (|req_in) begin
                    weight_cnt <= weight_cnt + 1; 
                end
            end

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    last_req <= 'b1;
                end else if (grant == 'b1 && weight_cnt != W-1) begin
                    last_req <= last_req;
                end else if (|req_in) begin
                    last_req <= {grant[N-2:0], grant[N-1]}; 
                end
            end
        end
    endgenerate

endmodule
