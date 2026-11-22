//==========================================================================
// clk_mmcm.v  —  50MHz 输入 -> 100MHz(clk_sys) + 25MHz(clk_pix) + 24MHz(clk_xclk)
//
// 手写 MMCME2_BASE 原语，避免 IP 工程文件（.xci）进版本库。
//
// 分频设计（VCO = 600MHz，全部整数分频，无占空比误差）：
//     VCO     = 50MHz x 12 / 1  = 600.000MHz
//     CLKOUT0 = 600 / 6.000     = 100.000MHz -> clk_sys  （视觉算法主时钟，M3+ 使用）
//     CLKOUT1 = 600 / 24        =  25.000MHz -> clk_pix  （VGA 640x480@59.5Hz）
//     CLKOUT2 = 600 / 25        =  24.000MHz -> clk_xclk （OV5640 输入时钟）
//
// 说明：OV_XCLK 必须是 24MHz（硬件说明 F20 标注），OV5640 初始化表中
//       0x3036=0x69 的 PLL 倍频值即按 24MHz 输入标定。
//==========================================================================
`timescale 1ns / 1ps

module clk_mmcm (
    input  wire clk50,
    input  wire rst,        // 高有效，来自顶层上电计数
    output wire clk_sys,
    output wire clk_pix,
    output wire clk_xclk,
    output wire locked
);

    wire clkfb_raw, clkfb_buf;
    wire clk_sys_raw, clk_pix_raw, clk_xclk_raw;

    MMCME2_BASE #(
        .CLKIN1_PERIOD      (20.000),
        .REF_JITTER1        (0.010),
        .DIVCLK_DIVIDE      (1),
        .CLKFBOUT_MULT_F    (12.000),   // VCO = 50 * 12 = 600MHz
        .CLKFBOUT_PHASE     (0.0),
        .CLKOUT0_DIVIDE_F   (6.000),    // 100MHz
        .CLKOUT0_DUTY_CYCLE (0.5),
        .CLKOUT0_PHASE      (0.0),
        .CLKOUT1_DIVIDE     (24),       // 25MHz (VGA)
        .CLKOUT1_DUTY_CYCLE (0.5),
        .CLKOUT1_PHASE      (0.0),
        .CLKOUT2_DIVIDE     (25),       // 24MHz (OV5640 XCLK)
        .CLKOUT2_DUTY_CYCLE (0.5),
        .CLKOUT2_PHASE      (0.0),
        .CLKOUT3_DIVIDE     (1),
        .CLKOUT4_DIVIDE     (1),
        .CLKOUT5_DIVIDE     (1),
        .CLKOUT4_CASCADE    ("FALSE"),
        .STARTUP_WAIT       ("FALSE")
    ) u_mmcm (
        .CLKIN1    (clk50),
        .CLKFBIN   (clkfb_buf),
        .CLKFBOUT  (clkfb_raw),
        .CLKFBOUTB (),
        .CLKOUT0   (clk_sys_raw),
        .CLKOUT0B  (),
        .CLKOUT1   (clk_pix_raw),
        .CLKOUT1B  (),
        .CLKOUT2   (clk_xclk_raw),
        .CLKOUT2B  (),
        .CLKOUT3   (),
        .CLKOUT3B  (),
        .CLKOUT4   (),
        .CLKOUT5   (),
        .CLKOUT6   (),
        .LOCKED    (locked),
        .PWRDWN    (1'b0),
        .RST       (rst)
    );

    BUFG u_bufg_fb   (.I(clkfb_raw),    .O(clkfb_buf));
    BUFG u_bufg_sys  (.I(clk_sys_raw),  .O(clk_sys));
    BUFG u_bufg_pix  (.I(clk_pix_raw),  .O(clk_pix));
    BUFG u_bufg_xclk (.I(clk_xclk_raw), .O(clk_xclk));

endmodule
