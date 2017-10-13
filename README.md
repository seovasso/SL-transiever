# SL-transiever
Данный проект направлен на реализацию кода приемопередатчика SL-канала с выходом на шину APB.


Пользователю доступно четыре регистра:


config_r[15:0]  //[0] - parity check, [6:1] - bit cnt(8-32bits), [7] - rxtx mode, [8] - IRQ mode ####address on config_r is 0 (zero)


status_r[15:0] //[0] - word length fail, [1] - word receiveing process going, [2] - empty, [3] - word received, [4] - parity error, [5] - level error on line,


data_to_send_r[31:0] // data to transmit


buffered_data_r[31:0] //received data
