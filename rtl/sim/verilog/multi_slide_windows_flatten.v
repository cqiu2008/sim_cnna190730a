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
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_RAM_ADDR_WIDTH        = 9         ,
    C_RAM_DATA_WIDTH        = 128       
)(
// clk
input                               I_clk               ,
input                               I_rst               ,
input                               I_allap_start       ,
input                               I_ap_start          ,
output reg                          O_ap_done           ,
//ibuf
output      [C_RAM_ADDR_WIDTH-1  :0]O_ibuf0_addr        , 
output      [C_RAM_ADDR_WIDTH-1  :0]O_ibuf1_addr        , 
input       [C_RAM_DATA_WIDTH-1  :0]I_ibuf0_rdata       , 
input       [C_RAM_DATA_WIDTH-1  :0]I_ibuf1_rdata       , 
//sbuf
input       [C_RAM_ADDR_WIDTH-1  :0]I_raddr0            , 
input       [C_RAM_ADDR_WIDTH-1  :0]I_raddr1            , 
output reg  [C_RAM_DATA_WIDTH-1  :0]O_rdata0            , 
output reg  [C_RAM_DATA_WIDTH-1  :0]O_rdata1            , 
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

localparam   C_AP_START       = 16                                      ; 
localparam   C_RDBPIX         = {1'b1,{C_POWER_OF_RDBPIX{1'b0}}}        ;
localparam   C_WOT_DIV_PEPIX  = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_WOT_DIV_RDBPIX = C_DIM_WIDTH - C_POWER_OF_RDBPIX+1       ;
localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX    = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_CNV_K_GROUP    = C_CNV_K_WIDTH + C_NCH_GROUP             ;
localparam   C_PADDING        = 6                                       ;

wire [       C_DIM_WIDTH-1:0]S_hcnt                                     ;
wire                         S_hindex_suite                             ;
wire [       C_DIM_WIDTH-1:0]S_sbuf0_index                              ; 
wire [       C_DIM_WIDTH-1:0]S_sbuf1_index                              ; 
reg                          S_sbuf0_index_neq                          ; 
reg                          S_sbuf1_index_neq                          ; 
reg  [        C_AP_START-1:0]S_ap_start_shift                           ; 
reg                          S_swap_start                               ;
reg                          S_swap_done                                ;
reg                          S_sbuf0_en                                 ;
reg                          S_sbuf1_en                                 ;
reg                          S_no_suite_done                            ;
reg                          S_split_en                                 ;
reg  [     C_CNV_K_WIDTH-1:0]S_pepix_stride_w                           ;
reg  [     C_CNV_K_WIDTH-1:0]S_pesub1pix_stride_w                       ;
reg  [       C_DIM_WIDTH-1:0]S_pesub1pix_stride_w_addkernel             ;
wire [  C_WOT_DIV_RDBPIX-1:0]S_pesub1pix_stride_w_addkernel_div_rdb     ;
reg  [       C_DIM_WIDTH-1:0]S_wo_total1                                ;
reg  [       C_DIM_WIDTH-1:0]S_wo_total2                                ;
reg  [       C_DIM_WIDTH-1:0]S_wo_total3                                ;
reg  [       C_DIM_WIDTH-1:0]S_wo_total                                 ;
wire [   C_WOT_DIV_PEPIX-1:0]S_wot_div_pepix                            ;
wire [  C_WOT_DIV_RDBPIX-1:0]S_wot_div_rdbpix                           ;
reg  [       C_DIM_WIDTH-1:0]S_wpart                                    ;
reg  [       C_DIM_WIDTH-1:0]S_id[C_RDBPIX]                             ;
reg                          S_id_more0[C_RDBPIX]                       ;

reg  [       C_DIM_WIDTH-1:0]S_windex[C_RDBPIX]                         ;
reg                          S_windex_suite[C_RDBPIX][C_PEPIX]          ;
reg  [       C_DIM_WIDTH-1:0]S_wremainder[C_RDBPIX]                     ;
reg  [       C_DIM_WIDTH-1:0]S_wthreshold[C_PEPIX]                      ;
reg  [     C_CNV_K_PEPIX-1:0]S_p_stride_w[C_PEPIX]                      ;

