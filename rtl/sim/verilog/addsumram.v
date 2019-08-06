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
module addsumram #(
parameter   
    C_MEM_STYLE     = "block"   ,
    C_DSIZE         = 32        ,
    C_ASIZE         = 10        ,
    C_LENSIZE       = 9          
)(
input                               I_clk           ,
// ctrl bus
input                               I_first_flag    ,
input       [C_LENSIZE-1         :0]I_len           ,
input                               I_dv_p2         ,
// mem bus
input       [C_DSIZE-1           :0]I_din           ,
input                               I_dv            ,
input       [C_ASIZE-1           :0]I_raddr         ,
input                               I_rd            ,
output reg  [C_DSIZE-1           :0]O_rdata             
);

//reg  [C_DSIZE-1           :0]I_wdata         ,
//reg                          I_wr            ,
//reg  [C_ASIZE-1           :0]I_raddr         ,
//reg                          I_rd            ,
//reg  [C_DSIZE-1           :0]O_rdata             

sdpram #(
    .C_MEM_STYLE (C_MEM_STYLE   ),
    .C_DSIZE     (C_DSIZE       ),
    .C_ASIZE     (C_ASIZE       ))
u_sdpram(
    .I_wclk      (I_clk         ),
    .I_waddr     (I_waddr       ),
    .I_wdata     (I_wdata       ),
    .I_ce        (1'b1          ),
    .I_wr        (I_wr          ),
    .I_rclk      (I_clk         ),
    .I_raddr     (I_raddr       ),
    .I_rd        (I_rd          ),
    .O_rdata     (O_rdata       )    
);



endmodule
