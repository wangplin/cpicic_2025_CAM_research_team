////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x^1 + 1
//   * d width: 32
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////

module CRC32_D20#(
    parameter               HW      =   5,
                            HIGH    =   0,
                            BANK_ID =   1'b0
    )(
    input                   clk,
    input                   rst_n,

    input       [18:0]      calc_d_i,
    input                   calc_en_i,

    output      [HW-1:0]    crc32_o,
    output  reg             crc32_valid_o
    );

    wire    [31:0]  new_crc;
    reg     [31:0]  crc32;

    assign new_crc = nextCRC32_D20({calc_d_i,1'b0});

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            crc32           <=    32'h0;
        end
        else if(calc_en_i) begin
            crc32           <=    new_crc;
        end
    end

    assign  crc32_o     =   (HIGH == 1)?crc32[31:32-HW]:crc32[HW-1:0];

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            crc32_valid_o   <=    1'h0;
        end
        else begin
            crc32_valid_o   <=    calc_en_i;
        end
    end

  // polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x^1 + 1
  // d width: 32
  // convention: the first serial bit is D[31]
  function automatic [31:0] nextCRC32_D20;
    // input [31:0] crcIn;
    input [19:0] data;
    localparam c = 32'h5ad7_95ad;
    localparam d_0 = BANK_ID;
    reg [19:0] d;
    reg [31:0] newcrc;
    begin

        d = data;

        newcrc[0] = c[4] ^ c[8] ^ c[10] ^ c[11] ^ c[14] ^ c[20] ^ d[4] ^ d[8] ^ d[10] ^ d[11] ^ d[14];
        newcrc[1] = c[5] ^ c[9] ^ c[11] ^ c[12] ^ c[15] ^ c[21] ^ d[5] ^ d[9] ^ d[11] ^ d[12] ^ d[15];
        newcrc[2] = c[6] ^ c[10] ^ c[12] ^ c[13] ^ c[16] ^ c[22] ^ d[6] ^ d[10] ^ d[12] ^ d[13] ^ d[16];
        newcrc[3] = c[7] ^ c[11] ^ c[13] ^ c[14] ^ c[17] ^ c[23] ^ d[7] ^ d[11] ^ d[13] ^ d[14] ^ d[17];
        newcrc[4] = c[0] ^ c[8] ^ c[12] ^ c[14] ^ c[15] ^ c[18] ^ c[24] ^ d_0 ^ d[8] ^ d[12] ^ d[14] ^ d[15] ^ d[18];
        newcrc[5] = c[0] ^ c[1] ^ c[9] ^ c[13] ^ c[15] ^ c[16] ^ c[19] ^ c[25] ^ d_0 ^ d[1] ^ d[9] ^ d[13] ^ d[15] ^ d[16] ^ d[19];
        newcrc[6] = c[0] ^ c[1] ^ c[2] ^ c[4] ^ c[8] ^ c[11] ^ c[16] ^ c[17] ^ c[26] ^ d_0 ^ d[1] ^ d[2] ^ d[4] ^ d[8] ^ d[11] ^ d[16] ^ d[17];
        newcrc[7] = c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[9] ^ c[12] ^ c[17] ^ c[18] ^ c[27] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[9] ^ d[12] ^ d[17] ^ d[18];
        newcrc[8] = c[0] ^ c[2] ^ c[3] ^ c[4] ^ c[6] ^ c[10] ^ c[13] ^ c[18] ^ c[19] ^ c[28] ^ d_0 ^ d[2] ^ d[3] ^ d[4] ^ d[6] ^ d[10] ^ d[13] ^ d[18] ^ d[19];
        newcrc[9] = c[0] ^ c[1] ^ c[3] ^ c[5] ^ c[7] ^ c[8] ^ c[10] ^ c[19] ^ c[29] ^ d_0 ^ d[1] ^ d[3] ^ d[5] ^ d[7] ^ d[8] ^ d[10] ^ d[19];
        newcrc[10] = c[1] ^ c[2] ^ c[6] ^ c[9] ^ c[10] ^ c[14] ^ c[30] ^ d[1] ^ d[2] ^ d[6] ^ d[9] ^ d[10] ^ d[14];
        newcrc[11] = c[2] ^ c[3] ^ c[7] ^ c[10] ^ c[11] ^ c[15] ^ c[31] ^ d[2] ^ d[3] ^ d[7] ^ d[10] ^ d[11] ^ d[15];
        newcrc[12] = c[3] ^ c[4] ^ c[8] ^ c[11] ^ c[12] ^ c[16] ^ d[3] ^ d[4] ^ d[8] ^ d[11] ^ d[12] ^ d[16];
        newcrc[13] = c[0] ^ c[4] ^ c[5] ^ c[9] ^ c[12] ^ c[13] ^ c[17] ^ d_0 ^ d[4] ^ d[5] ^ d[9] ^ d[12] ^ d[13] ^ d[17];
        newcrc[14] = c[1] ^ c[5] ^ c[6] ^ c[10] ^ c[13] ^ c[14] ^ c[18] ^ d[1] ^ d[5] ^ d[6] ^ d[10] ^ d[13] ^ d[14] ^ d[18];
        newcrc[15] = c[0] ^ c[2] ^ c[6] ^ c[7] ^ c[11] ^ c[14] ^ c[15] ^ c[19] ^ d_0 ^ d[2] ^ d[6] ^ d[7] ^ d[11] ^ d[14] ^ d[15] ^ d[19];
        newcrc[16] = c[1] ^ c[3] ^ c[4] ^ c[7] ^ c[10] ^ c[11] ^ c[12] ^ c[14] ^ c[15] ^ c[16] ^ d[1] ^ d[3] ^ d[4] ^ d[7] ^ d[10] ^ d[11] ^ d[12] ^ d[14] ^ d[15] ^ d[16];
        newcrc[17] = c[0] ^ c[2] ^ c[4] ^ c[5] ^ c[8] ^ c[11] ^ c[12] ^ c[13] ^ c[15] ^ c[16] ^ c[17] ^ d_0 ^ d[2] ^ d[4] ^ d[5] ^ d[8] ^ d[11] ^ d[12] ^ d[13] ^ d[15] ^ d[16] ^ d[17];
        newcrc[18] = c[0] ^ c[1] ^ c[3] ^ c[5] ^ c[6] ^ c[9] ^ c[12] ^ c[13] ^ c[14] ^ c[16] ^ c[17] ^ c[18] ^ d_0 ^ d[1] ^ d[3] ^ d[5] ^ d[6] ^ d[9] ^ d[12] ^ d[13] ^ d[14] ^ d[16] ^ d[17] ^ d[18];
        newcrc[19] = c[1] ^ c[2] ^ c[4] ^ c[6] ^ c[7] ^ c[10] ^ c[13] ^ c[14] ^ c[15] ^ c[17] ^ c[18] ^ c[19] ^ d[1] ^ d[2] ^ d[4] ^ d[6] ^ d[7] ^ d[10] ^ d[13] ^ d[14] ^ d[15] ^ d[17] ^ d[18] ^ d[19];
        newcrc[20] = c[2] ^ c[3] ^ c[4] ^ c[5] ^ c[7] ^ c[10] ^ c[15] ^ c[16] ^ c[18] ^ c[19] ^ d[2] ^ d[3] ^ d[4] ^ d[5] ^ d[7] ^ d[10] ^ d[15] ^ d[16] ^ d[18] ^ d[19];
        newcrc[21] = c[0] ^ c[3] ^ c[5] ^ c[6] ^ c[10] ^ c[14] ^ c[16] ^ c[17] ^ c[19] ^ d_0 ^ d[3] ^ d[5] ^ d[6] ^ d[10] ^ d[14] ^ d[16] ^ d[17] ^ d[19];
        newcrc[22] = c[1] ^ c[6] ^ c[7] ^ c[8] ^ c[10] ^ c[14] ^ c[15] ^ c[17] ^ c[18] ^ d[1] ^ d[6] ^ d[7] ^ d[8] ^ d[10] ^ d[14] ^ d[15] ^ d[17] ^ d[18];
        newcrc[23] = c[2] ^ c[7] ^ c[8] ^ c[9] ^ c[11] ^ c[15] ^ c[16] ^ c[18] ^ c[19] ^ d[2] ^ d[7] ^ d[8] ^ d[9] ^ d[11] ^ d[15] ^ d[16] ^ d[18] ^ d[19];
        newcrc[24] = c[3] ^ c[4] ^ c[9] ^ c[11] ^ c[12] ^ c[14] ^ c[16] ^ c[17] ^ c[19] ^ d[3] ^ d[4] ^ d[9] ^ d[11] ^ d[12] ^ d[14] ^ d[16] ^ d[17] ^ d[19];
        newcrc[25] = c[5] ^ c[8] ^ c[11] ^ c[12] ^ c[13] ^ c[14] ^ c[15] ^ c[17] ^ c[18] ^ d[5] ^ d[8] ^ d[11] ^ d[12] ^ d[13] ^ d[14] ^ d[15] ^ d[17] ^ d[18];
        newcrc[26] = c[0] ^ c[6] ^ c[9] ^ c[12] ^ c[13] ^ c[14] ^ c[15] ^ c[16] ^ c[18] ^ c[19] ^ d_0 ^ d[6] ^ d[9] ^ d[12] ^ d[13] ^ d[14] ^ d[15] ^ d[16] ^ d[18] ^ d[19];
        newcrc[27] = c[0] ^ c[1] ^ c[4] ^ c[7] ^ c[8] ^ c[11] ^ c[13] ^ c[15] ^ c[16] ^ c[17] ^ c[19] ^ d_0 ^ d[1] ^ d[4] ^ d[7] ^ d[8] ^ d[11] ^ d[13] ^ d[15] ^ d[16] ^ d[17] ^ d[19];
        newcrc[28] = c[0] ^ c[1] ^ c[2] ^ c[4] ^ c[5] ^ c[9] ^ c[10] ^ c[11] ^ c[12] ^ c[16] ^ c[17] ^ c[18] ^ d_0 ^ d[1] ^ d[2] ^ d[4] ^ d[5] ^ d[9] ^ d[10] ^ d[11] ^ d[12] ^ d[16] ^ d[17] ^ d[18];
        newcrc[29] = c[1] ^ c[2] ^ c[3] ^ c[5] ^ c[6] ^ c[10] ^ c[11] ^ c[12] ^ c[13] ^ c[17] ^ c[18] ^ c[19] ^ d[1] ^ d[2] ^ d[3] ^ d[5] ^ d[6] ^ d[10] ^ d[11] ^ d[12] ^ d[13] ^ d[17] ^ d[18] ^ d[19];
        newcrc[30] = c[2] ^ c[3] ^ c[6] ^ c[7] ^ c[8] ^ c[10] ^ c[12] ^ c[13] ^ c[18] ^ c[19] ^ d[2] ^ d[3] ^ d[6] ^ d[7] ^ d[8] ^ d[10] ^ d[12] ^ d[13] ^ d[18] ^ d[19];
        newcrc[31] = c[3] ^ c[7] ^ c[9] ^ c[10] ^ c[13] ^ c[19] ^ d[3] ^ d[7] ^ d[9] ^ d[10] ^ d[13] ^ d[19];

        nextCRC32_D20 = newcrc;
    end
endfunction
endmodule
