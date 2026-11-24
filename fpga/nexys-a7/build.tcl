# Non-project Vivado build of the Tiny Tapestation for the Nexys A7.
#   vivado -mode batch -source build.tcl -tclargs <part> <chip sources...>
# The Makefile passes the part and the chip's sources from info.yaml (source_files).
set here [file dirname [file normalize [info script]]]
set part [lindex $argv 0]
set srcs [lrange $argv 1 end]
set out  $here/build
set ipdir $out/ip
file mkdir $out $ipdir

create_project -in_memory -part $part

source $here/clk_wiz.tcl
generate_target all [get_ips clk_wiz_0]
synth_ip [get_ips clk_wiz_0]

read_verilog $srcs
read_verilog $here/tts_fpga_top.v
read_xdc $here/nexys_a7.xdc

synth_design -top TTS_FPGA_top -part $part
opt_design
place_design
route_design
report_utilization    -file $out/utilization.rpt
report_timing_summary -file $out/timing.rpt
write_bitstream -force $out/tts_nexys_a7.bit
puts "Bitstream: $out/tts_nexys_a7.bit"
