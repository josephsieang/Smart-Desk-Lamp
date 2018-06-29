vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 \
"../../../../HD_Final.srcs/sources_1/ip/KeyboardCtrl_1/src/Ps2Interface.v" \
"../../../../HD_Final.srcs/sources_1/ip/KeyboardCtrl_1/src/KeyboardCtrl.v" \
"../../../../HD_Final.srcs/sources_1/ip/KeyboardCtrl_1/sim/KeyboardCtrl_1.v" \


vlog -work xil_defaultlib \
"glbl.v"

