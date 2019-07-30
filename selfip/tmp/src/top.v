`timescale 1ns / 1ps

module top#(
    parameter                        AXIWIDTH   = 128,
    parameter                        LITEWIDTH  = 32,
    parameter                        CH_IN      = 16,
    parameter                        DWIDTH     = 8,
    parameter                        CH_OUT     = 32,
    parameter                        PIX        = 8,
    parameter                        ADD_WIDTH  = 19,
    parameter                        LAYERWIDTH = 8,
    parameter                        KWIDTH     = 4,
    parameter                        COWIDTH    = 10,
    parameter                        DEPTHWIDTH = 9,
    parameter                        W_WIDTH    = 10,
    parameter                        SWIDTH     = 2,
    parameter                        PWIDTH     = 2,
    parameter                        RDB_PIX    = 2,
    parameter                        IEMEM_1ADOT=16
)(
    input                            I_clk,
    input                            I_rst,
    input   [AXIWIDTH-1:0]           I_feature,
    input                            I_feature_dv,
   
    input   [LAYERWIDTH-1:0]         I_layer_num,
    input   [LITEWIDTH-1:0]          I_feature_base_addr,
    input   [LITEWIDTH-1:0]          I_ci_num,
    input   [LITEWIDTH-1:0]          I_co_num,
    input   [LITEWIDTH-1:0]          I_kx_num,
    input   [LITEWIDTH-1:0]          I_iheight,
    input   [LITEWIDTH-1:0]          I_iwidth,
    input   [LITEWIDTH-1:0]          I_oheight,
    input   [KWIDTH-1:0]             I_kernel_h,
    input   [SWIDTH-1:0]             I_stride_h,
    input   [4:0]                    I_stride_w,
    input   [4:0]                    I_pad_w,
    input   [PWIDTH-1:0]             I_pad_h,
    input   [LITEWIDTH-1:0]          I_owidth_num,
    input                            I_ap_start,
    input   [AXIWIDTH-1:0]           I_weight,
    input                            I_weight_dv,
    input                            I_weight_ch,
    input                            I_relu_en,
    input   [LITEWIDTH-1:0]          I_imgOutAddr,
    input   [12:0]                   I_opara_coAlign16,
    input   [DEPTHWIDTH:0]           I_coAlign,
    input   [DEPTHWIDTH:0]           I_ciAlign,
    input   [DEPTHWIDTH-1:0]         I_ciGroup,
     
    input   [15:0]                   I_imgInPos,
    input   [15:0]                   I_wghInPos,
    input   [15:0]                   I_biasInPos,
    input   [15:0]                   I_imgOutPos,
    
    output  [24*CH_OUT*PIX-1:0]      O_result_0,
    output  [24*CH_OUT*PIX-1:0]      O_result_1,
    output                           O_data_dv,
    output                           O_last_line,
    output                           O_dram_feature_rd_flag,
    output  [31:0]                   O_dram_feature_rd_addr,
    output  [127:0]                  O_cnv_data,
    output                           O_cnv_dv,
    output  [31:0]                   O_wr_DDRaddr
    );

    wire    [DEPTHWIDTH-1:0]         S_woGroup;
    wire    [DEPTHWIDTH-1:0]         S_coGroup;
    wire    [DEPTHWIDTH-1:0]         S_ciMemGroup;
 
    wire                             S_line_end_flag;
    wire                             S_kx_end_flag;
    wire    [W_WIDTH-1:0]            S_h;
    wire    [KWIDTH-1:0]             S_kh;
    wire    [W_WIDTH-1:0]            S_hindex;
    wire                             S_compute_en;
    wire                             S_load_done;

    wire    [DEPTHWIDTH-1:0]         O_rd_fdepth;
    wire                             O_rd_dv;

    wire                             S_f_rdy;
    wire    [DEPTHWIDTH-1:0]         S_rd_wdepth;
    wire    [DEPTHWIDTH-1:0]         S_rd_fdepth;
    wire                             S_rd_dv;

    wire    [AXIWIDTH*PIX-1:0]       S_feature_out;
    wire                             S_feature_out_dv;
    
    wire                             S_data_dv;
    
    wire    [127:0]                  S_bias_new;
    wire                             S_bias_dv_new;
    wire    [127:0]                  S_weight_new;
    wire                             S_weight_dv_new;
    
    wire                             S_rd_new_en;
    wire                             S_line_end;
    wire                             S_dram_feature_rd_flag;
    reg                              S_dram_feature_rd_flag_d1=0;
    reg                              S_dram_feature_rd_flag_d2=0;
    reg                              S_dram_feature_rd_flag_d3=0;
    
    assign S_bias_new = !I_weight_ch ? I_weight : 128'd0;
    assign S_bias_dv_new = !I_weight_ch ? I_weight_dv : 1'd0;
    assign S_weight_new = I_weight_ch ? I_weight : 128'd0;
    assign S_weight_dv_new = I_weight_ch ? I_weight_dv : 1'd0;
    
    assign O_dram_feature_rd_flag = S_line_end || /*S_dram_feature_rd_flag*/S_kx_end_flag;

BaseCompute#(
    .LITEWIDTH                       (LITEWIDTH),
    .DEPTHWIDTH                      (DEPTHWIDTH),
    .CH_IN                           (CH_IN),
    .CH_OUT                          (CH_OUT),
    .PIX                             (PIX),
    .IEMEM_1ADOT                     (IEMEM_1ADOT)
)BaseCompute_inst(
    .I_clk                           (I_clk),
    .I_ci_num                        (I_ci_num),
    .I_co_num                        (I_co_num),
    .I_owidth_num                    (I_owidth_num),
    .I_coAlign                       (I_coAlign),
    .I_ciAlign                       (I_ciAlign),
    .O_woGroup                       (S_woGroup),
    .O_coGroup                       (S_coGroup),
    .O_ciMemGroup                    (S_ciMemGroup)
    );
    
transformhCnt#(
    .C_W_WIDTH                       (W_WIDTH),
    .C_KWIDTH                        (KWIDTH),
    .C_SWIDTH                        (SWIDTH),
    .C_PWIDTH                        (PWIDTH)
    )transformhCnt_inst(
    .I_clk                           (I_clk),
    .I_rst                           (I_rst),
    .I_ap_start                      (I_ap_start),
    .I_hcnt_flag                     (S_line_end_flag),
    .I_oheight                       (I_oheight[W_WIDTH-1:0]),
    .I_kernel_h                      (I_kernel_h),
    .I_stride_h                      (I_stride_h),
    .I_pad_h                         (I_pad_h),
    .O_h                             (S_h),
    .O_kh                            (S_kh), 
    .O_hindex                        (S_hindex),
    .O_compute_en                    (S_compute_en),
    .O_last_line                     (O_last_line)
    );

    
DRAMFeatureRdAddr#(
    .W_WIDTH                         (W_WIDTH),
    .LITEWIDTH                       (LITEWIDTH),
    .DEPTHWIDTH                      (DEPTHWIDTH),
    .AXIWIDTH                        (AXIWIDTH)
    )DRAMFeatureRdAddr_inst(
    .I_clk                           (I_clk),
    .I_rst                           (I_rst),
    .I_ap_start                      (I_ap_start),
    .I_f_rdy                         (S_f_rdy),
    .I_ciAlign                       (I_ciAlign),
    .I_ciMemGroup                    (S_ciMemGroup),
    .I_feature_base_addr             (I_feature_base_addr),
    .I_hindex                        (S_hindex),
    .I_compute_en                    (S_compute_en),
    .I_iheight                       (I_iheight[W_WIDTH-1:0]),
    .I_iwidth                        (I_iwidth[W_WIDTH-1:0]),
    .O_dram_feature_rd_addr          (O_dram_feature_rd_addr),
    .O_dram_feature_rd_flag          ()
    );  
        
rd_addr_ctl#(
    .AXIWIDTH                        (LITEWIDTH),
    .DEPTHWIDTH                      (DEPTHWIDTH),
    .CH_IN                           (CH_IN),
    .CH_OUT                          (CH_OUT),
    .PIX                             (PIX)
    )rd_addr_ctl_inst(
    .I_clk                           (I_clk),
    .I_rst                           (I_rst),
    .I_ap_start                      (I_ap_start),
    .I_f_rdy                         (S_f_rdy /*|| S_line_end*/),
    .I_weight_load_done              (S_load_done),
    .I_ci_num                        (I_ci_num),
    .I_co_num                        (I_co_num),
    .I_kx_num                        (I_kx_num),
    .I_ky_num                        ({28'd0,I_kernel_h}),
    .I_owidth_num                    (I_owidth_num),
    .I_hindex                        (S_hindex),
    .I_ky                            (S_kh),
    .I_compute_en                    (S_compute_en),
    .I_coAlign                       (I_coAlign),
    .I_ciAlign                       (I_ciAlign),
    .I_woGroup                       (S_woGroup),
    .I_coGroup                       (S_coGroup),
    .I_ciGroup                       (I_ciGroup),
    .O_rd_wdepth                     (S_rd_wdepth),
    .O_rd_fdepth                     (S_rd_fdepth),
    .O_rd_dv                         (S_rd_dv),
    .O_rd_new_en                     (S_dram_feature_rd_flag)
    );
    
    
AXI2ibuf2sbuf_update#(
    .AXIWIDTH                        (AXIWIDTH),
    .LITEWIDTH                       (LITEWIDTH),
    .W_WIDTH                         (W_WIDTH),
    .PIX                             (PIX),
    .RDB_PIX                         (RDB_PIX),
    .DEPTHWIDTH                      (DEPTHWIDTH)
    )AXI2ibuf2sbuf_update_inst(
    .I_clk                           (I_clk),
    .I_rst                           (I_rst),
    .I_ap_start                      (I_ap_start),
    .I_feature                       (I_feature),
    .I_feature_dv                    (I_feature_dv),
    .I_hcnt_flag                     (S_line_end_flag),
    .I_iheight                       (I_iheight),
    .I_iwidth                        (I_iwidth),
    .I_hindex                        (S_hindex),
    .I_compute_en                    (S_compute_en),
    .I_k_w                           (I_kx_num),
    .I_stride_w                      ({27'd0,I_stride_w}),
    .I_pad_w                         ({27'd0,I_pad_w}),
    .I_ciGroup                       (I_ciGroup),
    .I_rd_fdepth                     (S_rd_fdepth),
    .I_rd_dv                         (S_rd_dv),
    .O_f_rdy                         (S_f_rdy),
    .O_feature_out                   (S_feature_out),
    .O_feature_out_dv                (S_feature_out_dv)
    );
    
    
ProcessTop#(
    .AXIWIDTH                        (AXIWIDTH),
    .LITEWIDTH                       (LITEWIDTH),
    .CH_IN                           (CH_IN),
    .DWIDTH                          (DWIDTH),
    .CH_OUT                          (CH_OUT),
    .PIX                             (PIX),
    .ADD_WIDTH                       (ADD_WIDTH), 
    .LAYERWIDTH                      (LAYERWIDTH),
    .KWIDTH                          (KWIDTH),
    .COWIDTH                         (COWIDTH),
    .DEPTHWIDTH                      (DEPTHWIDTH)
)ProcessTop_inst(
    .I_clk                           (I_clk),
    .I_rst                           (I_rst),
    .I_feature                       (S_feature_out),
    .I_feature_dv                    (S_feature_out_dv),
    
    .I_coAlign                       (I_coAlign),
    .I_ciAlign                       (I_ciAlign),
    .I_woGroup                       (S_woGroup),
    .I_coGroup                       (S_coGroup),
    .I_ciGroup                       (I_ciGroup),   
    
    .I_layer_num                     (I_layer_num),
    .I_ci_num                        (I_ci_num),
    .I_co_num                        (I_co_num),
    .I_kx_num                        (I_kx_num),
    .I_ky_num                        ({28'd0,I_kernel_h}),
    .I_owidth_num                    (I_owidth_num),
    .I_ap_start                      (I_ap_start),
    .I_compute_en                    (S_compute_en),
    .I_line_end                      (S_line_end),
    .I_weight                        (S_weight_new),
    .I_weight_dv                     (S_weight_dv_new),
    
    .I_rd_wdepth                     (S_rd_wdepth),
    .I_rd_fdepth                     (S_rd_fdepth),
    .I_rd_dv                         (S_rd_dv),
    
    .I_ky                            (S_kh),
    .I_pad                           (I_pad_h),
    .O_load_done                     (S_load_done),
    .O_line_end_flag                 (S_line_end_flag),
    .O_kx_end_flag                   (S_kx_end_flag),
    .O_result_0                      (O_result_0),
    .O_result_1                      (O_result_1),
    .O_data_dv                       (S_data_dv),
    .O_rd_fdepth                     (O_rd_fdepth),
    .O_rd_dv                         (O_rd_dv)
);

cnvPost#(
    .CH_OUT                          (CH_OUT),
    .PIX                             (PIX),
    .DWIDTH                          (DWIDTH),
    .AXIWIDTH                        (AXIWIDTH),
    .LITEWIDTH                       (LITEWIDTH),
    .KWIDTH                          (KWIDTH),
    .DEPTHWIDTH                      (DEPTHWIDTH)
)cnvPost_inst(
    .I_clk                           (I_clk),
    .I_rst                           (),
    
    .I_ap_start                      (I_ap_start),
    .I_ky                            (S_kh),
    .I_ky_num                        ({28'd0,I_kernel_h}),
    .I_coGroup                       (S_coGroup),
    .I_woGroup                       (S_woGroup),
    
    .I_result_0                      (O_result_0),
    .I_result_1                      (O_result_1),
    .I_data_dv                       (S_data_dv),
    
    .I_weight                        (S_bias_new),
    .I_weight_dv                     (S_bias_dv_new),
    
    .I_imgInPos                      ({{(16){I_imgInPos[15]}},I_imgInPos}),
    .I_wghInPos                      ({{(16){I_wghInPos[15]}},I_wghInPos}),
    .I_biasInPos                     ({{(16){I_biasInPos[15]}},I_biasInPos}),
    .I_imgOutPos                     ({{(16){I_imgOutPos[15]}},I_imgOutPos}),
    
    .I_relu_en                       (I_relu_en),
    .I_imgOutAddr                    (I_imgOutAddr),
    .I_h                             (S_h),
    
    .O_cnv_data                      (O_cnv_data),
    .O_cnv_dv                        (O_cnv_dv),
    .O_wr_DDRaddr                    (O_wr_DDRaddr),
    .O_line_end                      (S_line_end)
    );

endmodule
