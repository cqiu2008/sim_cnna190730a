//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : process_qbuf.v
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
module process_qbuf #(
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
//qbuf
output      [C_RAM_ADDR_WIDTH-1  :0]O_qraddr0           ,//dly=3
output      [C_RAM_ADDR_WIDTH-1  :0]O_qraddr1           , 
input       [  C_LQIBUF_WIDTH-1  :0]I_qrdata0           ,//dly=6
input       [  C_LQIBUF_WIDTH-1  :0]I_qrdata1           , 
// reg
input       [       C_DIM_WIDTH-1:0]I_hindex            ,
input       [     C_CNV_K_WIDTH-1:-]I_kh                ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_h          ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_w          ,
input                               I_hcnt_odd          ,
input                               I_enwr_obuf0        ,
input       [       C_DIM_WIDTH-1:0]I_ipara_height      ,
input       [       C_DIM_WIDTH-1:0]I_opara_width       ,
input       [    C_CNV_CH_WIDTH-1:0]I_ipara_ci           
);

localparam   C_RDBPIX         = {1'b1,{C_POWER_OF_RDBPIX{1'b0}}}        ;
localparam   C_WOT_DIV_PEPIX  = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_WOT_DIV_RDBPIX = C_DIM_WIDTH - C_POWER_OF_RDBPIX+1       ;
localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX    = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_CNV_K_GROUP    = C_CNV_K_WIDTH + C_NCH_GROUP             ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) SL_+"xx"  name type (S_layer_xxx) , means variable changed every layer   
//        such as SL_wo_total, SL_wo_group, SL_wpart ... and so on 
// (2) SR_+"xx"  name type (S_row_xxx), means variable changed every row 
//        such as SR_hindex , SR_hindex  ... and so on 
// (3) SC_+"xx"  name type (S_clock_xxx), means variable changed every clock 
//        such as SC_id , ... and so on 
////////////////////////////////////////////////////////////////////////////////////////////////////


