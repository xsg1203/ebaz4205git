//==========================================================================
// ov5640_cfg.v  —  OV5640 上电配置序列（DVP / RGB565 / 640x480 / 30fps）
//
// 表项格式 24 位：{ADDR[15:0], DATA[7:0]}，特殊码：
//   24'hFFFFFF = 序列结束
//   24'hFFFFFE = 纯延时 5ms
//
// 关键配置（已被上板验证合法）：
//   - 0x3017=0xFF / 0x3018=0xFC：DVP 引脚方向全部设为"输出"
//     （写 0x00 会让传感器一条线都不驱动，表现为假同步 + 无像素）
//   - 0x3808~0x380B：输出 640x480
//   - 0x4300=0x6F：RGB565 输出
//   - 0x3035/0x3036：PLL，按 24MHz 输入标定
//   - 0x3503=0x00 / 0x3406=0x00：AEC/AWB 全自动
//   - 0x4202=0x00：开流（不写这一条可能导致 PCLK 在跑但一行数据都不输出）
//   - 0x300E=0x58：DVP 接口使能（0x45=MIPI，勿写反）
//==========================================================================
`timescale 1ns / 1ps

module ov5640_cfg (
    input  wire        clk,
    input  wire        rst_n,
    output reg         go,
    output reg  [15:0] o_reg,
    output reg  [7:0]  o_dat,
    input  wire        busy,
    input  wire        done,
    input  wire        ack_err,
    output reg         cfg_done,
    output reg  [7:0]  err_cnt      // SCCB 无 ACK 次数（应为 0）
);

    localparam [23:0] END_CODE = 24'hFFFFFF;
    localparam [23:0] DLY_CODE = 24'hFFFFFE;

    localparam [2:0] S_INIT = 3'd0,
                     S_GO   = 3'd1,
                     S_WAIT = 3'd2,
                     S_GAP  = 3'd3,
                     S_END  = 3'd4;

    reg [2:0]  st;
    reg [8:0]  idx;
    reg [18:0] gap;

    wire [23:0] ent = cfg_rom(idx);

    //----------------------------------------------------------------------
    // 寄存器表 {ADDR[15:0], DATA[7:0]}
    //----------------------------------------------------------------------
    function [23:0] cfg_rom;
        input [8:0] i;
        begin
            case (i)
            //===== 1. 上电时序：软复位 =====
            9'd0  : cfg_rom = {16'h3103, 8'h03};
            9'd1  : cfg_rom = {16'h3008, 8'h82};   // 软复位（bit7=1 + bit6=休眠）
            9'd2  : cfg_rom = DLY_CODE;            // 必须等 >=5ms
            9'd3  : cfg_rom = {16'h3008, 8'h02};   // 正常模式（bit7=0退出复位, bit6=0退出休眠）
            9'd4  : cfg_rom = {16'h3103, 8'h03};

            //===== 2. 输出引脚方向：必须全部设为"输出" =====
            9'd5  : cfg_rom = {16'h3017, 8'hFF};   // VSYNC/HREF/PCLK/D[9:6] 输出
            9'd6  : cfg_rom = {16'h3018, 8'hFC};   // D[5:0] 输出，GPIO 输入
            9'd7  : cfg_rom = {16'h3034, 8'h1A};   // PLL 根分频 / MIPI bit 模式
            9'd8  : cfg_rom = {16'h3037, 8'h13};   // PLL 预分频
            9'd9  : cfg_rom = {16'h3108, 8'h01};   // PCLK 根分频

            //===== 3. 模拟前端标定 =====
            9'd10 : cfg_rom = {16'h3630, 8'h36};
            9'd11 : cfg_rom = {16'h3631, 8'h0E};
            9'd12 : cfg_rom = {16'h3632, 8'hE2};
            9'd13 : cfg_rom = {16'h3633, 8'h12};
            9'd14 : cfg_rom = {16'h3621, 8'hE0};
            9'd15 : cfg_rom = {16'h3704, 8'hA0};
            9'd16 : cfg_rom = {16'h3703, 8'h5A};
            9'd17 : cfg_rom = {16'h3715, 8'h78};
            9'd18 : cfg_rom = {16'h3717, 8'h01};
            9'd19 : cfg_rom = {16'h370B, 8'h60};
            9'd20 : cfg_rom = {16'h3705, 8'h1A};
            9'd21 : cfg_rom = {16'h3905, 8'h02};
            9'd22 : cfg_rom = {16'h3906, 8'h10};
            9'd23 : cfg_rom = {16'h3901, 8'h0A};
            9'd24 : cfg_rom = {16'h3731, 8'h02};
            9'd25 : cfg_rom = {16'h3600, 8'h08};
            9'd26 : cfg_rom = {16'h3601, 8'h33};
            9'd27 : cfg_rom = {16'h302D, 8'h60};
            9'd28 : cfg_rom = {16'h3620, 8'h52};
            9'd29 : cfg_rom = {16'h371B, 8'h20};
            9'd30 : cfg_rom = {16'h471C, 8'h50};
            9'd31 : cfg_rom = {16'h3A13, 8'h43};
            9'd32 : cfg_rom = {16'h3A18, 8'h00};

            //===== 4. AEC / AWB 上限（写 0x07 会导致曝光压到最小、图像全黑）=====
            9'd33 : cfg_rom = {16'h3A19, 8'hF8};   // AEC 最大增益上限
            9'd34 : cfg_rom = {16'h3635, 8'h13};
            9'd35 : cfg_rom = {16'h3636, 8'h03};
            9'd36 : cfg_rom = {16'h3634, 8'h40};
            9'd37 : cfg_rom = {16'h3622, 8'h01};
            9'd38 : cfg_rom = {16'h3C01, 8'h34};   // AEC/AGC 控制
            9'd39 : cfg_rom = {16'h3C04, 8'h28};   // AEC 上限（高字节）
            9'd40 : cfg_rom = {16'h3C05, 8'h98};   // AEC 上限（低字节）
            9'd41 : cfg_rom = {16'h3C06, 8'h00};
            9'd42 : cfg_rom = {16'h3C07, 8'h08};
            9'd43 : cfg_rom = {16'h3C08, 8'h00};
            9'd44 : cfg_rom = {16'h3C09, 8'h1C};
            9'd45 : cfg_rom = {16'h3C0A, 8'h9C};
            9'd46 : cfg_rom = {16'h3C0B, 8'h40};

            //===== 5. 时序极性 / 镜像 / 子采样 =====
            // 0x3820/0x3821：镜像与翻转控制（小梅哥官方定义）。
            //   0x3820：0x40=不翻转，0x47=上下翻转
            //   0x3821：0x00=左右镜像，0x07=不镜像
            //   当前模组仍翻转 -> 尝试"上下翻转+左右镜像"组合（对角翻转）
            9'd47 : cfg_rom = {16'h3820, 8'h47};
            9'd48 : cfg_rom = {16'h3821, 8'h00};
            9'd49 : cfg_rom = {16'h3814, 8'h31};
            9'd50 : cfg_rom = {16'h3815, 8'h31};

            //===== 6. 输出窗口 2624x1952 -> 640x480 =====
            9'd51 : cfg_rom = {16'h3800, 8'h00};   // X start = 0
            9'd52 : cfg_rom = {16'h3801, 8'h00};
            9'd53 : cfg_rom = {16'h3802, 8'h00};   // Y start = 0x0004
            9'd54 : cfg_rom = {16'h3803, 8'h04};
            9'd55 : cfg_rom = {16'h3804, 8'h0A};   // X end = 0x0A3F = 2623
            9'd56 : cfg_rom = {16'h3805, 8'h3F};
            9'd57 : cfg_rom = {16'h3806, 8'h07};   // Y end = 0x07A3 = 1955
            9'd58 : cfg_rom = {16'h3807, 8'hA3};
            9'd59 : cfg_rom = {16'h3808, 8'h02};   // 输出宽 = 0x0280 = 640
            9'd60 : cfg_rom = {16'h3809, 8'h80};
            9'd61 : cfg_rom = {16'h380A, 8'h01};   // 输出高 = 0x01E0 = 480
            9'd62 : cfg_rom = {16'h380B, 8'hE0};
            9'd63 : cfg_rom = {16'h380C, 8'h07};   // HTS = 1896
            9'd64 : cfg_rom = {16'h380D, 8'h68};
            9'd65 : cfg_rom = {16'h380E, 8'h03};   // VTS = 0x03D8 = 984（30fps）
            9'd66 : cfg_rom = {16'h380F, 8'hD8};
            9'd67 : cfg_rom = {16'h3810, 8'h00};   // ISP X offset 高字节
            9'd68 : cfg_rom = {16'h3811, 8'h10};   // ISP X offset 低字节（0x0010）
            9'd69 : cfg_rom = {16'h3812, 8'h00};   // ISP Y offset 高字节
            9'd70 : cfg_rom = {16'h3813, 8'h06};   // ISP Y offset 低字节（0x0006）

            //===== 7. 黑电平 / 镜头阴影校正 =====
            9'd71 : cfg_rom = {16'h3618, 8'h00};
            9'd72 : cfg_rom = {16'h3619, 8'h99};
            9'd73 : cfg_rom = {16'h3708, 8'h63};
            9'd74 : cfg_rom = {16'h3709, 8'h52};
            9'd75 : cfg_rom = {16'h370C, 8'h03};

            //===== 8. 系统时钟与 DVP 输出配置 =====
            9'd76 : cfg_rom = {16'h3002, 8'h1C};
            9'd77 : cfg_rom = {16'h3006, 8'hC3};
            9'd78 : cfg_rom = {16'h300E, 8'h58};   // 接口模式：0x58=DVP使能/MIPI关，0x45=MIPI使能（勿写反）
            9'd79 : cfg_rom = {16'h302E, 8'h00};

            //===== 9. 输出格式：RGB565 / ISP 输出 RGB =====
            9'd80 : cfg_rom = {16'h4300, 8'h61};   // RGB565 高字节在前{R,G5:3}+{G2:0,B}，匹配 {b1,data} 拼接（0x6F=字节序颠倒）
            9'd81 : cfg_rom = {16'h501F, 8'h01};   // ISP 输出格式 = RGB
            9'd82 : cfg_rom = {16'h4713, 8'h03};
            9'd83 : cfg_rom = {16'h4407, 8'h04};
            9'd84 : cfg_rom = {16'h440E, 8'h00};
            9'd85 : cfg_rom = {16'h460B, 8'h35};   // DVP PCLK 分频
            9'd86 : cfg_rom = {16'h460C, 8'h22};
            9'd87 : cfg_rom = {16'h4837, 8'h22};
            9'd88 : cfg_rom = {16'h3824, 8'h02};   // DVP PCLK 手动分频使能

            //===== 10. ISP 模块使能 =====
            9'd89 : cfg_rom = {16'h5000, 8'hA7};   // LENC/BPC/WPC/CIP
            9'd90 : cfg_rom = {16'h5001, 8'hA3};   // 白平衡/色彩校正

            //===== 11. 自动曝光/自动白平衡：必须置自动 =====
            9'd91 : cfg_rom = {16'h3503, 8'h00};   // 0x00 = AEC/AGC 全自动
            9'd92 : cfg_rom = {16'h3406, 8'h00};   // 0x00 = AWB 自动

            //===== 12. 测试图案（调试开关）=====
            9'd93 : cfg_rom = {16'h503D, 8'h00};   // 0x00=正常输出，0x80=传感器内部彩条（调试 DVP 链路用）

            //===== 13. PLL 起振（必须在模拟/窗口之后）=====
            9'd94 : cfg_rom = {16'h3035, 8'h11};
            9'd95 : cfg_rom = {16'h3036, 8'h69};   // PLL 倍频（24MHz 输入标定）
            9'd96 : cfg_rom = {16'h3037, 8'h13};
            9'd97 : cfg_rom = {16'h3108, 8'h01};

            //===== 14. 开始输出图像 =====
            9'd98 : cfg_rom = {16'h3008, 8'h02};   // bit6=0 退出 power down
            9'd99 : cfg_rom = {16'h4202, 8'h00};   // 开流

            9'd100 : cfg_rom = END_CODE;
            default: cfg_rom = END_CODE;
            endcase
        end
    endfunction

    //----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= S_INIT;
            idx      <= 9'd0;
            go       <= 1'b0;
            gap      <= 19'd0;
            o_reg    <= 16'd0;
            o_dat    <= 8'd0;
            cfg_done <= 1'b0;
            err_cnt  <= 8'd0;
        end else begin
            go <= 1'b0;
            case (st)
                S_INIT: begin
                    if (ent == END_CODE) begin
                        cfg_done <= 1'b1;
                        st       <= S_END;
                    end else if (ent == DLY_CODE) begin
                        gap <= 19'd250000;          // 5ms @50MHz
                        st  <= S_GAP;
                    end else begin
                        o_reg <= ent[23:8];
                        o_dat <= ent[7:0];
                        st    <= S_GO;
                    end
                end
                S_GO: begin
                    go <= 1'b1;
                    st <= S_WAIT;
                end
                S_WAIT: begin
                    if (done) begin
                        if (ack_err) err_cnt <= err_cnt + 8'd1;
                        gap <= 19'd2000;            // 40us 字节间隔
                        st  <= S_GAP;
                    end
                end
                S_GAP: begin
                    if (gap == 19'd0) begin
                        idx <= idx + 9'd1;
                        st  <= S_INIT;
                    end else begin
                        gap <= gap - 19'd1;
                    end
                end
                S_END: st <= S_END;
                default: st <= S_INIT;
            endcase
        end
    end

endmodule
