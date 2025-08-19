#!/bin/bash

CURRENT_DIR=$(pwd)

cd tb/sim/

mkdir -p ../log

packets=100000

for seed in $(seq 0 1000 9000); do
    echo "Running test with seed $seed..."
    
    # 执行测试
    ./run_test.sh 2 $packets $seed
    cp scenario2_${packets}_seed${seed}.log ../log/scenario2_${packets}_seed_${seed}.txt


    ./run_test.sh 3 $packets $seed
    cp scenario3_${packets}_seed${seed}.log ../log/scenario3_${packets}_seed_${seed}.txt
    
    
    echo "Test with seed $seed completed"
    echo "----------------------------------------"
    
done

cd $CURRENT_DIR