reg                          SR_kh_equal0                                   ;
reg                          SR_hindex_equal0                               ;
reg                          SR_kh_or_hindex_equal0                         ;
reg                          SC_cig_cnt_equal0                              ;
reg                          SC_kw_cnt_equal0                               ;
reg                          SC_kw_and_cig_equal0                           ;
reg                          SC_noadd_qodout                                ;
wire                         SR_ndap_start                                  ;
reg  [                   3:0]SR_ndap_start_shift                            ;
wire                         SR_hindex_suite                                ;
reg  [     C_CNV_K_GROUP-1:0]SL_kernel_ci_group                             ; 
wire [       C_NCH_GROUP-1:0]SC_cig_cnt                                     ;
reg  [       C_NCH_GROUP-1:0]SC_cig_cnt_1d                                  ;
reg  [       C_NCH_GROUP-1:0]SC_cig_cnt_2d                                  ;
wire [       C_NCH_GROUP-1:0]SL_ci_group                                    ;   
reg  [       C_NCH_GROUP-1:0]SL_ci_group_1d                                 ;   
reg                          SC_cig_valid                                   ;
wire                         SC_cig_over_flag                               ; 
wire [     C_CNV_K_WIDTH-1:-]SC_kw_cnt                                      ;
wire                         SC_kw_valid                                    ;
wire                         SC_kw_over_flag                                ; 
wire [   C_WOT_DIV_PEPIX-1:0]SC_wog_cnt                                     ;
wire                         SC_wog_valid                                   ;
wire                         SC_wog_over_flag                               ; 
wire [   C_WOT_DIV_PEPIX-1:0]SL_wo_group                                    ;
reg  [   C_WOT_DIV_PEPIX-1:0]SL_wo_group_1d                                 ;
wire                         SR_qibuf0_en                                   ;
wire                         SR_qobuf0_en                                   ;
wire                         SR_qobuf1_en                                   ;
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_depth_s1a                                   ;
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_depth_s1b                                   ;
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_depth_s2                                    ;
reg  [C_RAM_ADDR_WIDTH-1  :0]SC_depth_s3                                    ;
reg  [  C_LQIBUF_WIDTH-1  :0]SC_qrdata                                      ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial layer variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// equal signals
always @(posedge I_clk)begin
    SR_kh_equal0            <= (I_kh == {C_CNV_K_WIDTH{1'b0}})                  ; 
    SR_hindex_equal0        <= (I_hindex == {C_DIM_WIDTH{1'b0}})                ;
    SR_kh_or_hindex_equal0  <= SR_kh_equal0 || SR_hindex_equal0                 ;
    SC_cig_cnt_equal0       <= (SC_cig_cnt == {C_NCH_GROUP{1'b0}})              ;//dly=1 
    SC_kw_cnt_equal0        <= (SC_kw_cnt == {C_CNV_K_WIDTH{1'b0}})             ; 
    SC_kw_and_cig_equal0    <=  SC_cig_cnt_equal0 && SC_kw_cnt_equal0           ;//dly=2 
    SC_noadd_qodout         <=  SC_kw_and_cig_equal0 && SR_kh_or_hindex_equal0  ;//dly=3
end

// calculate SL_wo_group    ;
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_DIM_WIDTH        ),
    .C_POWER2_NUM   (C_POWER_OF_PEPIX   ))
u_wog_group(
    .I_din          (I_opara_width      ),
    .O_dout         (SL_wo_group        )   
);

always @(posedge I_clk)begin
    SL_wo_group_1d <= SL_wo_group   ;
end

// calcuate SL_ci_group_1d
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_PECI    ))
u_ci_group(
    .I_din (I_ipara_ci),
    .O_dout(SL_ci_group )   
);

always @(posedge I_clk)begin
    SL_ci_group_1d <= SL_ci_group;
end

// calcuate SL_kernel_ci_group
always @(posedge I_clk)begin
    SL_kernel_ci_group  <= I_kernel_w  * SL_ci_group_1d;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial row variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// calcuate SR_hindex_suite
suite_range #(
    .C_DIM_WIDTH (C_DIM_WIDTH))
u_suite_range(
    .I_clk          (I_clk           ),
    .I_index        (I_hindex        ),
    .I_index_upper  (I_ipara_height  ),
    .O_index_suite  (SR_hindex_suite ) //dly=2
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// ap interface
////////////////////////////////////////////////////////////////////////////////////////////////////

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (3          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_ap_start      ),
    .O_dout    (SR_ndap_start    )
);

always @(posedge I_clk)begin
    SR_ndap_start_shift   <={SR_ndap_start_shift[2:0],(SR_ndap_start&&SR_hindex_suite)}    ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// loop cnt ctrl 
////////////////////////////////////////////////////////////////////////////////////////////////////

//calcualte valid signals
always @(posedge I_clk)begin
    if(SR_ndap_start_shift[0]&& I_ap_start)begin
        SC_cig_valid <= 1'b1;
    end
    else begin
        SC_cig_valid <= 1'b0;
    end
end

assign SC_kw_valid  = SC_cig_valid && SC_cig_over_flag ;
assign SC_wog_valid = SC_kw_valid  && SC_kw_over_flag   ;

cm_cnt #(
    .C_WIDTH(C_NCH_GROUP))
u_loop1_cig_cnt (
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_cig_valid           ),
.I_cnt_upper        (SL_ci_group_1d         ),
.O_over_flag        (SC_cig_over_flag       ),
.O_cnt              (SC_cig_cnt             )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_CNV_K_WIDTH))
u_loop2_kw_cnt (
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_kw_valid            ),
.I_cnt_upper        (I_kernel_w             ),
.O_over_flag        (SC_kw_over_flag        ),
.O_cnt              (SC_kw_cnt              )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_WOT_DIV_PEPIX))
u_loop3_wog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_cig_valid           ),
.I_cnt_valid        (SC_wog_valid           ),
.I_cnt_upper        (SL_wo_group_1d         ),
.O_over_flag        (SC_wog_over_flag       ),
.O_cnt              (SC_wog_cnt             )//dly=0
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// read data from qibuf 
////////////////////////////////////////////////////////////////////////////////////////////////////

// calculate SC_depth_s3
always @(posedge I_clk)begin
    SC_cig_cnt_1d   <= SC_cig_cnt                           ;
    SC_cig_cnt_2d   <= SC_cig_cnt_1d                        ;
    SC_depth_s1a    <= SC_wog_cnt * SL_kernel_ci_group      ;
    SC_depth_s1b    <= SC_kw_cnt  * SL_ci_group_1d          ;
    SC_depth_s2     <= SC_depth_s1a + SC_depth_s1b          ; 
    SC_depth_s3     <= SC_depth_s2 + SC_cig_cnt_2d          ;//dly=3
end

assign O_qraddr0 = SC_depth_s3 ;
assign O_qraddr1 = SC_depth_s3 ;

always @(posedge I_clk)begin
    SC_qrdata <= SR_qibuf0_en ? I_qrdata0 : I_qrdata1       ;//dly=7
end

// calculate buf_en
assign SR_qibuf0_en  = ~I_hcnt_odd   ; 
assign SR_qobuf0_en  = I_enwr_obuf0  ;
assign SR_qobuf1_en  = ~I_enwr_obuf0 ;

// output      [C_RAM_ADDR_WIDTH-1  :0]O_qraddr0           ,//dly=3
// output      [C_RAM_ADDR_WIDTH-1  :0]O_qraddr1           , 
// input       [  C_LQIBUF_WIDTH-1  :0]I_qrdata0           ,//dly=6
// input       [  C_LQIBUF_WIDTH-1  :0]I_qrdata1           , 
// write here by cqiu
addsumram #(
    .C_MEM_STYLE    (C_MEM_STYLE      ),
    .C_ISIZE        (C_QIBUF_WIDTH    ),
    .C_DSIZE        (C_QOBUF_WIDTH    ),
    .C_ASIZE        (C_RAM_ADDR_WIDTH ))
u_addsumram(
    .I_clk          (I_clk            ),
    .I_first_flag   (I_first_flag     ),
    .I_dv_pre4      (I_dv_pre4        ),//dly=0
    .I_din          (I_din            ),
    .I_dven         (I_dven           ),
    .I_raddr        (I_raddr          ),
    .O_rdata        (O_rdata          )     
);


////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule

