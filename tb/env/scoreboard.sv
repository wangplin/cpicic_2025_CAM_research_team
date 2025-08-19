`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

import c_module_pkg::*;

class scoreboard;
    
    // 从模块B发送的报文队列
    packet_transaction sent_pkts[$];
    
    // 从模块D接收的报文队列
    packet_transaction received_pkts[$];

    // 保序检查队列（按order_id分组）
    packet_transaction order_queues[8][$];  // 8个order_id队列
    
    // 临时历史队列（用于保序检查）
    packet_transaction history[$];
    
    // 查表请求和响应的关联
    lookup_request lkp_requests[bit [REQ_WIDTH-1:0]];
    lookup_response lkp_responses[bit [INFO_LENGTH-1:0]];
    
    // 报文ID到查表结果的映射
    bit [INFO_LENGTH-1:0] pkt_lkp_results[int];
    
    // 用于检查缺失数据包的队列
    int all_pkt_ids[$];
    
    // 统计信息
    int total_sent;
    int total_received;
    int order_violations;
    int total_lkp_requests;
    int total_lkp_responses;
    int errors;
    
    // SO=0报文统计
    int so0_total_pkts;
    real so0_max_latency;
    real so0_min_latency;
    real so0_total_latency;
    real so0_latency_bins[10];  // 延迟分布统计

    // SO=1报文统计
    int so1_total_pkts;
    real so1_max_latency;
    real so1_min_latency;
    real so1_total_latency;
    real so1_latency_bins[10];  // 延迟分布统计

    
    // order_id 1-7的延迟统计
    int order_total_pkts[8];  // 每个order_id的总包数
    real order_max_latency[8];  // 每个order_id的最大延迟
    real order_min_latency[8];  // 每个order_id的最小延迟
    real order_total_latency[8];  // 每个order_id的总延迟
    real order_latency_bins[8][10];  // 每个order_id的延迟分布统计
    // int file_handle_2;

    // 带宽统计相关变量
    parameter TIME_WINDOW = 5000;  // 统计窗口大小（单位：ns）
    real last_bandwidth_time;  // 上次带宽统计时间
    int window_packet_count;       // 当前窗口内的包计数
    real bandwidth_history[$];     // 带宽历史记录
    real max_bandwidth;            // 最大带宽
    real min_bandwidth;            // 最小带宽
    real total_bandwidth;          // 总带宽
    int bandwidth_sample_count;    // 带宽采样次数
    
    // 带宽统计bin
    real bandwidth_bins[10];       // 带宽分布统计

    // 反压检测相关变量
    bit former_a2c_lkp_rdy;
    bit former_c2a_lkp_vld;
    bit [INFO_LENGTH-1:0] former_c2a_lkp_info;
    bit [REQ_WIDTH-1:0] former_c2a_lkp_req_id;

    bit former_d2c_pkt_rdy;
    bit former_c2d_pkt_vld;
    bit [ORDER_ID-1:0] former_c2d_pkt_odr_id;
    bit former_c2d_pkt_so;
    bit [INFO_LENGTH-1:0] former_c2d_pkt_lkp_rslt;
    bit [DATA_LENGTH-1:0] former_c2d_pkt_payload;
    
    function new();
        total_sent = 0;
        total_received = 0;
        order_violations = 0;
        total_lkp_requests = 0;
        total_lkp_responses = 0;
        errors = 0;
        
        // 初始化SO=0统计
        so0_total_pkts = 0;
        so0_max_latency = 0;
        so0_min_latency = 1000000;  
        so0_total_latency = 0;
        foreach(so0_latency_bins[i]) so0_latency_bins[i] = 0;

        // 初始化SO=1统计
        so1_total_pkts = 0;
        so1_max_latency = 0;
        so1_min_latency = 1000000;  
        so1_total_latency = 0;
        foreach(so1_latency_bins[i]) so1_latency_bins[i] = 0;
        
        // 初始化order_id 1-7统计
        for (int i = 1; i < 8; i++) begin
            order_total_pkts[i] = 0;
            order_max_latency[i] = 0;
            order_min_latency[i] = 1000000;  
            order_total_latency[i] = 0;
            foreach(order_latency_bins[i][j]) order_latency_bins[i][j] = 0;
        end

        // 初始化带宽统计变量
        last_bandwidth_time = 0;
        window_packet_count = 0;
        max_bandwidth = 0;
        min_bandwidth = 1000000;  
        total_bandwidth = 0;
        bandwidth_sample_count = 0;
        foreach(bandwidth_bins[i]) bandwidth_bins[i] = 0;

    endfunction
    
    // 记录发送的报文
    function void add_sent_packet(packet_transaction pkt);
        // $display("[Scoreboard] Before adding: queue size = %0d", sent_pkts.size());
        sent_pkts.push_back(pkt);        // 直接存储报文
        total_sent++;
        $display("[Scoreboard] Add sent packet: pkt_id=%0d, odr_id=%0d, so=%0b, lkp_en=%0b, lkp_info=0x%0h, payload=0x%0h", 
                 pkt.pkt_id, pkt.odr_id, pkt.so, pkt.lkp_en, pkt.lkp_info, pkt.payload);
    endfunction
    
    // 记录查表请求
    function void add_lookup_request(lookup_request req);
        lkp_requests[req.req_id] = req;
        total_lkp_requests++;
        $display("[Scoreboard] Added lookup request, req_id=%0d, lkp_info=0x%0h", req.req_id, req.lkp_info);
    endfunction
    
    // 记录查表响应
    function void add_lookup_response(lookup_response rsp);
        if (lkp_requests.exists(rsp.rsp_id)) begin
            lookup_request req = lkp_requests[rsp.rsp_id];
            pkt_lkp_results[req.lkp_info] = rsp.lkp_rslt;
            lkp_responses[rsp.lkp_rslt] = rsp;
            total_lkp_responses++;
            $display("[Scoreboard] Added lookup response, rsp_id=%0d, lkp_info=0x%0h, lkp_rslt=0x%0h", 
                     rsp.rsp_id, req.lkp_info, rsp.lkp_rslt);
        end else begin
            $error("[Scoreboard] Received response for non-existent request, rsp_id=%0d", rsp.rsp_id);
            errors++;
        end
    endfunction
    
    // 记录接收的报文
    function void add_received_packet(packet_transaction pkt);
        received_pkts.push_back(pkt);
        total_received++;
        
        // 检查报文
        check_packet(pkt);

        // 检查保序
        check_ordering(pkt);

        // 更新SO=0和SO=1报文统计
        update_so01_statistics(pkt);

        // 更新order_id 1-7的延迟统计
        update_order_statistics(pkt);

        // 更新带宽统计
        update_bandwidth_statistics(pkt);
    endfunction

    function void check_backpressure_a2c(bit a2c_lkp_rdy, bit c2a_lkp_vld, bit [INFO_LENGTH-1:0] c2a_lkp_info, bit [REQ_WIDTH-1:0] c2a_lkp_req_id);
        // 当 a2c_vif.a2c_lkp_rdy 拉低时，c2a_lkp_vld，c2a_lkp_info，c2a_lkp_req_id维持不变
        
        if (former_a2c_lkp_rdy == 1 && a2c_lkp_rdy == 0) begin
            former_c2a_lkp_vld = c2a_lkp_vld;
            former_c2a_lkp_info = c2a_lkp_info;
            former_c2a_lkp_req_id = c2a_lkp_req_id;
        end else if (former_a2c_lkp_rdy == 0 && a2c_lkp_rdy == 0) begin
            if ((former_c2a_lkp_info != c2a_lkp_info) && (former_c2a_lkp_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2a_lkp_info detected on A2C interface!");
                errors++;
            end
            if ((former_c2a_lkp_req_id != c2a_lkp_req_id) && (former_c2a_lkp_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2a_lkp_req_id detected on A2C interface!");
                errors++;
            end
            if ((former_c2a_lkp_vld != c2a_lkp_vld) && (former_c2a_lkp_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2a_lkp_vld detected on A2C interface!");
                errors++;
            end
        end 

        former_a2c_lkp_rdy = a2c_lkp_rdy;

    endfunction

    function void check_backpressure_c2d(bit d2c_pkt_rdy, bit c2d_pkt_vld, bit [ORDER_ID-1:0] c2d_pkt_odr_id, bit c2d_pkt_so, bit [INFO_LENGTH-1:0] c2d_pkt_lkp_rslt, bit [DATA_LENGTH-1:0] c2d_pkt_payload);
        // 当 c2d_vif.d2c_pkt_rdy 拉低时，c2d_pkt_vld，c2d_pkt_odr_id，c2d_pkt_so，c2d_pkt_lkp_rslt，c2d_pkt_payload维持不变 

        if (former_d2c_pkt_rdy == 1 && d2c_pkt_rdy == 0) begin
            former_c2d_pkt_vld = c2d_pkt_vld;
            former_c2d_pkt_odr_id = c2d_pkt_odr_id;
            former_c2d_pkt_so = c2d_pkt_so;
            former_c2d_pkt_lkp_rslt = c2d_pkt_lkp_rslt;
            former_c2d_pkt_payload = c2d_pkt_payload;
        end else if (former_d2c_pkt_rdy == 0 && d2c_pkt_rdy == 0) begin
            if ((former_c2d_pkt_vld != c2d_pkt_vld) && (former_c2d_pkt_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2d_pkt_vld detected on C2D interface!");
                errors++;
            end
            if ((former_c2d_pkt_odr_id != c2d_pkt_odr_id) && (former_c2d_pkt_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2d_pkt_odr_id detected on C2D interface!");
                errors++;
            end
            if ((former_c2d_pkt_so != c2d_pkt_so) && (former_c2d_pkt_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2d_pkt_so detected on C2D interface!");
                errors++;
            end
            if ((former_c2d_pkt_lkp_rslt != c2d_pkt_lkp_rslt) && (former_c2d_pkt_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2d_pkt_lkp_rslt detected on C2D interface!");
                errors++;
            end
            if ((former_c2d_pkt_payload != c2d_pkt_payload) && (former_c2d_pkt_vld == 1)) begin
                $error("[Scoreboard] Backpressure error c2d_pkt_payload detected on C2D interface!");
                errors++;
            end
        end

        former_d2c_pkt_rdy = d2c_pkt_rdy;
    endfunction
    
    // 检查单个报文的正确性
    function void check_packet(packet_transaction pkt);
        // 查找对应的发送报文
        packet_transaction sent_pkt = null;
        foreach (sent_pkts[i]) begin
            // 根据payload查找报文
            if (sent_pkts[i].payload == pkt.payload) begin
                sent_pkt = sent_pkts[i];
                break;
            end
        end

        $display("[%0t] Module D: Received packet pkt_id=%0d", 
            $realtime, sent_pkt.pkt_id);

        if (sent_pkt == null) begin
            $error("[Scoreboard] Received unknown packet!");
            errors++;
            return;
        end
        
        // 检查基本字段 odr_id, so, payload
        if (pkt.odr_id != sent_pkt.odr_id || 
            pkt.so != sent_pkt.so ||
            pkt.payload != sent_pkt.payload) begin
            $error("[Scoreboard] Packet #%0d field mismatch! Expected odr_id=%0d, so=%0b, payload=0x%0h; Got odr_id=%0d, so=%0b, payload=0x%0h",
                   sent_pkt.pkt_id, sent_pkt.odr_id, sent_pkt.so, sent_pkt.payload, pkt.odr_id, pkt.so, pkt.payload);
            errors++;
        end
        
        // 检查查表结果
        if (sent_pkt.lkp_en) begin
            if (pkt_lkp_results.exists(sent_pkt.lkp_info)) begin
                bit [INFO_LENGTH-1:0] expected_rslt = pkt_lkp_results[sent_pkt.lkp_info];
                if (pkt.lkp_rslt != expected_rslt) begin
                    $error("[Scoreboard] Packet #%0d lkp_info=0x%0h lookup result mismatch! Expected 0x%0h, Got 0x%0h",
                           sent_pkt.pkt_id, sent_pkt.lkp_info, expected_rslt, pkt.lkp_rslt);
                    errors++;
                end
            end else begin
                $warning("[Scoreboard] Packet #%0d lookup result not found in records", sent_pkt.pkt_id);
            end
        end else begin
            // 不需要查表的报文，lkp_rslt应该为lkp_info
            if (pkt.lkp_rslt != sent_pkt.lkp_info) begin
                $warning("[Scoreboard] Packet #%0d doesn't need lookup but has lkp_rslt=0x%0h, lkp_info=0x%0h",
                         sent_pkt.pkt_id, pkt.lkp_rslt, sent_pkt.lkp_info);
            end
        end
        pkt.pkt_id = sent_pkt.pkt_id;
        pkt.timestamp_in = sent_pkt.timestamp_in;
        pkt.lkp_en = sent_pkt.lkp_en;
        
    endfunction

    // 更新SO=0和SO=1报文统计
    function void update_so01_statistics(packet_transaction pkt);
        realtime latency;
        int bin_index;
        
        if(pkt.so == 0) begin
            if (pkt.lkp_en) begin
                if (lkp_responses[pkt.lkp_rslt].rsp_time > pkt.timestamp_in) begin
                    latency = pkt.timestamp_out - lkp_responses[pkt.lkp_rslt].rsp_time;
                end else begin
                    latency = pkt.timestamp_out - pkt.timestamp_in;
                end
            end else begin
                latency = pkt.timestamp_out - pkt.timestamp_in;
            end
            
            // 更新统计数据
            so0_total_pkts++;
            so0_total_latency += latency;
            
            if(latency > so0_max_latency) so0_max_latency = latency;
            if(latency < so0_min_latency) so0_min_latency = latency;
            
            // 更新延迟分布
            bin_index = ((latency - so0_min_latency) * 10 / (so0_max_latency - so0_min_latency));
            if(bin_index >= 10) bin_index = 9;
            if(bin_index < 0) bin_index = 0;
            so0_latency_bins[bin_index]++;
            
        end else begin
            if (pkt.lkp_en) begin
                if (lkp_responses[pkt.lkp_rslt].rsp_time > pkt.timestamp_in) begin
                    latency = pkt.timestamp_out - lkp_responses[pkt.lkp_rslt].rsp_time;
                end else begin
                    latency = pkt.timestamp_out - pkt.timestamp_in;
                end
            end else begin
                latency = pkt.timestamp_out - pkt.timestamp_in;
            end
            
            // 更新统计数据
            so1_total_pkts++;
            so1_total_latency += latency;
            
            if(latency > so1_max_latency) so1_max_latency = latency;
            if(latency < so1_min_latency) so1_min_latency = latency;
            
            // 更新延迟分布
            bin_index = ((latency - so1_min_latency) * 10 / (so1_max_latency - so1_min_latency));
            if(bin_index >= 10) bin_index = 9;
            if(bin_index < 0) bin_index = 0;
            so1_latency_bins[bin_index]++;
            
        end
    endfunction

    // 更新order_id 1-7的延迟统计
    function void update_order_statistics(packet_transaction pkt);
        realtime latency;
        int bin_index;
        

        latency = pkt.timestamp_out - pkt.timestamp_in;
        
        // 更新统计数据
        order_total_pkts[pkt.odr_id]++;
        order_total_latency[pkt.odr_id] += latency;
        
        if(latency > order_max_latency[pkt.odr_id]) 
            order_max_latency[pkt.odr_id] = latency;
        if(latency < order_min_latency[pkt.odr_id]) 
            order_min_latency[pkt.odr_id] = latency;
        
        // 更新延迟分布
        bin_index = ((latency - order_min_latency[pkt.odr_id]) * 10 / 
                    (order_max_latency[pkt.odr_id] - order_min_latency[pkt.odr_id]));
        if(bin_index >= 10) bin_index = 9;
        if(bin_index < 0) bin_index = 0;
        order_latency_bins[pkt.odr_id][bin_index]++;
            

    endfunction

    function void check_ordering(packet_transaction pkt);
        if (pkt.odr_id == 0) begin
            order_queues[pkt.odr_id].push_back(pkt);
            return;
        end

        // 获取该order_id的历史队列
        history = order_queues[pkt.odr_id];  

        if (pkt.so == 1) begin
            // SO=1的报文需要检查前面所有报文是否已发送
            foreach (history[i]) begin
                if (history[i].timestamp_in > pkt.timestamp_in && 
                    history[i].timestamp_out > pkt.timestamp_out) begin
                    $error("[Scoreboard]: Order violation detected! Packet #%0d (odr_id=%0d, so=1) sent before packet #%0d",
                           $time, pkt.pkt_id, pkt.odr_id, history[i].pkt_id);
                    order_violations++;
                    errors++;
                end
            end
        end 

        // 将当前报文加入历史队列
        order_queues[pkt.odr_id].push_back(pkt);
    endfunction
    
    // 更新带宽统计
    function void update_bandwidth_statistics(packet_transaction pkt);
        realtime current_time = pkt.timestamp_out;
        real current_bandwidth;
        int bin_index;
        
        // 如果超过统计窗口，计算并记录带宽
        if (current_time - last_bandwidth_time >= TIME_WINDOW) begin
            if (window_packet_count > 0) begin
                current_bandwidth = (window_packet_count * (DATA_LENGTH / 8)) / 
                                  ((current_time - last_bandwidth_time) / 1e9) / 1e9;
                
                // 更新统计数据
                bandwidth_history.push_back(current_bandwidth);
                total_bandwidth += current_bandwidth;
                bandwidth_sample_count++;
                
                $display("[Scoreboard] Time window [%.2f-%.2f] ns: Bandwidth = %.2f GB/s", 
                        last_bandwidth_time, current_time, current_bandwidth);
                

                if (current_bandwidth > max_bandwidth) 
                    max_bandwidth = current_bandwidth;
                if (current_bandwidth < min_bandwidth) 
                    min_bandwidth = current_bandwidth;
                
                // 更新带宽分布
                if (max_bandwidth > min_bandwidth) begin
                    bin_index = ((current_bandwidth - min_bandwidth) * 10 / 
                               (max_bandwidth - min_bandwidth));
                    if (bin_index >= 10) 
                        bin_index = 9;
                    if (bin_index < 0) 
                        bin_index = 0;
                    bandwidth_bins[bin_index]++;
                end else if (max_bandwidth == min_bandwidth) begin
                    // 如果最大和最小带宽相等，将其放入第一个区间
                    bandwidth_bins[0]++;
                end
                
                // 打印当前窗口的带宽信息
                $display("[Scoreboard] Time window [%.2f-%.2f] ns: Bandwidth = %.2f GB/s", 
                        last_bandwidth_time, current_time, current_bandwidth);
            end
            
            // 重置窗口计数
            window_packet_count = 0;
            last_bandwidth_time = current_time;
        end
        
        // 增加当前窗口的包计数
        window_packet_count++;
    endfunction
    
    // 最终检查
    function void final_check();
        real bandwidth_variance;
        real avg_bandwidth;
        real bandwidth_std_dev;
        real bandwidth_variance_without_min;
        real bandwidth_std_dev_without_min;
        real avg_bandwidth_without_min;
        real lower_bound;
        real upper_bound;
        int i, j;
        int unique_latencies[$];
        int latency_counts[int];
        
        $display("=== Scoreboard Final Check ===");
        $display("Total sent packets: %0d", total_sent);
        $display("Total received packets: %0d", total_received);
        $display("Total lookup requests: %0d", total_lkp_requests);
        $display("Total lookup responses: %0d", total_lkp_responses);
        $display("Total order violations: %0d", order_violations);

        if (total_sent != total_received) begin
            $error("Packet count mismatch! Sent=%0d, Received=%0d", total_sent, total_received);
            errors++;

            // 创建包含所有pkt_id的队列
            all_pkt_ids.delete();  // 清空队列
            for (i = 0; i < sent_pkts.size(); i++) begin
                all_pkt_ids.push_back(i);
            end

            // 遍历received_pkts，删除已接收的pkt_id
            foreach (received_pkts[i]) begin
                int idx[$];
                idx = all_pkt_ids.find_index with (item == received_pkts[i].pkt_id);
                if (idx.size() > 0) begin
                    all_pkt_ids.delete(idx[0]);
                end
            end

            $display("\n=== Missing Packets Analysis ===");
            foreach (all_pkt_ids[i]) begin
                // 在sent_pkts中找到对应的数据包信息
                foreach (sent_pkts[j]) begin
                    if (sent_pkts[j].pkt_id == all_pkt_ids[i]) begin
                        $error("[Scoreboard]: Missing packet: pkt_id=%0d", 
                               all_pkt_ids[i]);
                        break;
                    end
                end
            end
        end
        
        // 显示每个order_id的统计
        for (i = 0; i < 8; i++) begin
            if (order_queues[i].size() > 0) begin
                $display("  Order_id %0d: %0d packets", i, order_queues[i].size());
            end
        end
        
        // 显示SO=0报文统计
        if(so0_total_pkts > 0) begin
            $display("\n=== SO=0 Packet Statistics ===");
            $display("Total packets: %0d", so0_total_pkts);
            $display("Max latency: %.2f ns", so0_max_latency);
            $display("Min latency: %.2f ns", so0_min_latency);
            $display("Average latency: %.2f ns", so0_total_latency/so0_total_pkts);
            
            
            $display("\nSO=0 packet latency distribution:");
            for(i = 0; i < 10; i++) begin
                lower_bound = so0_min_latency + (so0_max_latency - so0_min_latency) * i / 10;
                upper_bound = so0_min_latency + (so0_max_latency - so0_min_latency) * (i+1) / 10;
                $display("Bin %0d (%.2f-%.2f ns): %0d packets", 
                        i, lower_bound, upper_bound, so0_latency_bins[i]);
            end
        end


        // 显示SO=1报文统计
        if(so1_total_pkts > 0) begin
            $display("\n=== SO=1 Packet Statistics ===");
            $display("Total packets: %0d", so1_total_pkts);
            $display("Max latency: %.2f ns", so1_max_latency);
            $display("Min latency: %.2f ns", so1_min_latency);
            $display("Average latency: %.2f ns", so1_total_latency/so1_total_pkts);

            $display("\nSO=1 packet latency distribution:");
            for(i = 0; i < 10; i++) begin
                lower_bound = so1_min_latency + (so1_max_latency - so1_min_latency) * i / 10;
                upper_bound = so1_min_latency + (so1_max_latency - so1_min_latency) * (i+1) / 10;
                $display("Bin %0d (%.2f-%.2f ns): %0d packets", 
                        i, lower_bound, upper_bound, so1_latency_bins[i]);
            end
        end
        
        // 显示order_id 0-7的延迟统计
        $display("\n=== Order_id 0-7 Packet Statistics ===");
        for (i = 0; i < 8; i++) begin
            if(order_total_pkts[i] > 0) begin
                $display("\nOrder_id %0d Statistics:", i);
                $display("Total packets: %0d", order_total_pkts[i]);
                $display("Max latency: %.2f ns", order_max_latency[i]);
                $display("Min latency: %.2f ns", order_min_latency[i]);
                $display("Average latency: %.2f ns", order_total_latency[i]/order_total_pkts[i]);
                
                $display("\nOrder_id %0d packet latency distribution:", i);
                for(j = 0; j < 10; j++) begin
                    lower_bound = order_min_latency[i] + (order_max_latency[i] - order_min_latency[i]) * j / 10;
                    upper_bound = order_min_latency[i] + (order_max_latency[i] - order_min_latency[i]) * (j+1) / 10;
                    $display("Bin %0d (%.2f-%.2f ns): %0d packets", 
                            j, lower_bound, upper_bound, order_latency_bins[i][j]);
                end
            end
        end


        // 显示带宽统计信息
        if (bandwidth_sample_count > 0) begin
            $display("\n=== Bandwidth Statistics ===");
            $display("Total bandwidth samples: %0d", bandwidth_sample_count);
            $display("Max bandwidth: %.2f GB/s", max_bandwidth);
            $display("Min bandwidth: %.2f GB/s", min_bandwidth);
            $display("Average bandwidth: %.2f GB/s", total_bandwidth/bandwidth_sample_count);
            $display("Average bandwidth: %.2f GB/s (without min_bandwidth)", (total_bandwidth - min_bandwidth)/(bandwidth_sample_count - 1));
            
            $display("\nBandwidth distribution:");
            for(i = 0; i < 10; i++) begin
                lower_bound = min_bandwidth + (max_bandwidth - min_bandwidth) * i / 10;
                upper_bound = min_bandwidth + (max_bandwidth - min_bandwidth) * (i+1) / 10;
                $display("Bin %0d (%.2f-%.2f GB/s): %0d samples", 
                        i, lower_bound, upper_bound, bandwidth_bins[i]);
            end
            
            // 计算带宽波动率
            bandwidth_variance = 0;
            avg_bandwidth = total_bandwidth/bandwidth_sample_count;
            foreach(bandwidth_history[i]) begin
                bandwidth_variance += (bandwidth_history[i] - avg_bandwidth) * 
                                    (bandwidth_history[i] - avg_bandwidth);
            end
            bandwidth_variance /= bandwidth_sample_count;
            bandwidth_std_dev = $sqrt(bandwidth_variance);
            

            bandwidth_variance_without_min = 0;
            avg_bandwidth_without_min = (total_bandwidth - min_bandwidth)/(bandwidth_sample_count - 1);
            foreach(bandwidth_history[i]) begin
                if (bandwidth_history[i] > min_bandwidth) begin
                    bandwidth_variance_without_min += (bandwidth_history[i] - avg_bandwidth_without_min) * 
                                                    (bandwidth_history[i] - avg_bandwidth_without_min);
                end
            end
            bandwidth_variance_without_min /= bandwidth_sample_count - 1;
            bandwidth_std_dev_without_min = $sqrt(bandwidth_variance_without_min);
            
            $display("\nBandwidth stability metrics:");
            $display("Standard deviation: %.2f GB/s", bandwidth_std_dev);
            $display("Coefficient of variation: %.2f%%", 
                    (bandwidth_std_dev/avg_bandwidth)*100);

            $display("Standard deviation (without min_bandwidth): %.2f GB/s", bandwidth_std_dev_without_min);
            $display("Coefficient of variation (without min_bandwidth): %.2f%%", 
                    (bandwidth_std_dev_without_min/avg_bandwidth_without_min)*100);

        end
        
        if (errors == 0) begin
            $display("*** ALL CHECKS PASSED! ***");
        end else begin
            $error("*** FOUND %0d ERRORS! ***", errors);
        end
        
        $display("==============================");
    endfunction
    
endclass

`endif 