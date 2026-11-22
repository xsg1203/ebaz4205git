#===========================================================================
# refresh_fileset.tcl  —  新增 RTL 后刷新已打开工程的文件列表（不用关 Vivado）
#
# 在 Vivado GUI 的 Tcl Console 里执行：
#   source {D:/ebaz4205/scripts/refresh_fileset.tcl}
#
# 场景：往 rtl/ 里加了新模块后，.xpr 的文件列表不会自动更新，
#       综合会报 "module 'xxx' not found"。本脚本递归扫描 rtl/，
#       补上缺失文件、更新编译顺序、复位 synth_1/impl_1。
#===========================================================================

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]

set rtl_files [list]
foreach f [glob -nocomplain [file join $proj_root "rtl" "*.v"]] { lappend rtl_files $f }
foreach subdir {clk ctrl ov5640 imgproc video} {
    foreach f [glob -nocomplain [file join $proj_root "rtl" $subdir "*.v"]] { lappend rtl_files $f }
}

# 现有工程里的文件
set existing [get_files -quiet -filter {FILE_TYPE == Verilog}]

set added 0
foreach f $rtl_files {
    set f_norm [file normalize $f]
    set found 0
    foreach e $existing {
        if {[file normalize $e] == $f_norm} { set found 1; break }
    }
    if {!$found} {
        add_files -norecurse $f
        incr added
        puts "  added: $f"
    }
}

# 约束文件同步
foreach x [glob -nocomplain [file join $proj_root "constr" "*.xdc"]] {
    set x_norm [file normalize $x]
    set xfound 0
    foreach e [get_files -quiet -filter {FILE_TYPE == XDC}] {
        if {[file normalize $e] == $x_norm} { set xfound 1; break }
    }
    if {!$xfound} { add_files -fileset constrs_1 -norecurse $x; puts "  added xdc: $x" }
}

update_compile_order -fileset sources_1

# 复位过期的实现
reset_run synth_1
reset_run impl_1

puts "==== REFRESH OK ===="
puts "added $added RTL file(s), total RTL: [llength $rtl_files]"
