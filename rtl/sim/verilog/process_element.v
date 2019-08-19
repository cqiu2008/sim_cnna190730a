//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : process_element.v
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
module process_element #(
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
    C_COEF_DATA             = 8*16*32   , 
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
//sbuf
input       [C_RAM_ADDR_WIDTH-1  :0]O_sraddr0           , 
input       [C_RAM_ADDR_WIDTH-1  :0]O_sraddr1           , 
output reg  [C_RAM_LDATA_WIDTH-1 :0]I_srdata0           , 
output reg  [C_RAM_LDATA_WIDTH-1 :0]I_srdata1           , 
//cbuf,coefficient as weight
output reg  [  C_RAM_ADDR_WIDTH-1:0]O_craddr            ,        
input       [       C_COEF_DATA-1:0]I_crdata            ,
// reg
input       [       C_DIM_WIDTH-1:0]I_hindex            ,
input       [     C_CNV_K_WIDTH-1:0]I_kh                ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_h          ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_w          ,
input                               I_hcnt_odd          ,
input                               I_enwr_obuf0        ,
input       [       C_DIM_WIDTH-1:0]I_ipara_height      ,
input       [       C_DIM_WIDTH-1:0]I_opara_width       ,
input       [    C_CNV_CH_WIDTH-1:0]I_opara_co          ,
input       [    C_CNV_CH_WIDTH-1:0]I_ipara_ci           
);

localparam   C_WOT_DIV_PEPIX  = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX    = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_CNV_K_GROUP    = C_CNV_K_WIDTH + C_NCH_GROUP             ;
localparam   C_FILTER_WIDTH   = C_CNV_K_WIDTH + C_CNV_K_WIDTH           ;

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

reg                          SL_co_group_only_once                          ;
reg                          SL_ci_group_equal1                             ;
reg                          SL_kernel_h_equal1                             ;
reg                          SL_kernel_w_equal1                             ;
reg                          SL_add_only_once                               ;
wire                         SR_ndap_start                                  ;
reg                          SR_ndap_start_1d                               ;
reg  [                   3:0]SR_ndap_start_shift                            ;
wire                         SR_hindex_suite                                ;
reg                          SR_kh_equal0                                   ;
reg                          SR_hindex_equal0                               ;
reg                          SR_kh_or_hindex_equal0                         ;
reg                          SC_cig_cnt_equal0                              ;
reg                          SC_kw_cnt_equal0                               ;
reg                          SC_kw_and_cig_equal0                           ;
reg  [    C_FILTER_WIDTH-1:0]SR_kh_kernel_w                                 ;
reg  [    C_FILTER_WIDTH-1:0]SC_k_cnt                                       ;
wire [       C_NCH_GROUP-1:0]SC_cig_cnt                                     ;
reg                          SC_cig_valid                                   ;
wire                         SC_cig_over_flag                               ; 
wire [       C_NCH_GROUP-1:0]SL_ci_group                                    ;   
reg  [       C_NCH_GROUP-1:0]SL_ci_group_1d                                 ;   

wire [     C_CNV_K_WIDTH-1:0]SC_kw_cnt                                      ;
wire                         SC_kw_valid                                    ;
wire                         SC_kw_over_flag                                ; 

wire [       C_NCH_GROUP-1:0]SC_cog_cnt                                     ;   
wire                         SC_cog_valid                                   ;
wire                         SC_cog_over_flag                               ; 
wire [       C_NCH_GROUP-1:0]SL_co_group                                    ;   
reg  [       C_NCH_GROUP-1:0]SL_co_group_1d                                 ;   

wire [   C_WOT_DIV_PEPIX-1:0]SC_wog_cnt                                     ;
wire                         SC_wog_valid                                   ;
wire                         SC_wog_over_flag                               ; 
wire [   C_WOT_DIV_PEPIX-1:0]SL_wo_group                                    ;
reg  [   C_WOT_DIV_PEPIX-1:0]SL_wo_group_1d                                 ;

