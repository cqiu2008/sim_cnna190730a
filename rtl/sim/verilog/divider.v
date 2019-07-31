//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : divider.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_divider
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
module divider #(
parameter 
    C_DIVIDEND          = 16         , 
    C_DIVISOR           = 16         ,
    C_QUOTIENT          = 16         ,
    C_REMAINDER         = 16            
)(
// clk
input                               I_clk           ,
input       [        C_DIVIDEND-1:0]I_dividend      ,
input       [         C_DIVISOR-1:0]I_divisor       ,
output      [        C_QUOTIENT-1:0]O_quotient      ,//After C_DIVIDEND+2 result
output      [       C_REMAINDER-1:0]O_remainder
);

//function integer clogb2(input integer depth);
//    begin
//        for(clogb2=0;depth>0;clogb2=clogb2+1)begin
//            depth = depth >> 1;
//        end
//    end
//endfunction
//
//localparam   C_CNT = clogb2(C_DIV); 

parameter C_DIV = C_DIVIDEND    ;
parameter C_DIS = C_DIVISOR     ;
parameter C_DB  = 2 * C_DIV     ;

wire [        C_DIV-1:0]S_divisor             ;
wire [        C_DIV-1:0]S_quotient            ;
wire [        C_DIV-1:0]S_remainder           ;
reg  [         C_DB-1:0]S_body0[0:C_DIV+2]    ;
reg  [         C_DB-1:0]S_body1[0:C_DIV+1]    ;
wire [         C_DB-1:0]S_case[0:C_DIV+1]     ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// signal alignment
////////////////////////////////////////////////////////////////////////////////////////////////////

align #(
    .C_IN_WIDTH (C_DIS  ),
    .C_OUT_WIDTH(C_DIV ))
u_S_divisor(
    .I_din      (I_divisor),
    .O_dout     (S_divisor)
);

align #(
    .C_IN_WIDTH (C_DIV      ),
    .C_OUT_WIDTH(C_QUOTIENT ))
u_S_quotient(
    .I_din      (S_quotient),
    .O_dout     (O_quotient)
);

align #(
    .C_IN_WIDTH (C_DIV      ),
    .C_OUT_WIDTH(C_REMAINDER))
u_S_remainder(
    .I_din      (S_remainder),
    .O_dout     (O_remainder)
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// pipeline  
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin:init
    S_body0[0]   <= {{(C_DIV){1'b0}},I_dividend};
    S_body1[0]   <= { S_divisor,{(C_DIV){1'b0}}};
end

genvar idx;

generate
    begin:body
        for(idx=0;idx<C_DIV;idx=idx+1)begin:num
            assign S_case[idx] = S_body0[idx]-S_body1[idx]+{{(C_DB-1){1'b0}},1'b1};
            always @(posedge I_clk)begin
                S_body0[idx+1]  <= (S_body0[idx] >= S_body1[idx]) ? {S_case[idx][C_DB-2:0],1'b0} : {S_body0[idx][C_DB-2:0],1'b0} ;
                S_body1[idx+1]  <=  S_body1[idx]; 
            end
        end
    end
endgenerate

assign S_case[C_DIV] = S_body0[C_DIV]-S_body1[C_DIV]+{{(C_DB-1){1'b0}},1'b1};

always @(posedge I_clk)begin:last
    S_body0[C_DIV+1]  <= (S_body0[C_DIV] >= S_body1[C_DIV]) ? 
                            {S_case[C_DIV][C_DB-2:0],1'b0} : S_body0[C_DIV];
end

assign S_remainder = S_body0[C_DIV+1][   C_DB-1:C_DIV];
assign S_quotient  = S_body0[C_DIV+1][  C_DIV-1:    0];

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

