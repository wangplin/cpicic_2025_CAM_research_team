`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/19 21:11:13
// Design Name: 
// Module Name: multi_hash
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

module multi_hash#(
    parameter               SN  =   4,      //slot number
                            HW  =   5,      //hash width
                            DW  =   20,     //data width
                            RW  =   20,     //result width
                            TW  =   0,      //time width
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

    //search port-a
    input                   search_a_i,
    input   [DW-1:0]        search_a_data_i,
    output                  search_a_exist_o,
    output                  search_a_end_o,
    output  [(RW+DW)-1:0]   search_a_result_o,

    //RAM A interface
    //side A
    // output                        rama_wea_o,
    output  [HW-1:0]              rama_addra_o,
    // output  [(TW+RW+DW+1)*SN-1:0] rama_dina_o,
    input   [(TW+RW+DW+1)*SN-1:0] rama_douta_i,

    //side B
    output                        rama_web_o,
    output  [HW-1:0]              rama_addrb_o,
    output  [(TW+RW+DW+1)*SN-1:0] rama_dinb_o,
    input   [(TW+RW+DW+1)*SN-1:0] rama_doutb_i,

    //RAM B interface
    //side A
    // output                        ramb_wea_o,
    output  [HW-1:0]              ramb_addra_o,
    // output  [(TW+RW+DW+1)*SN-1:0] ramb_dina_o,
    input   [(TW+RW+DW+1)*SN-1:0] ramb_douta_i,

    //side B
    output                        ramb_web_o,
    output  [HW-1:0]              ramb_addrb_o,
    output  [(TW+RW+DW+1)*SN-1:0] ramb_dinb_o,
    input   [(TW+RW+DW+1)*SN-1:0] ramb_doutb_i
    );

    //------------Declare Signals----------------
    //register
    reg                     insert_r;
    reg                     insert_rr;

    reg                     search_a_r;
    reg                     search_a_rr;

    //result register
    reg     [RW-1:0]        result_r;
    reg     [RW-1:0]        result_rr;

    //hash calculate
    wire                    hash_a_valid;
    wire    [DW-1:0]        hash_a_data;
    reg     [DW-1:0]        hash_a_data_r;
    reg     [DW-1:0]        hash_a_data_rr;

    wire                    hasha_a_result_valid;
    wire    [HW-1:0]        hasha_a_result;
    wire                    hashb_a_result_valid;
    wire    [HW-1:0]        hashb_a_result;

    wire                    hash_b_valid;
    wire    [DW-1:0]        hash_b_data;
    reg     [DW-1:0]        hash_b_data_r;
    reg     [DW-1:0]        hash_b_data_rr;

    wire                    hasha_b_result_valid;
    wire    [HW-1:0]        hasha_b_result;
    reg     [HW-1:0]        hasha_b_result_r;
    wire                    hashb_b_result_valid;
    wire    [HW-1:0]        hashb_b_result;
    reg     [HW-1:0]        hashb_b_result_r;

    //search hash table
    wire    [HW-1:0]        rama_rd_addra;
    wire    [HW-1:0]        rama_rd_addrb;
    reg                     rama_rd_dataa_valid;
    reg                     rama_rd_datab_valid;

    wire    [HW-1:0]        ramb_rd_addra;
    wire    [HW-1:0]        ramb_rd_addrb;
    reg                     ramb_rd_dataa_valid;
    reg                     ramb_rd_datab_valid;

    wire    [SN-1:0]        rama_blank_slot;
    wire    [SN-1:0]        rama_min_blank_slot;
    reg     [SN-1:0]        rama_rep_blank_slot;

    wire    [SN-1:0]        ramb_blank_slot;
    wire    [SN-1:0]        ramb_min_blank_slot;
    reg     [SN-1:0]        ramb_rep_blank_slot;

    wire    [SN-1:0]        rama_exist_a_slot;
    wire    [RW-1:0]        rama_search_a_result;
    wire                    rama_exist_a;

    wire    [SN-1:0]        ramb_exist_a_slot;
    wire    [RW-1:0]        ramb_search_a_result;
    wire                    ramb_exist_a;


    //random counter
    reg     [2:0]           cnt; 

    //bypass
    reg     [RW-1:0]        bypass_a_result_r;
    reg     [RW-1:0]        bypass_a_result_rr;
    reg                     bypass_a_exist_r;
    reg                     bypass_a_exist_rr;

    //insert or delete
    reg                     select_ram;

    wire                       rama_wr;
    wire    [HW-1:0]           rama_wr_addr;
    wire    [(RW+DW+1)*SN-1:0] rama_wr_data_insert;
    wire    [(RW+DW+1)*SN-1:0] rama_wr_data;

    wire                       ramb_wr;
    wire    [HW-1:0]           ramb_wr_addr;
    wire    [(RW+DW+1)*SN-1:0] ramb_wr_data_insert;
    wire    [(RW+DW+1)*SN-1:0] ramb_wr_data;

    //---------------Processing------------------
    //register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            insert_r        <=  1'b0;
            insert_rr       <=  1'b0;
            search_a_r      <=  1'b0;
            search_a_rr     <=  1'b0;
        end
        else begin
            insert_r        <=  insert_i;
            insert_rr       <=  insert_r;
            search_a_r      <=  search_a_i;
            search_a_rr     <=  search_a_r;
        end
    end

    //random counter
    always @(negedge rst_n or posedge clk)
    begin
        if (!rst_n)
        begin
            cnt <= 3'b0;
        end
        else if (hash_b_valid)
        begin
            cnt <= cnt + 1'b1;
        end
        else
        begin
            cnt <= cnt;
        end
    end

    //bypass
    always @(negedge rst_n or posedge clk)
    begin
        if(!rst_n)
        begin
            bypass_a_result_r <= {DW{1'b0}};
            bypass_a_result_rr <= {DW{1'b0}};
            bypass_a_exist_r <= 1'b0;
            bypass_a_exist_rr <= 1'b0;
        end
        else
        begin
            bypass_a_result_r  <=   (search_a_data_i == hash_b_data) ? insert_data_i[(RW+DW)-1:DW]:
                                    (search_a_data_i == hash_b_data_r) ? result_r                 :
                                    (search_a_data_i == hash_b_data_rr) ? result_rr : {DW{1'b0}};
            bypass_a_result_rr <= bypass_a_result_r;
            bypass_a_exist_r   <= ( (search_a_data_i == hash_b_data) | 
                                    (search_a_data_i == hash_b_data_r) | 
                                    (search_a_data_i == hash_b_data_rr)) ? 1'b1 : 1'b0;
            bypass_a_exist_rr  <= bypass_a_exist_r;
        end
    end

    //step 0: hash calculate
    //for search_a
    assign  hash_a_valid    =   search_a_i;
    assign  hash_a_data     =   search_a_i ? search_a_data_i : {DW{1'h0}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            result_r   <=  {RW{1'b0}};
            result_rr  <=  {RW{1'b0}};
        end
        else begin
            result_r   <=  insert_data_i[(RW+DW)-1:DW];
            result_rr  <=  result_r;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            hash_a_data_r   <=  {DW{1'b0}};
            hash_a_data_rr  <=  {DW{1'b0}};
        end
        else begin
            hash_a_data_r   <=  hash_a_data;
            hash_a_data_rr  <=  hash_a_data_r;
        end
    end

    CRC32_D20 #(
        .HW      (HW),
        .HIGH    (0),
        .BANK_ID (BANK_ID)
    ) U0_CRC32_D32(
        .clk                (clk),
        .rst_n              (rst_n),

        .calc_d_i           (hash_a_data),
        .calc_en_i          (hash_a_valid),

        .crc32_o            (hasha_a_result),
        .crc32_valid_o      (hasha_a_result_valid)
    );

    CRC32_D20 #(
        .HW      (HW),
        .HIGH    (1),
        .BANK_ID (BANK_ID)
    ) U1_CRC32_D32(
        .clk                (clk),
        .rst_n              (rst_n),

        .calc_d_i           (hash_a_data),
        .calc_en_i          (hash_a_valid),

        .crc32_o            (hashb_a_result),
        .crc32_valid_o      (hashb_a_result_valid)
    );

    //for insert
    assign  hash_b_valid    =   insert_i;
    assign  hash_b_data     =   insert_i ? insert_data_i[DW-1:0] : {DW{1'h0}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            hash_b_data_r   <=  {DW{1'b0}};
            hash_b_data_rr  <=  {DW{1'b0}};
        end
        else begin
            hash_b_data_r   <=  hash_b_data;
            hash_b_data_rr  <=  hash_b_data_r;
        end
    end

    CRC32_D20 #(
        .HW      (HW),
        .HIGH    (0),
        .BANK_ID (BANK_ID)
    ) U2_CRC32_D32(
        .clk                (clk),
        .rst_n              (rst_n),

        .calc_d_i           (hash_b_data),
        .calc_en_i          (hash_b_valid),

        .crc32_o            (hasha_b_result),
        .crc32_valid_o      (hasha_b_result_valid)
    );

    CRC32_D20 #(
        .HW      (HW),
        .HIGH    (1),
        .BANK_ID (BANK_ID)
    ) U3_CRC32_D32(
        .clk                (clk),
        .rst_n              (rst_n),

        .calc_d_i           (hash_b_data),
        .calc_en_i          (hash_b_valid),

        .crc32_o            (hashb_b_result),
        .crc32_valid_o      (hashb_b_result_valid)
    );

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hasha_b_result_r    <=  {HW{1'b0}};
            hashb_b_result_r    <=  {HW{1'b0}};
        end
        else begin
            hasha_b_result_r    <=  hasha_b_result;
            hashb_b_result_r    <=  hashb_b_result;
        end
    end

    //step 1: search hash table
    assign  rama_rd_addra       =   hasha_a_result;
    assign  rama_rd_addrb       =   hasha_b_result;

    assign  ramb_rd_addra       =   hashb_a_result;
    assign  ramb_rd_addrb       =   hashb_b_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset
            rama_rd_dataa_valid <=  1'b0;
            rama_rd_datab_valid <=  1'b0;

            ramb_rd_dataa_valid <=  1'b0;
            ramb_rd_datab_valid <=  1'b0;
        end
        else begin
            rama_rd_dataa_valid <=  hasha_a_result_valid;
            rama_rd_datab_valid <=  hasha_b_result_valid;

            ramb_rd_dataa_valid <=  hashb_a_result_valid;
            ramb_rd_datab_valid <=  hashb_b_result_valid;
        end
    end

    //insert: confirm blank slot
    generate
        genvar i;
        for (i=0;i<SN;i=i+1) begin:confirm_blank_slot
            assign  rama_blank_slot[i]  =   rama_rd_datab_valid & (~rama_doutb_i[(TW+RW+DW+1)*(i+1)-(TW+RW)-1]);
            assign  ramb_blank_slot[i]  =   ramb_rd_datab_valid & (~ramb_doutb_i[(TW+RW+DW+1)*(i+1)-(TW+RW)-1]);
        end
    endgenerate

    assign  rama_min_blank_slot = (rama_blank_slot & ~(rama_blank_slot - 1));

    assign  ramb_min_blank_slot = (ramb_blank_slot & ~(ramb_blank_slot - 1));

    //delete: confirm exist slot
    generate
        genvar j;
        for (j=0;j<SN;j=j+1) begin:confirm_exist_slot
            assign  rama_exist_a_slot[j]    =   rama_rd_dataa_valid & (rama_douta_i[(TW+RW+DW+1)*(j+1)-(TW+RW)-1]) & (hash_a_data_rr == rama_douta_i[(TW+RW+DW+1)*(j+1)-(TW+RW)-2:(TW+RW+DW+1)*j]);

            assign  ramb_exist_a_slot[j]    =   ramb_rd_dataa_valid & (ramb_douta_i[(TW+RW+DW+1)*(j+1)-(TW+RW)-1]) & (hash_a_data_rr == ramb_douta_i[(TW+RW+DW+1)*(j+1)-(TW+RW)-2:(TW+RW+DW+1)*j]);
        end
    endgenerate

    assign  rama_exist_a    =   |rama_exist_a_slot;

    assign  ramb_exist_a    =   |ramb_exist_a_slot;

    generate
        genvar i0;
        wire [RW-1:0] rama_search_a_slot_result [0:SN-1];
        wire [RW-1:0] ramb_search_a_slot_result [0:SN-1];
        for (i0=0; i0<SN; i0=i0+1) begin : search_a_result
            if (i0 == 0) begin
                assign rama_search_a_slot_result[i0] = {RW{rama_exist_a_slot[i0]}} & rama_douta_i[(TW+RW+DW+1)*(i0+1)-TW-1 -: RW];
                assign ramb_search_a_slot_result[i0] = {RW{ramb_exist_a_slot[i0]}} & ramb_douta_i[(TW+RW+DW+1)*(i0+1)-TW-1 -: RW];
            end else begin
                assign rama_search_a_slot_result[i0] = rama_search_a_slot_result[i0-1] | {RW{rama_exist_a_slot[i0]}} & rama_douta_i[(TW+RW+DW+1)*(i0+1)-TW-1 -: RW];
                assign ramb_search_a_slot_result[i0] = ramb_search_a_slot_result[i0-1] | {RW{ramb_exist_a_slot[i0]}} & ramb_douta_i[(TW+RW+DW+1)*(i0+1)-TW-1 -: RW];
            end
        end

        assign rama_search_a_result = rama_search_a_slot_result[SN-1];
        assign ramb_search_a_result = ramb_search_a_slot_result[SN-1];
    endgenerate

    //step 2: insert or delete
    always @ (*) begin
        rama_rep_blank_slot = {SN{1'b0}};
        ramb_rep_blank_slot = {SN{1'b0}};
        case({{|rama_min_blank_slot},{|ramb_min_blank_slot}})
            2'b00:
            begin
                select_ram          =  cnt[0];
                rama_rep_blank_slot =  cnt[0] ? (1 << (cnt[2:1])) : rama_min_blank_slot;
                ramb_rep_blank_slot = !cnt[0] ? (1 << (cnt[2:1])) : ramb_min_blank_slot;
            end
            2'b01:select_ram    =  1'b0;
            2'b10:select_ram    =  1'b1;
            2'b11:select_ram    =  rama_min_blank_slot < ramb_min_blank_slot;  //0:ramb;1:rama
            default:select_ram  =  1'b0;
        endcase
    end

    assign  rama_wr         =   (insert_rr & (({{|rama_min_blank_slot},{|ramb_min_blank_slot}}==2'b00) ? (|rama_rep_blank_slot) : (|rama_min_blank_slot)) & select_ram);
    assign  rama_wr_addr    =   hasha_b_result_r;

    assign  ramb_wr         =   (insert_rr & (({{|rama_min_blank_slot},{|ramb_min_blank_slot}}==2'b00) ? (|ramb_rep_blank_slot) : (|ramb_min_blank_slot)) & (~select_ram));
    assign  ramb_wr_addr    =   hashb_b_result_r;

    generate
        genvar k;
        for (k=0;k<SN;k=k+1) begin:gen_ram_wr_data
            assign  rama_wr_data_insert[(TW+RW+DW+1)*(k+1)-1:(TW+RW+DW+1)*k]    =   insert_rr && ((({{|rama_min_blank_slot},{|ramb_min_blank_slot}}==2'b00) ? rama_rep_blank_slot[k] : rama_min_blank_slot[k]) &   select_ram) ?{result_rr,1'b1,hash_b_data_rr}:rama_doutb_i[(TW+RW+DW+1)*(k+1)-1:(TW+RW+DW+1)*k];

            assign  ramb_wr_data_insert[(TW+RW+DW+1)*(k+1)-1:(TW+RW+DW+1)*k]    =   insert_rr && ((({{|rama_min_blank_slot},{|ramb_min_blank_slot}}==2'b00) ? ramb_rep_blank_slot[k] : ramb_min_blank_slot[k]) & (~select_ram))?{result_rr,1'b1,hash_b_data_rr}:ramb_doutb_i[(TW+RW+DW+1)*(k+1)-1:(TW+RW+DW+1)*k];
        end
    endgenerate

    assign  rama_wr_data    =   rama_wr_data_insert;
    assign  ramb_wr_data    =   ramb_wr_data_insert;

    //------------Output Signals-----------------
    //bypass

    assign  insert_end_o        =   insert_i;

    //search / bypass
    assign  search_a_exist_o    =   search_a_rr ? (
                                    bypass_a_exist_rr ? bypass_a_exist_rr : (
                                    (rama_exist_a | ramb_exist_a) ? 1'b1 : (
                                        ((hash_a_data_rr == insert_data_i[(DW)-1:0]) | (hash_a_data_rr == hash_b_data_r)) ? 1'b1 : 1'b0
                                    ))) : 0;
    assign  search_a_end_o      =   search_a_rr;
    assign  search_a_result_o   =   search_a_rr ? (
                                    bypass_a_exist_rr ? {hash_a_data_rr,bypass_a_result_rr} : (
                                    (rama_exist_a | ramb_exist_a) ? 
                                    (rama_exist_a ? {hash_a_data_rr,rama_search_a_result} : {hash_a_data_rr,ramb_search_a_result}) : (
                                        (hash_a_data_rr == hash_b_data_r) ? {hash_a_data_rr,result_r} : 
                                            ((hash_a_data_rr == hash_b_data) ? {hash_a_data_rr,insert_data_i[(RW+DW)-1:DW]} : {hash_a_data_rr, {RW{1'b0}}})
                                    ))) : 0;
    //RAM A
    // assign  rama_wea_o          =   1'b0;
    assign  rama_addra_o        =   rama_rd_addra;
    // assign  rama_dina_o         =   {((DW+1)*SN){1'b0}};

    assign  rama_web_o          =   rama_wr;
    assign  rama_addrb_o        =   rama_wr?rama_wr_addr:rama_rd_addrb;
    assign  rama_dinb_o         =   rama_wr?rama_wr_data:{((TW+RW+DW+1)*SN){1'b0}};

    //RAM B
    // assign  ramb_wea_o          =   1'b0;
    assign  ramb_addra_o        =   ramb_rd_addra;
    // assign  ramb_dina_o         =   {((DW+1)*SN){1'b0}};

    assign  ramb_web_o          =   ramb_wr;
    assign  ramb_addrb_o        =   ramb_wr?ramb_wr_addr:ramb_rd_addrb;
    assign  ramb_dinb_o         =   ramb_wr?ramb_wr_data:{((TW+RW+DW+1)*SN){1'b0}};

    //------------Debug Signals------------------
endmodule
