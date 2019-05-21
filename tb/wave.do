onerror {resume}
quietly virtual signal -install /tb/dut/Core_Interface/SHA_inst { /tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[1:0]} msg_byte_cnt10
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/clk
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/reset_n
add wave -noupdate /tb/dut/address
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/ld_meta
add wave -noupdate -radix unsigned -childformat {{{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[15]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[14]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[13]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[12]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[11]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[10]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[9]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[8]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[7]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[6]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[5]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[4]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[3]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[2]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[1]} -radix unsigned} {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[0]} -radix unsigned}} -subitemconfig {{/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[15]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[14]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[13]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[12]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[11]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[10]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[9]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[8]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[7]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[6]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[5]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[4]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[3]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[2]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[1]} {-height 15 -radix unsigned} {/tb/dut/Core_Interface/SHA_inst/msg_byte_cnt[0]} {-height 15 -radix unsigned}} /tb/dut/Core_Interface/SHA_inst/msg_byte_cnt
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/num_msg_blks
add wave -noupdate -radix binary /tb/dut/Core_Interface/SHA_inst/byte_position
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/final_blk_wrd_cnt
add wave -noupdate -divider {New Divider}
add wave -noupdate -color CYAN -itemcolor CYAN /tb/dut/Core_Interface/SHA_inst/SHA_CTRL_SM
add wave -noupdate -color cyan -itemcolor cyan /tb/dut/Core_Interface/SHA_inst/track_ptr
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/thread_CTRL
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/dat_sw_ref_cntr
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/dat_sw_sel
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/RAM_Data
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/RAM_Data_OUT_p
add wave -noupdate /tb/DUT_MSG_BLK_1
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/INC_SRC_RAM_ADDR
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/MSG_SCHED_RAM_WE
add wave -noupdate -divider {New Divider}
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_0
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_1
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_2
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_3
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_4
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_5
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_6
add wave -noupdate -group HASH_OUT /tb/dut/Core_Interface/SHA_inst/H_reg_7
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/msg_sch_ram_addr_src
add wave -noupdate /tb/extra_msg_blk
add wave -noupdate /tb/HASH
add wave -noupdate /tb/DUT_HASH
add wave -noupdate /tb/TB_HASH
add wave -noupdate /tb/str1
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/SHA_PROC_STATE
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/MSG_SCHED_RAM_WR_ADDR
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/MSG_SCHED_RAM_WE
add wave -noupdate /tb/dut/Core_Interface/SHA_inst/sha_sm_busy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {2345701993 ps} 0} {{Cursor 2} {35107165 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 212
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {31890943 ps} {32204186 ps}
