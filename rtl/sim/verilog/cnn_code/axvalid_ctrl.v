//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : axvalid_ctrl.v
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
//a)When I_ap_start is high level, 
//b)O_axvalid and I_axready all high level only active one clk.
//----------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER------------------------------------------------------------------
`timescale 1 ns / 100 ps
module axvalid_ctrl (
    input       I_clk       ,
    input       I_ap_start  ,
    input       I_axready   ,
    output reg  O_axvalid  
);

////Case 1
////    __    __    __    __    __    __    __    __    __    __    __    __    __    __
//// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
////                      _______________________________________________
////I_ap_start  _________|                                               |_________________
////            _______________                                                  __________
////S_axvalid_en               |________________________________________________|
////           __________________________________       ____________
////I_axready                                    |_____|            |______________________
////                            ____
////O_axvalid__________________|    |______________________________________________________ 
////

////Case 2 
////    __    __    __    __    __    __    __    __    __    __    __    __    __    __
//// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
////                      _______________________________________________
////I_ap_start  _________|                                               |_________________
////            _______________                                                  __________
////S_axvalid_en               |________________________________________________|
////                                        _________________        ___________
////I_axready   ___________________________|                 |______|           |__________
////                            _________________
////O_axvalid__________________|                 |_________________________________________
////

reg                         S_axvalid_en   ;

always @(posedge I_clk)begin
    if(I_ap_start)begin
        S_axvalid_en   <= 1'b0;
    end
    else begin
        S_axvalid_en   <= 1'b1;
    end
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_axvalid_en)begin
            O_axvalid      <= 1'b1        ;
        end
        else if(I_axready)begin
            O_axvalid      <= 1'b0        ;
        end
        else begin 
            O_axvalid      <= O_axvalid   ; 
        end
    end
    else begin
        O_axvalid      <= 1'b0;
    end
end

endmodule

