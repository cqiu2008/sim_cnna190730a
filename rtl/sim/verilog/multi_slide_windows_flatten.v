//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : multi_slide_windows_flatten.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_main_process.v
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_main_process
//--------------------------------------------------------------------------------------------------
//Relaese History :
//--------------------------------------------------------------------------------------------------
//Version         Date           Author        Description
// 1.1           july-30-2019                    
//--------------------------------------------------------------------------------------------------
//Main Function:
//a)Get the data from ddr chip using axi master bus
//b)Write it to the ibuf ram
//--------------------------------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER----------------------------------------------------------------------------------------
module multi_slide_windows_flatten #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_POWER_OF_RDBPIX       = 1         , 
    C_PEPIX                 = 8         ,
    C_DATA_WIDTH            = 8         ,
    C_QIBUF_WIDTH           = 12        ,
    C_QOBUF_WIDTH           = 24        ,
    C_LQIBUF_WIDTH          = 12*8      ,       
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_RAM_ADDR_WIDTH        = 9         ,
    C_RAM_DATA_WIDTH        = 128       , 
    C_RAM_LDATA_WIDTH       = 128*8       
)(
// clk
input                               I_clk               ,
input                               I_rst               ,
input                               I_allap_start       ,
input                               I_ap_start          ,
output reg                          O_ap_done           ,
//ibuf
output      [C_RAM_ADDR_WIDTH-1  :0]O_ibuf0_addr        ,//dly=23
output      [C_RAM_ADDR_WIDTH-1  :0]O_ibuf1_addr        , 
input       [C_RAM_DATA_WIDTH-1  :0]I_ibuf0_rdata       ,//dly=26 
input       [C_RAM_DATA_WIDTH-1  :0]I_ibuf1_rdata       , 
//sbuf
input       [C_RAM_ADDR_WIDTH-1  :0]I_sraddr0           , 
input       [C_RAM_ADDR_WIDTH-1  :0]I_sraddr1           , 
output reg  [C_RAM_LDATA_WIDTH-1 :0]O_srdata0           , 
output reg  [C_RAM_LDATA_WIDTH-1 :0]O_srdata1           , 
//qbuf
input       [C_RAM_ADDR_WIDTH-1  :0]I_qraddr0           , 
input       [C_RAM_ADDR_WIDTH-1  :0]I_qraddr1           , 
output reg  [  C_LQIBUF_WIDTH-1  :0]O_qrdata0           , 
output reg  [  C_LQIBUF_WIDTH-1  :0]O_qrdata1           , 
// reg
input       [       C_DIM_WIDTH-1:0]I_ipara_height      ,
input       [       C_DIM_WIDTH-1:0]I_hindex            ,
input                               I_hcnt_odd          ,//1,3,5,...active
input       [     C_CNV_K_WIDTH-1:0]I_kernel_w          ,
input       [     C_CNV_K_WIDTH-1:0]I_stride_w          ,
input       [     C_CNV_K_WIDTH-1:0]I_pad_w             ,
input       [       C_DIM_WIDTH-1:0]I_ipara_width       ,
input       [    C_CNV_CH_WIDTH-1:0]I_ipara_ci           
);

localparam   C_RDBPIX         = {1'b1,{C_POWER_OF_RDBPIX{1'b0}}}        ;
localparam   C_WOT_DIV_PEPIX  = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_WOT_DIV_RDBPIX = C_DIM_WIDTH - C_POWER_OF_RDBPIX+1       ;
localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX    = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_CNV_K_GROUP    = C_CNV_K_WIDTH + C_NCH_GROUP             ;
localparam   C_PADDING        = 6                                       ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) SL_+"xx"  name type (S_layer_xxx) , means variable changed every layer   
//        such as SL_wo_total, SL_wo_group, SL_wpart ... and so on 
// (2) SR_+"xx"  name type (S_row_xxx), means variable changed every row 
//        such as SR_hindex , SR_hindex  ... and so on 
// (3) SC_+"xx"  name type (S_clock_xxx), means variable changed every clock 
//        such as SC_id , ... and so on 
////////////////////////////////////////////////////////////////////////////////////////////////////

