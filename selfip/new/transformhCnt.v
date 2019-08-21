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
    output reg [C_W_WIDTH-1:0]    O_h,
    output reg [C_KWIDTH-1:0]     O_kh,
    output reg [C_W_WIDTH-1:0]    O_hindex=0,
    output reg                    O_compute_en = 0,
    output                        O_compute_en_real,
    output reg                    O_last_line=0
);

reg                               S_ap_start = 0;
reg   [C_W_WIDTH-1:0]             S_hcnt     = 0;
reg   [C_W_WIDTH-1:0]             S_oheight_div=0;
reg   [C_W_WIDTH-1:0]             S_hcntTotal=0;
reg                               S_compute_en = 0;
reg                               S_compute_en_d1 = 0;

wire  [47:0]                      S_hcntTotal_tmp0;

dsp_unit1 dsp_unit_inst0(
    .I_clk              (I_clk),
    .I_weight_l         ({{20{S_oheight_div[C_W_WIDTH-1]}},S_oheight_div}),
    .I_weight_h         (27'd0),
    .I_1feature         ({{14{I_kernel_h[C_KWIDTH-1]}},I_kernel_h}),
    .I_pi_cas           (48'd2),
    .O_pi               (),
    .O_p                (S_hcntTotal_tmp0)
    );

always@ (posedge I_clk)
begin
//    S_oheight_div <= (I_oheight+I_stride_h-1)/I_stride_h;
    S_oheight_div <= I_oheight+I_stride_h-1;
    S_hcntTotal <= S_hcntTotal_tmp0+I_kernel_h;
end

always@ (posedge I_clk)
begin
    S_ap_start <= I_ap_start;
     
    if (~S_ap_start && I_ap_start)
        S_hcnt <= 'd0;
    else if (O_hindex[C_W_WIDTH-1] && O_compute_en && S_compute_en && !S_compute_en_d1)
        S_hcnt <= S_hcnt + 'd1;
    else if (I_hcnt_flag)
        S_hcnt <= S_hcnt + 'd1;
end

always@ (posedge I_clk)
    O_hindex <= O_h + O_kh - I_pad_h;

always@ (posedge I_clk)
begin
    if (~S_ap_start && I_ap_start)
        O_h <= 'd0;
    else
//        O_h <= (S_hcnt/I_kernel_h)*I_stride_h;
        O_h <= (S_hcnt/3)*I_stride_h;

//        O_kh <= S_hcnt%I_kernel_h;
        O_kh <= S_hcnt%3;
end

always@ (posedge I_clk)
begin
    S_compute_en <= O_compute_en;
    S_compute_en_d1 <= S_compute_en;
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

assign O_compute_en_real = S_compute_en_d1;

endmodule
