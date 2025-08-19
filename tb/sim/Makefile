# Makefile for C Module Testbench

# VCS编译选项
VCS = vcs
VCS_FLAGS = -full64 -sverilog -debug_all -timescale=1ns/1ps \
            -l compile.log +v2k -kdb -lca +lint=all 


# 仿真选项
SIM_FLAGS = -l sim.log 

# 源文件路径
RTL_DIR = ../../rtl
TB_DIR = ..
ENV_DIR = $(TB_DIR)/env
BFM_DIR = $(TB_DIR)/bfm
TEST_DIR = $(TB_DIR)/test

# 包含路径
INCDIR = +incdir+$(ENV_DIR)+$(BFM_DIR)

# RTL文件列表
RTL_FILES = $(RTL_DIR)/top_c_module.v \
            $(RTL_DIR)/input_interface.v \
            $(RTL_DIR)/cache_control.v \
			$(RTL_DIR)/cache_control_multibank.v \
			$(RTL_DIR)/rr_arbiter_base.v \
            $(RTL_DIR)/decode.v \
			$(RTL_DIR)/CRC32_D20.v \
			$(RTL_DIR)/dual_port_ram.v \
			$(RTL_DIR)/multi_hash_ram_top.v \
			$(RTL_DIR)/multi_hash_top.v \
			$(RTL_DIR)/multi_hash.v \
            $(RTL_DIR)/ROB_file.v \
            $(RTL_DIR)/register_file.v \
            $(RTL_DIR)/writeback.v \
			$(RTL_DIR)/rr_arbiter.v \
            $(RTL_DIR)/ext_fifo.v \
            $(RTL_DIR)/output_interface.v \
            $(RTL_DIR)/execute.v

# Testbench文件列表
TB_FILES = $(ENV_DIR)/c_module_pkg.sv \
           $(ENV_DIR)/interfaces.sv \
           $(BFM_DIR)/module_b_bfm.sv \
           $(BFM_DIR)/module_a_bfm.sv \
           $(BFM_DIR)/module_d_bfm.sv \
           $(ENV_DIR)/scoreboard.sv \
           $(ENV_DIR)/test_env.sv \
           $(TEST_DIR)/top_tb.sv

# 默认目标
all: compile

# 编译
compile:
	$(VCS) $(VCS_FLAGS) $(INCDIR) $(RTL_FILES) $(TB_FILES) -o simv

# 运行场景1测试
run_scenario1:
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_1 +PACKETS=10000

# 运行场景2测试
run_scenario2:
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_2 +PACKETS=5000

# 运行场景3测试
run_scenario3:
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_3 +PACKETS=5000

# 运行所有场景
run_all: compile
	@echo "=== Running Scenario 1 ==="
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_1 +PACKETS=10000 | tee scenario1.log
	@echo "\n=== Running Scenario 2 ==="
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_2 +PACKETS=5000 | tee scenario2.log
	@echo "\n=== Running Scenario 3 ==="
	./simv $(SIM_FLAGS) +SCENARIO=SCENARIO_3 +PACKETS=5000 | tee scenario3.log

# 清理
clean:
	rm -rf simv* csrc *.log *.vpd *.vcd DVEfiles ucli.key coverage urgReport

.PHONY: all compile run_scenario1 run_scenario2 run_scenario3 run_all clean