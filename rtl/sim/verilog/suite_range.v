//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : suite_range.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_suite_range
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
module suite_range #(
parameter 
    C_DIM_WIDTH =  16
    )(
input                               I_clk           ,
input       [       C_DIM_WIDTH-1:0]I_index         ,
input       [       C_DIM_WIDTH-1:0]I_index_upper   ,
output                              O_index_suite   
);

// function clogb2(input [C_DIM_WIDTH-1:0]depth);
//     begin
//         for(clogb2=0;depth>0;clogb2=clogb2+1)begin
//             depth = depth >> 1;
//         end
//     end
// endfunction
// 
// localparam C_REAL_WIDTH = clog2(I_index_upper);

reg                          S_index_less0      ;
reg                          S_index_lessupper  ;
reg                          S_index_suite      ;


always @(posedge I_clk)begin
    S_index_less0      <= ($signed(I_index) < 0)                            ;
    S_index_lessupper  <= ($signed(I_index) < $signed(I_index_upper) )      ; 
    S_index_suite      <= (!S_index_less0) && S_index_lessupper             ;
end

assign O_index_suite = S_index_suite;

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