wire                         SR_ndap_start                                  ;
reg  [                   3:0]SR_ndap_start_shift                            ;
wire                         SR_hindex_suite                                ;
wire [       C_DIM_WIDTH-1:0]SR_sbuf0_index                                 ; 
wire [       C_DIM_WIDTH-1:0]SR_sbuf1_index                                 ; 
reg                          SR_sbuf0_index_neq                             ; 
reg                          SR_sbuf1_index_neq                             ; 
reg                          SR_swap_start                                  ;
wire                         SR_ndswap_start                                ;
reg                          SR_swap_done                                   ;
wire                         SR_ndswap_done                                 ;//dly=31
reg                          SR_sbuf0_en                                    ;
reg                          SR_sbuf1_en                                    ;
reg                          SR_no_suite_done                               ;
reg                          SL_split_en                                    ;
reg  [     C_CNV_K_WIDTH-1:0]SL_pepix_stride_w                              ;
reg  [     C_CNV_K_WIDTH-1:0]SL_pesub1pix_stride_w                          ;
reg  [       C_DIM_WIDTH-1:0]SL_pesub1pix_stride_w_addkernel                ;
wire [  C_WOT_DIV_RDBPIX-1:0]SL_pesub1pix_stride_w_addkernel_div_rdb        ;
reg  [       C_DIM_WIDTH-1:0]SL_wo_total1                                   ;
reg  [       C_DIM_WIDTH-1:0]SL_wo_total2                                   ;
wire [       C_DIM_WIDTH-1:0]SL_wo_total3                                   ;
reg  [       C_DIM_WIDTH-1:0]SL_wo_total                                    ;
wire [   C_WOT_DIV_PEPIX-1:0]SL_wot_div_pepix                               ;
wire [  C_WOT_DIV_RDBPIX-1:0]SL_wot_div_rdbpix                              ;
wire [       C_DIM_WIDTH-1:0]SL_wpart_t                                     ;
reg  [       C_DIM_WIDTH-1:0]SL_wpart                                       ;
reg  [       C_DIM_WIDTH-1:0]SC_id[0:C_RDBPIX-1]                            ;
wire [       C_DIM_WIDTH-1:0]SC_ndid[0:C_RDBPIX-1]                          ;
reg                          SC_id_more0[0:C_RDBPIX-1]                      ;
reg  [       C_DIM_WIDTH-1:0]SC_windex[0:C_RDBPIX-1]                        ;//dly=21
wire [       C_DIM_WIDTH-1:0]SC_ndwindex[0:C_RDBPIX-1]                      ;//dly=26
wire                         SC_windex_suite[0:C_RDBPIX-1][0:C_PEPIX-1]     ;//dly=28
wire                         SC_ndwindex_suite[0:C_RDBPIX-1][0:C_PEPIX-1]   ;//dly=30
reg  [       C_DIM_WIDTH-1:0]SC_wremainder[0:C_RDBPIX-1]                    ;
reg  [       C_DIM_WIDTH-1:0]SL_wthreshold[0:C_PEPIX-1]                     ;
reg  [     C_CNV_K_PEPIX-1:0]SL_p_stride_w[0:C_PEPIX-1]                     ;
reg  [       C_DIM_WIDTH-1:0]SL_wthreshold_t2[0:C_PEPIX-1]                  ;
reg                          SC_rem_less_thr[0:C_RDBPIX-1][0:C_PEPIX-1]     ;
reg  [       C_DIM_WIDTH-1:0]SC_idforpix[0:C_RDBPIX-1][0:C_PEPIX-1]         ;
reg  [       C_DIM_WIDTH-1:0]SC_pfirst[0:C_RDBPIX-1][0:C_PEPIX-1]           ;
reg  [     C_CNV_K_WIDTH-1:0]SC_k[0:C_RDBPIX-1][0:C_PEPIX-1]                ;
reg  [     C_CNV_K_WIDTH-1:0]SC_k_t1[0:C_RDBPIX-1][0:C_PEPIX-1]             ;
wire                         SC_k_suite[0:C_RDBPIX-1][0:C_PEPIX-1]          ;
reg  [       C_DIM_WIDTH-1:0]SC_depth[0:C_RDBPIX-1][0:C_PEPIX-1]            ;//dly=28
wire [       C_DIM_WIDTH-1:0]SC_ndepth[0:C_RDBPIX-1][0:C_PEPIX-1]           ;//dly=30
reg  [       C_DIM_WIDTH-1:0]SC_depth_t1[0:C_RDBPIX-1][0:C_PEPIX-1]         ;
reg  [       C_DIM_WIDTH-1:0]SC_depth_t2[0:C_RDBPIX-1][0:C_PEPIX-1]         ;
reg  [       C_DIM_WIDTH-1:0]SC_depth_t2a[0:C_RDBPIX-1][0:C_PEPIX-1]        ;
reg  [       C_DIM_WIDTH-1:0]SC_depth_t2b[0:C_RDBPIX-1][0:C_PEPIX-1]        ;
reg  [       C_DIM_WIDTH-1:0]SC_depth_t3[0:C_RDBPIX-1][0:C_PEPIX-1]         ;
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_ibufaddr_t1[0:C_RDBPIX-1]                   ;
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_ibufaddr[0:C_RDBPIX-1]                      ;
wire [     C_QIBUF_WIDTH-1:0]SC_sum[0:C_RDBPIX-1]                           ;
wire [       C_NCH_GROUP-1:0]SC_cig_cnt                                     ;
wire [       C_NCH_GROUP-1:0]SC_ndcig_cnt                                   ;
wire [       C_NCH_GROUP-1:0]SC_n1dcig_cnt                                  ;
wire [       C_NCH_GROUP-1:0]SL_ci_group                                    ;   
reg  [       C_NCH_GROUP-1:0]SL_ci_group_1d                                 ;   
reg                          SC_cig_valid                                   ;
wire                         SC_cig_over_flag                               ; 
wire [       C_DIM_WIDTH-1:0]SC_woc_cnt                                     ;
reg  [       C_DIM_WIDTH-1:0]SL_wo_consume                                  ;
wire                         SC_woc_valid                                   ;
wire                         SC_woc_over_flag                               ; 
wire [       C_DIM_WIDTH-1:0]SC_wog_cnt                                     ;
wire [       C_DIM_WIDTH-1:0]SC_ndwog_cnt                                   ;
reg  [       C_DIM_WIDTH-1:0]SL_wo_group                                    ;
wire                         SC_wog_valid                                   ;
wire                         SC_wog_over_flag                               ; 
reg  [       C_DIM_WIDTH-1:0]SC_w                                           ;
reg  [       C_DIM_WIDTH-1:0]SC_wws[0:C_RDBPIX-1]                           ;
wire [       C_DIM_WIDTH-1:0]SC_ndwws[0:C_RDBPIX-1]                         ;
wire [       C_DIM_WIDTH-1:0]SC_n1dwws[0:C_RDBPIX-1]                        ;
wire [       C_DIM_WIDTH-1:0]SC_wws_divwpart[0:C_RDBPIX-1]                  ;
wire [       C_DIM_WIDTH-1:0]SC_wws_remwpart[0:C_RDBPIX-1]                  ;
wire [       C_DIM_WIDTH-1:0]SC_woc_rdbpix                                  ;
wire [       C_DIM_WIDTH-1:0]SC_wog_rdbpix                                  ;
wire [       C_DIM_WIDTH-1:0]SC_wog_pepix                                   ;
wire [       C_DIM_WIDTH-1:0]SC_wog_pe_or_rdb_pix                           ;
reg  [     C_CNV_K_GROUP-1:0]SL_kernel_w_ci_group                           ;
wire [C_RAM_DATA_WIDTH-1  :0]SC_ibuf_rdata[0:C_RDBPIX-1]                    ;//dly=28
wire [C_RAM_DATA_WIDTH-1  :0]SC_ndibuf_rdata[0:C_RDBPIX-1]                  ;//dly=28
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_addr0[0:C_RDBPIX-1][0:C_PEPIX-1]                ;//dly=29
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_addr1[0:C_RDBPIX-1][0:C_PEPIX-1]                ;
reg                          SC_wr0[0:C_RDBPIX-1][0:C_PEPIX-1]                  ;//dly=29       
reg                          SC_wr1[0:C_RDBPIX-1][0:C_PEPIX-1]                  ;                                     
reg  [C_RAM_DATA_WIDTH-1  :0]SC_wdata0[0:C_RDBPIX-1][0:C_PEPIX-1]               ;
reg  [C_RAM_DATA_WIDTH-1  :0]SC_wdata1[0:C_RDBPIX-1][0:C_PEPIX-1]               ;
wire [C_RAM_DATA_WIDTH-1  :0]SC_rdata0[0:C_RDBPIX-1][0:C_PEPIX-1]               ;                                  
wire [C_RAM_DATA_WIDTH-1  :0]SC_rdata1[0:C_RDBPIX-1][0:C_PEPIX-1]               ;                                  
wire [C_RAM_LDATA_WIDTH-1 :0]SC_lrdata0[0:C_RDBPIX-1]                       ;
wire [C_RAM_LDATA_WIDTH-1 :0]SC_lrdata1[0:C_RDBPIX-1]                       ;
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_qaddr0[0:C_RDBPIX-1][0:C_PEPIX-1]               ;//dly=
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_qaddr1[0:C_RDBPIX-1][0:C_PEPIX-1]               ;
wire                         SC_qwr0[0:C_RDBPIX-1][0:C_PEPIX-1]                 ;//dly=31    
wire                         SC_qwr1[0:C_RDBPIX-1][0:C_PEPIX-1]                 ;                                     
reg  [     C_QIBUF_WIDTH-1:0]SC_qwdata0[0:C_RDBPIX-1][0:C_PEPIX-1]              ;
reg  [     C_QIBUF_WIDTH-1:0]SC_qwdata1[0:C_RDBPIX-1][0:C_PEPIX-1]              ;
wire [     C_QIBUF_WIDTH-1:0]SC_qrdata0[0:C_RDBPIX-1][0:C_PEPIX-1]              ;                                  
wire [     C_QIBUF_WIDTH-1:0]SC_qrdata1[0:C_RDBPIX-1][0:C_PEPIX-1]              ;                                  
wire [    C_LQIBUF_WIDTH-1:0]SC_lqrdata0[0:C_RDBPIX-1]                      ;
wire [    C_LQIBUF_WIDTH-1:0]SC_lqrdata1[0:C_RDBPIX-1]                      ;
reg                          SR_ndswap_done_1d                          ;//dly=31
////////////////////////////////////////////////////////////////////////////////////////////////////
// initial layer variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// calcuate SL_split_en 
always @(posedge I_clk)begin
    SL_pepix_stride_w <= {I_stride_w[C_CNV_K_WIDTH-C_POWER_OF_PEPIX-1:0],{C_POWER_OF_PEPIX{1'b0}}}   ;
    SL_split_en       <= !(I_kernel_w < SL_pepix_stride_w)                                           ;
end

// calcuate SL_wo_total 
always @(posedge I_clk)begin
    SL_wo_total1 <= I_ipara_width + {I_pad_w[C_CNV_K_WIDTH-1:0],1'b0}  ;
    SL_wo_total2 <= SL_wo_total1 - I_kernel_w                          ; 
    //SL_wo_total3   <= SL_wo_total2 / I_stride_w                          ;////divtag
    SL_wo_total  <= SL_wo_total3 + {{(C_DIM_WIDTH-1){1'b0}},1'b1}      ;
end

divider #(
    .C_DIVIDEND   (C_DIM_WIDTH  ), 
    .C_DIVISOR    (C_CNV_K_WIDTH),
    .C_QUOTIENT   (C_DIM_WIDTH  ),
    .C_REMAINDER  (C_DIM_WIDTH  ))
u_wo_total(
    .I_clk        (I_clk            ),
    .I_dividend   (SL_wo_total2     ),
    .I_divisor    (I_stride_w       ),
    .O_quotient   (SL_wo_total3     ), 
    .O_remainder  (                 )
);

// calcuate SL_wo_group
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_PEPIX   ))
U0_wot_div_pepix(
    .I_din          (SL_wo_total        ),
    .O_dout         (SL_wot_div_pepix   )   
);

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_RDBPIX  ))
U0_wot_div_rdbpix(
    .I_din          (SL_wo_total1       ),
    .O_dout         (SL_wot_div_rdbpix  )   
);

always @(posedge I_clk)begin
    if(SL_split_en)begin
        SL_wo_group  <= SL_wot_div_pepix    ;
    end
    else begin
        SL_wo_group  <= SL_wot_div_rdbpix   ;
    end
end

// calcuate SL_wo_consume
always @(posedge I_clk)begin
    SL_pesub1pix_stride_w            <= SL_pepix_stride_w - I_stride_w      ; 
    SL_pesub1pix_stride_w_addkernel  <= SL_pesub1pix_stride_w + I_kernel_w  ;
end

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_RDBPIX  ))
U0_pesub1pix_div_rdb(
    .I_din (SL_pesub1pix_stride_w_addkernel              ), 
    .O_dout(SL_pesub1pix_stride_w_addkernel_div_rdb      )
);

