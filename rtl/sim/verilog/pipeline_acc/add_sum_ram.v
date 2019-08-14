//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : dpram.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_dpram
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_main_process
//----------------------------------------------------------------------------
//Relaese History :
//----------------------------------------------------------------------------
//Version         Date           Author        Description
// 1.1           july-30-2019                    
//----------------------------------------------------------------------------
//Main Function:
//a)Get the data from ddr chip using axi master bus
//b)Write it to the ibuf ram
//----------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER------------------------------------------------------------------
`timescale 1 ns / 100 ps
module add_sum_ram #(
parameter   
    C_MEM_STYLE     = "block"   ,
    C_CNT           = 8         ,
    C_ISIZE         = 12        ,
    C_DSIZE         = 24        ,
    C_ASIZE         = 10          
)(
input                               I_clk           ,
// ctrl bus
input       [             C_CNT-1:0]I_cnt_boundary  ,
input                               I_first_flag    ,
input                               I_din_valid     ,//dly=0
input       [C_ISIZE-1           :0]I_din           ,
input                               I_dven          ,
input       [C_ASIZE-1           :0]I_raddr         ,
output      [C_DSIZE-1           :0]O_rdata             
);

wire                            S_first_flag;
wire                            S_rdy_pre4  ;   
wire    [C_DSIZE-1           :0]S_result    ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// pipeline_acc 
////////////////////////////////////////////////////////////////////////////////////////////////////
pipeline_acc #(
    .C_CNT              (C_CNT              ),
    .C_IN1              (C_ISIZE            ),
    .C_OUT              (C_DSIZE            ))
u_pipeline_ac(
    .I_clk              (I_clk              ),
    .I_cnt_boundary     (I_cnt_boundary     ),
    .I_op_en            (I_dven             ),
    .I_op_rdy           (I_din_valid        ),
    .I_operand          (I_din              ),
    .O_result_first_flag(S_first_flag       ),
    .O_result_rdy_pre4  (S_rdy_pre4         ),
    .O_result           (S_result           )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// sum_ram 
////////////////////////////////////////////////////////////////////////////////////////////////////
sum_ram#(
    .C_MEM_STYLE  (C_MEM_STYLE      ),
    .C_ISIZE      (C_ISIZE          ),
    .C_DSIZE      (C_DSIZE          ),
    .C_ASIZE      (C_ASIZE          ))
u_sum_ram(
    .I_clk        (I_clk            ),
    .I_first_flag (S_first_flag     ),
    .I_dv_pre4    (S_rdy_pre4       ),//dly=0
    .I_din        (S_result         ),
    .I_dven       (I_dven           ),
    .I_raddr      (I_raddr          ),
    .O_rdata      (O_rdata          )    
);

endmodule

