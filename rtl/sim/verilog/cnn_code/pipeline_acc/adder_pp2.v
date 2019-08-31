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
module adder_pp2 #(
parameter   
    C_IN1       = 12        ,
    C_IN2       = 12        ,
    C_OUT       = 13        
)(
input                               I_clk        ,
input       [             C_IN1-1:0]I_a          ,
input       [             C_IN2-1:0]I_b          ,
output      [             C_OUT-1:0]O_dout          
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate parameter width 
////////////////////////////////////////////////////////////////////////////////////////////////////

generate
    if(C_IN1 < C_IN2 )begin:less_tmp
        if(C_IN2 > 2*(C_IN2 /2) )begin:odd_to_even
            adder_pp2_core #(
                .C_IN1     (C_IN1   ),
                .C_IN2     (C_IN2   ),
                .C_IN      (C_IN2+1 ),
                .C_OUT     (C_OUT   ))
            u_addr2_pp2(
                .I_clk     (I_clk   ),
                .I_a       (I_a     ),
                .I_b       (I_b     ),
                .O_dout    (O_dout  )   
            );
        end
        else begin:even
            adder_pp2_core #(
                .C_IN1     (C_IN1   ),
                .C_IN2     (C_IN2   ),
                .C_IN      (C_IN2   ),
                .C_OUT     (C_OUT   ))
            u_addr2_pp2(
                .I_clk     (I_clk   ),
                .I_a       (I_a     ),
                .I_b       (I_b     ),
                .O_dout    (O_dout  )   
            );
        end
    end
    else begin:more_tmp
        if(C_IN1 > 2*(C_IN1 / 2) )begin:odd_to_even
            adder_pp2_core #(
                .C_IN1     (C_IN1   ),
                .C_IN2     (C_IN2   ),
                .C_IN      (C_IN1+1 ),
                .C_OUT     (C_OUT   ))
            u_addr2_pp2(
                .I_clk     (I_clk   ),
                .I_a       (I_a     ),
                .I_b       (I_b     ),
                .O_dout    (O_dout  )   
            );
        end
        else begin:even
            adder_pp2_core #(
                .C_IN1     (C_IN1   ),
                .C_IN2     (C_IN2   ),
                .C_IN      (C_IN1   ),
                .C_OUT     (C_OUT   ))
            u_addr2_pp2(
                .I_clk     (I_clk   ),
                .I_a       (I_a     ),
                .I_b       (I_b     ),
                .O_dout    (O_dout  )   
            );
        end
    end
endgenerate

endmodule

