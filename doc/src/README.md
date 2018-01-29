
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
|ApbCommunicator        |Связывает апб с буферами             |[в работе][ApbSpec]  |не создан            |[src][ApbRtl]  |[TB][ApbTb]

[TopSpec]:    spec_SlTransiever.adoc
[TopTest]:    testplan_SlTransiever.adoc
[TransSpec]:  spec_SlTransmitter.adoc
[TransTest]:  testplan_SlTransmitter.adoc
[RecSpec]:    spec_SlReciever.adoc
[RecTest]:    testplan_SlReciever.adoc
[RoutSpec]:   spec_Router.adoc
[ApbSpec]:    spec_ApbCommunicator.adoc

[MainRtl]:../../rtl/SlTransiever.v
[MainTb]:../../bench/hdl/SLTransieverTB.sv
[RoutRtl]:../../rtl/Router.v
[RoutTb]:../../bench/hdl/RouterTB.sv
[RecRtl]:../../rtl/SlReceiver.v
[RecTb]:../../bench/hdl/SLReceiverTb.sv
[TransRtl]:../../rtl/SlTransmitter.v
[TransTb]:../../bench/hdl/SLTransmitterTB.sv
[ApbRtl]:../../rtl/ApbCommunicator.v
[ApbTb]:../../bench/hdl/ApbCommunicatorTb.sv
[FifoRtl]:../../rtl/AsyncFifo.v
[FifoTb]:../../bench/hdl/AsyncFifoTb.sv
