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
input       [             C_IN1-1:0]I_b          ,
output      [             C_OUT-1:0]O_dout          
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate parameter width 
////////////////////////////////////////////////////////////////////////////////////////////////////

generate

    if(C_IN1 < C_IN2 )begin:less_tmp
        localparam C_IN_TMP = C_IN2;
    end
    else begin:more_tmp
        localparam C_IN_TMP= C_IN1;
    end

    if(C_IN_TMP > 2*(C_IN_TMP/2) )begin:odd_to_even
        localparam C_IN = C_IN_TMP+1;
    end
    else begin:even
        localparam C_IN = C_IN_TMP  ;
    end

endgenerate

localparam C_I = C_IN/2;

wire [C_IN-1              :0]S_a        ;
wire [C_IN-1              :0]S_b        ;
wire [C_IN                :0]S_sum      ;
reg                          S_lcout_1d ;
reg  [C_I-1               :0]S_lsum_1d  ;
reg  [C_I-1               :0]S_ha_1d    ;
reg  [C_I-1               :0]S_hb_1d    ;
reg                          S_hcout_2d ;
reg  [C_I-1               :0]S_hsum_2d  ;
reg  [C_I-1               :0]S_lsum_2d  ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// align 
////////////////////////////////////////////////////////////////////////////////////////////////////

align #(
    .C_IN_WIDTH (C_IN1      ), 
    .C_OUT_WIDTH(C_IN       ))
u_a(
    .I_din      (I_a     ),
    .O_dout     (S_a     )
);

align #(
    .C_IN_WIDTH (C_IN2      ), 
    .C_OUT_WIDTH(C_IN       ))
u_b(
    .I_din      (I_b     ),
    .O_dout     (S_b     )
);

align #(
    .C_IN_WIDTH (C_IN+1     ), 
    .C_OUT_WIDTH(C_OUT      ))
u_dout(
    .I_din      (S_sum      ),
    .O_dout     (O_dout     )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// adder pipeline 
////////////////////////////////////////////////////////////////////////////////////////////////////

//stage 1
always @(posedge I_clk)begin
    {S_lcout_1d,S_lsum_1d} <= S_a[C_I-1:0] + S_b[C_I-1:0]           ;     
    S_ha_1d                <= S_a[C_IN-1:C_I]                       ;
    S_hb_1d                <= S_b[C_IN-1:C_I]                       ;
end

//stage 2 
always @(posedge I_clk)begin
    {S_hcout_2d,S_hsum_2d} <= S_ha_1d + S_hb_1d + S_lcout_1d        ;
    S_lsum_2d              <= S_lsum_1d                             ;
end

assign S_sum = {S_hcout_2d,S_hsum_2d,S_lsum_2d} ;

endmodule

