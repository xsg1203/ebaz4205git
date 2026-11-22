//==========================================================================
// ov5640_capture.v  —  DVP 8bit -> RGB565 像素流
//
// OV5640 在 RGB565 模式下每像素两字节：
//   字节1 = {R[4:0], G[5:3]}   字节2 = {G[2:0], B[4:0]}
// 拼接后 pix = {R[4:0], G[5:3], G[2:0], B[4:0]}，与 VGA 输出位序一致。
//
// 坐标管理（关键）：
//   - VSYNC 上升沿（frame_start）：清零 xcnt/ycnt。
//   - HREF 上升沿：清零 xcnt（新的一行从第 0 列开始），byte_sel 复位。
//   - HREF 高电平期间：每 2 字节合成 1 像素，xcnt 递增，ycnt 保持当前行号。
//   - HREF 下降沿：ycnt 递增（进入下一行）。
//==========================================================================
`timescale 1ns / 1ps

module ov5640_capture (
    input  wire        pclk,
    input  wire        rst_n,
    input  wire        vsync,       // 高有效，帧同步
    input  wire        href,        // 高有效，行有效
    input  wire [7:0]  data,
    output reg  [15:0] pix,
    output reg         pix_vld,     // 单拍，pix / cx / cy 同时有效
    output reg  [9:0]  cx,
    output reg  [9:0]  cy,
    output reg         frame_start  // VSYNC 上升沿单拍
);

    reg        vsync_d, href_d;
    reg        byte_sel;
    reg [7:0]  b1;
    reg [9:0]  xcnt, ycnt;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_d     <= 1'b0;
            href_d      <= 1'b0;
            byte_sel    <= 1'b0;
            b1          <= 8'd0;
            pix         <= 16'd0;
            pix_vld     <= 1'b0;
            cx          <= 10'd0;
            cy          <= 10'd0;
            xcnt        <= 10'd0;
            ycnt        <= 10'd0;
            frame_start <= 1'b0;
        end else begin
            vsync_d     <= vsync;
            href_d      <= href;
            pix_vld     <= 1'b0;
            frame_start <= vsync & ~vsync_d;

            if (vsync) begin
                // 帧同步：VSYNC 高电平期间，坐标整体清零
                xcnt     <= 10'd0;
                ycnt     <= 10'd0;
                byte_sel <= 1'b0;
            end else if (href) begin
                // 行有效期间（含 HREF 上升沿第一拍）：连续采集字节对。
                // 不区分 HREF 上升沿，而是纯靠 byte_sel 在字节对之间翻转，
                // 保证不丢字节、字节对不错位。
                if (!byte_sel) begin
                    b1       <= data;       // 第一个字节（高字节）
                    byte_sel <= 1'b1;
                end else begin
                    pix      <= {b1, data}; // 合成 RGB565
                    pix_vld  <= 1'b1;
                    cx       <= xcnt;
                    cy       <= ycnt;
                    xcnt     <= xcnt + 10'd1;
                    byte_sel <= 1'b0;
                end
            end else begin
                // 行结束：复位字节对，行号递增
                byte_sel <= 1'b0;
                if (href_d) begin
                    xcnt <= 10'd0;          // 新行列号清零
                    ycnt <= ycnt + 10'd1;   // 行号递增
                end
            end
        end
    end

endmodule
