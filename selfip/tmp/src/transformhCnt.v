`timescale 1ns / 1ps

//--------------------------------------------
//
//  hindex is the y-direction count
//  hindex++ when a line-count PE finished
//
//--------------------------------------------

module transformhCnt#(
    parameter             C_W_WIDTH = 10,
    parameter             C_KWIDTH  = 4,
    parameter             C_SWIDTH  = 2,
    parameter             C_PWIDTH  = 2
)(
    input                         I_clk,
    input                         I_rst,
    input                         I_ap_start,
    input                         I_hcnt_flag,
    input      [C_W_WIDTH-1:0]    I_oheight,
    input      [C_KWIDTH-1:0]     I_kernel_h,
    input      [C_SWIDTH-1:0]     I_stride_h,
    input      [C_PWIDTH-1:0]     I_pad_h,
    output     [C_W_WIDTH-1:0]    O_h,
    output     [C_KWIDTH-1:0]     O_kh,
    output     [C_W_WIDTH-1:0]    O_hindex,
    output reg                    O_compute_en = 0,
    output reg                    O_last_line=0
);

reg                               S_ap_start = 0;
reg   [C_W_WIDTH-1:0]             S_hcnt     = 0;
wire  [C_W_WIDTH-1:0]             S_oheight_div;
wire  [C_W_WIDTH-1:0]             S_hcntTotal;

assign S_oheight_div = (I_oheight+I_stride_h-1)/I_stride_h;
assign S_hcntTotal = S_oheight_div*I_kernel_h+2+I_kernel_h;

always@ (posedge I_clk)
begin
    S_ap_start <= I_ap_start;
     
    if (~S_ap_start && I_ap_start)
        S_hcnt <= 'd0;
    else if (O_hindex[C_W_WIDTH-1])
        S_hcnt <= S_hcnt + 'd1;
    else if (I_hcnt_flag)
        S_hcnt <= S_hcnt + 'd1;
end

assign    O_h      = (S_hcnt/I_kernel_h)*I_stride_h;
assign    O_kh     = S_hcnt%I_kernel_h;
assign    O_hindex = O_h + O_kh - I_pad_h;

always@ (posedge I_clk)
begin
    if (~S_ap_start && I_ap_start)
        O_compute_en <= 1'b0;
    else if (S_hcnt == S_hcntTotal-1)
        O_compute_en <= 1'b0;
    else if (I_ap_start)
        O_compute_en <= 1'b1;
end

always@ (posedge I_clk)
begin
    if (~S_ap_start && I_ap_start)
        O_last_line <= 1'b0;
    else if (O_h==I_oheight-1)
        O_last_line <= 1'b1;
end

endmodule
