#===========================================================================
# build_flat.tcl  —  无头全流程：综合 -> 实现 -> 生成 bitstream
#
# 不依赖 .xpr 工程文件，直接读源码，适合命令行快速验证。
# 用法（在工程根目录 D:/ebaz4205 下执行）：
#   vivado -mode batch -source scripts/build_flat.tcl
#
# 输出：build_flat/ct_top.bit（以及 .rpt 报告）
#===========================================================================

set part "xc7z010clg400-1"

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]
set out_dir    [file join $proj_root "build_flat"]

file delete -force $out_dir
file mkdir $out_dir

# 读入所有 RTL 源文件
set rtl_files [list]
foreach f [glob -nocomplain [file join $proj_root "rtl" "*.v"]] { lappend rtl_files $f }
foreach subdir {clk ctrl ov5640 imgproc video} {
    foreach f [glob -nocomplain [file join $proj_root "rtl" $subdir "*.v"]] { lappend rtl_files $f }
}

puts "==== reading [llength $rtl_files] RTL files ===="
foreach f $rtl_files { puts "  read: $f" }
read_verilog $rtl_files

# 读入约束
foreach x [glob -nocomplain [file join $proj_root "constr" "*.xdc"]] {
    puts "  xdc: $x"
    read_xdc $x
}

# 综合
synth_design -top ct_top -part $part
write_checkpoint -force [file join $out_dir "post_synth.dcp"]

# 报告时序（综合后）
report_timing_summary -file [file join $out_dir "synth_timing.rpt"]

# 实现
opt_design
place_design
route_design
write_checkpoint -force [file join $out_dir "post_route.dcp"]

# 实现后时序/资源报告
report_timing_summary -file [file join $out_dir "impl_timing.rpt"]
report_utilization   -file [file join $out_dir "impl_utilization.rpt"]

# 生成 bitstream
write_bitstream -force [file join $out_dir "ct_top.bit"]

puts "==== BUILD DONE ===="
puts "bitstream: $out_dir/ct_top.bit"
