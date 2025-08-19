`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/20 15:58:26
// Design Name: 
// Module Name: multi_hash_ram_top
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

module multi_hash_ram_top#(
    parameter               SN  =   4,      //slot number
                            HW  =   6,      //hash width
                            DW  =   19,     //data width
                            RW  =   20,     //result width
                            TW  =   0       //time width
    )(
    //system signals
    input                   clk,
    input                   rst_n,

    //RAM A
    // input                         rama_wea_i,
    input   [HW-1:0]              rama_addra_i,
    // input   [(TW+RW+DW+1)*SN-1:0] rama_dina_i,
    output  [(TW+RW+DW+1)*SN-1:0] rama_douta_o,

    input                         rama_web_i,
    input   [HW-1:0]              rama_addrb_i,
    input   [(TW+RW+DW+1)*SN-1:0] rama_dinb_i,
    output  [(TW+RW+DW+1)*SN-1:0] rama_doutb_o,

    //RAM B
    // input                         ramb_wea_i,
    input   [HW-1:0]              ramb_addra_i,
    // input   [(TW+RW+DW+1)*SN-1:0] ramb_dina_i,
    output  [(TW+RW+DW+1)*SN-1:0] ramb_douta_o,

    input                         ramb_web_i,
    input   [HW-1:0]              ramb_addrb_i,
    input   [(TW+RW+DW+1)*SN-1:0] ramb_dinb_i,
    output  [(TW+RW+DW+1)*SN-1:0] ramb_doutb_o
    );

    // localparam slice_sram_length = SN*(TW+RW+DW+1) / 40;

    // generate
    //     genvar i;
    //     for (i=0;i<slice_sram_length;i=i+1) begin:slice_sram
    //         TSDN12FFCLLULVTA64X40M4 U0_dual_port_ram(
    //             .AA(rama_addra_i),
    //             .DA(0),
    //             .WEBA(1'b1),.CEBA(0),.CLKA(clk),
    //             .AB(rama_addrb_i),
    //             .DB(rama_dinb_i[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)]),
    //             .WEBB(~rama_web_i),.CEBB(0),.CLKB(clk),
    //             .QA(rama_douta_o[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)]),
    //             .QB(rama_doutb_o[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)])
    //         );

    //         TSDN12FFCLLULVTA64X40M4 U1_dual_port_ram(
    //             .AA(ramb_addra_i),
    //             .DA(0),
    //             .WEBA(1'b1),.CEBA(0),.CLKA(clk),
    //             .AB(ramb_addrb_i),
    //             .DB(ramb_dinb_i[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)]),
    //             .WEBB(~ramb_web_i),.CEBB(0),.CLKB(clk),
    //             .QA(ramb_douta_o[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)]),
    //             .QB(ramb_doutb_o[(TW+RW+DW+1)*SN-40*i-1:(TW+RW+DW+1)*SN-40*(i+1)])
    //         );
    //     end
    // endgenerate

    generate
        genvar i;
        for (i=0;i<SN;i=i+1) begin:gen_ram
            dual_port_ram #(
                .DPW        (HW),
                .DW         (TW+RW+DW+1)
            ) U0_dual_port_ram(
                //port a
                .clka       (clk),
                // .wea        (rama_wea_i),
                .addra      (rama_addra_i),
                // .dina       (rama_dina_i[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),
                .douta      (rama_douta_o[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),

                //port b
                .clkb       (clk),
                .web        (rama_web_i),
                .addrb      (rama_addrb_i),
                .dinb       (rama_dinb_i[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),
                .doutb      (rama_doutb_o[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i])
            );

            dual_port_ram #(
                .DPW        (HW),
                .DW         (RW+DW+1)
            ) U1_dual_port_ram(
                //port a
                .clka       (clk),
                // .wea        (ramb_wea_i),
                .addra      (ramb_addra_i),
                // .dina       (ramb_dina_i[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),
                .douta      (ramb_douta_o[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),

                //port b
                .clkb       (clk),
                .web        (ramb_web_i),
                .addrb      (ramb_addrb_i),
                .dinb       (ramb_dinb_i[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i]),
                .doutb      (ramb_doutb_o[(TW+RW+DW+1)*(i+1)-1:(TW+RW+DW+1)*i])
            );
        end
    endgenerate

endmodule
