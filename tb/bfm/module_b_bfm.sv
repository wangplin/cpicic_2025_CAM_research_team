`ifndef MODULE_B_BFM_SV
`define MODULE_B_BFM_SV

import c_module_pkg::*;

class module_b_bfm;
    
    // 接口信号
    virtual interface b2c_if vif;

    int file_handle;
    int file_handle_bw;
    
    // 配置参数
    scenario_e current_scenario;
    int packet_count;
    int packet_sent;
    
    // 报文队列
    packet_transaction pkt_queue[$];
    
    // 历史报文缓存（用于生成相同lkp_info）
    packet_transaction history_pkts[$];
    int history_size = 128;
    
    // 保序约束跟踪：记录每个order_id的连续SO=0计数
    int so_zero_count[8];  // order_id范围是0-7
    parameter MAX_SO_ZERO_BETWEEN_SO_ONE = 16;
    
    // 统计信息
    int total_sent;
    realtime start_time;
    realtime end_time;
    
    // 随机种子控制
    int unsigned seed;
    bit use_seed;
    process seed_process;  // 用于种子控制的进程
    
    function new(virtual interface b2c_if vif);
        this.vif = vif;
        packet_count = 0;
        packet_sent = 0;
        total_sent = 0;
        use_seed = 0;
        seed = 0;
        // 初始化SO=0计数器
        foreach(so_zero_count[i]) begin
            so_zero_count[i] = 0;
        end

    endfunction
    
    // 设置随机种子
    function void set_seed(int unsigned s);
        seed = s;
        use_seed = 1;
        // 获取当前进程并设置种子
        seed_process = process::self();
        seed_process.srandom(seed);
        $display("[Module B BFM] Random seed set to: %0d", seed);
    endfunction
    
    // 基于种子的随机数生成器
    function int unsigned get_random(int unsigned min, int unsigned max);
        if (use_seed) begin
            return min + ($urandom() % (max - min + 1));
        end else begin
            return $urandom_range(min, max);
        end
    endfunction
    
    // 生成场景1的报文：无查表无保序
    function packet_transaction gen_scenario1_packet();
        packet_transaction pkt = new();
        pkt.pkt_id = packet_count++;
        
        if (use_seed) begin
            pkt.srandom(seed + pkt.pkt_id);
        end
        
        assert(pkt.randomize() with {
            lkp_en == 0;
            odr_id == 0;
        });
        
        // 设置payload为pkt_id
        pkt.payload = pkt.pkt_id;
        
        return pkt;
    endfunction
    
    // 生成场景2的报文：全查表，混合保序
    function packet_transaction gen_scenario2_packet();
        packet_transaction pkt = new();
        int idx;  
        bit force_so_one;
        bit [ORDER_ID-1:0] temp_odr_id;
        bit [INFO_LENGTH-1:0] temp_lkp_info;
        
        pkt.pkt_id = packet_count++;
        
        if (use_seed) begin
            pkt.srandom(seed + pkt.pkt_id);
        end
        
        // 先随机生成order_id
        assert(pkt.randomize() with {
            pkt.lkp_en == 1;
            pkt.odr_id dist {0:=1, [1:7]:=1};  // 0-7均匀分布
        });

        temp_lkp_info = pkt.lkp_info;

        // 50%概率复用历史lkp_info
        if (history_pkts.size() > 0 && get_random(0, 1) == 1) begin
            idx = get_random(0, history_pkts.size()-1);
            pkt.lkp_info = history_pkts[idx].lkp_info;
            temp_lkp_info = pkt.lkp_info;
        end
        
        temp_odr_id = pkt.odr_id;
        
        // 检查是否需要强制生成SO=1
        force_so_one = (pkt.odr_id != 0) && (so_zero_count[pkt.odr_id] >= MAX_SO_ZERO_BETWEEN_SO_ONE);
        
        // 根据约束生成SO
        if (force_so_one) begin
            pkt.so = 1;
            so_zero_count[pkt.odr_id] = 0;  // 重置计数器
        end else begin
            // 正常随机生成
            assert(pkt.randomize() with {
                pkt.lkp_en == 1;
                pkt.odr_id == temp_odr_id;  // 保持已生成的order_id
                pkt.lkp_info == temp_lkp_info;  // 保持已生成的lkp_info
                pkt.so dist {0:=77, 1:=23};  // 由于Order_ID=0,SO强制为0，因此设置SO=1的概率为16/70(不考虑相同oder_id中16个SO=0的包)
            });
            
            // 更新计数器
            if (pkt.odr_id != 0) begin
                if (pkt.so == 0) begin
                    so_zero_count[pkt.odr_id]++;
                end else begin
                    so_zero_count[pkt.odr_id] = 0;
                end
            end
        end
        
        // 设置payload为pkt_id
        pkt.payload = pkt.pkt_id;
        
        // 更新历史缓存
        history_pkts.push_back(pkt);
        if (history_pkts.size() > history_size) begin
            history_pkts.pop_front();
        end
        return pkt;
    endfunction
    
    // 生成场景3的报文：混合查表，高保序
    function packet_transaction gen_scenario3_packet();
        packet_transaction pkt = new();
        int idx;  
        bit force_so_one;
        bit temp_lkp_en;
        bit [ORDER_ID-1:0] temp_odr_id;
        bit [INFO_LENGTH-1:0] temp_lkp_info;
        
        pkt.pkt_id = packet_count++;
        
        if (use_seed) begin
            pkt.srandom(seed + pkt.pkt_id);
        end


        // 先随机生成order_id
        assert(pkt.randomize() with {
            pkt.lkp_en dist {0:=20, 1:=80}; // lkp_en=0占20%，lkp_en=1占80%
            pkt.odr_id dist {0:=1, [1:7]:=1};  // 0-7均匀分布
        });


        temp_lkp_info = pkt.lkp_info;

        // 50%概率复用历史lkp_info
        if (history_pkts.size() > 0 && get_random(0, 1) == 1) begin
            idx = get_random(0, history_pkts.size()-1);
            pkt.lkp_info = history_pkts[idx].lkp_info;
            temp_lkp_info = pkt.lkp_info;
        end

        // 保存已生成的值
        temp_odr_id = pkt.odr_id;
        temp_lkp_en = pkt.lkp_en;


        // 检查是否需要强制生成SO=1
        force_so_one = (pkt.odr_id != 0) && (so_zero_count[pkt.odr_id] >= MAX_SO_ZERO_BETWEEN_SO_ONE);
        

        // 根据约束生成SO
        if (force_so_one) begin
            pkt.so = 1;
            so_zero_count[pkt.odr_id] = 0;  // 重置计数器
        end else begin
            // 正常随机生成
            assert(pkt.randomize() with {
                pkt.lkp_en == temp_lkp_en;
                pkt.odr_id == temp_odr_id;  // 保持已生成的order_id
                pkt.lkp_info == temp_lkp_info;  // 保持已生成的lkp_info
                pkt.so dist {0:=9, 1:=91};  // 由于Order_ID=0,SO强制为0，因此设置SO=1的概率为32/35(不考虑相同oder_id中16个SO=0的包)
            });
            
            // 更新计数器
            if (pkt.odr_id != 0) begin
                if (pkt.so == 0) begin
                    so_zero_count[pkt.odr_id]++;
                end else begin
                    so_zero_count[pkt.odr_id] = 0;
                end
            end
        end

        // 设置payload为pkt_id
        pkt.payload = pkt.pkt_id;

        // 更新历史缓存
        history_pkts.push_back(pkt);
        if (history_pkts.size() > history_size) begin
            history_pkts.pop_front();
        end

        return pkt;
    endfunction
    
    // 生成报文
    task generate_packets(int num_packets);
        packet_transaction pkt;
        
        // 如果设置了种子，确保在当前任务进程中生效
        if (use_seed) begin
            process::self().srandom(seed);
        end
        
        for (int i = 0; i < num_packets; i++) begin
            case (current_scenario)
                SCENARIO_1: pkt = gen_scenario1_packet();
                SCENARIO_2: pkt = gen_scenario2_packet();
                SCENARIO_3: pkt = gen_scenario3_packet();
            endcase
            
            pkt_queue.push_back(pkt);
        end
    endtask
    
    // 发送报文
    task send_packet(packet_transaction pkt);
        vif.b2c_pkt_vld <= 1'b1;
        vif.b2c_pkt_lkp_en <= pkt.lkp_en;
        vif.b2c_pkt_lkp_info <= pkt.lkp_info;
        vif.b2c_pkt_odr_id <= pkt.odr_id;
        vif.b2c_pkt_so <= pkt.so;
        vif.b2c_pkt_payload <= pkt.payload;
        
        // 等待ready信号为高，期间维持数据包
        do begin
            @(posedge vif.clk);
        end while (!vif.c2b_pkt_rdy);
        
        pkt.timestamp_in = $realtime;
        packet_sent++;
        total_sent++;
        

    endtask
    
    // 运行BFM
    task run();
        
        if (use_seed) begin
            process::self().srandom(seed);
        end
        
        // 初始化接口信号
        vif.b2c_pkt_vld <= 1'b0;
        vif.b2c_pkt_lkp_en <= 1'b0;
        vif.b2c_pkt_lkp_info <= '0;
        vif.b2c_pkt_odr_id <= '0;
        vif.b2c_pkt_so <= 1'b0;
        vif.b2c_pkt_payload <= '0;
        
        // 等待复位完成
        wait(vif.rst_n == 1'b1);
        repeat(10) @(posedge vif.clk);

        start_time = $realtime + CLK_PERIOD;
        
        // 发送所有报文
        while (pkt_queue.size() > 0) begin
            packet_transaction pkt = pkt_queue.pop_front();
            send_packet(pkt);
        end

        // 所有包发送完成后，将vld拉低
        vif.b2c_pkt_vld <= 1'b0;
        
        end_time = $realtime;
        
        // 计算并显示带宽
        display_statistics();
        // $fclose(file_handle);
        // $fclose(file_handle_bw);
    endtask
    
    // 显示统计信息
    function void display_statistics();
        real duration_ns = (end_time - start_time + CLK_PERIOD);
        real duration_s = duration_ns / 1e9;
        real bytes_sent = total_sent * (DATA_LENGTH / 8);
        real bandwidth_gbps = (bytes_sent) / (duration_s * 1e9);
        
        $display("=== Module B BFM Statistics ===");
        $display("Start time: %0t", start_time);
        $display("End time: %0t", end_time);
        $display("Scenario: %s", current_scenario.name());
        $display("Total packets sent: %0d", total_sent);
        $display("Duration: %.3f ns (%.6f s)", duration_ns, duration_s);
        $display("Bandwidth: %.2f GB/s", bandwidth_gbps);
        $display("===============================");

    endfunction
    
endclass

`endif 