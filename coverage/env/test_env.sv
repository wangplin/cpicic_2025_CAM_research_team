`ifndef TEST_ENV_SV
`define TEST_ENV_SV

import c_module_pkg::*;

`include "module_b_bfm.sv"
`include "module_a_bfm.sv"
`include "module_d_bfm.sv"
`include "scoreboard.sv"

class test_env;
    
    // BFMs
    module_b_bfm b_bfm;
    module_a_bfm a_bfm;
    module_d_bfm d_bfm;
    
    // Scoreboard
    scoreboard sb;
    
    // 接口
    virtual interface b2c_if b2c_vif;
    virtual interface a2c_if a2c_vif;
    virtual interface c2d_if c2d_vif;
    
    // 配置参数
    scenario_e test_scenario;
    int num_packets;
    
    function new(
        virtual interface b2c_if b2c_vif,
        virtual interface a2c_if a2c_vif,
        virtual interface c2d_if c2d_vif
    );
        this.b2c_vif = b2c_vif;
        this.a2c_vif = a2c_vif;
        this.c2d_vif = c2d_vif;
        
        // 创建BFMs
        b_bfm = new(b2c_vif);
        a_bfm = new(a2c_vif);
        d_bfm = new(c2d_vif);
        
        // 创建Scoreboard
        sb = new();
    endfunction
    
    // 配置测试场景
    function void configure(scenario_e scenario, int packets, int unsigned seed = 0);
        test_scenario = scenario;
        num_packets = packets;
        
        b_bfm.current_scenario = scenario;
        a_bfm.current_scenario = scenario;
        
        // 如果提供了种子，设置BFM的种子
        if (seed != 0) begin
            b_bfm.set_seed(seed);
        end
        
        $display("=== Test Configuration ===");
        $display("Scenario: %s", scenario.name());
        $display("Number of packets: %0d", packets);
        if (seed != 0) begin
            $display("Random seed: %0d", seed);
        end
        $display("=========================");
    endfunction
    
    // 监控B到C的接口
    task monitor_b2c();
        forever begin
            @(posedge b2c_vif.clk);
            if (b2c_vif.b2c_pkt_vld && b2c_vif.c2b_pkt_rdy) begin
                packet_transaction pkt = new();
                pkt.lkp_en = b2c_vif.b2c_pkt_lkp_en;
                pkt.lkp_info = b2c_vif.b2c_pkt_lkp_info;
                pkt.odr_id = b2c_vif.b2c_pkt_odr_id;
                pkt.so = b2c_vif.b2c_pkt_so;
                pkt.payload = b2c_vif.b2c_pkt_payload;
                pkt.timestamp_in = $realtime;
                pkt.pkt_id = sb.total_sent;
                
                sb.add_sent_packet(pkt);
            end
        end
    endtask
    
    // 监控A到C的查表接口
    task monitor_a2c();
        forever begin
            @(posedge a2c_vif.clk);
            
            // 监控查表请求
            if (a2c_vif.c2a_lkp_vld && a2c_vif.a2c_lkp_rdy) begin
                lookup_request req = new();
                req.lkp_info = a2c_vif.c2a_lkp_info;
                req.req_id = a2c_vif.c2a_lkp_req_id;
                req.req_time = $realtime;
                req.pkt_id = sb.total_lkp_requests;
                
                sb.add_lookup_request(req);
            end
            
            // 监控查表响应
            if (a2c_vif.a2c_lkp_rsp_vld) begin
                lookup_response rsp = new();
                rsp.rsp_id = a2c_vif.a2c_lkp_rsp_id;
                rsp.lkp_rslt = a2c_vif.a2c_lkp_rslt;
                rsp.rsp_time = $realtime;
                
                sb.add_lookup_response(rsp);
            end
        end
    endtask
    
    // 监控C到D的接口
    task monitor_c2d();
        forever begin
            @(posedge c2d_vif.clk);
            if (c2d_vif.c2d_pkt_vld && c2d_vif.d2c_pkt_rdy) begin
                packet_transaction pkt = new();
                pkt.odr_id = c2d_vif.c2d_pkt_odr_id;
                pkt.so = c2d_vif.c2d_pkt_so;
                pkt.lkp_rslt = c2d_vif.c2d_pkt_lkp_rslt;
                pkt.payload = c2d_vif.c2d_pkt_payload;
                pkt.timestamp_out = $realtime;
                
                sb.add_received_packet(pkt);
            end
        end
    endtask
    
    // 运行测试
    task run();
        // 生成报文
        b_bfm.generate_packets(num_packets);
        
        // 启动所有监控任务
        fork
            monitor_b2c();
            monitor_a2c();
            monitor_c2d();
        join_none
        
        // 启动BFMs
        fork
            b_bfm.run();
            a_bfm.run();
            d_bfm.run();
        join_none
        
        // 等待所有报文处理完成
        wait(sb.total_received == num_packets);
        
        // 额外等待一段时间确保所有事务完成
        #100ns;
        
    endtask
    
endclass

`endif 