//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : align.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_align
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

module align #(
parameter 
    C_IN_WIDTH              = 8         , 
    C_OUT_WIDTH             = 16        
)(
input       [        C_IN_WIDTH-1:0]I_din           ,
output      [       C_OUT_WIDTH-1:0]O_dout          
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// turn the I_din data with to O_dout data width 
////////////////////////////////////////////////////////////////////////////////////////////////////

generate
    begin:align
        if(C_IN_WIDTH < C_OUT_WIDTH)begin:less
            assign O_dout = {{(C_OUT_WIDTH-C_IN_WIDTH){1'b0}},I_din};
        end
        else begin:more
            assign O_dout = I_din[C_OUT_WIDTH-1:0]; 
            //$display("Error : you will lose the valid data");
            //$display("C_OUT_WIDTH is %d",C_OUT_WIDTH);
            //$display("C_IN_WIDTH is %d",C_IN_WIDTH);
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
