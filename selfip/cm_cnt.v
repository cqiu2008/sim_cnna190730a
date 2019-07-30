//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : cm_cnt.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_cm_cnt
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
module cm_cnt #(
parameter 
    C_WIDTH         = 8     
)(
input                                   I_clk       ,
input                                   I_cnt_en    ,
input                                   I_cnt_valid ,
input       [               C_WIDTH-1:0]I_cnt_upper ,
output reg                              O_over_flag ,
////wirte here
output reg  [               C_WIDTH-1:0]O_cnt         
);

always @(posedge I_clk)begin
    O_over_flag <= O_cnt == (I_cnt_upper-{(C_WIDTH-1){1'b0},1'b1});
end

always @(posedge I_clk)begin
    if(I_cnt_en)begin
        if(I_cnt_valid)begin
            //if(O_cnt == (I_cnt_upper-{(C_WIDTH-1){1'b0},1'b1}))begin
            if(O_over_flag)begin
                O_cnt <= {(C_WIDTH){1'b0}};
            end
            else begin
                O_cnt <= O_cnt + {(C_WIDTH-1){1'b0},1'b1}; 
            end
        end
        else begin
            O_cnt <= O_cnt          ; 
        end
    end
    else begin
        O_cnt <= {(C_WIDTH){1'b0}};
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
////////////////////////////////////////////////////////////////////////////////////////////////////

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
