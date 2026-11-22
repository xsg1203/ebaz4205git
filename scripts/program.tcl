#===========================================================================
# program.tcl  —  通过 JTAG 探测并烧录 bitstream
#
# 前置：hw_server 已启动（默认端口 3121）
# 用法：
#   vivado -mode batch -source scripts/program.tcl -tclargs <bit文件路径>
#===========================================================================

set bit_file [lindex $argv 0]
if {$bit_file == ""} {
    set bit_file "build_flat/ct_top.bit"
}

puts "==== JTAG 探测 ===="
open_hw_manager
connect_hw_server -url localhost:3121
set targets [get_hw_targets *]
puts "发现 targets: $targets"

if {[llength $targets] == 0} {
    puts "ERROR: 未发现任何 JTAG target，请检查下载器连接与上电"
    exit 1
}

current_hw_target [lindex $targets 0]
open_hw_target

set devices [get_hw_devices *]
puts "发现 devices: $devices"

if {[llength $devices] == 0} {
    puts "ERROR: 未发现任何 device，请检查下载器与核心板连接"
    exit 1
}

# 找到 Zynq 器件（xc7z010）
set zynq_dev ""
foreach d $devices {
    set part [get_property PART $d]
    puts "  device: $d  part=$part"
    if {[string match "xc7z010*" $part]} {
        set zynq_dev $d
    }
}
if {$zynq_dev == ""} {
    set zynq_dev [lindex $devices 0]
}

puts "==== 烧录 $bit_file 到 $zynq_dev ===="
set_property PROGRAM.FILE [file normalize $bit_file] $zynq_dev
program_hw_devices $zynq_dev

puts "==== PROGRAM DONE ===="
