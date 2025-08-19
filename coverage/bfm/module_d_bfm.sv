`ifndef MODULE_D_BFM_SV
`define MODULE_D_BFM_SV

import c_module_pkg::*;

class module_d_bfm;
    
    // 接口信号
    virtual interface c2d_if vif;
    
    // 接收到的报文队列
    packet_transaction received_pkts[$];
    
    // 配置参数
    bit backpressure_enable;
    int backpressure_rate;  // 0-100，表示不ready的概率百分比
    
    // 统计信息
    int total_received;
    realtime start_time;
    realtime end_time;
    
    function new(virtual interface c2d_if vif);
        this.vif = vif;
        total_received = 0;
        backpressure_enable = 1;
        backpressure_rate = 50;

    endfunction
    
    
    // 接收报文
    task receive_packets();
        forever begin
            @(posedge vif.clk);
            
            // 生成ready信号（可能有背压）
            if (backpressure_enable && $urandom_range(1, 100) <= backpressure_rate) begin
                vif.d2c_pkt_rdy <= 1'b0;
            end else begin
                vif.d2c_pkt_rdy <= 1'b1;
            end
            
            // 接收报文
            if (vif.c2d_pkt_vld && vif.d2c_pkt_rdy) begin
                packet_transaction pkt = new();
                pkt.odr_id = vif.c2d_pkt_odr_id;
                pkt.so = vif.c2d_pkt_so;
                pkt.lkp_rslt = vif.c2d_pkt_lkp_rslt;
                pkt.payload = vif.c2d_pkt_payload;
                pkt.timestamp_out = $realtime;
                
                received_pkts.push_back(pkt);
                total_received++;
                
                
                if (total_received == 1) begin
                    start_time = $realtime;
                end
                end_time = $realtime;
            end
        end
    endtask
    
    // 运行BFM
    task run();
        // 初始化接口信号
        vif.d2c_pkt_rdy <= 1'b1;
        
        // 等待复位完成
        wait(vif.rst_n == 1'b1);
        repeat(10) @(posedge vif.clk);
        
        // 开始接收报文
        receive_packets();
    endtask
    
endclass

`endif 