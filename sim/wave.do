onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sl_rt_tb/dut/rst_n
add wave -noupdate /sl_rt_tb/dut/clk
add wave -noupdate /sl_rt_tb/dut/serial_line_zeroes_a
add wave -noupdate /sl_rt_tb/dut/serial_line_ones_a
add wave -noupdate /sl_rt_tb/dut/pclk_a
add wave -noupdate /sl_rt_tb/dut/preset_n_a
add wave -noupdate /sl_rt_tb/dut/paddr_a
add wave -noupdate /sl_rt_tb/dut/psel_a
add wave -noupdate /sl_rt_tb/dut/penable_a
add wave -noupdate /sl_rt_tb/dut/pwrite_a
add wave -noupdate /sl_rt_tb/dut/pdata_a
add wave -noupdate /sl_rt_tb/dut/state_r
add wave -noupdate /sl_rt_tb/dut/next_r
add wave -noupdate /sl_rt_tb/dut/sl0_tmp_r
add wave -noupdate /sl_rt_tb/dut/sl1_tmp_r
add wave -noupdate /sl_rt_tb/dut/shift_data_r
add wave -noupdate /sl_rt_tb/dut/cycle_cnt_r
add wave -noupdate /sl_rt_tb/dut/bit_cnt_r
add wave -noupdate /sl_rt_tb/dut/buffered_data_r
add wave -noupdate /sl_rt_tb/dut/data_to_send_r
add wave -noupdate /sl_rt_tb/dut/config_r
add wave -noupdate /sl_rt_tb/dut/status_r
add wave -noupdate /sl_rt_tb/dut/parity_ones
add wave -noupdate /sl_rt_tb/dut/parity_zeroes
add wave -noupdate /sl_rt_tb/dut/apb_state
add wave -noupdate /sl_rt_tb/dut/bit_ended
add wave -noupdate /sl_rt_tb/dut/bit_started
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 208
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
WaveRestoreZoom {0 ps} {1418100 ps}
