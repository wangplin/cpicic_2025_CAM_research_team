`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

import c_module_pkg::*;

class scoreboard;
    
    // 从模块B发送的报文队列
    packet_transaction sent_pkts[$];
    
    // 从模块D接收的报文队列
    packet_transaction received_pkts[$];
    
    // 查表请求和响应的关联
    lookup_request lkp_requests[bit [REQ_WIDTH-1:0]];
    lookup_response lkp_responses[bit [INFO_LENGTH-1:0]];
    
    // 报文ID到查表结果的映射
    bit [INFO_LENGTH-1:0] pkt_lkp_results[int];
    
    // 统计信息
    int total_sent;
    int total_received;
    int total_lkp_requests;
    int total_lkp_responses;
    
    function new();
        total_sent = 0;
        total_received = 0;
        total_lkp_requests = 0;
        total_lkp_responses = 0;
    endfunction
    
    // 记录发送的报文
    function void add_sent_packet(packet_transaction pkt);
        sent_pkts.push_back(pkt);
        total_sent++;
    endfunction
    
    // 记录查表请求
    function void add_lookup_request(lookup_request req);
        lkp_requests[req.req_id] = req;
        total_lkp_requests++;
    endfunction
    
    // 记录查表响应
    function void add_lookup_response(lookup_response rsp);
        if (lkp_requests.exists(rsp.rsp_id)) begin
            lookup_request req = lkp_requests[rsp.rsp_id];
            pkt_lkp_results[req.lkp_info] = rsp.lkp_rslt;
            lkp_responses[rsp.lkp_rslt] = rsp;
            total_lkp_responses++;
        end
    endfunction
    
    // 记录接收的报文
    function void add_received_packet(packet_transaction pkt);
        received_pkts.push_back(pkt);
        total_received++;
    endfunction
    
    // 打印统计信息
    function void print_statistics();
        $display("=== Scoreboard Statistics ===");
        $display("Total packets sent: %0d", total_sent);
        $display("Total packets received: %0d", total_received);
        $display("Total lookup requests: %0d", total_lkp_requests);
        $display("Total lookup responses: %0d", total_lkp_responses);
        $display("==========================");
    endfunction

endclass

`endif 