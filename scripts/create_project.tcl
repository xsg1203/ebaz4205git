#===========================================================================
# create_project.tcl  —  从零创建 Vivado 工程（GUI 模式）
#
# 用法（在工程根目录 D:/ebaz4205 下执行）：
#   vivado -mode batch -source scripts/create_project.tcl
#
# 生成：build/ct_ebaz4205.xpr
#===========================================================================

set part "xc7z010clg400-1"

# 获取脚本所在目录的上级（工程根目录）
set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file dirname $script_dir]
set build_dir  [file join $proj_root "build"]

# 若已存在旧工程则先删除
file delete -force $build_dir
file mkdir $build_dir

create_project ct_ebaz4205 $build_dir -part $part -force

# 设置顶层模块
set_property top ct_top [current_fileset]

# 收集所有 RTL 源文件
set rtl_files [glob -nocomplain [file join $proj_root "rtl" "*.v"]]
foreach subdir {clk ctrl ov5640 imgproc video} {
    set subfiles [glob -nocomplain [file join $proj_root "rtl" $subdir "*.v"]]
    set rtl_files [concat $rtl_files $subfiles]
}

if {[llength $rtl_files] > 0} {
    add_files -norecurse $rtl_files
} else {
    puts "ERROR: no RTL files found under rtl/"
    exit 1
}

# 添加约束文件
set xdc_files [glob -nocomplain [file join $proj_root "constr" "*.xdc"]]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 -norecurse $xdc_files
}

# 更新编译顺序（自动分析依赖）
update_compile_order -fileset sources_1

puts "==== PROJECT CREATED ===="
puts "RTL files : [llength $rtl_files]"
puts "XDC files : [llength $xdc_files]"
puts "Project   : $build_dir/ct_ebaz4205.xpr"
