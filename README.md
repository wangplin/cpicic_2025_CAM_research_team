# [CPICIC 2025] CAM Research Team (CAM研究小队)
*第八届研究生创芯大赛 HW赛题三：查表保序管理模块设计*

## Directory Structure
```shell
.
├── coverage                   
├── README.md                   
├── rtl                         
├── run_all_tests.sh            
└── tb                          
    ├── bfm
    │   ├── module_a_bfm.sv     
    │   ├── module_b_bfm.sv     
    │   └── module_d_bfm.sv     
    ├── env
    │   ├── c_module_pkg.sv     
    │   ├── interfaces.sv       
    │   ├── scoreboard.sv       
    │   └── test_env.sv         
    ├── log                     
    ├── sim
    │   ├── Makefile
    │   └── run_test.sh         
    └── test
        └── top_tb.sv           
```

## Performance Test

```shell
# Default 10w packets
./run_all_test.sh
```

## Code Coverage 

```shell
cd coverage/sim
#                 10w packet    seed
./run_test.sh all   100000       0
make verdi_cov
```

## Authors

* [Zhirong Ye](https://github.com/Kanae-Ye)
* [Peilin Wang](https://github.com/wangplin)
* [Zeqi Yang](https://github.com/yangzqi)
