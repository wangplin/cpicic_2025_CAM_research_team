`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/19 15:29:04
// Design Name: 
// Module Name: multi_hash_top
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

module multi_hash_top#(
    parameter               SN      =   4,      //slot number
                            HW      =   5,      //hash width
                            DW      =   20,     //data width
                            RW      =   20,     //result width
                            TW      =   0,      //time width
                            BANK_ID = 1'b0
    )(
    //system signals
    input                   clk,
    input                   rst_n,

    //insert
    input                   insert_i,
    input   [(RW+DW)-1:0]   insert_data_i,
    // output                  insert_error_o,
    output                  insert_end_o,

    //search a
    input                   search_a_i,
    input   [DW-1:0]        search_a_data_i,
    output                  search_a_exist_o,
    output                  search_a_end_o,
    output  [(RW+DW)-1:0]   search_a_result_o
    );

    //RAM A
    // wire                          rama_wea;
    wire    [HW-1:0]              rama_addra;
    // wire    [(TW+RW+DW+1)*SN-1:0] rama_dina;
    wire    [(TW+RW+DW+1)*SN-1:0] rama_douta;

    wire                          rama_web;
    wire    [HW-1:0]              rama_addrb;
    wire    [(TW+RW+DW+1)*SN-1:0] rama_dinb;
    wire    [(TW+RW+DW+1)*SN-1:0] rama_doutb;

    //RAM B
    // wire                          ramb_wea;
    wire    [HW-1:0]              ramb_addra;
    // wire    [(TW+RW+DW+1)*SN-1:0] ramb_dina;
    wire    [(TW+RW+DW+1)*SN-1:0] ramb_douta;

    wire                          ramb_web;
    wire    [HW-1:0]              ramb_addrb;
    wire    [(TW+RW+DW+1)*SN-1:0] ramb_dinb;
    wire    [(TW+RW+DW+1)*SN-1:0] ramb_doutb;

    //multi hash
    multi_hash #(
        .SN      (SN),   //slot number
        .HW      (HW),   //hash width
        .DW      (DW),   //data width
        .RW      (RW),   //result width
        .TW      (TW),   //time width
        .BANK_ID (BANK_ID)
    ) U_multi_hash(
        //system signals
        .clk                (clk),
        .rst_n              (rst_n),

        //insert
        .insert_i           (insert_i),
        .insert_data_i      (insert_data_i),
        // .insert_error_o     (insert_error_o),
        .insert_end_o       (insert_end_o),

        //search port-a
        .search_a_i         (search_a_i),
        .search_a_data_i    (search_a_data_i),
        .search_a_exist_o   (search_a_exist_o),
        .search_a_end_o     (search_a_end_o),
        .search_a_result_o  (search_a_result_o),

        //RAM A interface
        //side A
        // .rama_wea_o         (rama_wea),
        .rama_addra_o       (rama_addra),
        // .rama_dina_o        (rama_dina),
        .rama_douta_i       (rama_douta),

        //side B
        .rama_web_o         (rama_web),
        .rama_addrb_o       (rama_addrb),
        .rama_dinb_o        (rama_dinb),
        .rama_doutb_i       (rama_doutb),

        //RAM B interface
        //side A
        // .ramb_wea_o         (ramb_wea),
        .ramb_addra_o       (ramb_addra),
        // .ramb_dina_o        (ramb_dina),
        .ramb_douta_i       (ramb_douta),

        //side B
        .ramb_web_o         (ramb_web),
        .ramb_addrb_o       (ramb_addrb),
        .ramb_dinb_o        (ramb_dinb),
        .ramb_doutb_i       (ramb_doutb)
    );

    //ram
    multi_hash_ram_top #(
        .SN                 (SN),   //slot number
        .HW                 (HW),   //hash width
        .DW                 (DW),   //data width
        .RW                 (RW),   //result width
        .TW                 (TW)    //time width
    ) U_multi_hash_ram_top(
        //system signals
        .clk                (clk),
        .rst_n              (rst_n),

        //RAM A
        // .rama_wea_i         (0),
        .rama_addra_i       (rama_addra),
        // .rama_dina_i        (0),
        .rama_douta_o       (rama_douta),

        .rama_web_i         (rama_web),
        .rama_addrb_i       (rama_addrb),
        .rama_dinb_i        (rama_dinb),
        .rama_doutb_o       (rama_doutb),

        //RAM B
        // .ramb_wea_i         (0),
        .ramb_addra_i       (ramb_addra),
        // .ramb_dina_i        (0),
        .ramb_douta_o       (ramb_douta),

        .ramb_web_i         (ramb_web),
        .ramb_addrb_i       (ramb_addrb),
        .ramb_dinb_i        (ramb_dinb),
        .ramb_doutb_o       (ramb_doutb)
    );

endmodule
