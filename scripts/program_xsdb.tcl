#===========================================================================
# program_xsdb.tcl  —  用 xsdb 通过 JTAG 烧录 bitstream（简化版）
#
# 用法：xsdb scripts/program_xsdb.tcl <bit文件路径>
#
# 本板 JTAG 链固定：target 4 = xc7z010（PL）
#  1 APU / 2-3 ARM DAP / 4 xc7z010 / 5 04900220
#===========================================================================

set bit_file [lindex $argv 0]
if {$bit_file == ""} {
    set bit_file "build_flat/ct_top.bit"
}

puts "==== connect ===="
connect

puts "==== targets ===="
puts [targets]

puts "==== select target 4 (xc7z010 PL) ===="
targets 4

puts "==== program bitstream: $bit_file ===="
fpga -file [file normalize $bit_file]

puts "==== PROGRAM DONE ===="
