onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sl_rt_tb/dut_tx/rst_n
add wave -noupdate /sl_rt_tb/dut_tx/clk
add wave -noupdate /sl_rt_tb/dut_tx/SL0
add wave -noupdate /sl_rt_tb/dut_tx/SL1
add wave -noupdate /sl_rt_tb/dut_tx/data_a
add wave -noupdate /sl_rt_tb/dut_tx/send_imm
add wave -noupdate /sl_rt_tb/dut_tx/txdata_r
add wave -noupdate /sl_rt_tb/dut_tx/state_r
add wave -noupdate /sl_rt_tb/dut_tx/next_r
add wave -noupdate /sl_rt_tb/dut_tx/config_r
add wave -noupdate /sl_rt_tb/dut_tx/bitcnt_r
add wave -noupdate /sl_rt_tb/dut_tx/status_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 221
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1263800 ps}