always @(posedge I_clk)begin
    if(SL_split_en)begin
        SL_wo_consume <= SL_pesub1pix_stride_w_addkernel_div_rdb  ;   
    end
    else begin
        SL_wo_consume <= {{(C_DIM_WIDTH-1){1'b0}},1'b1}; 
    end
end

// calcuate SL_wpart
align #(
    .C_IN_WIDTH (C_CNV_K_WIDTH+C_POWER_OF_PEPIX),
    .C_OUT_WIDTH(C_DIM_WIDTH))
u_wpart_t(
    .I_din      ({I_stride_w[C_CNV_K_WIDTH-1:0],{C_POWER_OF_PEPIX{1'b0}}}   ),
    .O_dout     (SL_wpart_t                                                 )
);

always @(posedge I_clk)begin
    SL_wpart <= SL_wpart_t        ; 
end

// calcuate SL_ci_group_1d
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_PECI    ))
U0_ci_group(
    .I_din (I_ipara_ci),
    .O_dout(SL_ci_group )   
);

always @(posedge I_clk)begin
    SL_ci_group_1d <= SL_ci_group;
end

// calcuate SL_kernel_w_ci_group
always @(posedge I_clk)begin
    SL_kernel_w_ci_group    <= I_kernel_w  * SL_ci_group_1d     ; 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial row variable , ap_done
////////////////////////////////////////////////////////////////////////////////////////////////////
suite_range #(
    .C_DIM_WIDTH (C_DIM_WIDTH))
u_suite_range(
    .I_clk          (I_clk           ),
    .I_index        (I_hindex        ),
    .I_index_upper  (I_ipara_height  ),
    .O_index_suite  (SR_hindex_suite ) //dly=2
);

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_sbuf0_index(
    .I_clk        (I_clk            ),
    .I_ap_start   (I_allap_start    ),
    .I_index_en   (SR_sbuf0_en      ),
    .I_index      (I_hindex         ),
    .O_index_lck  (SR_sbuf0_index   )     
);

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_sbuf1_index(
    .I_clk        (I_clk            ),
    .I_ap_start   (I_allap_start    ),
    .I_index_en   (SR_sbuf1_en      ),
    .I_index      (I_hindex         ),
    .O_index_lck  (SR_sbuf1_index   )     
);

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (2          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_ap_start      ),
    .O_dout    (SR_ndap_start    )
);

always @(posedge I_clk)begin
    SR_ndap_start_shift   <={SR_ndap_start_shift[2:0],SR_ndap_start}    ;
    SR_sbuf0_index_neq   <= SR_sbuf0_index != I_hindex                  ; 
    SR_sbuf1_index_neq   <= SR_sbuf1_index != I_hindex                  ; 
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(SR_ndap_start_shift[1:0] == 2'b01)begin
            SR_sbuf0_en  <= SR_hindex_suite && SR_sbuf0_index_neq && ( I_hcnt_odd) ;
            SR_sbuf1_en  <= SR_hindex_suite && SR_sbuf1_index_neq && (~I_hcnt_odd) ;
        end
        else begin
            SR_sbuf0_en  <= SR_sbuf0_en   ; 
            SR_sbuf1_en  <= SR_sbuf1_en   ; 
        end
    end
    else begin
        SR_sbuf0_en <= 1'b0 ;
        SR_sbuf1_en <= 1'b0 ;
    end
end

always @(posedge I_clk)begin
    SR_swap_start <= SR_sbuf0_en | SR_sbuf1_en;
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(SC_wog_valid && SC_wog_over_flag)begin
            SR_swap_done <= 1'b1;
        end
        else begin
            SR_swap_done <= SR_swap_done; 
        end
    end
    else begin
        SR_swap_done <= 1'b0;
    end
end

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (31         ))
u_ndswap_done(
    .I_clk     (I_clk           ),
    .I_din     (SR_swap_done    ),
    .O_dout    (SR_ndswap_done  ) //dly=31
);

always @(posedge I_clk)begin
    SR_ndswap_done_1d <= SR_ndswap_done                                             ;
    SR_no_suite_done  <= (SR_ndap_start_shift[3:2]==2'b01) && (~SR_swap_start)      ; 
    O_ap_done         <= SR_no_suite_done || (SR_ndswap_done&&(~SR_ndswap_done_1d)) ; 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// loop cnt ctrl 
////////////////////////////////////////////////////////////////////////////////////////////////////

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (1          ))
u_ndswap_start(
    .I_clk     (I_clk           ),
    .I_din     (SR_swap_start   ),
    .O_dout    (SR_ndswap_start )
);

always @(posedge I_clk)begin
    if(SR_ndswap_start && I_ap_start)begin
        SC_cig_valid <= 1'b1;
    end
    else begin
        SC_cig_valid <= 1'b0;
    end
end

assign SC_woc_valid = SC_cig_valid && SC_cig_over_flag ;
assign SC_wog_valid = SC_woc_valid && SC_woc_over_flag ;

cm_cnt #(
    .C_WIDTH(C_NCH_GROUP))
