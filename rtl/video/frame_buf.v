//==========================================================================
// frame_buf.v  —  320x240x16bit 单帧双口缓存（写 ov_pclk 域 / 读 clk_pix 域）
//
// 76800 x 16bit = 1,228,800 bit -> 34 x BRAM36（Zynq-7010 共 60 块）
// 读侧 1 拍延迟：调用方需同步延迟 hsync/vsync/de 各 1 拍。
//
// 640x480 采集经 2x2 点采样降采样到 320x240 存入，VGA 端 2x2 放大显示。
//==========================================================================
`timescale 1ns / 1ps

module frame_buf (
    // 写侧（ov_pclk 域）
    input  wire        wr_clk,
    input  wire        wr_en,
    input  wire [16:0] wr_addr,     // 0 .. 76799
    input  wire [15:0] wr_data,
    // 读侧（clk_pix 域）
    input  wire        rd_clk,
    input  wire [16:0] rd_addr,
    output reg  [15:0] rd_data
);

    reg [15:0] mem [0:76799];

    always @(posedge wr_clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
    end

    always @(posedge rd_clk) begin
        rd_data <= mem[rd_addr];
    end

endmodule
