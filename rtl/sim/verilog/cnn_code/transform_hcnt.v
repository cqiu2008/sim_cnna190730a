//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : transform_hcnt.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_transform_hcnt
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
module transform_hcnt #(
parameter 
    C_DSIZE                 = 16    ,
    C_CNV_CH_WIDTH          = 8     , 
    C_CNV_K_WIDTH           = 5     
)(
input                              I_clk            ,
input       [    C_CNV_K_WIDTH-1:0]I_kernel_h       ,
input       [    C_CNV_K_WIDTH-1:0]I_stride_h       ,
input       [    C_CNV_K_WIDTH-1:0]I_pad_h          ,
input       [          C_DSIZE-1:0]I_hcnt           ,
output reg  [          C_DSIZE-1:0]O_hfirst         ,////dly=23
output reg  [          C_DSIZE-1:0]O_kh             ,
output reg  [          C_DSIZE-1:0]O_hindex        
);

reg                         S_lessthan0                     ; 
wire[           C_DSIZE-1:0]S_hcnt_div_kh                   ;
wire[           C_DSIZE-1:0]S_hcnt_rem_kh                   ;
reg [           C_DSIZE-1:0]S_hfirst                        ; 
reg [           C_DSIZE-1:0]S_kh                            ;
reg [           C_DSIZE-1:0]S_hindex                        ; 
reg [           C_DSIZE-1:0]S_2d_hfirst                     ; 
reg [           C_DSIZE-1:0]S_2d_kh                         ;
reg [           C_DSIZE-1:0]S_2d_hindex                     ; 
reg [           C_DSIZE-1:0]S_3d_hfirst_kh                  ; 
reg [           C_DSIZE-1:0]S_4d_hindex                     ; 

divider #(
    .C_DIVIDEND   (C_DSIZE      ), 
    .C_DIVISOR    (C_CNV_K_WIDTH),
    .C_QUOTIENT   (C_DSIZE      ),
    .C_REMAINDER  (C_DSIZE      ))
u_hcnt_div_rempart(//dly=C_DSIZE+2=18
    .I_clk        (I_clk                    ),
    .I_dividend   (I_hcnt                   ),
    .I_divisor    (I_kernel_h               ),
    .O_quotient   (S_hcnt_div_kh            ), 
    .O_remainder  (S_hcnt_rem_kh            )
);

always @(posedge I_clk)begin

    //S_hcnt_div_kh   <= $signed(I_hcnt) / $signed(I_kernel_h)        ;
    //S_hcnt_rem_kh   <= $signed(I_hcnt) % $signed(I_kernel_h)        ;

    S_2d_hfirst     <= $signed(S_hcnt_div_kh) * $signed(I_stride_h) ;
    S_2d_kh         <= $signed(S_hcnt_rem_kh)                       ; 
    S_3d_hfirst_kh  <= $signed(S_2d_hfirst) + $signed(S_2d_kh)      ;
    S_4d_hindex     <= $signed(S_3d_hfirst_kh) - $signed(I_pad_h)   ;
end

always @(posedge I_clk)begin
    S_lessthan0 <=  $signed(I_hcnt) < $signed(0) ;
end

always @(posedge I_clk)begin
    if(S_lessthan0)begin
        S_hfirst    <= $signed(-1); 
        S_kh        <= $signed(-1);
        S_hindex    <= $signed(-1); 
    end
    else begin
        S_hfirst    <= $signed(S_2d_hfirst  );
        S_kh        <= $signed(S_2d_kh      );
        S_hindex    <= $signed(S_4d_hindex  );
    end
end

always @(posedge I_clk)begin
    O_hfirst    <= S_hfirst   ; 
    O_kh        <= S_kh       ;
    O_hindex    <= S_hindex   ; 
end

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

