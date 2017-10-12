onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sl_rt_tb/reset
add wave -noupdate /sl_rt_tb/clk
add wave -noupdate /sl_rt_tb/sl0
add wave -noupdate /sl_rt_tb/sl1
add wave -noupdate /sl_rt_tb/pclk
add wave -noupdate /sl_rt_tb/preset_n
add wave -noupdate /sl_rt_tb/paddr
add wave -noupdate /sl_rt_tb/psel
add wave -noupdate /sl_rt_tb/penable
add wave -noupdate /sl_rt_tb/pwrite
add wave -noupdate /sl_rt_tb/pdata
add wave -noupdate /sl_rt_tb/parity0
add wave -noupdate /sl_rt_tb/parity1
add wave -noupdate /sl_rt_tb/var1
add wave -noupdate /sl_rt_tb/i
add wave -noupdate /sl_rt_tb/word
add wave -noupdate /sl_rt_tb/ini_word
add wave -noupdate /sl_rt_tb/dut/buffered_data_r
add wave -noupdate /sl_rt_tb/dut/apb_buffered_data_r
add wave -noupdate /sl_rt_tb/dut/apb_config_r
add wave -noupdate /sl_rt_tb/dut/apb_status_r
add wave -noupdate /sl_rt_tb/dut/apb_muxed_out_r
add wave -noupdate /sl_rt_tb/dut/apb_state
add wave -noupdate /sl_rt_tb/dut/shift_data_r
add wave -noupdate /sl_rt_tb/dut/cycle_cnt_r
add wave -noupdate -radix decimal /sl_rt_tb/dut/bit_cnt_r
add wave -noupdate -radix binary /sl_rt_tb/dut/state_r
add wave -noupdate /sl_rt_tb/dut/buffered_data_r
add wave -noupdate /sl_rt_tb/dut/config_r
add wave -noupdate /sl_rt_tb/dut/status_r
add wave -noupdate /sl_rt_tb/dut/parity_ones
add wave -noupdate /sl_rt_tb/dut/parity_zeroes
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5174200 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 222
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
WaveRestoreZoom {0 ps} {7008 ns}
