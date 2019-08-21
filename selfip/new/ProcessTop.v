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
    input   [8:0]                    I_post_raddr,
    output                           O_load_done,
    output                           O_line_end_flag,
    output                           O_kx_end_flag,
    output                           O_post_begin_flag,
//    output  [24*CH_OUT*PIX-1:0]      O_result_0,
//    output  [24*CH_OUT*PIX-1:0]      O_result_1,
    output  [24*CH_OUT*PIX-1:0]      O_data_out,
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
reg                              S_feature_dv=0;
reg                              S_feature_dv_d1=0;
reg                              S_feature_dv_d2=0;
reg   [KWIDTH-1:0]               S_ky=0;
wire  [48*CH_IN*PIX-1:0]         S_line_out_data;
wire                             S_line_out_dv;

assign  O_rd_fdepth = S_rd_fdepth;
assign  O_rd_dv = S_rd_dv;

always@ (posedge I_clk)
begin
    S_feature_dv <= I_feature_dv;
    S_feature_dv_d1 <= S_feature_dv;
    S_feature_dv_d2 <= S_feature_dv_d1;
    S_ky <= I_ky; 
end

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
    .I_kx_num         (I_kx_num),
    .I_ky_num         (I_ky_num),
    .I_ciAlign        ({3'd0,I_ciAlign}),
    .I_coAlign        ({3'd0,I_coAlign}),
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
    .ADD_WIDTH        (ADD_WIDTH),
    .KWIDTH           (KWIDTH)
)ComputeMA_inst(
    .I_clk            (I_clk),
    .I_feature        (I_feature),
    .I_weight         (S_weight),
    .I_cpt_dv         (S_feature_dv_d2),
    .I_kx_num         (I_kx_num),
    .I_line_add_data  (S_line_out_data),
    .I_line_out_dv    (S_line_out_dv),
    .O_data           (S_result_tmp),
    .O_data_dv        (S_result_dv)
);

CnvAdd#(
    .CH_IN            (CH_IN),
    .CH_OUT           (CH_OUT),
    .PIX              (PIX),
    .KWIDTH           (KWIDTH),
    .DEPTHWIDTH       (9),
    .PWIDTH           (PWIDTH)
)CnvAdd_inst(
    .I_clk            (I_clk),
    .I_rst            (),
    .I_kx             (I_kx_num),
    .I_ky             (S_ky),
    .I_compute_en     (I_compute_en),
    .I_cpt_dv         (S_feature_dv_d1),
    .I_line_end       (I_line_end),
    .I_coGroup        (I_coGroup),
    .I_woGroup        (I_woGroup),
    .I_result_tmp     (S_result_tmp),
    .I_result_dv      (S_result_dv),
    .I_post_raddr     (I_post_raddr),
    
    .O_line_out_data  (S_line_out_data),
    .O_line_out_dv    (S_line_out_dv),
    .O_line_end_flag  (O_line_end_flag),
    .O_kx_end_flag    (O_kx_end_flag),
//    .O_result_0       (O_result_0),
//    .O_result_1       (O_result_1),
    .O_data_out       (O_data_out),
    .O_data_dv        (O_data_dv),
    .O_macc_data      (O_macc_data),
    .O_post_begin_flag(O_post_begin_flag)
    );

endmodule
