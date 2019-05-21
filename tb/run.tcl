#
# M31 E-Multiplier with Avalon Bus interface
#
set RTL_DIR  ../rtl
set IP_DIR   ../rtl/Quartus_IP
set INC_DIR  ../rtl/inc

set svlib   C:/intelFPGA_lite/16.1/modelsim_ase/svlib/src
set TB_DIR  .


if {[file exists tbSHA256/_info]} {
   echo "INFO: Simulation library tbSHA256 already exists"
} else {
   file delete -force tbSHA256 
   vlib tbSHA256
}

vmap work tbSHA256

vlog -work tbSHA256 $IP_DIR/RAM2PORT/RAM2Pv1.v      +incdir+$INC_DIR
vlog -work tbSHA256 $RTL_DIR/SHA256.v               +incdir+$INC_DIR
vlog -work tbSHA256 $RTL_DIR/SHA256_core.v          +incdir+$INC_DIR
vlog -work tbSHA256 $RTL_DIR/ram_infer_sha.v            +incdir+$INC_DIR
vlog -work tbSHA256 $RTL_DIR/sha256_k_constants.v   +incdir+$INC_DIR
vlog -work tbSHA256 $RTL_DIR/SHA256_top.v           +incdir+$INC_DIR
vlog -sv -work tbSHA256 $INC_DIR/EMTest_pkg.vh      +incdir+$INC_DIR
vlog -sv -work tbSHA256 $TB_DIR/tb.sv               +incdir+$INC_DIR


#vlog  -sv -work work $TB_DIR/tb.sv +incdir+C:/intelFPGA_lite/16.1/modelsim_ase/svlib/src -f C:/intelFPGA_lite/16.1/modelsim_ase/svlib/src/svlib.f  

set TOP_LEVEL tb

vsim -L altera_mf_ver -L tbSHA256 -L lpm_ver -L svlib $TOP_LEVEL 

add log -r /*

do wave.do


puts "\n\n SHA256 IP Test \n\n"

#run -all

