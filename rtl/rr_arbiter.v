`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/10 16:42:17
// Design Name: 
// Module Name: rr_arbiter
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


module rr_arbiter #(
    parameter  N = 7 // 仲裁输入的位宽
    )(
    // system signals
    input               clk,
    input               rst,
    // signal
    input   [N-1:0]     req_in, // 需要仲裁的请求
    input               arbiter_valid, // 需要进行仲裁
    output wire [N-1:0] grant   // one-hot输出仲裁结果
    );

    wire    [N-1:0] req_after_mask;
    reg [N-1:0]     mask_ptr;
    wire [N-1:0]     grant_without_mask, grant_with_mask;
    //---------------------------------------------------
    // first fixed priority arbiter
    //---------------------------------------------------
    assign req_after_mask = req_in & mask_ptr;
    assign grant_with_mask = req_after_mask & ~(req_after_mask - 1);
    
    //---------------------------------------------------
    // first fixed priority arbiter
    //---------------------------------------------------
    assign grant_without_mask = req_in & ~(req_in - 1);

    //---------------------------------------------------
    // select which grant to use
    //---------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mask_ptr <= {N{1'b1}};
        end else begin
            if (|req_after_mask && arbiter_valid)
                mask_ptr <= mask_ptr & ~((grant_with_mask << 1) - 1);
            else if (|req_in && arbiter_valid) 
                mask_ptr <= {N{1'b1}} & ~((grant_without_mask << 1) - 1);
        end
    end

    assign grant = |req_after_mask ? grant_with_mask : grant_without_mask;

endmodule
