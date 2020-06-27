# WS2812b4FPGA
WS2812b verilog control IP for 50MHz clock.
The linetransmitter module requires an external memory for data and provides the address output buss.
The address value changes each time the next LED is going to be transmitted.

Address wide is the parameter to determine the address capasity and represents the bit size of the buss width.
External memory required to provide next LED value immediately the address changed.

The module is developed with icarus verilog and GTKWave.
The module is tested on Cyclone V SoC 5CSEMA4U23 (DE0-Nano-SoC board)

See the main module for usage example.