reg  [       C_DIM_WIDTH-1:0]S_wthreshold_t2[C_PEPIX]                   ;
reg                          S_rem_less_thr[C_RDBPIX][C_PEPIX]          ;
reg  [       C_DIM_WIDTH-1:0]S_idforpix[C_RDBPIX][C_PEPIX]              ;
reg  [       C_DIM_WIDTH-1:0]S_pfirst[C_RDBPIX][C_PEPIX]                ;
reg  [     C_CNV_K_WIDTH-1:0]S_k[C_RDBPIX][C_PEPIX]                     ;
reg  [     C_CNV_K_WIDTH-1:0]S_k_t1[C_RDBPIX][C_PEPIX]                  ;
reg                          S_k_suite[C_RDBPIX][C_PEPIX]               ;

reg  [       C_DIM_WIDTH-1:0]S_depth[C_RDBPIX][C_PEPIX]                 ;
reg  [       C_DIM_WIDTH-1:0]S_depth_t1[C_RDBPIX][C_PEPIX]              ;
reg  [       C_DIM_WIDTH-1:0]S_depth_t2[C_RDBPIX][C_PEPIX]              ;
reg  [       C_DIM_WIDTH-1:0]S_depth_t3[C_RDBPIX][C_PEPIX]              ;
reg  [  C_RAM_ADDR_WIDTH-1:0]S_ibufaddr[C_RDBPIX]                       ;

reg  [     C_QIBUF_WIDTH-1:0]S_sum[C_RDBPIX]                            ;
wire [       C_NCH_GROUP-1:0]S_cig_cnt                                  ;
wire [       C_NCH_GROUP-1:0]S_ci_group                                 ;   
reg  [       C_NCH_GROUP-1:0]S_ci_group_1d                              ;   
reg                          S_cig_valid                                ;
wire                         S_cig_over_flag                            ; 
wire [       C_DIM_WIDTH-1:0]S_woc_cnt                                  ;
reg  [       C_DIM_WIDTH-1:0]S_wo_consume                               ;
wire                         S_woc_valid                                ;
wire                         S_woc_over_flag                            ; 
wire [       C_DIM_WIDTH-1:0]S_wog_cnt                                  ;
reg  [       C_DIM_WIDTH-1:0]S_wo_group                                 ;
wire                         S_wog_valid                                ;
wire                         S_wog_over_flag                            ; 
reg  [         C_PADDING-1:0]S_padding_cnt                              ;
reg  [       C_DIM_WIDTH-1:0]S_w                                        ;
reg  [       C_DIM_WIDTH-1:0]S_wws[C_RDBPIX]                            ;
reg  [       C_DIM_WIDTH-1:0]S_wws_divwpart[C_RDBPIX]                   ;
reg  [       C_DIM_WIDTH-1:0]S_wws_remwpart[C_RDBPIX]                   ;
reg  [       C_DIM_WIDTH-1:0]S_woc_rdbpix                               ;
reg  [       C_DIM_WIDTH-1:0]S_wog_rdbpix                               ;
reg  [       C_DIM_WIDTH-1:0]S_wog_pepix                                ;
reg  [     C_CNV_K_GROUP-1:0]S_kernel_w_ci_group                        ;

reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr0[C_RDBPIX][C_PEPIX]                ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata0[C_RDBPIX]                        ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata0[C_RDBPIX][C_PEPIX]               ;                                  
reg                          S_wr0[C_RDBPIX][C_PEPIX]                  ;                                     
reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr1[C_RDBPIX][C_PEPIX]                ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata1[C_RDBPIX]                        ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata1[C_RDBPIX][C_PEPIX]               ;                                  
reg                          S_wr1[C_RDBPIX][C_PEPIX]                  ;                                     


