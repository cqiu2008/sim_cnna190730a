//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : dly.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_dly
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
module dly #(
parameter 
    C_DATA_WIDTH            = 8         , 
    C_DLY_NUM               = 4         
)(
// clk
input                               I_clk           ,
input       [      C_DATA_WIDTH-1:0]I_din           ,
output      [      C_DATA_WIDTH-1:0]O_dout          
);

//localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_1ADOTS + 1  ;

reg  [      C_DATA_WIDTH-1:0]S_dly[0:C_DLY_NUM-1]     ;


generate
    begin
        if(C_DLY_NUM == 0)begin:dly_num_equal_0
            assign O_dout = I_din               ;
        end
        else begin:dly_num_more_0
            always @(posedge I_clk)begin
                S_dly[0]    <=  I_din               ;
            end
            genvar idx;
            for(idx=0;idx<C_DLY_NUM-1;idx=idx+1)begin
                always @(posedge I_clk)begin
                    S_dly[idx+1] <= S_dly[idx]      ;
                end
            end
            assign O_dout = S_dly[C_DLY_NUM-1]; 
        end
    end
endgenerate

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

endmodule
