//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : axim_rddr.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_axim_rddr
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
//`timescale 1 ns / 100 ps
//module xxx #(
//parameter 
//    C_M_AXI_ID_WIDTH        = 1     ,
//)(
//// clk
//input                               I_clk           ,
//input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
//input       [C_RAM_ADDR_WIDTH-1  :0]I_len           ,
//
//wire [  C_RAM_ADDR_WIDTH-1:0]S_waddr            ;   
//reg  [  C_RAM_DATA_WIDTH-1:0]S_rdata_1d         ;
////    __    __    __    __    __    __    __    __    __    __    __    __    __    __
//// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
////
////



//endmodule
