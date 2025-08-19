`ifndef C_MODULE_PKG_SV
`define C_MODULE_PKG_SV

package c_module_pkg;

    // 参数定义
    parameter INFO_LENGTH = 20;
    parameter ORDER_ID = 3;
    parameter DATA_LENGTH = 512;
    parameter REQ_WIDTH = 10;
    
    // 时钟周期 (1GHz = 1ns)
    parameter CLK_PERIOD = 1.0;
    
    // 性能场景定义
    typedef enum {
        SCENARIO_1,  // 无查表无保序
        SCENARIO_2,  // 全查表，混合保序
        SCENARIO_3   // 混合查表，高保序
    } scenario_e;
    
    // 查表延时分布
    typedef enum {
        DELAY_10_25NS,   // 10-25ns (90%)
        DELAY_25_100NS,  // 25-100ns (7%)
        DELAY_100_200NS  // 100-200ns (3%)
    } delay_range_e;
    
    // 报文事务类
    class packet_transaction;
        rand bit                    lkp_en;
        rand bit [INFO_LENGTH-1:0]  lkp_info;
        rand bit [ORDER_ID-1:0]     odr_id;
        rand bit                    so;
        rand bit [DATA_LENGTH-1:0]  payload;
        
        // 用于跟踪的字段
        int                         pkt_id;
        realtime                    timestamp_in;
        realtime                    timestamp_out;
        bit [INFO_LENGTH-1:0]       lkp_rslt;
        bit                         lkp_done;
        
        // 约束
        constraint order_so_c {
            // Order_id为0时，SO固定为0
            (odr_id == 0) -> (so == 0);
        }
        
        function new();
            lkp_done = 0;
        endfunction
        
        function void display(string prefix = "");
            $display("%s[%0t] Packet #%0d: lkp_en=%0b, lkp_info=0x%0h, odr_id=%0d, so=%0b", 
                     prefix, $time, pkt_id, lkp_en, lkp_info, odr_id, so);
        endfunction
        
        function packet_transaction copy();
            packet_transaction pkt = new();
            pkt.lkp_en = this.lkp_en;
            pkt.lkp_info = this.lkp_info;
            pkt.odr_id = this.odr_id;
            pkt.so = this.so;
            pkt.payload = this.payload;
            pkt.pkt_id = this.pkt_id;
            pkt.timestamp_in = this.timestamp_in;
            pkt.timestamp_out = this.timestamp_out;
            pkt.lkp_rslt = this.lkp_rslt;
            pkt.lkp_done = this.lkp_done;
            return pkt;
        endfunction
    endclass
    
    // 查表请求事务类
    class lookup_request;
        bit [INFO_LENGTH-1:0]  lkp_info;
        bit [REQ_WIDTH-1:0]    req_id;
        int                    pkt_id;  // 关联到原始报文
        realtime               req_time;
        
        function new();
        endfunction
    endclass
    
    // 查表响应事务类
    class lookup_response;
        bit [REQ_WIDTH-1:0]    rsp_id;
        bit [INFO_LENGTH-1:0]  lkp_rslt;
        realtime               rsp_time;
        
        function new();
        endfunction
    endclass

endpackage

`endif 