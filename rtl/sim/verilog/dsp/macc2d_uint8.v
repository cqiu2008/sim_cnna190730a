//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : macc2d_uint8.v
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
module macc2d_uint8 #(
parameter 
    C_PEPIX         = 8                                 ,
    C_PECI          = 16                                ,
    C_HALF_PECO     = 16                                ,
    C_DATA_WIDTH    = 8                                 ,
    C_RESULT        = 20                                , 
    C_PIX_WIDTH     = C_PECI*C_DATA_WIDTH               , 
    C_COE_WIDTH     = C_PECI*C_DATA_WIDTH               , 
    C_RES_WIDTH     = C_RESULT      
)(
// clk
input                               I_clk               ,
input       [       C_PIX_WIDTH-1:0]I_pix               ,//
input       [       C_COE_WIDTH-1:0]I_coeh              ,//
input       [       C_COE_WIDTH-1:0]I_coel              ,//
output      [       C_RES_WIDTH-1:0]O_resh              ,//
output      [       C_RES_WIDTH-1:0]O_resl              
);

parameter    C_MULTIPLIERA     = 30                             ; 
parameter    C_MULTIPLIERB     = 18                             ; 
parameter    C_PRODUCTC       = C_MULTIPLIERA + C_MULTIPLIERB   ;

