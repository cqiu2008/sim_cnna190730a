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
module front_ctrl (
input                               I_rst           ,
input                               I_clk           ,
input                               I_op_rdy        ,
input                               I_op_last       ,
output                              O_op_select     ,
output                              O_op_rdy            
);

reg                         S_sin       ;
reg                         S_sin_next  ;

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
// operate 
////////////////////////////////////////////////////////////////////////////////////////////////////

assign O_op_select = (I_op_last && S_sin) || (!I_op_last)   ;
assign O_op_rdy    = (I_op_rdy  && S_sin) || I_op_last      ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// update state 
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    S_sin <= S_sin_next ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// jump state
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(*)begin
    if( I_rst )begin 
        S_sin_next <= 1'b0                  ;
    end
    else begin
        case(S_sin)
        1'b0:begin
            if(I_op_rdy && I_op_last)begin
                S_sin_next <= 1'b0          ;
            end
            else if(I_op_rdy && (!I_op_last))begin
                S_sin_next <= 1'b1          ;
            end
            else begin
                S_sin_next <= 1'b0          ; 
            end
        end
        1'b1:begin
            if(I_op_rdy)begin
                S_sin_next <= 1'b0          ; 
            end
            else begin
                S_sin_next <= 1'b1          ; 
            end
        end
        default:
                S_sin_next <= 1'b0          ; 
        endcase
    end
end

endmodule

