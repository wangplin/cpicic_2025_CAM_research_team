`timescale 1ns/1ps

import c_module_pkg::*;

`include "interfaces.sv"
`include "test_env.sv"

module top_tb;
    
    // 时钟和复位信号
    logic clk;
    logic rst_n;
    
    // 生成时钟（1GHz = 1ns周期）
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // 生成复位信号
    initial begin
        rst_n = 0;
        repeat(20) @(posedge clk);
        rst_n = 1;
    end
    
    // 接口实例
    b2c_if b2c_if_inst(clk, rst_n);
    a2c_if a2c_if_inst(clk, rst_n);
    c2d_if c2d_if_inst(clk, rst_n);
    
    // DUT实例
    top_c_module dut (
        .clk                (clk),
        .rst_n              (rst_n),  
        
        // B到C接口
        .b2c_pkt_vld        (b2c_if_inst.b2c_pkt_vld),
        .b2c_pkt_lkp_en     (b2c_if_inst.b2c_pkt_lkp_en),
        .b2c_pkt_lkp_info   (b2c_if_inst.b2c_pkt_lkp_info),
        .b2c_pkt_odr_id     (b2c_if_inst.b2c_pkt_odr_id),
        .b2c_pkt_so         (b2c_if_inst.b2c_pkt_so),
        .b2c_pkt_payload    (b2c_if_inst.b2c_pkt_payload),
        .c2b_pkt_rdy        (b2c_if_inst.c2b_pkt_rdy),
        
        // A到C接口
        .c2a_lkp_vld        (a2c_if_inst.c2a_lkp_vld),
        .c2a_lkp_info       (a2c_if_inst.c2a_lkp_info),
        .c2a_lkp_req_id     (a2c_if_inst.c2a_lkp_req_id),
        .a2c_lkp_rdy        (a2c_if_inst.a2c_lkp_rdy),
        .a2c_lkp_rsp_vld    (a2c_if_inst.a2c_lkp_rsp_vld),
        .a2c_lkp_rsp_id     (a2c_if_inst.a2c_lkp_rsp_id),
        .a2c_lkp_rslt       (a2c_if_inst.a2c_lkp_rslt),
        
        // C到D接口
        .c2d_pkt_vld        (c2d_if_inst.c2d_pkt_vld),
        .c2d_pkt_lkp_rslt   (c2d_if_inst.c2d_pkt_lkp_rslt),
        .c2d_pkt_odr_id     (c2d_if_inst.c2d_pkt_odr_id),
        .c2d_pkt_so         (c2d_if_inst.c2d_pkt_so),
        .c2d_pkt_payload    (c2d_if_inst.c2d_pkt_payload),
        .d2c_pkt_rdy        (c2d_if_inst.d2c_pkt_rdy)
    );
    
    // 测试环境实例
    test_env env;
    
    // 测试场景选择
    string scenario_str;
    scenario_e test_scenario;
    int num_packets;
    int unsigned seed;
    
    initial begin
        if ($value$plusargs("SCENARIO=%s", scenario_str)) begin
            case (scenario_str)
                "SCENARIO_1": test_scenario = SCENARIO_1;
                "SCENARIO_2": test_scenario = SCENARIO_2;
                "SCENARIO_3": test_scenario = SCENARIO_3;
                default: begin
                    test_scenario = SCENARIO_1;
                    $warning("Unknown scenario '%s', using SCENARIO_1", scenario_str);
                end
            endcase
        end else begin
            test_scenario = SCENARIO_1;  // 默认场景1
        end
        
        if ($value$plusargs("PACKETS=%d", num_packets)) begin
            $display("Number of packets: %d", num_packets);
        end else begin
            num_packets = 1000;  // 默认1000个报文
        end
        
        // 获取随机种子
        if ($value$plusargs("SEED=%d", seed)) begin
            $display("Using random seed: %d", seed);
        end else begin
            seed = 0;  // 0表示不使用固定种子
        end
        
        // 创建测试环境
        env = new(b2c_if_inst, a2c_if_inst, c2d_if_inst);
        
        // 配置测试
        env.configure(test_scenario, num_packets, seed);
        
        // 等待复位完成
        wait(rst_n == 1);
        repeat(10) @(posedge clk);
        
        // 运行测试
        env.run();
        
        // 测试完成
        $display("\n=== Test Completed ===\n");
        $finish;
    end
    
    // 波形转储
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, top_tb);
    end
    
    // 超时保护
    initial begin
        #10ms;
        $error("Test timeout!");
        $finish;
    end
    
endmodule 