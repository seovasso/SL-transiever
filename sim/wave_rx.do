onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sl_rt_tb/dut_rx/rst_n
add wave -noupdate /sl_rt_tb/dut_rx/clk
add wave -noupdate /sl_rt_tb/dut_rx/serial_line_zeroes_a
add wave -noupdate /sl_rt_tb/dut_rx/serial_line_ones_a
add wave -noupdate /sl_rt_tb/dut_rx/status_w
add wave -noupdate /sl_rt_tb/dut_rx/data_w
add wave -noupdate /sl_rt_tb/dut_rx/config_w
add wave -noupdate /sl_rt_tb/dut_rx/state_r
add wave -noupdate /sl_rt_tb/dut_rx/next_r
add wave -noupdate /sl_rt_tb/dut_rx/shift_data_r
add wave -noupdate /sl_rt_tb/dut_rx/buffered_data_r
add wave -noupdate /sl_rt_tb/dut_rx/cycle_cnt_r
add wave -noupdate /sl_rt_tb/dut_rx/bit_cnt_r
add wave -noupdate /sl_rt_tb/dut_rx/config_r
add wave -noupdate /sl_rt_tb/dut_rx/status_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {19999200 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 242
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
WaveRestoreZoom {0 ps} {6419500 ps}
