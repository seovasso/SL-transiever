
# Документация
Данный раздел содержит исходники документации на SlTranciever

## Структурная схема СФ блока
![Структрная схема](../img/SlTrancieverStructure.png)

## Список документации на элементы, входящие в СФ-блок

|Модуль                 |Описание                             |Спецификация         |Тест план            |rtl описание   | Тестовое окружение
|-----------------------|-------------------------------------|---------------------|---------------------|-------------- |--------------------
|SlTransiever           |Верхний уровень СФ-блока             |[в работе][TopSpec]  |[в работе][TopTest]  |[src][MainRtl] |[TB][MainTb]             
|SlTransmitter          |Передатчик                           |[в работе][TransSpec]|[в работе][TransTest]|[src][TransRtl]|[TB][TransTb]             
|SlReciever             |Приемник                             |[в работе][RecSpec]  |[в работе][RecTest]  |[src][RecRtl]  |[TB][RecTb]            
|Router                 |Управляет приемниками и передатчиками|[в работе][RoutSpec] |не создан            |[src][RoutRtl] |[TB][RoutTb]
|AsyncFifo              |Асинхронный буфер                    |не создана           |не создан            |[src][FifoRtl] |[TB][FifoTb]
|ApbCommunicator        |Связывает апб с буферами             |[в работе][ApbSpec]  |не создан            |[src][ApbRtl]  |[src][ApbTb]

[TopSpec]: sl_tranciever_spec.adoc
[TopTest]: apb_sl_brdige_test_plan.adoc
[TransSpec]: sl_tx_spec.adoc
[TransTest]: sl_tx_test_plan.adoc
[RecSpec]: sl_rx_spec.adoc
[RecTest]: sl_rx_test_plan.adoc
[RoutSpec]: router_spec.adoc
[ApbSpec]: apb_2_fifo_spec.adoc

[MainRtl]:../../rtl/SlTransiever.v
[MainTb]:../../bench/hdl/SLTransieverTB.sv
[RoutRtl]:../../rtl/Router.v
[RoutTb]:../../bench/hdl/RouterTB.sv
[RecRtl]:../../rtl/SlReciever.v
[RecTb]:../../bench/hdl/SlRecieverTB.sv
[TransRtl]:../../rtl/SlTransmitter.v
[TransTb]:../../bench/hdl/SltransmitterTB.sv
[ApbRtl]:../../rtl/ApbCommunicator.v
[ApbTb]:../../bench/hdl/ApbCommunicatorTB.sv
[FifoRtl]:../../rtl/AsyncFifo.v
[FifoTb]:../../bench/hdl/AsyncFifoTb.sv