u_loop1_cig_cnt (
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_swap_start          ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_cig_valid           ),
.I_cnt_upper        (SL_ci_group_1d         ),
.O_over_flag        (SC_cig_over_flag       ),
.O_cnt              (SC_cig_cnt             )
);

cm_cnt #(
    .C_WIDTH(C_DIM_WIDTH))
u_loop2_woc_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_swap_start          ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_woc_valid           ),
.I_cnt_upper        (SL_wo_consume          ),
.O_over_flag        (SC_woc_over_flag       ),
.O_cnt              (SC_woc_cnt             )
);

cm_cnt #(
    .C_WIDTH(C_DIM_WIDTH))
u_loop3_wog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_swap_start          ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_wog_valid           ),
.I_cnt_upper        (SL_wo_group            ),
.O_over_flag        (SC_wog_over_flag       ),
.O_cnt              (SC_wog_cnt             )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate dly variable
////////////////////////////////////////////////////////////////////////////////////////////////////
dly #(
    .C_DATA_WIDTH   (C_DIM_WIDTH    ), 
    .C_DLY_NUM      (20             ))
u_ndwog_cnt(
    .I_clk          (I_clk           ),
    .I_din          (SC_wog_cnt      ),
    .O_dout         (SC_ndwog_cnt    )
);

dly #(
    .C_DATA_WIDTH   (C_NCH_GROUP            ), 
    .C_DLY_NUM      (22                     ))
