//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : main_post.v
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
module main_post #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_POWER_OF_RDBPIX       = 1         , 
    C_PEPIX                 = 8         ,
    C_SUBLAYERS_WIDTH       = 11        , 
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
    C_COEF_DATA             = 8*16*32   , 
    C_LQOBUF_WIDTH          = 8*24      ,//write here
    C_LOBUF_WIDTH           = 8*32*24   ,//write here
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
// reg
input                               I_fc_en             ,
input                               I_cnv_en            ,
input                               I_pool_en           ,
input       [ C_SUBLAYERS_WIDTH-1:0]I_sublayer_num      , 
input       [ C_SUBLAYERS_WIDTH-1:0]I_sublayer_seq      , 
input       [       C_DIM_WIDTH-1:0]I_posthaddr         , 
input       [       C_DIM_WIDTH-1:0]I_opara_width       ,//ok
input       [    C_CNV_CH_WIDTH-1:0]I_opara_co          ,//ok
//qobuf
output      [C_RAM_ADDR_WIDTH-1  :0]O_qoraddr           ,
input       [  C_LQOBUF_WIDTH-1  :0]I_qordata0          , 
input       [  C_LQOBUF_WIDTH-1  :0]I_qordata1          , 
//obuf
output      [  C_RAM_ADDR_WIDTH-1:0]O_oraddr            ,
input       [ C_OBUF_DATA_WIDTH-1:0]I_ordata0           ,
input       [ C_OBUF_DATA_WIDTH-1:0]I_ordata1           ,
//bbuf
output      [  C_RAM_ADDR_WIDTH-1:0]O_braddr            ,        
input       [  C_RAM_DATA_WIDTH-1:0]I_brdata            ,
// master write address channel
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr         ,
output      [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_awlen        ,
input                               I_maxi_awready      ,   
output                              O_maxi_awvalid      ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_awaddr       ,
input                               I_maxi_wready       ,
output                              O_maxi_wvalid       ,
output      [C_M_AXI_DATA_WIDTH-1:0]O_maxi_wdata        ,       
input                               I_maxi_bvalid       ,
output                              O_maxi_bready           
);

localparam   C_WOT_DIV_PEPIX  = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_NCO_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECO + 1    ;
localparam   C_NCI_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX    = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_KCI_GROUP      = C_CNV_K_WIDTH + C_NCI_GROUP             ;
localparam   C_FILTER_WIDTH   = C_CNV_K_WIDTH + C_CNV_K_WIDTH           ;
localparam   C_PECO           = {1'b1,{C_POWER_OF_PECO{1'b0}}}          ; 
localparam   C_PECI           = {1'b1,{C_POWER_OF_PECI{1'b0}}}          ; 
localparam   C_HALF_PECO      = {1'b1,{(C_POWER_OF_PECO-1){1'b0}}}      ; 

localparam   C_PIX_WIDTH      = C_PECI*C_DATA_WIDTH                     ; 
localparam   C_COE_WIDTH      = C_PECI*C_DATA_WIDTH                     ; 
localparam   C_SUM_WIDTH      = 20                                      ; 
localparam   C_COCNT_WIDTH    = 2                                       ;
localparam   C_PCNT_WIDTH     = C_POWER_OF_PEPIX+1                      ;

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) SL_+"xx"  name type (S_layer_xxx) , means variable changed every layer   
//        such as SL_wo_total, SL_wo_group, SL_wpart ... and so on 
// (2) SR_+"xx"  name type (S_row_xxx), means variable changed every row 
//        such as SR_hindex , SR_hindex  ... and so on 
// (3) SC_+"xx"  name type (S_clock_xxx), means variable changed every clock 
//        such as SC_id , ... and so on 
////////////////////////////////////////////////////////////////////////////////////////////////////
wire [   C_WOT_DIV_PEPIX-1:0]SL_wo_group                                    ;
reg  [   C_WOT_DIV_PEPIX-1:0]SL_wo_group_1d                                 ;
wire [       C_NCO_GROUP-1:0]SL_co_group                                    ;   
reg  [       C_NCO_GROUP-1:0]SL_co_group_1d                                 ;   
reg                          SL_bias_en                                     ;
reg                          SL_sublayer_last                               ;
wire                         SR_ndap_start                                  ;
reg                          SR_ndap_start_1d                               ;
reg  [                   3:0]SR_ndap_start_shift                            ;
wire [     C_COCNT_WIDTH-1:0]SC_co_cnt                                      ;
reg                          SC_co_valid                                    ;//dly=0
wire                         SC_co_over_flag                                ; 
wire [       C_NCO_GROUP-1:0]SC_cog_cnt                                     ;   
wire                         SC_cog_valid                                   ;
wire                         SC_cog_over_flag                               ; 
wire [      C_PCNT_WIDTH-1:0]SC_pix_cnt                                     ;   
wire                         SC_pix_valid                                   ;
wire                         SC_pix_over_flag                               ; 
wire [   C_WOT_DIV_PEPIX-1:0]SC_wog_cnt                                     ;
wire                         SC_wog_valid                                   ;
wire                         SC_wog_over_flag                               ; 


