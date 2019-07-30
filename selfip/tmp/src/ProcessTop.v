`timescale 1ns / 1ps

module ProcessTop#(
parameter          AXIWIDTH   = 128,
parameter          LITEWIDTH  = 32,
parameter          CH_IN      = 16,
parameter          DWIDTH     = 8,
parameter          CH_OUT     = 32,
parameter          PIX        = 8,
parameter          ADD_WIDTH  = 19,
parameter          LAYERWIDTH = 8,
parameter          KWIDTH     = 4,
parameter          COWIDTH    = 10,
parameter          DEPTHWIDTH = 9,
parameter          PWIDTH     = 2
)(
    input                            I_clk,
    input                            I_rst,
    input   [AXIWIDTH*8-1:0]         I_feature,
    input                            I_feature_dv,
    
    input   [DEPTHWIDTH:0]           I_coAlign,
    input   [DEPTHWIDTH:0]           I_ciAlign,
    input   [DEPTHWIDTH-1:0]         I_woGroup,
    input   [DEPTHWIDTH-1:0]         I_coGroup,
    input   [DEPTHWIDTH-1:0]         I_ciGroup, 
    
    input   [LAYERWIDTH-1:0]         I_layer_num,
    input   [LITEWIDTH-1:0]          I_ci_num,
    input   [LITEWIDTH-1:0]          I_co_num,
    input   [LITEWIDTH-1:0]          I_kx_num,
    input   [LITEWIDTH-1:0]          I_ky_num,
    input   [LITEWIDTH-1:0]          I_owidth_num,
    input                            I_ap_start,
    input                            I_compute_en,
    input                            I_line_end,
    input   [AXIWIDTH-1:0]           I_weight,
    input                            I_weight_dv,
    
    input   [DEPTHWIDTH-1:0]         I_rd_wdepth,
    input   [DEPTHWIDTH-1:0]         I_rd_fdepth,
    input                            I_rd_dv,
    
    input   [KWIDTH-1:0]             I_ky,
    input   [PWIDTH-1:0]             I_pad,
    output                           O_load_done,
    output                           O_line_end_flag,
    output                           O_kx_end_flag,
    output  [24*CH_OUT*PIX-1:0]      O_result_0,
    output  [24*CH_OUT*PIX-1:0]      O_result_1,
    output                           O_data_dv,
    output  [24*CH_OUT*PIX-1:0]      O_macc_data,
    output  [DEPTHWIDTH-1:0]         O_rd_fdepth,
    output                           O_rd_dv
);

wire  [DWIDTH*CH_OUT*CH_IN-1:0]  S_weight;
wire  [DWIDTH*CH_IN*PIX-1:0]     S_fout;
wire  [DEPTHWIDTH-1:0]           S_woGroup;
wire  [DEPTHWIDTH-1:0]           S_coGroup;
wire  [DEPTHWIDTH-1:0]           S_ciGroup;
wire  [DEPTHWIDTH-1:0]           S_rd_wdepth;
wire  [DEPTHWIDTH-1:0]           S_rd_fdepth;
wire                             S_rd_dv;
wire                             S_f_rdy;
wire                             S_cpt_dv;
wire  [24*CH_OUT*PIX-1:0]        S_result_tmp;
wire                             S_result_dv;

assign  O_rd_fdepth = S_rd_fdepth;
assign  O_rd_dv = S_rd_dv;

weight_load_update#(
    .AXIWIDTH         (AXIWIDTH),
    .LITEWIDTH        (LITEWIDTH),
    .CH_IN            (CH_IN),
    .CH_OUT           (CH_OUT),
    .PIX              (PIX),
    .LAYERWIDTH       (LAYERWIDTH),
    .KWIDTH           (KWIDTH),
    .COWIDTH          (COWIDTH),
    .DWIDTH           (DWIDTH)
)weight_load_update_inst(

    .I_clk            (I_clk),
    .I_rst            (I_rst),
    .I_layer_num      (I_layer_num),
    .I_ci_num         (I_ci_num),
    .I_co_num         (I_co_num),
    .I_kxk_num        (I_kx_num*I_ky_num),
    .I_ap_start       (I_ap_start),
    .I_weight         (I_weight),
    .I_weight_dv      (I_weight_dv),
    .I_rd_dv          (I_feature_dv),
    .I_rd_wdepth      (I_rd_wdepth),
    .O_load_done      (O_load_done),
    .O_weight         (S_weight)
    );
    

ComputeMA#(
    .CH_IN            (CH_IN),
    .DWIDTH           (DWIDTH),
    .CH_OUT           (CH_OUT),
    .PIX              (PIX),
    .ADD_WIDTH        (ADD_WIDTH)
)ComputeMA_inst(
    .I_clk            (I_clk),
    .I_feature        (I_feature),
    .I_weight         (S_weight),
    .I_cpt_dv         (I_feature_dv),
    .O_data           (S_result_tmp),
    .O_data_dv        (S_result_dv)
);

CnvAdd#(
    .CH_IN            (CH_IN),
    .CH_OUT           (CH_OUT),
    .PIX              (PIX),
    .KWIDTH           (KWIDTH),
    .PWIDTH           (PWIDTH)
)CnvAdd_inst(
    .I_clk            (I_clk),
    .I_rst            (),
    .I_pad            (I_pad),
    .I_compute_en     (I_compute_en),
    .I_line_end       (I_line_end),
    .I_kx             (I_kx_num),
    .I_ky             (I_ky),
    .I_coGroup        (I_coGroup),
    .I_woGroup        (I_woGroup),
    .I_result_tmp     (S_result_tmp),
    .I_result_dv      (S_result_dv),
    .O_line_end_flag  (O_line_end_flag),
    .O_kx_end_flag    (O_kx_end_flag),
    .O_result_0       (O_result_0),
    .O_result_1       (O_result_1),
    .O_data_dv        (O_data_dv),
    .O_macc_data      (O_macc_data)
    );

endmodule