u_ndcig(
    .I_clk          (I_clk                  ),
    .I_din          (SC_cig_cnt             ),
    .O_dout         (SC_ndcig_cnt           ) //dly=22
);

dly #(
    .C_DATA_WIDTH   (C_NCH_GROUP            ), 
    .C_DLY_NUM      (2                      ))
u_n1dcig(
    .I_clk          (I_clk                  ),
    .I_din          (SC_ndcig_cnt           ),
    .O_dout         (SC_n1dcig_cnt          ) //dly=24
);

genvar ws_idd;
genvar p_idd;
generate
    begin:dly_idd
        for(ws_idd=0;ws_idd<C_RDBPIX;ws_idd=ws_idd+1)begin:dly_idd_s1
            for(p_idd=0;p_idd<C_PEPIX;p_idd=p_idd+1)begin:dly_idd_s2

                dly #(
                    .C_DATA_WIDTH   (1                                  ), 
                    .C_DLY_NUM      (2                                  ))
                u_ndwindex_suite(
                    .I_clk          (I_clk                              ),
                    .I_din          (SC_windex_suite[ws_idd][p_idd]     ),//dly=28
                    .O_dout         (SC_ndwindex_suite[ws_idd][p_idd]   ) //dly=30
                );

                dly #(
                    .C_DATA_WIDTH   (1                                  ), 
                    .C_DLY_NUM      (2                                  ))
                u_qwr0(
                    .I_clk          (I_clk                              ),
                    .I_din          (SC_wr0[ws_idd][p_idd]              ),//dly=29
                    .O_dout         (SC_qwr0[ws_idd][p_idd]             ) //dly=31
                );

                dly #(
                    .C_DATA_WIDTH   (1                                  ), 
                    .C_DLY_NUM      (2                                  ))
                u_qwr1(
                    .I_clk          (I_clk                              ),
                    .I_din          (SC_wr1[ws_idd][p_idd]              ),//dly=29
                    .O_dout         (SC_qwr1[ws_idd][p_idd]             ) //dly=31
                );

                dly #(
                    .C_DATA_WIDTH   (C_DIM_WIDTH                ), 
                    .C_DLY_NUM      (2                          ))
                u_ndepth(
                    .I_clk          (I_clk                      ),
                    .I_din          (SC_depth[ws_idd][p_idd]    ),//dly=28
                    .O_dout         (SC_ndepth[ws_idd][p_idd]   ) //dly=30
                );

            end

            dly #(
                .C_DATA_WIDTH   (C_DIM_WIDTH        ), 
                .C_DLY_NUM      (18                 ))
            u_ndwws(
                .I_clk          (I_clk              ),
                .I_din          (SC_wws[ws_idd]     ),//dly=2
                .O_dout         (SC_ndwws[ws_idd]   ) //dly=20
            );

            dly #(
                .C_DATA_WIDTH   (C_DIM_WIDTH        ), 
                .C_DLY_NUM      (4                 ))
            u_n1dwws(
                .I_clk          (I_clk              ),
                .I_din          (SC_ndwws[ws_idd]   ),
                .O_dout         (SC_n1dwws[ws_idd]  ) //dly=24
            );

            dly #(
                .C_DATA_WIDTH   (C_DIM_WIDTH        ), 
                .C_DLY_NUM      (1                  ))
            u_ndid(
                .I_clk          (I_clk              ),
                .I_din          (SC_id[ws_idd]      ),
                .O_dout         (SC_ndid[ws_idd]    )
            );

            dly #(
                .C_DATA_WIDTH   (C_DIM_WIDTH            ), 
                .C_DLY_NUM      (5                      ))
            u_nd_windex(
                .I_clk          (I_clk                  ),
                .I_din          (SC_windex[ws_idd]      ),//dly=21
                .O_dout         (SC_ndwindex[ws_idd]    ) //dly=26
            );

            dly #(
                .C_DATA_WIDTH   (C_RAM_DATA_WIDTH       ), 
                .C_DLY_NUM      (2                      ))
            u_nd_ibuf_rdata(
                .I_clk          (I_clk                  ),
                .I_din          (SC_ibuf_rdata[ws_idd]  ),//dly=26
                .O_dout         (SC_ndibuf_rdata[ws_idd]) //dly=28
            );


        end
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// calculate SC_w
assign SC_woc_rdbpix        = {SC_woc_cnt[C_DIM_WIDTH-1-C_POWER_OF_RDBPIX:0],{C_POWER_OF_RDBPIX{1'b0}}}     ;
assign SC_wog_rdbpix        = {SC_wog_cnt[C_DIM_WIDTH-1-C_POWER_OF_RDBPIX:0],{C_POWER_OF_RDBPIX{1'b0}}}     ;
assign SC_wog_pepix         = {SC_wog_cnt[C_DIM_WIDTH-1-C_POWER_OF_PEPIX:0] ,{C_POWER_OF_PEPIX{1'b0}}}      ;
assign SC_wog_pe_or_rdb_pix =  SL_split_en ? SC_wog_pepix : SC_wog_rdbpix                                   ; 

always @(posedge I_clk)begin
    SC_w  <= SC_wog_pe_or_rdb_pix + SC_woc_rdbpix   ;//dly=1 
end

// calculate SC_id 
// calculate SC_windex
// calculate SC_wremainder
// calculate SC_ibufaddr
genvar ws_idc;
generate
    begin:ws_idc_cm
        for(ws_idc=0;ws_idc<C_RDBPIX;ws_idc=ws_idc+1)begin:ws_idc_cm_s1
            divider #(
                .C_DIVIDEND   (C_DIM_WIDTH  ), 
                .C_DIVISOR    (C_DIM_WIDTH  ),
                .C_QUOTIENT   (C_DIM_WIDTH  ),
                .C_REMAINDER  (C_DIM_WIDTH  ))
            u_wws_div_rem(
                .I_clk        (I_clk                    ),
                .I_dividend   (SC_wws[ws_idc]           ),
                .I_divisor    (SL_wpart                 ),
                .O_quotient   (SC_wws_divwpart[ws_idc]  ),//dly=20
                .O_remainder  (SC_wws_remwpart[ws_idc]  )
            );
            always @(posedge I_clk)begin
                SC_wws[ws_idc]             <= SC_w + ws_idc                                         ;//dly=2
                //SC_wws_divwpart[ws_idc]  <= SC_wws[ws_idc] / SL_wpart                             ;
                //SC_wws_remwpart[ws_idc]  <= SC_wws[ws_idc] % SL_wpart                             ;
                SC_id[ws_idc]              <= SL_split_en ? SC_ndwog_cnt : SC_wws_divwpart[ws_idc]  ;//dly=21
                SC_windex[ws_idc]          <= $signed(SC_ndwws[ws_idc]) - $signed(I_pad_w)          ;//dly=21
                SC_wremainder[ws_idc]      <= SC_wws_remwpart[ws_idc]                               ;
            end
            //calculate SC_ibufaddr
            always @(posedge I_clk)begin
                SC_ibufaddr_t1[ws_idc] <= SC_windex[ws_idc] * SL_ci_group_1d                        ;//dly=22
                SC_ibufaddr[ws_idc]    <= SC_ibufaddr_t1[ws_idc] + SC_ndcig_cnt                     ;//dly=23 
            end
        end
    end
endgenerate

// calculate SC_id 
genvar ws_idx;
genvar p_idx;
generate
    begin:ws_p_idx
        for(p_idx=0;p_idx<C_PEPIX;p_idx=p_idx+1)begin:ws_p_idx_s1
            //main loop unroll
            for(ws_idx=0;ws_idx<C_RDBPIX;ws_idx=ws_idx+1)begin:ws_p_idx_s2
                //calculate SC_idforpix
                always @(posedge I_clk)begin
                    SC_id_more0[ws_idx]           <= $signed(SC_id[ws_idx]) > 0                                     ;//dly=22
                    SC_rem_less_thr[ws_idx][p_idx] <= $signed(SC_wremainder[ws_idx]) < $signed(SL_wthreshold[p_idx]);//dly=22 
                end
                always @(posedge I_clk)begin
                    if(SC_id_more0[ws_idx] && SC_rem_less_thr[ws_idx][p_idx] && (!SL_split_en))begin
                        SC_idforpix[ws_idx][p_idx] <= $signed(SC_ndid[ws_idx])-$signed(1);//dly=23
                    end
                    else begin
                        SC_idforpix[ws_idx][p_idx] <= $signed(SC_ndid[ws_idx]);
                    end
                end
                //calculate SC_pfirst
                //calculate SC_k 
                always @(posedge I_clk)begin
                    SC_pfirst[ws_idx][p_idx] <= SC_idforpix[ws_idx][p_idx] * SL_wpart                           ;//dly=24
                    SC_k_t1[ws_idx][p_idx]   <= $signed(SC_n1dwws[ws_idx]) - $signed(SC_pfirst[ws_idx][p_idx])  ;//dly=25
                    SC_k[ws_idx][p_idx]      <= $signed(SC_k_t1[ws_idx][p_idx])-$signed(SL_p_stride_w[p_idx])   ;//dly=26
                end
                //calculate SC_depth
                always @(posedge I_clk)begin
                    SC_depth_t1[ws_idx][p_idx]  <= SC_idforpix[ws_idx][p_idx] * SL_kernel_w_ci_group        ;//dly=24
                    SC_depth_t2[ws_idx][p_idx]  <= SC_depth_t1[ws_idx][p_idx] + SC_n1dcig_cnt               ;//dly=25 
                    SC_depth_t2a[ws_idx][p_idx] <= SC_depth_t2[ws_idx][p_idx]                               ;//dly=26 
                    SC_depth_t2b[ws_idx][p_idx] <= SC_depth_t2a[ws_idx][p_idx]                              ;//dly=27 
                    SC_depth_t3[ws_idx][p_idx]  <= SC_k[ws_idx][p_idx] * SL_ci_group_1d                     ;//dly=27 
                    SC_depth[ws_idx][p_idx]     <= SC_depth_t3[ws_idx][p_idx] + SC_depth_t2b[ws_idx][p_idx] ;//dly=28
                end

                suite_range #(
                    .C_DIM_WIDTH (C_CNV_K_WIDTH))
                u_k_suite_range(
                    .I_clk          (I_clk                      ),
                    .I_index        (SC_k[ws_idx][p_idx]        ),//dly=26
                    .I_index_upper  (I_kernel_w                 ),
                    .O_index_suite  (SC_k_suite[ws_idx][p_idx]  ) //dly=28
                );

                suite_range #(
                    .C_DIM_WIDTH (C_DIM_WIDTH))
                u_windex_suite_range(
                    .I_clk          (I_clk                          ),
                    .I_index        (SC_ndwindex[ws_idx]            ),//dly=26
                    .I_index_upper  (I_ipara_width                  ),
                    .O_index_suite  (SC_windex_suite[ws_idx][p_idx] ) //dly=28
                );

                //calculate SC_wr0,SC_wr1
                always @(posedge I_clk)begin
                    SC_wr0[ws_idx][p_idx]  <= SR_sbuf0_en && SC_k_suite[ws_idx][p_idx]   ;//dly=29
                    SC_wr1[ws_idx][p_idx]  <= SR_sbuf1_en && SC_k_suite[ws_idx][p_idx]   ;
                end

            end //ws_idx
            //calculate SL_wthreshold
            always @(posedge I_clk)begin
                SL_p_stride_w[p_idx]    <= p_idx * I_stride_w                                                               ;
                SL_wthreshold_t2[p_idx] <= SL_p_stride_w[p_idx] + I_kernel_w                                                ; 
                SL_wthreshold[p_idx]    <= $signed(SL_wthreshold_t2[p_idx])-$signed({I_stride_w,{C_POWER_OF_PEPIX{1'b0}}})  ;
            end
            //sbuf write process
            always @(posedge I_clk)begin
                SC_addr0[0][p_idx]  <= SR_sbuf0_en               ? SC_depth[0][p_idx] : I_sraddr0  ;//dly=29
                SC_addr0[1][p_idx]  <= SR_sbuf0_en               ? SC_depth[1][p_idx] : I_sraddr1  ; 
                SC_addr1[0][p_idx]  <= SR_sbuf1_en               ? SC_depth[0][p_idx] : I_sraddr0  ;
                SC_addr1[1][p_idx]  <= SR_sbuf1_en               ? SC_depth[1][p_idx] : I_sraddr1  ;
                SC_wdata0[0][p_idx] <= SC_windex_suite[0][p_idx] ? SC_ndibuf_rdata[0] : 0         ;//dly=29
                SC_wdata0[1][p_idx] <= SC_windex_suite[1][p_idx] ? SC_ndibuf_rdata[1] : 0         ;
                SC_wdata1[0][p_idx] <= SC_windex_suite[0][p_idx] ? SC_ndibuf_rdata[0] : 0         ;
                SC_wdata1[1][p_idx] <= SC_windex_suite[1][p_idx] ? SC_ndibuf_rdata[1] : 0         ;
            end
            //write to sbuf  
            dpram #(
                .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                .DSIZE      (C_RAM_DATA_WIDTH           ))
            u_sbuf0(
                .I_clk0     (I_clk                      ),
                .I_addr0    (SC_addr0[0][p_idx]         ),
                .I_wdata0   (SC_wdata0[0][p_idx]        ),
                .I_ce0      (1'b1                       ),
                .I_wr0      (SC_wr0[0][p_idx]           ),
                .O_rdata0   (SC_rdata0[0][p_idx]        ),
                .I_clk1     (I_clk                      ),
                .I_addr1    (SC_addr0[1][p_idx]         ),
                .I_wdata1   (SC_wdata0[1][p_idx]        ),
                .I_ce1      (1'b1                       ),
                .I_wr1      (SC_wr0[1][p_idx]           ),
                .O_rdata1   (SC_rdata0[1][p_idx]        )
            );
            dpram #(
                .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                .DSIZE      (C_RAM_DATA_WIDTH           ))
            u_sbuf1(
                .I_clk0     (I_clk                      ),
                .I_addr0    (SC_addr1[0][p_idx]         ),
                .I_wdata0   (SC_wdata1[0][p_idx]        ),
                .I_ce0      (1'b1                       ),
                .I_wr0      (SC_wr1[0][p_idx]           ),
                .O_rdata0   (SC_rdata1[0][p_idx]        ),
                .I_clk1     (I_clk                      ),
                .I_addr1    (SC_addr1[1][p_idx]         ),
                .I_wdata1   (SC_wdata1[1][p_idx]        ),
                .I_ce1      (1'b1                       ),
                .I_wr1      (SC_wr1[1][p_idx]           ),
                .O_rdata1   (SC_rdata1[1][p_idx]        )
            );
        end //p_idx
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// take the SC_rdata0/1 array to one larger width 
////////////////////////////////////////////////////////////////////////////////////////////////////

genvar ws_idr;
genvar p_idr;
generate
    begin:rdata_gen
        for(ws_idr=0;ws_idr<C_RDBPIX;ws_idr=ws_idr+1)begin:rs1
            for(p_idr=0;p_idr<C_PEPIX;p_idr=p_idr+1)begin:rs2
                assign SC_lrdata0[ws_idr][(p_idr+1)*C_M_AXI_DATA_WIDTH-1:p_idr*C_M_AXI_DATA_WIDTH] = SC_rdata0[ws_idr][p_idr];
                assign SC_lrdata1[ws_idr][(p_idr+1)*C_M_AXI_DATA_WIDTH-1:p_idr*C_M_AXI_DATA_WIDTH] = SC_rdata1[ws_idr][p_idr];
            end
        end
    end
endgenerate

always @(posedge I_clk)begin
    if(!SR_sbuf0_en)begin
        O_srdata0 <= SC_lrdata0[0]  ;
        O_srdata1 <= SC_lrdata0[1]  ;
    end
    else if(!SR_sbuf1_en)begin
        O_srdata0 <= SC_lrdata1[0]  ;
        O_srdata1 <= SC_lrdata1[1]  ;
    end
    else begin
        O_srdata0 <= 0              ; 
        O_srdata1 <= 0              ; 
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// ibuf raddress  
////////////////////////////////////////////////////////////////////////////////////////////////////

assign O_ibuf0_addr     = SC_ibufaddr[0];//dly=23
assign O_ibuf1_addr     = SC_ibufaddr[1];//dly=23 
assign SC_ibuf_rdata[0] = I_ibuf0_rdata ;//dly=26
assign SC_ibuf_rdata[1] = I_ibuf1_rdata ;//dly=26

////////////////////////////////////////////////////////////////////////////////////////////////////
// write qibuf 
////////////////////////////////////////////////////////////////////////////////////////////////////

genvar p_idq;
generate
    begin
        for(p_idq=0;p_idq<C_PEPIX;p_idq=p_idq+1)begin:p_idq_s1
            always @(posedge I_clk)begin
                SC_qwdata0[0][p_idq] <= SC_ndwindex_suite[0][p_idq] ? SC_sum[0]           : {C_QIBUF_WIDTH{1'b0}}   ;//dly=31
                SC_qwdata1[0][p_idq] <= SC_ndwindex_suite[0][p_idq] ? SC_sum[0]           : {C_QIBUF_WIDTH{1'b0}}   ;//dly=31
                SC_qwdata0[1][p_idq] <= SC_ndwindex_suite[1][p_idq] ? SC_sum[1]           : {C_QIBUF_WIDTH{1'b0}}   ;//dly=31
                SC_qwdata1[1][p_idq] <= SC_ndwindex_suite[1][p_idq] ? SC_sum[1]           : {C_QIBUF_WIDTH{1'b0}}   ;//dly=31
                 SC_qaddr0[0][p_idq] <= SR_sbuf0_en                 ? SC_ndepth[0][p_idq] : I_qraddr0               ;//dly=31
                 SC_qaddr0[1][p_idq] <= SR_sbuf0_en                 ? SC_ndepth[1][p_idq] : I_qraddr1               ; 
                 SC_qaddr1[0][p_idq] <= SR_sbuf1_en                 ? SC_ndepth[0][p_idq] : I_qraddr0               ;
                 SC_qaddr1[1][p_idq] <= SR_sbuf1_en                 ? SC_ndepth[1][p_idq] : I_qraddr1               ;
            end
            dpram #(
                .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                .DSIZE      (C_QIBUF_WIDTH              ))
            u_qibuf0(
                .I_clk0     (I_clk                      ),
                .I_addr0    (SC_qaddr0[0][p_idq]        ),
                .I_wdata0   (SC_qwdata0[0][p_idq]       ),
                .I_ce0      (1'b1                       ),
                .I_wr0      (SC_qwr0[0][p_idq]          ),
                .O_rdata0   (SC_qrdata0[0][p_idq]       ),
                .I_clk1     (I_clk                      ),
                .I_addr1    (SC_qaddr0[1][p_idq]        ),
                .I_wdata1   (SC_qwdata0[1][p_idq]       ),
                .I_ce1      (1'b1                       ),
                .I_wr1      (SC_qwr0[1][p_idq]          ),
                .O_rdata1   (SC_qrdata0[1][p_idq]       )
            );
            dpram #(
                .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                .DSIZE      (C_QIBUF_WIDTH              ))
            u_qibuf1(
                .I_clk0     (I_clk                      ),
                .I_addr0    (SC_qaddr1[0][p_idq]        ),
                .I_wdata0   (SC_qwdata1[0][p_idq]       ),
                .I_ce0      (1'b1                       ),
                .I_wr0      (SC_qwr1[0][p_idq]          ),
                .O_rdata0   (SC_qrdata1[0][p_idq]       ),
                .I_clk1     (I_clk                      ),
                .I_addr1    (SC_qaddr1[1][p_idq]        ),
                .I_wdata1   (SC_qwdata1[1][p_idq]       ),
                .I_ce1      (1'b1                       ),
                .I_wr1      (SC_qwr1[1][p_idq]          ),
                .O_rdata1   (SC_qrdata1[1][p_idq]       )
            );
        end
    end
endgenerate

iemem_sum #(
    .C_IEMEM_WIDTH (C_M_AXI_DATA_WIDTH ), 
    .C_SPLIT_WIDTH (C_DATA_WIDTH       ),
    .C_DATA_WIDTH  (C_QIBUF_WIDTH      ))
u_iemem_sum0(
    .I_clk         (I_clk              ),
    .I_din         (I_ibuf0_rdata      ),//dly=26
    .O_dout        (SC_sum[0]          ) //dly=30,hard
);

iemem_sum #(
    .C_IEMEM_WIDTH (C_M_AXI_DATA_WIDTH ), 
    .C_SPLIT_WIDTH (C_DATA_WIDTH       ),
    .C_DATA_WIDTH  (C_QIBUF_WIDTH      ))
u_iemem_sum1(
    .I_clk         (I_clk              ),
    .I_din         (I_ibuf1_rdata      ),
    .O_dout        (SC_sum[1]          )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// take the SC_qrdata0/1 array to one larger width 
////////////////////////////////////////////////////////////////////////////////////////////////////

genvar ws_idqr;
genvar p_idqr;
generate
    begin:idqrdata_gen
        for(ws_idqr=0;ws_idqr<C_RDBPIX;ws_idqr=ws_idqr+1)begin:rs1
            for(p_idqr=0;p_idqr<C_PEPIX;p_idqr=p_idqr+1)begin:rs2
                assign SC_lqrdata0[ws_idqr][(p_idqr+1)*C_QIBUF_WIDTH-1:p_idqr*C_QIBUF_WIDTH] = SC_qrdata0[ws_idqr][p_idqr];
                assign SC_lqrdata1[ws_idqr][(p_idqr+1)*C_QIBUF_WIDTH-1:p_idqr*C_QIBUF_WIDTH] = SC_qrdata1[ws_idqr][p_idqr];
            end
        end
    end
endgenerate

always @(posedge I_clk)begin
    if(!SR_sbuf0_en)begin
        O_qrdata0 <= SC_lqrdata0[0]  ;
        O_qrdata1 <= SC_lqrdata0[1]  ;
    end
    else if(!SR_sbuf1_en)begin
        O_qrdata0 <= SC_lqrdata1[0]  ;
        O_qrdata1 <= SC_lqrdata1[1]  ;
    end
    else begin
        O_qrdata0 <= 0              ; 
        O_qrdata1 <= 0              ; 
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
