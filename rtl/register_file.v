`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/19 09:13:43
// Design Name: 
// Module Name: register_file
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


module register_file(
    clk, rst, addr0_i, rd0_i,
    addr1_i, data1_i, wr1_i, 
    reg_data_o, full_reg_o, register_valid_o
    );

//---------------------------------------------------------------------------
// parameters
//---------------------------------------------------------------------------
parameter data_length = 512;
parameter register_num = 32;

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

localparam register_width = clogb(register_num);

// localparam slice_sram_length = data_length / 64;

input                           clk;
input                           rst;
// port 0
// Inputs
input   [register_width-1:0]    addr0_i;
input                           rd0_i;

// port 1
// Inputs
input   [register_width-1:0]    addr1_i;
input   [data_length-1:0]       data1_i;
input                           wr1_i;

// Outputs
output wire [data_length-1:0]   reg_data_o;
output wire                     full_reg_o;
output wire [register_num-1:0]  register_valid_o;

reg [data_length-1:0] register [0:register_num-1];

reg [data_length-1:0] register_read0_q;
always @ (posedge clk)
begin
    if (wr1_i)
        register[addr1_i] = data1_i;

    if (rd0_i)
        register_read0_q = register[addr0_i];
end

/* memory complier
wire [data_length-1:0] sram0_read0_q;
wire [data_length-1:0] sram1_read0_q;
reg [register_width-1:0] addr0_q;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        addr0_q <= 0;
    end else begin
        addr0_q <= addr0_i;
    end
end
wire [data_length-1:0] register_read0_q;
assign register_read0_q = addr0_q[8] ? sram1_read0_q : sram0_read0_q;
generate
    genvar i;
    for (i=0; i<slice_sram_length; i=i+1) begin:slice_sram
        wire [7:0] addr_sram0_0, addr_sram0_1;
        assign addr_sram0_0 = addr0_i[8] ? 8'h0 : addr0_i[7:0];
        assign addr_sram0_1 = addr1_i[8] ? 8'h0 : addr1_i[7:0];
        TSDN12FFCLLULVTA256X64M4 u_dual_port_ram_0(
            // .WTSEL(2'b01),
            // .RTSEL(2'b01),
            .AA(addr_sram0_1),
            .DA(data1_i[64*(i+1)-1:64*i]),
            .WEBA(~wr1_i),.CEBA(0),.CLKA(clk),
            .AB(addr_sram0_0),
            .DB(0),
            .WEBB(1'b1),.CEBB(0),.CLKB(clk),
            .QA(),
            .QB(sram0_read0_q[64*(i+1)-1:64*i])
        );

        wire [5:0] addr_sram1_0, addr_sram1_1;
        assign addr_sram1_0 = addr0_i[8] ? addr0_i[5:0] : 6'b0;
        assign addr_sram1_1 = addr1_i[8] ? addr1_i[5:0] : 6'b0;
        TSDN12FFCLLULVTA64X64M4 u_dual_port_ram_1(
            // .WTSEL(2'b01),
            // .RTSEL(2'b01),
            .AA(addr_sram1_1),
            .DA(data1_i[64*(i+1)-1:64*i]),
            .WEBA(~wr1_i),.CEBA(0),.CLKA(clk),
            .AB(addr_sram1_0),
            .DB(0),
            .WEBB(1'b1),.CEBB(0),.CLKB(clk),
            .QA(),
            .QB(sram1_read0_q[64*(i+1)-1:64*i])
        );
    end
endgenerate
*/
assign reg_data_o = register_read0_q;

reg [register_num-1:0] register_valid;

assign full_reg_o = &register_valid; // valid全为1表示寄存器已满

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        register_valid <= 0;
    end else begin
        if (wr1_i) begin
            register_valid[addr1_i] <= 1;
        end

        if (rd0_i) begin
            register_valid[addr0_i] <= 0;
        end
    end
end

reg [register_num-1:0] register_valid_temp;
always @(*) begin
    register_valid_temp = register_valid;
    if (wr1_i) begin
        register_valid_temp[addr1_i] = 1;
    end
    if (rd0_i) begin
        register_valid_temp[addr0_i] = 0;
    end
end

reg [register_num-1:0] register_valid_onehot;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        register_valid_onehot <= 0;
    end else begin
        register_valid_onehot <= ~register_valid_temp & ~(~register_valid_temp-1);
    end
end

assign register_valid_o = register_valid_onehot;

endmodule
