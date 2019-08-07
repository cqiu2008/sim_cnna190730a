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
module addsumram #(
parameter   
    C_MEM_STYLE     = "block"   ,
    C_ISIZE         = 12        ,
    C_DSIZE         = 24        ,
    C_ASIZE         = 10          
)(
input                               I_clk           ,
// ctrl bus
input                               I_first_flag    ,
// mem bus
input                               I_dv_pre4       ,//dly=0
input       [C_ISIZE-1           :0]I_din           ,
input                               I_dven          ,
input       [C_ASIZE-1           :0]I_raddr         ,
output reg  [C_DSIZE-1           :0]O_rdata             
);

reg  [C_ASIZE-1           :0]S_waddr    ;
reg  [C_DSIZE-1           :0]S_wdata    ;       
wire                         S_wr       ;        
reg  [C_ASIZE-1           :0]S_raddr    ;        
reg  [C_ASIZE-1           :0]S_rcnt     ;        
reg                          S_rd       ;        
wire [C_DSIZE-1           :0]S_rdata    ;           
reg  [C_DSIZE-1           :0]S_rdata_1d ;     
wire [C_DSIZE-1           :0]S_sum_tmp  ;     
wire [C_DSIZE-1           :0]S_sum      ;     
reg  [C_DSIZE-1           :0]S_sum_1d   ;     
reg  [C_DSIZE-1           :0]S_sum_2d   ;     

////////////////////////////////////////////////////////////////////////////////////////////////////
// ram bus 
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    S_raddr     <= I_dven   ? S_rcnt : I_raddr   ;//dly=2 
    S_rdata_1d  <= S_rdata;//dly=4
end

always @(posedge I_clk)begin
    if(I_dven)begin
        if(I_dv_pre4)begin
            S_rcnt  <=  S_rcnt + {{(C_ASIZE-1){1'b0}},1'b1} ;
        end
        else begin
            S_rcnt  <=  S_rcnt                              ; 
        end
    end
    else begin
        S_rcnt  <=  {C_ASIZE{1'b0}}                         ;
    end
end

sdpram #(
    .C_MEM_STYLE (C_MEM_STYLE   ),
    .C_DSIZE     (C_DSIZE       ),
    .C_ASIZE     (C_ASIZE       ))
u_sdpram(
    .I_wclk      (I_clk         ),
    .I_waddr     (S_waddr       ),
    .I_wdata     (S_wdata       ),
    .I_ce        (1'b1          ),
    .I_wr        (S_wr          ),
    .I_rclk      (I_clk         ),
    .I_raddr     (S_raddr       ),
    .I_rd        (1'b1          ),
    .O_rdata     (S_rdata       )    
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// add process 
////////////////////////////////////////////////////////////////////////////////////////////////////
assign S_sum_tmp = I_first_flag ? {C_DSIZE{1'b0}} : S_rdata_1d  ;
assign S_sum     = S_sum_tmp + I_din  ;

// S_wdata
always @(posedge I_clk)begin
    S_sum_1d <= S_sum       ;
    S_sum_2d <= S_sum_1d    ;
    S_wdata  <= S_sum_2d    ;//dly=7
end

// S_wr
dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (7          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_dv_pre4       ),
    .O_dout    (S_wr            )
);

// S_waddr
always @(posedge I_clk)begin
    if(I_dven)begin
        if(S_wr)begin
            S_waddr <= S_waddr + {{(C_ASIZE-1){1'b0}},1'b1} ;
        end
        else begin
            S_waddr <= S_waddr                              ; 
        end
    end
    else begin
            S_waddr <= {C_ASIZE{1'b0}}                      ; 
    end
end



endmodule
