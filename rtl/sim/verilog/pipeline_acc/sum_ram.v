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
module sum_ram#(
parameter   
    C_MEM_STYLE     = "block"   ,
    C_ISIZE         = 12        ,
    C_DSIZE         = 24        ,
    C_ASIZE         = 10          
)(
input                               I_clk           ,
// ctrl bus
input                               I_wram0_en      , 
input                               I_first_flag    ,
// mem bus
input                               I_dv_pre4       ,//dly=0
input       [C_ISIZE-1           :0]I_din           ,
input                               I_dven          ,
input       [C_ASIZE-1           :0]I_raddr         ,
output reg  [C_DSIZE-1           :0]O_rdata0        ,       
output reg  [C_DSIZE-1           :0]O_rdata1             
);

reg  [C_ASIZE-1           :0]S_waddr        ;
reg  [C_DSIZE-1           :0]S_wdata        ;       
wire                         S_wr_pre       ;        
reg                          S_wr0          ;        
reg                          S_wr1          ;        
reg  [C_ASIZE-1           :0]S_raddr0       ;        
reg  [C_ASIZE-1           :0]S_raddr1       ;        
reg  [C_ASIZE-1           :0]S_rcnt         ;        
reg                          S_rd           ;        
wire [C_DSIZE-1           :0]S_rdata0       ;           
wire [C_DSIZE-1           :0]S_rdata1       ;           
reg  [C_DSIZE-1           :0]S_sumdin_1d    ;     
reg  [C_DSIZE-1           :0]S_sum_tmp      ;     
//wire [C_DSIZE-1           :0]S_sum      ;     
//wire [C_DSIZE-1           :0]S_sum_1d   ;     
wire [C_DSIZE-1           :0]S_sum_2d       ;     

////////////////////////////////////////////////////////////////////////////////////////////////////
// ram bus 
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    S_raddr0    <= I_dven&&I_wram0_en    ? S_rcnt   : I_raddr   ;//dly=1
    S_raddr1    <= I_dven&&(~I_wram0_en) ? S_rcnt   : I_raddr   ;//dly=1
    S_sumdin_1d <= I_wram0_en ? S_rdata0 : S_rdata1             ;//dly=3
    O_rdata1    <= S_rdata1                                     ; 
    O_rdata0    <= S_rdata0                                     ;
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
u_sdpram0(
    .I_wclk      (I_clk         ),
    .I_waddr     (S_waddr       ),
    .I_wdata     (S_wdata       ),
    .I_wr        (S_wr0         ),
    .I_ce        (1'b1          ),
    .I_rclk      (I_clk         ),
    .I_raddr     (S_raddr0      ),
    .I_rd        (1'b1          ),
    .O_rdata     (S_rdata0      )    
);

sdpram #(
    .C_MEM_STYLE (C_MEM_STYLE   ),
    .C_DSIZE     (C_DSIZE       ),
    .C_ASIZE     (C_ASIZE       ))
u_sdpram1(
    .I_wclk      (I_clk         ),
    .I_waddr     (S_waddr       ),
    .I_wdata     (S_wdata       ),
    .I_wr        (S_wr1         ),
    .I_ce        (1'b1          ),
    .I_rclk      (I_clk         ),
    .I_raddr     (S_raddr1      ),
    .I_rd        (1'b1          ),
    .O_rdata     (S_rdata1      )    
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// add process 
////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge I_clk)begin
    S_sum_tmp <= I_first_flag ? {C_DSIZE{1'b0}} : S_sumdin_1d  ;//dly=4
end
//assign S_sum     = S_sum_tmp + I_din  ;
adder_pp2 #(
    .C_IN1  (C_DSIZE ),
    .C_IN2  (C_DSIZE ),
    .C_OUT  (C_DSIZE ))
u_adder_pp2(
    .I_clk  (I_clk      ),
    .I_a    (S_sum_tmp  ),
    .I_b    (I_din      ),
    .O_dout (S_sum_2d   )   
);

// S_wdata
always @(posedge I_clk)begin
    S_wdata  <= S_sum_2d    ;//dly=7
end

// S_wr_pre
dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (6          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_dv_pre4       ),
    .O_dout    (S_wr_pre        ) 
);

always @(posedge I_clk)begin
    S_wr0 <= S_wr_pre && I_wram0_en     ;
    S_wr1 <= S_wr_pre && (~I_wram0_en)  ;
end

// S_waddr
always @(posedge I_clk)begin
    if(I_dven)begin
        if(S_wr0 | S_wr1 )begin
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

