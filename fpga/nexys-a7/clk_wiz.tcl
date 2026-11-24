# clk_wiz_0: the 100 MHz board clock (E3) -> 25 MHz, the Tiny Tapestation's clock (info.yaml
# clock_hz) and close to the 25.175 MHz of 640x480 VGA. Sourced by build.tcl; expects
# $ipdir to be set. Ports used by tts_fpga_top.v: reset, clk_in1, clk_out1.
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0 -dir $ipdir
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_HIGH} \
] [get_ips clk_wiz_0]
