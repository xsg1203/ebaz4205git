# CT-EBAZ4205 · ZYNQ-7010 多运动目标颜色识别与追踪系统

基于 EBAZ4205（XC7Z010-1CLG400I）+ 教学扩展板 + OV5640 + VGA，**纯 PL 逻辑（RTL/Verilog）** 实现的多运动目标检测与颜色识别追踪系统。

## 功能

- OV5640 实时采集 640×480@30fps（DVP 8bit + SCCB 配置，开启 AWB/AEC）
- 同一画面同时检测并分类框选不同颜色的运动目标，**边框颜色 = 物体颜色**
- 五色目标：红 / 绿 / 蓝 / 黄 / 紫（瓶盖模拟）
- 4×4 块级运动检测（帧差）+ 五色分类（块内投票）+ 连通域分离多目标
- 指定颜色单目标持续追踪（质心匹配 + 丢失保持 0.5s）
- 按键控制：key1/key2 切换追踪颜色、key3 单色追踪开关、key4 五色全框选开关
- VGA 640×480@60Hz 叠加显示 + OSD（图例 / 模式 / ID / 帧率）

## 硬件平台

| 项 | 规格 |
|---|---|
| 核心板 | EBAZ4205（Zynq-7010，`xc7z010clg400-1`） |
| 摄像头 | OV5640（DVP 8bit RGB565） |
| 显示 | VGA 电阻网络 DAC（RGB565） |
| 主时钟 | 50MHz（N18，X5 晶振） |
| 开发环境 | Vivado 2017.4 |

## 目录

```
docs/       需求规格书、架构、调试记录、测试报告
rtl/        RTL 源码（clk / ov5640 / imgproc / video / ctrl 分层）
sim/        testbench 与图像激励
constr/     XDC 约束
scripts/    建工程、编译、仿真脚本
```

### 常用脚本

| 脚本 | 用途 |
|---|---|
| `scripts/create_project.tcl` | 从零建 Vivado 工程（GUI 用） |
| `scripts/build_flat.tcl` | 无头全流程：综合 → 实现 → 生成 bit |
| `scripts/refresh_fileset.tcl` | 新增 RTL 后刷新工程文件列表 |
| `scripts/push.sh` | 推送到 GitHub（SSH，走 443 接入点） |

## 里程碑

| 里程碑 | 内容 | tag |
|---|---|---|
| M0 | 需求规格书 | `v0.1-spec` |
| M1 | 架构与模块划分 | `v0.2-arch` |
| M2 | OV5640 采集 → VGA 直显 | `v0.3-m2` |
| M3 | 五色分类 + 块统计 | — |
| M4 | 运动检测 + CCL + 框选叠加 | — |
| M5 | 单色追踪 + 按键 + OSD | — |
| M6 | 约束 + 时序收敛 | — |
| M7 | 上板调优 + 交付报告 | `v1.0` |

## 仓库

- 远端：`git@github.com:xsg1203/ebaz4205git.git`
- 推送：`./scripts/push.sh`

> SSH 走 GitHub 官方 443 接入点（`ssh.github.com:443`），避免 22 端口被网络屏蔽。
> 详见 `~/.ssh/config`。