////////////////////////////////////////////////////////////////////////////////////////////////////
// initial layer variable
////////////////////////////////////////////////////////////////////////////////////////////////////

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

// calculate SL_co_group_1d
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_PECO    ))
u_co_group(
    .I_din (I_opara_co),
    .O_dout(SL_co_group )   
);

always @(posedge I_clk)begin
    SL_co_group_1d <= SL_co_group;
end

// calculate SL_bias_en
always @(posedge I_clk)begin
    SL_sublayer_last <= I_sublayer_num == (I_sublayer_seq + {{(C_SUBLAYERS_WIDTH-1){1'b0}},1'b1});
    SL_bias_en <= I_cnv_en || (I_fc_en && SL_sublayer_last) ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial row variable
////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////
// variable change every clock 
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// get wbuf rdata 
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// ap interface
////////////////////////////////////////////////////////////////////////////////////////////////////

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (3          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_ap_start      ),
    .O_dout    (SR_ndap_start   )
);

always @(posedge I_clk)begin
    SR_ndap_start_1d    <= SR_ndap_start                                ;
    SR_ndap_start_shift <={SR_ndap_start_shift[2:0],(SR_ndap_start)}    ;
end

always @(posedge I_clk)begin
    //O_ap_done           <= ((~SR_ndap_start_1d) && SR_ndap_start && (~SR_hindex_suite)) || (SC_mdcig_valid_2d && (~SC_mdcig_valid_1d)) ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// loop cnt ctrl 
////////////////////////////////////////////////////////////////////////////////////////////////////

//calcualte valid signals
always @(posedge I_clk)begin
    if(SR_ndap_start_shift[0]&& I_ap_start)begin
        if(SR_ndap_start_shift[1:0]==2'b01)begin
            SC_co_valid <= 1'b1;
        end
        else if(SC_wog_over_flag && SC_wog_valid)begin
            SC_co_valid <= 1'b0;
        end
        else begin
            SC_co_valid <= SC_co_valid ;
        end
    end
    else begin
        SC_co_valid <= 1'b0;//dly=0
    end
end

assign SC_cog_valid = SC_co_valid   && SC_co_over_flag  ;
assign SC_pix_valid = SC_cog_valid  && SC_cog_over_flag ;
assign SC_wog_valid = SC_pix_valid  && SC_pix_over_flag ;

cm_cnt #(
    .C_WIDTH(C_COCNT_WIDTH)
u_loop1_cig_cnt (
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_co_valid            ),
.I_cnt_valid        (SC_co_valid            ),
.I_cnt_upper        (2                      ),
.O_over_flag        (SC_co_over_flag        ),
.O_cnt              (SC_co_cnt              )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_NCO_GROUP))
u_loop2_cog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_co_valid            ),
.I_cnt_valid        (SC_cog_valid           ),
.I_cnt_upper        (SL_co_group_1d         ),
.O_over_flag        (SC_cog_over_flag       ),
.O_cnt              (SC_cog_cnt             )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_PCNT_WIDTH))
u_loop3_pix_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_co_valid            ),
.I_cnt_valid        (SC_pix_valid           ),
.I_cnt_upper        (C_PEPIX                ),
.O_over_flag        (SC_pix_over_flag       ),
.O_cnt              (SC_pix_cnt             )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_WOT_DIV_PEPIX))
u_loop4_wog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_co_valid            ),
.I_cnt_valid        (SC_wog_valid           ),
.I_cnt_upper        (SL_wo_group_1d         ),
.O_over_flag        (SC_wog_over_flag       ),
.O_cnt              (SC_wog_cnt             )//dly=0
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// read data from qibuf 
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule

