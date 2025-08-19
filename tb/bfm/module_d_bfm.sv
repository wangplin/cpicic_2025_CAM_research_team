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
    int file_handle_bw;
    
    function new(virtual interface c2d_if vif);
        this.vif = vif;
        total_received = 0;
        backpressure_enable = 0;
        backpressure_rate = 0;

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
                
                
                $display("[%0t] Module D: Received packet #%0d, odr_id=%0d, so=%0b, lkp_rslt=0x%0h", 
                         $realtime, total_received, pkt.odr_id, pkt.so, pkt.lkp_rslt);
                
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
    
    // 显示统计信息
    function void display_statistics();
        real duration_ns;
        real duration_s;
        real bytes_received;
        real bandwidth_gbps;
        real stable_start_time;
        real stable_end_time;
        real stable_duration_ns;
        real stable_duration_s;
        real stable_bytes_received;
        real stable_bandwidth_gbps;
        int stable_packets;
        int i;

        duration_ns = (end_time - start_time + CLK_PERIOD);
        duration_s = duration_ns / 1e9;
        bytes_received = total_received * (DATA_LENGTH / 8);
        bandwidth_gbps = (bytes_received) / (duration_s * 1e9);
        
        // 计算稳定区间的带宽 （起始阶段后3000个周期---结束阶段前1000个周期）
        stable_start_time = start_time + 3000 * CLK_PERIOD;
        stable_end_time = end_time - 1000 * CLK_PERIOD;
        stable_duration_ns = (stable_end_time - stable_start_time + CLK_PERIOD);
        stable_duration_s = stable_duration_ns / 1e9;
        
        // 计算稳定区间内的包数量
        stable_packets = 0;
        for (i = 0; i < received_pkts.size(); i++) begin
            if (received_pkts[i].timestamp_out >= stable_start_time && 
                received_pkts[i].timestamp_out <= stable_end_time) begin
                stable_packets++;
            end
        end
        
        stable_bytes_received = stable_packets * (DATA_LENGTH / 8);
        stable_bandwidth_gbps = (stable_bytes_received) / (stable_duration_s * 1e9);
        
        $display("=== Module D BFM Statistics ===");
        $display("Start time: %0t", start_time);
        $display("End time: %0t", end_time);
        $display("Total packets received: %0d", total_received);
        $display("Duration: %.3f ns (%.6f s)", duration_ns, duration_s);
        $display("Bandwidth: %.2f GB/s", bandwidth_gbps);
        
        $display("\n=== Stable Bandwidth Statistics ===");
        $display("Stable start time: %0t", stable_start_time);
        $display("Stable end time: %0t", stable_end_time);
        $display("Stable packets: %0d", stable_packets);
        $display("Stable duration: %.3f ns (%.6f s)", stable_duration_ns, stable_duration_s);
        $display("Stable bandwidth: %.2f GB/s", stable_bandwidth_gbps);
        
        $display("===============================");



    endfunction
    
endclass

`endif 