////////////////////////////////////////////////////////////////////////////////////////////////////
// initial variable
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    S_pepix_stride_w                <= {I_stride_w[C_CNV_K_WIDTH-C_POWER_OF_PEPIX-1:0],{C_POWER_OF_PEPIX{1'b0}}};
    S_pesub1pix_stride_w            <= S_pepix_stride_w - I_stride_w                                            ; 
    S_pesub1pix_stride_w_addkernel  <= S_pesub1pix_stride_w + I_kernel_w                                        ;
    S_split_en                      <= ~(I_kernel_w < S_pepix_stride_w)                                         ;

    S_wo_total1                     <= I_ipara_width + {I_pad_w[C_CNV_K_WIDTH-1:0],1'b0}                        ;
    S_wo_total2                     <= S_wo_total1 - I_kernel_w                                                 ; 
    S_wo_total3                     <= S_wo_total2 / I_stride_w                                                 ;////divtag
    S_wo_total                      <= S_wo_total3 + 1                                                          ;
    S_wpart                         <= {{(C_DIM_WIDTH-C_CNV_K_WIDTH-C_POWER_OF_PEPIX){1'b0}},
                                        I_stride_w[C_CNV_K_WIDTH-1:0],{C_POWER_OF_PEPIX{1'b0}}}                 ;
    S_woc_rdbpix                    <= {S_woc_cnt[C_DIM_WIDTH-1-C_POWER_OF_RDBPIX:0],{C_POWER_OF_RDBPIX{1'b0}}}     ;
    S_wog_rdbpix                    <= {S_wog_cnt[C_DIM_WIDTH-1-C_POWER_OF_RDBPIX:0],{C_POWER_OF_RDBPIX{1'b0}}}     ;
    S_wog_pepix                     <= {S_wog_cnt[C_DIM_WIDTH-1-C_POWER_OF_PEPIX:0] ,{C_POWER_OF_PEPIX{1'b0}}}      ;
    S_w                             <= S_split_en ? S_wog_pepix + S_woc_rdbpix  : S_wog_rdbpix + S_woc_rdbpix   ; 
    S_kernel_w_ci_group             <= I_kernel_w  * S_ci_group_1d                                              ; 
end

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_PEPIX   ))
U0_wot_div_pepix(
    .I_din (S_wo_total          ),
    .O_dout(S_wot_div_pepix     )   
);

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_RDBPIX  ))
U0_wot_div_rdbpix(
    .I_din (S_wo_total1         ),
    .O_dout(S_wot_div_rdbpix    )   
);

always @(posedge I_clk)begin
    if(S_split_en)begin
        S_wo_group  <=   S_wot_div_pepix    ;
    end
    else begin
        S_wo_group  <=   S_wot_div_rdbpix   ;
    end
end

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_RDBPIX  ))
U0_pesub1pix_div_rdb(
    .I_din (S_pesub1pix_stride_w_addkernel              ), 
    .O_dout(S_pesub1pix_stride_w_addkernel_div_rdb      )
);

always @(posedge I_clk)begin
    if(S_split_en)begin
        S_wo_consume <= S_pesub1pix_stride_w_addkernel_div_rdb  ;   
    end
    else begin
        S_wo_consume <= {{(C_DIM_WIDTH-1){1'b0}},1'b1}; 
    end
end

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_PECI    ))
U0_ci_group(
    .I_din (I_ipara_ci),
    .O_dout(S_ci_group )   
);

always @(posedge I_clk)begin
    S_ci_group_1d <= S_ci_group;
end

//    C_POWER_OF_RDBPIX       = 1         , 

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_sbuf0_index(
    .I_clk        (I_clk          ),
    .I_ap_start   (I_allap_start  ),
    .I_index_en   (S_sbuf0_en     ),
    .I_index      (I_hindex       ),
    .O_index_lck  (S_sbuf0_index  )     
);

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_sbuf1_index(
    .I_clk        (I_clk          ),
    .I_ap_start   (I_allap_start  ),
    .I_index_en   (S_sbuf1_en     ),
    .I_index      (I_hindex       ),
    .O_index_lck  (S_sbuf1_index  )     
);

suite_range #(
    .C_DIM_WIDTH (C_DIM_WIDTH))
u_suite_range(
    .I_clk          (I_clk           ),
    .I_index        (I_hindex        ),
    .I_index_upper  (I_ipara_height  ),
    .O_index_suite  (S_hindex_suite  )
);

always @(posedge I_clk)begin
    S_ap_start_shift    <= {S_ap_start_shift[C_AP_START-2:0],I_ap_start}        ;
    S_sbuf0_index_neq   <= S_sbuf0_index != I_hindex                            ; 
    S_sbuf1_index_neq   <= S_sbuf1_index != I_hindex                            ; 
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_ap_start_shift[7:6] == 2'b01)begin
            S_sbuf0_en  <= S_hindex_suite && S_sbuf0_index_neq && ( I_hcnt_odd) ;
            S_sbuf1_en  <= S_hindex_suite && S_sbuf1_index_neq && (~I_hcnt_odd) ;
        end
        else begin
            S_sbuf0_en  <= S_sbuf0_en   ; 
            S_sbuf1_en  <= S_sbuf1_en   ; 
        end
    end
    else begin
        S_sbuf0_en <= 1'b0;
        S_sbuf1_en <= 1'b0;
    end
end
always @(posedge I_clk)begin
    S_swap_start <= S_sbuf0_en | S_sbuf1_en;
end


always @(posedge I_clk)begin
    S_no_suite_done  <= (S_ap_start_shift[9:8]==2'b01) && (~S_swap_start); 
    O_ap_done        <= S_no_suite_done || S_swap_done                   ; 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate variable
////////////////////////////////////////////////////////////////////////////////////////////////////

genvar ws_idc;
generate
    begin:ws_idc_cm
        for(ws_idc=0;ws_idc<C_RDBPIX;ws_idc=ws_idc+1)begin
            always @(posedge I_clk)begin
                S_wws[ws_idc]                   <= S_w + ws_idc                                     ;
                S_wws_divwpart[ws_idc]          <= S_wws[ws_idc] / S_wpart                          ;//divtag
                S_wws_remwpart[ws_idc]          <= S_wws[ws_idc] % S_wpart                          ;//divtag
                S_id[ws_idc]                    <= S_split_en ? S_wog_cnt : S_wws_divwpart[ws_idc]  ;
                S_windex[ws_idc]                <= $signed(S_wws[ws_idc] - I_pad_w)                 ;
                S_wremainder[ws_idc]            <= S_wws_remwpart[ws_idc]                           ;
            end
        end
    end
endgenerate

assign O_ibuf0_addr = S_ibufaddr[0]; 
assign O_ibuf1_addr = S_ibufaddr[1]; 

iemem_sum #(
    .C_IEMEM_WIDTH (C_M_AXI_DATA_WIDTH ), 
    .C_SPLIT_WIDTH (C_DATA_WIDTH       ),
    .C_DATA_WIDTH  (C_QIBUF_WIDTH      ))
u_iemem_sum0(
    .I_clk         (I_clk              ),
    .I_din         (I_ibuf0_rdata      ),
    .O_dout        (S_sum[0]           )
);

iemem_sum #(
    .C_IEMEM_WIDTH (C_M_AXI_DATA_WIDTH ), 
    .C_SPLIT_WIDTH (C_DATA_WIDTH       ),
    .C_DATA_WIDTH  (C_QIBUF_WIDTH      ))
u_iemem_sum1(
    .I_clk         (I_clk              ),
    .I_din         (I_ibuf1_rdata      ),
    .O_dout        (S_sum[1]           )
);

genvar ws_idx;
genvar p_idx;

generate
    begin:ws_p_idx
        for(p_idx=0;p_idx<C_PEPIX;p_idx=p_idx+1)begin

            always @(posedge I_clk)begin
                S_p_stride_w[p_idx]     <= p_idx * I_stride_w                                                       ;
                S_wthreshold_t2[p_idx]  <= S_p_stride_w[p_idx] + I_kernel_w                                         ; 
                S_wthreshold[p_idx]     <= $signed(S_wthreshold_t2[p_idx]-{I_stride_w,{C_POWER_OF_PEPIX{1'b0}}})    ;
            end

            for(ws_idx=0;ws_idx<C_RDBPIX;ws_idx=ws_idx+1)begin

                always @(posedge I_clk)begin

                    S_ibufaddr[ws_idx]              <= S_windex[ws_idx] * S_ci_group_1d + S_cig_cnt ; 
                    S_id_more0[ws_idx]              <= S_id[ws_idx] > 0                             ;
                    S_rem_less_thr[ws_idx][p_idx]   <= S_wremainder[ws_idx] < S_wthreshold[p_idx]   ; 

                    if(S_id_more0[ws_idx] && S_rem_less_thr[ws_idx][p_idx] && (!S_split_en))begin
                        S_idforpix[ws_idx][p_idx]   <= $signed(S_id[ws_idx]-1);
                    end
                    else begin
                        S_idforpix[ws_idx][p_idx]   <= $signed(S_id[ws_idx]);
                    end

                    S_pfirst[ws_idx][p_idx]         <= S_idforpix[ws_idx][p_idx] * S_wpart;
                    S_k_t1[ws_idx][p_idx]           <= $signed(S_wws[ws_idx] - S_pfirst[ws_idx][p_idx])     ;
                    S_k[ws_idx][p_idx]              <= $signed(S_k_t1[ws_idx][p_idx]-S_p_stride_w[p_idx])   ;
                    S_depth_t1[ws_idx][p_idx]       <= S_idforpix[ws_idx][p_idx] * S_kernel_w_ci_group      ;
                    S_depth_t2[ws_idx][p_idx]       <= S_depth_t1[ws_idx][p_idx] + S_cig_cnt                ; 
                    S_depth_t3[ws_idx][p_idx]       <= S_k[ws_idx][p_idx] * S_ci_group_1d                   ; 
                    S_depth[ws_idx][p_idx]          <= S_depth_t3[ws_idx][p_idx] + S_depth_t2[ws_idx][p_idx];

                    S_wr0[ws_idx][p_idx]            <= S_sbuf0_en && S_k_suite[ws_idx][p_idx]               ;
                    S_wr1[ws_idx][p_idx]            <= S_sbuf1_en && S_k_suite[ws_idx][p_idx]               ;

                end

                suite_range #(
                    .C_DIM_WIDTH (C_CNV_K_WIDTH))
                u_k_suite_range(
                    .I_clk          (I_clk                      ),
                    .I_index        (S_k[ws_idx][p_idx]         ),
                    .I_index_upper  (I_kernel_w                 ),
                    .O_index_suite  (S_k_suite[ws_idx][p_idx]   )
                );

                suite_range #(
                    .C_DIM_WIDTH (C_DIM_WIDTH))
                u_windex_suite_range(
                    .I_clk          (I_clk                                              ),
                    .I_index        (S_windex[ws_idx]                                   ),
                    .I_index_upper  ({{(C_DIM_WIDTH-C_CNV_K_WIDTH){1'b0}},I_kernel_w}   ),
                    .O_index_suite  (S_windex_suite[ws_idx][p_idx]                      )
                );

            end //ws_idx
                always @(posedge I_clk)begin
                    S_addr0[0][p_idx]               <= S_sbuf0_en ? S_depth[0][p_idx] : I_raddr0        ; 
                    S_addr0[1][p_idx]               <= S_sbuf0_en ? S_depth[1][p_idx] : I_raddr1        ; 
                    S_addr1[0][p_idx]               <= S_sbuf1_en ? S_depth[0][p_idx] : I_raddr0        ;
                    S_addr1[1][p_idx]               <= S_sbuf1_en ? S_depth[1][p_idx] : I_raddr1        ;
                    S_wdata0[0]                     <= S_windex_suite[0][p_idx] ? I_ibuf0_rdata : 0     ;
                    S_wdata0[1]                     <= S_windex_suite[1][p_idx] ? I_ibuf1_rdata : 0     ;
                    S_wdata1[0]                     <= S_windex_suite[0][p_idx] ? I_ibuf0_rdata : 0     ;
                    S_wdata1[1]                     <= S_windex_suite[1][p_idx] ? I_ibuf1_rdata : 0     ;
                end

                dpram #(
                    .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                    .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                    .DSIZE      (C_RAM_DATA_WIDTH           ))
                u_sbuf0(
                    .I_clk0     (I_clk                      ),
                    .I_addr0    (S_addr0[0][p_idx]          ),
                    .I_wdata0   (S_wdata0[0]                ),
                    .I_ce0      (1'b1                       ),
                    .I_wr0      (S_wr0[0][p_idx]            ),
                    .O_rdata0   (S_rdata0[0][p_idx]         ),
                    .I_clk1     (I_clk                      ),
                    .I_addr1    (S_addr0[1][p_idx]          ),
                    .I_wdata1   (S_wdata0[1]                ),
                    .I_ce1      (1'b1                       ),
                    .I_wr1      (S_wr0[1][p_idx]            ),
                    .O_rdata1   (S_rdata0[1][p_idx]         )
                );

                dpram #(
                    .MEM_STYLE  (C_MEM_STYLE                ),//"distributed"
                    .ASIZE      (C_RAM_ADDR_WIDTH           ),   
                    .DSIZE      (C_RAM_DATA_WIDTH           ))
                u_sbuf1(
                    .I_clk0     (I_clk                      ),
                    .I_addr0    (S_addr1[0][p_idx]          ),
                    .I_wdata0   (S_wdata1[0]                ),
                    .I_ce0      (1'b1                       ),
                    .I_wr0      (S_wr1[0][p_idx]            ),
                    .O_rdata0   (S_rdata1[0][p_idx]         ),
                    .I_clk1     (I_clk                      ),
                    .I_addr1    (S_addr1[1][p_idx]          ),
                    .I_wdata1   (S_wdata1[1]                ),
                    .I_ce1      (1'b1                       ),
                    .I_wr1      (S_wr1[1][p_idx]            ),
                    .O_rdata1   (S_rdata1[1][p_idx]         )
                );

        end //p_idx
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// loop cnt ctrl 
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    if(S_swap_start)begin
        if(&S_padding_cnt)begin
            S_padding_cnt <= S_padding_cnt  ;
        end
        else begin
            S_padding_cnt <= S_padding_cnt  + {{(C_PADDING-1){1'b0}},1'b1};
        end
    end
    else begin
        S_padding_cnt <= {C_PADDING{1'b0}}; 
    end
end

always @(posedge I_clk)begin
    if(S_padding_cnt > 8)begin
        S_cig_valid <= 1'b1;
    end
    else begin
        S_cig_valid <= 1'b0;
    end
end

assign S_woc_valid = S_cig_valid && S_cig_over_flag ;
assign S_wog_valid = S_woc_valid && S_woc_over_flag ;

cm_cnt #(
    .C_WIDTH(C_NCH_GROUP))
U0_loop1_cig_cnt (
.I_clk              (I_clk                  ),
.I_cnt_en           (S_swap_start           ),
.I_lowest_cnt_valid (S_cig_valid            ),
.I_cnt_valid        (S_cig_valid            ),
.I_cnt_upper        (S_ci_group_1d          ),
.O_over_flag        (S_cig_over_flag        ),
.O_cnt              (S_cig_cnt              )
);

cm_cnt #(
    .C_WIDTH(C_DIM_WIDTH))
U0_loop2_woc_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (S_swap_start           ),
.I_lowest_cnt_valid (S_cig_valid            ),
.I_cnt_valid        (S_woc_valid            ),
.I_cnt_upper        (S_wo_consume           ),
.O_over_flag        (S_woc_over_flag        ),
.O_cnt              (S_woc_cnt              )
);

cm_cnt #(
    .C_WIDTH(C_DIM_WIDTH))
U0_loop3_wog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (S_swap_start           ),
.I_lowest_cnt_valid (S_cig_valid            ),
.I_cnt_valid        (S_wog_valid            ),
.I_cnt_upper        (S_wo_group             ),
.O_over_flag        (S_wog_over_flag        ),
.O_cnt              (S_wog_cnt              )
);

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_wog_valid && S_wog_over_flag)begin
            S_swap_done <= 1'b1;
        end
        else begin
            S_swap_done <= S_swap_done; 
        end
    end
    else begin
        S_swap_done <= 1'b0;
    end
end
////////////////////////////////////////////////////////////////////////////////////////////////////
// load_image  
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) w+"xxx" name type , means write clock domain                                             
//        such as wrst,wclk,winc,wdata, wptr, waddr,wfull, and so on                            
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//        u0_wptr_full                                                                           
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