reg  [     C_CNV_K_GROUP-1:0]SL_kernel_ci_group                             ; 
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_kw_cig_cnt                                  ; 
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_kw_cig_cnt_1d                               ; 
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_depth_pbuf                                  ; 
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_depth_pbuf_s1                               ; 
reg  [  C_RAM_ADDR_WIDTH-1:0]SC_depth_obuf                                  ; 

                                
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

// calcuate SL_co_group_1d
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_PECO    ))
U0_co_group(
    .I_din (I_opara_co),
    .O_dout(SL_co_group )   
);

always @(posedge I_clk)begin
    SL_co_group_1d <= SL_co_group;
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

// equal signals
always @(posedge I_clk)begin
    SL_co_group_only_once  <= SL_co_group_1d=={{(C_NCH_GROUP-1){1'b0}},1'b1}                ; 
    SL_ci_group_equal1     <= SL_ci_group_1d=={{(C_NCH_GROUP-1){1'b0}},1'b1}                ; 
    SL_kernel_h_equal1     <= I_kernel_h    =={{(C_CNV_K_WIDTH-1){1'b0}},1'b1}              ; 
    SL_kernel_w_equal1     <= I_kernel_w    =={{(C_CNV_K_WIDTH-1){1'b0}},1'b1}              ; 
    SL_add_only_once       <= SL_ci_group_equal1 && SL_kernel_h_equal1 && SL_kernel_w_equal1;
    SR_kh_equal0            <= (I_kh == {C_CNV_K_WIDTH{1'b0}})                              ; 
    SR_hindex_equal0        <= (I_hindex == {C_DIM_WIDTH{1'b0}})                            ;
    SR_kh_or_hindex_equal0  <= SR_kh_equal0 || SR_hindex_equal0                             ;

    SC_cig_cnt_equal0       <= (SC_cig_cnt == {C_NCH_GROUP{1'b0}})                          ;//dly=1 
    SC_kw_cnt_equal0        <= (SC_kw_cnt == {C_CNV_K_WIDTH{1'b0}})                         ; 
    SC_kw_and_cig_equal0    <=  SC_cig_cnt_equal0 && SC_kw_cnt_equal0                       ;//dly=2 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial row variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// calculate SR_hindex_suite
suite_range #(
    .C_DIM_WIDTH (C_DIM_WIDTH))
u_suite_range(
    .I_clk          (I_clk           ),
    .I_index        (I_hindex        ),
    .I_index_upper  (I_ipara_height  ),
    .O_index_suite  (SR_hindex_suite ) //dly=2
);

always @(posedge I_clk)begin
    SR_kh_kernel_w <= I_kh * I_kernel_w;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// variable change every clock 
////////////////////////////////////////////////////////////////////////////////////////////////////

// calculate SC_k_cnt
always @(posedge I_clk)begin
    if(SC_cig_valid)begin
        if(SC_kw_valid)begin
            SC_k_cnt <= SC_k_cnt + {(C_FILTER_WIDTH-1){1'b0},1'b1}  ;
        end
        else begin
            SC_k_cnt <= SC_k_cnt                                    ; 
        end
    end
    else begin
            SC_k_cnt <= SR_kh_kernel_w                              ; 
    end
end

// calculate SC_depth_pbuf;
always @(posedge I_clk)begin
    if(SC_cig_valid)begin
        if(SC_kw_over_flag && SC_kw_valid)begin
            SC_kw_cig_cnt <=  {C_RAM_ADDR_WIDTH{1'b0}}                          ;
        end
        else begin
            SC_kw_cig_cnt <= SC_kw_cig_cnt+{{(C_RAM_ADDR_WIDTH-1){1'b0}},1'b1}  ;
        end
    end
    else begin
            SC_kw_cig_cnt <=  {C_RAM_ADDR_WIDTH{1'b0}}                          ;
    end
end

// calcuate SL_kernel_ci_group
always @(posedge I_clk)begin
    SL_kernel_ci_group  <= I_kernel_w  * SL_ci_group_1d                         ;
    SC_depth_pbuf_s1    <= SC_wog_cnt * SL_kernel_ci_group                      ;//dly=1
    SC_kw_cig_cnt_1d    <= SC_kw_cig_cnt                                        ;
    SC_depth_pbuf       <= SC_depth_pbuf_s1 + SC_kw_cig_cnt_1d                  ;//dly=2
end

// calculate SC_depth_obuf;
always @(posedge I_clk)begin
    if(SC_cig_valid)begin
        if(SC_cog_valid)begin
            SC_depth_obuf <= SC_depth_obuf + {{(C_RAM_ADDR_WIDTH-1){1'b0}},1'b1}    ;
        end
        else begin
            SC_depth_obuf <= SC_depth_obuf                                          ; 
        end
    end
    else begin
            SC_depth_obuf <=  {C_RAM_ADDR_WIDTH{1'b0}}                              ;
    end
end


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
    SR_ndap_start_1d    <= SR_ndap_start                                                 ;
    SR_ndap_start_shift <={SR_ndap_start_shift[2:0],(SR_ndap_start&&SR_hindex_suite)}    ;
end

// always @(posedge I_clk)begin
//     if(I_ap_start)begin
//         if(SC_wog_valid && SC_wog_over_flag)begin
//             SR_pqap_done <= 1'b1;
//         end
//         else begin
//             SR_pqap_done <= SR_pqap_done; 
//         end
//     end
//     else begin
//         SR_pqap_done <= 1'b0;
//     end
// end
// 
// dly #(
//     .C_DATA_WIDTH   (1          ), 
//     .C_DLY_NUM      (10         ))
// u_ap_done(
//     .I_clk     (I_clk           ),
//     .I_din     (SR_pqap_done    ),
//     .O_dout    (SR_ndpqap_done  )
// );
// 
// always @(posedge I_clk)begin
//     SR_ndap_start_1d    <= SR_ndap_start                                                                  ;
//     O_ap_done           <= SR_ndpqap_done ||((~SR_ndap_start_1d) && SR_ndap_start && (~SR_hindex_suite))  ;
// end

////////////////////////////////////////////////////////////////////////////////////////////////////
// loop cnt ctrl 
////////////////////////////////////////////////////////////////////////////////////////////////////

//calcualte valid signals
always @(posedge I_clk)begin
    if(SR_ndap_start_shift[0]&& I_ap_start)begin
        if(SR_ndap_start_shift[1:0]==2'b01)begin
            SC_cig_valid <= 1'b1;
        end
        else if(SC_wog_over_flag && SC_wog_valid)begin
            SC_cig_valid <= 1'b0;
        end
        else begin
            SC_cig_valid <= SC_cig_valid ;
        end
    end
    else begin
        SC_cig_valid <= 1'b0;//dly=0
    end
end

assign SC_kw_valid  = SC_cig_valid && SC_cig_over_flag  ;
assign SC_cog_valid = SC_kw_valid  && SC_kw_over_flag   ;
assign SC_wog_valid = SC_cog_valid && SC_cog_over_flag  ;

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
    .C_WIDTH(C_NCH_GROUP))
u_loop3_cog_cnt(
.I_clk              (I_clk                  ),
.I_cnt_en           (SR_ndap_start_shift[0] ),
.I_lowest_cnt_valid (SC_cog_valid           ),
.I_cnt_valid        (SC_cog_valid           ),
.I_cnt_upper        (SL_co_group_1d         ),
.O_over_flag        (SC_cog_over_flag       ),
.O_cnt              (SC_cog_cnt             )//dly=0
);

cm_cnt #(
    .C_WIDTH(C_WOT_DIV_PEPIX))
u_loop4_wog_cnt(
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

endmodule