wire [     C_MULTIPLIERB-1:0]S_pix[0:C_PECI-1]                  ;
reg  [     C_MULTIPLIERB-1:0]S_ndpix[0:C_PECI-1][0:C_PECI-1]    ;
wire [      C_DATA_WIDTH-1:0]S_coeh[0:C_PECI-1]                 ;
wire [      C_DATA_WIDTH-1:0]S_coel[0:C_PECI-1]                 ;
wire [     C_MULTIPLIERA-1:0]S_coe[0:C_PECI-1]                  ;
reg  [     C_MULTIPLIERA-1:0]S_ndcoe[0:C_PECI-1][0:C_PECI-1]    ;
wire [        C_PRODUCTC-1:0]S_product_cas[0:C_PECI]            ;
wire [        C_PRODUCTC-1:0]S_product[0:C_PECI-1]              ;
assign S_product_cas[0] = {C_PRODUCTC{1'b0}};

assign O_resl = {2'b0,S_product[C_PECI-1][17:0]};
assign O_resh = {S_product[C_PECI-1][37:18]}    ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Assign
////////////////////////////////////////////////////////////////////////////////////////////////////
genvar ci_idx;

generate
    begin:a1
        for(ci_idx=0;ci_idx<C_PECI;ci_idx=ci_idx+1)begin:ci
            //assign S_pix[ci_idx]  = I_pix[ci_idx*C_DATA_WIDTH+:C_DATA_WIDTH]  ;
            //assign S_coeh[ci_idx] = I_coeh[ci_idx*C_DATA_WIDTH+:C_DATA_WIDTH] ;
            //assign S_coel[ci_idx] = I_coel[ci_idx*C_DATA_WIDTH+:C_DATA_WIDTH] ;
            assign S_pix[ci_idx]  = {10'd0,I_pix[(ci_idx+1)*C_DATA_WIDTH-1:ci_idx*C_DATA_WIDTH]};
            assign S_coeh[ci_idx] = I_coeh[(ci_idx+1)*C_DATA_WIDTH-1:ci_idx*C_DATA_WIDTH];
            assign S_coel[ci_idx] = I_coel[(ci_idx+1)*C_DATA_WIDTH-1:ci_idx*C_DATA_WIDTH];
                                    //b26, b25-b18        ,b17-b8,b7-b0
            assign S_coe[ci_idx]  = {1'b0,S_coeh[ci_idx],10'b0,S_coel[ci_idx]};
            always @(posedge I_clk)begin
                S_ndcoe[ 0][ci_idx] <= S_coe[ci_idx]       ;
                S_ndcoe[ 1][ci_idx] <= S_ndcoe[ 0][ci_idx] ;
                S_ndcoe[ 2][ci_idx] <= S_ndcoe[ 1][ci_idx] ;
                S_ndcoe[ 3][ci_idx] <= S_ndcoe[ 2][ci_idx] ;
                S_ndcoe[ 4][ci_idx] <= S_ndcoe[ 3][ci_idx] ;
                S_ndcoe[ 5][ci_idx] <= S_ndcoe[ 4][ci_idx] ;
                S_ndcoe[ 6][ci_idx] <= S_ndcoe[ 5][ci_idx] ;
                S_ndcoe[ 7][ci_idx] <= S_ndcoe[ 6][ci_idx] ;
                S_ndcoe[ 8][ci_idx] <= S_ndcoe[ 7][ci_idx] ;
                S_ndcoe[ 9][ci_idx] <= S_ndcoe[ 8][ci_idx] ;
                S_ndcoe[10][ci_idx] <= S_ndcoe[ 9][ci_idx] ;
                S_ndcoe[11][ci_idx] <= S_ndcoe[10][ci_idx] ;
                S_ndcoe[12][ci_idx] <= S_ndcoe[11][ci_idx] ;
                S_ndcoe[13][ci_idx] <= S_ndcoe[12][ci_idx] ;
                S_ndcoe[14][ci_idx] <= S_ndcoe[13][ci_idx] ;
                S_ndcoe[15][ci_idx] <= S_ndcoe[14][ci_idx] ;
                S_ndpix[ 0][ci_idx] <= S_pix[ci_idx]       ;
                S_ndpix[ 1][ci_idx] <= S_ndpix[ 0][ci_idx] ;
                S_ndpix[ 2][ci_idx] <= S_ndpix[ 1][ci_idx] ;
                S_ndpix[ 3][ci_idx] <= S_ndpix[ 2][ci_idx] ;
                S_ndpix[ 4][ci_idx] <= S_ndpix[ 3][ci_idx] ;
                S_ndpix[ 5][ci_idx] <= S_ndpix[ 4][ci_idx] ;
                S_ndpix[ 6][ci_idx] <= S_ndpix[ 5][ci_idx] ;
                S_ndpix[ 7][ci_idx] <= S_ndpix[ 6][ci_idx] ;
                S_ndpix[ 8][ci_idx] <= S_ndpix[ 7][ci_idx] ;
                S_ndpix[ 9][ci_idx] <= S_ndpix[ 8][ci_idx] ;
                S_ndpix[10][ci_idx] <= S_ndpix[ 9][ci_idx] ;
                S_ndpix[11][ci_idx] <= S_ndpix[10][ci_idx] ;
                S_ndpix[12][ci_idx] <= S_ndpix[11][ci_idx] ;
                S_ndpix[13][ci_idx] <= S_ndpix[12][ci_idx] ;
                S_ndpix[14][ci_idx] <= S_ndpix[13][ci_idx] ;
                S_ndpix[15][ci_idx] <= S_ndpix[14][ci_idx] ;
            end
            dsp_unit #(
                .C_IN0          (C_MULTIPLIERA          ),
                .C_IN1          (C_MULTIPLIERB          ),
                .C_IN2          (C_PRODUCTC             ),
                .C_OUT          (C_PRODUCTC             ))
            u_dsp_unit(
                .I_clk          (I_clk                  ),
                .I_weight       (S_ndcoe[ci_idx][ci_idx]),//
                .I_pixel        (S_ndpix[ci_idx][ci_idx]),//
                .I_product_cas  (S_product_cas[ci_idx]  ),//
                //.I_product_cas  (48'd0                  ),//
                .O_product_cas  (S_product_cas[ci_idx+1]),//
                .O_product      (S_product[ci_idx]      )//
            );
        end
    end
endgenerate

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


// always @(posedge I_clk)begin
// 
// end
// 
// 
// genvar  p_idx;
// genvar co_idx;
// genvar ci_idx;
// 
// generate
//     begin:macc2d
//         for(p_idx=0;p_idx<C_PEPIX;p_idx=p_idx+1):pix
//             for(co_idx=0;co_idx<C_HALF_PECO;co_idx=co_idx+1):co
//                 for(ci_idx=0;ci_idx<C_PECI;ci_idx=ci_idx+1):ci
//                     
//                 end
//             end
//         end
//     end
// endgenerate

endmodule

