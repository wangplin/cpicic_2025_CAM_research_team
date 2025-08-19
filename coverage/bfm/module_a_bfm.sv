`ifndef MODULE_A_BFM_SV
`define MODULE_A_BFM_SV

import c_module_pkg::*;

class module_a_bfm;
    
    // 接口信号
    virtual interface a2c_if vif;
    
    // 配置参数
    scenario_e current_scenario;
    bit backpressure_enable;
    int backpressure_rate;
    
    // 查表延时配置
    int min_delay_10_25 = 10;
    int max_delay_10_25 = 25;
    int min_delay_25_100 = 25;
    int max_delay_25_100 = 100;
    int min_delay_100_200 = 100;
    int max_delay_100_200 = 200;
    int fixed_delay = 200;  // 场景3固定延时
    
    // 查表结果缓存（相同lkp_info返回相同结果）
    bit [INFO_LENGTH-1:0] lkp_cache[bit [INFO_LENGTH-1:0]];
    
    // 统计信息
    int total_requests;
    int total_responses;
    int outstanding_requests;
    int max_outstanding;
    
    // 添加响应队列和互斥信号
    bit [INFO_LENGTH-1:0] resp_queue_lkp_info[$];
    bit [REQ_WIDTH-1:0] resp_queue_req_id[$];
    bit [INFO_LENGTH-1:0] resp_queue_rslt[$];
    int resp_queue_delay[$];
    
    function new(virtual interface a2c_if vif);
        this.vif = vif;
        total_requests = 0;
        total_responses = 0;
        outstanding_requests = 0;
        max_outstanding = 0;

        backpressure_enable = 1;
        backpressure_rate = 30;
    endfunction
    
    // 生成查表延时
    function int generate_delay();
        int delay;
        int rand_val;  
        
        case (current_scenario)
            SCENARIO_1: delay = 0;  // 场景1不需要查表
            
            SCENARIO_2: begin
                // 随机延时分布
                rand_val = $urandom_range(1, 100);
                if (rand_val <= 90) begin
                    // 90%: 10-25ns
                    delay = $urandom_range(min_delay_10_25, max_delay_10_25);
                end else if (rand_val <= 97) begin
                    // 7%: 25-100ns
                    delay = $urandom_range(min_delay_25_100, max_delay_25_100);
                end else begin
                    // 3%: 100-200ns
                    delay = $urandom_range(min_delay_100_200, max_delay_100_200);
                end
            end
            
            SCENARIO_3: delay = fixed_delay;  // 固定200ns
        endcase
        
        return delay;
    endfunction
    
    // 生成查表结果
    function bit [INFO_LENGTH-1:0] generate_lkp_rslt(bit [INFO_LENGTH-1:0] lkp_info);
        // 检查缓存
        if (lkp_cache.exists(lkp_info)) begin
            return lkp_cache[lkp_info];
        end else begin
            // 生成新的查表结果
            bit [INFO_LENGTH-1:0] rslt = $urandom();
            lkp_cache[lkp_info] = rslt;
            return rslt;
        end
    endfunction
    
    // 处理单个请求的任务
    task process_single_request(bit [INFO_LENGTH-1:0] lkp_info, bit [REQ_WIDTH-1:0] req_id);
        int delay;
        bit [INFO_LENGTH-1:0] lkp_rslt;
        
        // 生成延时
        delay = generate_delay();
        
        // 生成查表结果
        lkp_rslt = generate_lkp_rslt(lkp_info);
        
        // 等待延时
        #((delay - 1) * 1ns);
        
        // 将响应信息加入队列
        resp_queue_lkp_info.push_back(lkp_info);
        resp_queue_req_id.push_back(req_id);
        resp_queue_rslt.push_back(lkp_rslt);
        resp_queue_delay.push_back(delay);
    endtask
    
    // 接收查表请求
    task receive_requests();
        forever begin
            @(posedge vif.clk);
            
            // 生成ready信号（可能有背压）
            if (backpressure_enable && $urandom_range(1, 100) <= backpressure_rate) begin
                vif.a2c_lkp_rdy <= 1'b0;
            end else begin
                vif.a2c_lkp_rdy <= 1'b1;
            end
            
            if (vif.c2a_lkp_vld && vif.a2c_lkp_rdy) begin
                total_requests++;
                outstanding_requests++;
                
                if (outstanding_requests > max_outstanding) begin
                    max_outstanding = outstanding_requests;
                end
                
                
                // 为每个请求启动一个独立的处理任务
                fork
                    process_single_request(vif.c2a_lkp_info, vif.c2a_lkp_req_id);
                join_none
            end
        end
    endtask
    
    // 增加持续输出响应的主循环任务
    task send_response_loop();
        forever begin
            @(posedge vif.clk);
            if (resp_queue_req_id.size() > 0) begin
                vif.a2c_lkp_rsp_vld <= 1'b1;
                vif.a2c_lkp_rsp_id  <= resp_queue_req_id[0];
                vif.a2c_lkp_rslt    <= resp_queue_rslt[0];
                // 统计和显示
                total_responses++;
                outstanding_requests--;
                
                // 出队
                resp_queue_lkp_info.pop_front();
                resp_queue_req_id.pop_front();
                resp_queue_rslt.pop_front();
                resp_queue_delay.pop_front();
            end else begin
                vif.a2c_lkp_rsp_vld <= 1'b0;
            end
        end
    endtask
    
    task run();
        // 初始化接口信号
        vif.a2c_lkp_rdy <= 1'b0;
        vif.a2c_lkp_rsp_vld <= 1'b0;
        vif.a2c_lkp_rsp_id <= '0;
        vif.a2c_lkp_rslt <= '0;
        
        // 等待复位完成
        wait(vif.rst_n == 1'b1);
        repeat(10) @(posedge vif.clk);
        
        // 并行运行接收和响应主循环
        fork
            receive_requests();
            send_response_loop();
        join_none
    endtask
    
endclass

`endif 