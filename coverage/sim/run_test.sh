#!/bin/bash

# 运行测试脚本

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 显示使用说明
show_usage() {
    echo "Usage: $0 <scenario> [num_packets] [seed]"
    echo "  scenario: 1, 2, 3, or all"
    echo "  num_packets: optional, default is 1000"
    echo "  seed: optional, random seed for reproducible results"
    echo ""
    echo "Examples:"
    echo "  $0 1                  # Run scenario 1 with 1000 packets, random seed"
    echo "  $0 2 5000             # Run scenario 2 with 5000 packets, random seed"
    echo "  $0 3 1000 12345       # Run scenario 3 with 1000 packets, seed=12345"
    echo "  $0 all                # Run all scenarios with default settings"
}

# 检查参数
if [ $# -eq 0 ]; then
    print_error "Missing required parameter: scenario"
    show_usage
    exit 1
fi

SCENARIO=$1
NUM_PACKETS=${2:-1000}
SEED=$3

# 构建种子参数
SEED_ARG=""
SEED_INFO=""
if [ ! -z "$SEED" ]; then
    SEED_ARG="+SEED=$SEED"
    SEED_INFO=" (seed=$SEED)"
    print_msg "Using random seed: $SEED"
else
    print_msg "Using random seed (not fixed)"
fi

# 清理旧文件
print_msg "Cleaning old files..."
make clean

# 编译
print_msg "Compiling design and testbench..."
make compile
if [ $? -ne 0 ]; then
    print_error "Compilation failed!"
    exit 1
fi

# 运行测试
case $SCENARIO in
    1)
        print_msg "Running Scenario 1 (No lookup, no ordering) with $NUM_PACKETS packets${SEED_INFO}..."
        if [ ! -z "$SEED" ]; then
            LOG_FILE="scenario1_${NUM_PACKETS}_seed${SEED}.log"
        else
            LOG_FILE="scenario1_${NUM_PACKETS}.log"
        fi
        ./simv -cm line+cond+fsm+tgl +SCENARIO=SCENARIO_1 +PACKETS=$NUM_PACKETS $SEED_ARG | tee $LOG_FILE
        ;;
    2)
        print_msg "Running Scenario 2 (All lookup, mixed ordering) with $NUM_PACKETS packets${SEED_INFO}..."
        if [ ! -z "$SEED" ]; then
            LOG_FILE="scenario2_${NUM_PACKETS}_seed${SEED}.log"
        else
            LOG_FILE="scenario2_${NUM_PACKETS}.log"
        fi
        ./simv -cm line+cond+fsm+tgl +SCENARIO=SCENARIO_2 +PACKETS=$NUM_PACKETS $SEED_ARG | tee $LOG_FILE
        ;;
    3)
        print_msg "Running Scenario 3 (Mixed lookup, high ordering) with $NUM_PACKETS packets${SEED_INFO}..."
        if [ ! -z "$SEED" ]; then
            LOG_FILE="scenario3_${NUM_PACKETS}_seed${SEED}.log"
        else
            LOG_FILE="scenario3_${NUM_PACKETS}.log"
        fi
        ./simv -cm line+cond+fsm+tgl +SCENARIO=SCENARIO_3 +PACKETS=$NUM_PACKETS $SEED_ARG | tee $LOG_FILE
        ;;
    all)
        print_msg "Scenario 2 with $NUM_PACKETS packets${SEED_INFO}..."
        if [ ! -z "$SEED" ]; then
            LOG2="scenario2_${NUM_PACKETS}_seed${SEED}.log"
        else
            LOG2="scenario2_${NUM_PACKETS}.log"
        fi
        ./simv -cm line+cond+fsm+tgl -cm_name scenario2 -cm_dir ./simv.vdb +SCENARIO=SCENARIO_2 +PACKETS=$NUM_PACKETS $SEED_ARG | tee $LOG2
        
        print_msg "Scenario 3 with $NUM_PACKETS packets${SEED_INFO}..."
        if [ ! -z "$SEED" ]; then
            LOG3="scenario3_${NUM_PACKETS}_seed${SEED}.log"
        else
            LOG3="scenario3_${NUM_PACKETS}.log"
        fi
        ./simv -cm line+cond+fsm+tgl -cm_name scenario3 -cm_dir ./simv.vdb +SCENARIO=SCENARIO_3 +PACKETS=$NUM_PACKETS $SEED_ARG | tee $LOG3
        
        # 合并覆盖率数据
        print_msg "Merging coverage data..."
        urg -full64 -noreport -dir simv.vdb -dbname coverage
        
        ;;
    *)
        print_error "Invalid scenario: $SCENARIO"
        echo "Valid options: 1, 2, 3, or all"
        exit 1
        ;;
esac