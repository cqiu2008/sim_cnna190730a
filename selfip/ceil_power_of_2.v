//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : ceil_power_of_2.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_ceil_power_of_2
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
//Clock Strategy: none 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER----------------------------------------------------------------------------------------
module ceil_power_of_2 #(
parameter 
    C_DIN_WIDTH         = 8     ,     
    C_POWER2_NUM        = 4     
)(
input       [           C_DIN_WIDTH-1:0]I_din   ,
output      [C_DIN_WIDTH-C_POWER2_NUM:0]O_dout  
);

wire [      C_POWER2_NUM-1:0]S_y_sub1       ;   
wire [         C_DIN_WIDTH:0]S_sum          ;
wire 

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// Attention C_DIN_WIDTH > C_POWER2_NUM;
// (1) Common #define CEIL_DIV(x,y) (((x)+(y)-1)/(y)) 
//     For this module y = power of (C_POWER2_NUM),
//          such as  C_POWER2_NUM = 4, ==> y = 16, ==> y-1 = 15, so S_y_sub1 = 4'b1111;
////////////////////////////////////////////////////////////////////////////////////////////////////

assign S_y_sub1 = (C_POWER2_NUM){1'b1}            ;//(y-1=11111...111)
assign S_sum = I_din + S_y_sub1                   ;
assign O_dout = S_sum[C_DIN_WIDTH:C_POWER2_NUM]   ;

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// instance                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
