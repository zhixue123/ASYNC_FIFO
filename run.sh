#!/bin/bash

# 编译仿真脚本
SIMULATOR=${1:-vcs}

case $SIMULATOR in
    "vcs")
        vcs -full64 -sverilog +v2k -timescale=1ns/1ns ASYNC_FIFO.v TB_ASYNC_FIFO.v -o simv
        ./simv
        ;;
        
    "iverilog")
        iverilog -o simv ASYNC_FIFO.v TB_ASYNC_FIFO.v
        vvp simv
        ;;
        
    "verilator")
        verilator --cc --exe --build ASYNC_FIFO.v TB_ASYNC_FIFO.v
        ./obj_dir/Vasync_fifo
        ;;
        
    *)
        echo "不支持的仿真器: $SIMULATOR"
        echo "支持: vcs, iverilog, verilator"
        exit 1
        ;;
esac