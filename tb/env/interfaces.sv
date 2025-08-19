`ifndef INTERFACES_SV
`define INTERFACES_SV

import c_module_pkg::*;

// B到C的接口
interface b2c_if(input logic clk, input logic rst_n);
    logic                       b2c_pkt_vld;
    logic                       b2c_pkt_lkp_en;
    logic [INFO_LENGTH-1:0]     b2c_pkt_lkp_info;
    logic [ORDER_ID-1:0]        b2c_pkt_odr_id;
    logic                       b2c_pkt_so;
    logic [DATA_LENGTH-1:0]     b2c_pkt_payload;
    logic                       c2b_pkt_rdy;
    
    // 时钟块定义
    clocking cb @(posedge clk);
        output b2c_pkt_vld;
        output b2c_pkt_lkp_en;
        output b2c_pkt_lkp_info;
        output b2c_pkt_odr_id;
        output b2c_pkt_so;
        output b2c_pkt_payload;
        input  c2b_pkt_rdy;
    endclocking
    
    modport master (
        clocking cb,
        input clk,
        input rst_n
    );
    
    modport slave (
        input  b2c_pkt_vld,
        input  b2c_pkt_lkp_en,
        input  b2c_pkt_lkp_info,
        input  b2c_pkt_odr_id,
        input  b2c_pkt_so,
        input  b2c_pkt_payload,
        output c2b_pkt_rdy,
        input  clk,
        input  rst_n
    );
endinterface

// A到C的接口
interface a2c_if(input logic clk, input logic rst_n);
    logic                       c2a_lkp_vld;
    logic [INFO_LENGTH-1:0]     c2a_lkp_info;
    logic [REQ_WIDTH-1:0]       c2a_lkp_req_id;
    logic                       a2c_lkp_rdy;
    logic                       a2c_lkp_rsp_vld;
    logic [REQ_WIDTH-1:0]       a2c_lkp_rsp_id;
    logic [INFO_LENGTH-1:0]     a2c_lkp_rslt;
    
    // 时钟块定义
    clocking cb @(posedge clk);
        input  c2a_lkp_vld;
        input  c2a_lkp_info;
        input  c2a_lkp_req_id;
        output a2c_lkp_rdy;
        output a2c_lkp_rsp_vld;
        output a2c_lkp_rsp_id;
        output a2c_lkp_rslt;
    endclocking
    
    modport master (
        clocking cb,
        input clk,
        input rst_n
    );
    
    modport slave (
        output c2a_lkp_vld,
        output c2a_lkp_info,
        output c2a_lkp_req_id,
        input  a2c_lkp_rdy,
        input  a2c_lkp_rsp_vld,
        input  a2c_lkp_rsp_id,
        input  a2c_lkp_rslt,
        input  clk,
        input  rst_n
    );
endinterface

// C到D的接口
interface c2d_if(input logic clk, input logic rst_n);
    logic                       c2d_pkt_vld;
    logic [INFO_LENGTH-1:0]     c2d_pkt_lkp_rslt;
    logic [ORDER_ID-1:0]        c2d_pkt_odr_id;
    logic                       c2d_pkt_so;
    logic [DATA_LENGTH-1:0]     c2d_pkt_payload;
    logic                       d2c_pkt_rdy;
    
    // 时钟块定义
    clocking cb @(posedge clk);
        input  c2d_pkt_vld;
        input  c2d_pkt_lkp_rslt;
        input  c2d_pkt_odr_id;
        input  c2d_pkt_so;
        input  c2d_pkt_payload;
        output d2c_pkt_rdy;
    endclocking
    
    modport master (
        clocking cb,
        input clk,
        input rst_n
    );
    
    modport slave (
        output c2d_pkt_vld,
        output c2d_pkt_lkp_rslt,
        output c2d_pkt_odr_id,
        output c2d_pkt_so,
        output c2d_pkt_payload,
        input  d2c_pkt_rdy,
        input  clk,
        input  rst_n
    );
endinterface

`endif 