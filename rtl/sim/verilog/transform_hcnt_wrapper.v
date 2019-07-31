//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : transform_hcnt_wrapper.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_transform_hcnt_wrapper
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
module transform_hcnt_wrapper #(
parameter 
    C_DSIZE                 = 16    ,
    C_CNV_CH_WIDTH          = 8     , 
    C_CNV_K_WIDTH           = 5     
)(
input                              I_clk            ,
input                              I_allap_start    ,
input                              I_ap_start       ,
output reg                         O_ap_done        ,
input       [    C_CNV_K_WIDTH-1:0]I_kernel_h       ,
input       [    C_CNV_K_WIDTH-1:0]I_stride_h       ,
input       [    C_CNV_K_WIDTH-1:0]I_pad_h          ,
input       [          C_DSIZE-1:0]I_hcnt           ,
output reg  [          C_DSIZE-1:0]O_r0hfirst       ,
output reg  [          C_DSIZE-1:0]O_r0kh           ,
output reg  [          C_DSIZE-1:0]O_r0hindex       ,  
output reg  [          C_DSIZE-1:0]O_r1hfirst       ,
output reg  [          C_DSIZE-1:0]O_r1kh           ,
output reg  [          C_DSIZE-1:0]O_r1hindex       , 
output reg  [          C_DSIZE-1:0]O_r2hfirst       ,
output reg  [          C_DSIZE-1:0]O_r2kh           ,
output reg  [          C_DSIZE-1:0]O_r2hindex       , 
output reg  [          C_DSIZE-1:0]O_r3hfirst       ,
output reg  [          C_DSIZE-1:0]O_r3kh           ,
output reg  [          C_DSIZE-1:0]O_r3hindex       
);

reg    [       C_DSIZE-1:0]S_reg_hfirst[2][4]   ;
reg    [       C_DSIZE-1:0]S_reg_kh[2][4]       ;
reg    [       C_DSIZE-1:0]S_reg_hindex[2][4]   ;

wire   [       C_DSIZE-1:0]S_hfirst[4]          ;
wire   [       C_DSIZE-1:0]S_kh[4]              ;
wire   [       C_DSIZE-1:0]S_hindex[4]          ;
wire                       S_ndap_start         ;
reg    [               3:0]S_ndap_start_shift   ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Calcuate the variable  
////////////////////////////////////////////////////////////////////////////////////////////////////
genvar idx;
generate
    for(idx=0;idx<4;idx=idx+1)begin:hcntInst
        transform_hcnt #(
            .C_DSIZE         (C_DSIZE                               ), 
            .C_CNV_CH_WIDTH  (C_CNV_CH_WIDTH                        ),
            .C_CNV_K_WIDTH   (C_CNV_K_WIDTH                         ))
        u_transform_hcnt(
            .I_clk           (I_clk                                 ),
            .I_kernel_h      (I_kernel_h                            ),
            .I_stride_h      (I_stride_h                            ),
            .I_pad_h         (I_pad_h                               ),
            .I_hcnt          ((I_hcnt-idx[C_DSIZE-1:0])             ),
            .O_hfirst        (S_hfirst[idx]                         ),
            .O_kh            (S_kh[idx]                             ),
            .O_hindex        (S_hindex[idx]                         )
        );
        always @(posedge I_clk)begin:h0
            if( (~I_hcnt[0]) && (S_ndap_start_shift[1:0]==2'b01) )begin
                S_reg_hfirst[0][idx] <= S_hfirst[idx]           ; 
                S_reg_kh[0][idx]     <= S_kh[idx]               ; 
                S_reg_hindex[0][idx] <= S_hindex[idx]           ; 
            end
            else begin
                S_reg_hfirst[0][idx] <= S_reg_hfirst[0][idx]    ; 
                S_reg_kh[0][idx]     <= S_reg_kh[0][idx]        ; 
                S_reg_hindex[0][idx] <= S_reg_hindex[0][idx]    ; 
            end
        end
        always @(posedge I_clk)begin:h1
            if( (I_hcnt[0]) && (S_ndap_start_shift[1:0]==2'b01) )begin
                S_reg_hfirst[1][idx] <= S_hfirst[idx]           ; 
                S_reg_kh[1][idx]     <= S_kh[idx]               ; 
                S_reg_hindex[1][idx] <= S_hindex[idx]           ; 
            end
            else begin
                S_reg_hfirst[1][idx] <= S_reg_hfirst[1][idx]    ; 
                S_reg_kh[1][idx]     <= S_reg_kh[1][idx]        ; 
                S_reg_hindex[1][idx] <= S_reg_hindex[1][idx]    ; 
            end
        end
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// Calcuate the variable  
////////////////////////////////////////////////////////////////////////////////////////////////////

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (20         ))
u_done_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_ap_start      ),
    .O_dout    (S_ndap_start    )
);

always @(posedge I_clk)begin
    S_ndap_start_shift <= {S_ndap_start_shift[2:0],S_ndap_start };
end

always @(posedge I_clk)begin
    O_ap_done <= (S_ndap_start_shift[3:2] == 2'b01) ;
end

initial begin
    O_r0hfirst     = {C_DSIZE{1'b0}};
    O_r0kh         = {C_DSIZE{1'b0}};
    O_r0hindex     = {C_DSIZE{1'b0}};  
    O_r1hfirst     = {C_DSIZE{1'b0}};
    O_r1kh         = {C_DSIZE{1'b0}};
    O_r1hindex     = {C_DSIZE{1'b0}};  
    O_r2hfirst     = {C_DSIZE{1'b0}};
    O_r2kh         = {C_DSIZE{1'b0}};
    O_r2hindex     = {C_DSIZE{1'b0}};  
    O_r3hfirst     = {C_DSIZE{1'b0}};
    O_r3kh         = {C_DSIZE{1'b0}};
    O_r3hindex     = {C_DSIZE{1'b0}};  
end

always @(posedge I_clk)begin
    if(I_allap_start)begin
        if( (I_hcnt[0]) && (S_ndap_start_shift[2:1]==2'b01) )begin
            O_r0hfirst     <= S_reg_hfirst[0][0];
            O_r0kh         <= S_reg_kh[0][0]    ;
            O_r0hindex     <= S_reg_hindex[0][0];  
            O_r1hfirst     <= S_reg_hfirst[0][1];
            O_r1kh         <= S_reg_kh[0][1]    ;
            O_r1hindex     <= S_reg_hindex[0][1];  
            O_r2hfirst     <= S_reg_hfirst[0][2];
            O_r2kh         <= S_reg_kh[0][2]    ;
            O_r2hindex     <= S_reg_hindex[0][2];  
            O_r3hfirst     <= S_reg_hfirst[0][3];
            O_r3kh         <= S_reg_kh[0][3]    ;
            O_r3hindex     <= S_reg_hindex[0][3];  
        end
        else if( (!I_hcnt[0]) && (S_ndap_start_shift[2:1]==2'b01) && (I_hcnt != {C_DSIZE{1'b0}}) )begin
            O_r0hfirst     <= S_reg_hfirst[1][0];
            O_r0kh         <= S_reg_kh[1][0]    ;
            O_r0hindex     <= S_reg_hindex[1][0];  
            O_r1hfirst     <= S_reg_hfirst[1][1];
            O_r1kh         <= S_reg_kh[1][1]    ;
            O_r1hindex     <= S_reg_hindex[1][1];  
            O_r2hfirst     <= S_reg_hfirst[1][2];
            O_r2kh         <= S_reg_kh[1][2]    ;
            O_r2hindex     <= S_reg_hindex[1][2];  
            O_r3hfirst     <= S_reg_hfirst[1][3];
            O_r3kh         <= S_reg_kh[1][3]    ;
            O_r3hindex     <= S_reg_hindex[1][3];  
        end
        else begin
            O_r0hfirst     <= O_r0hfirst     ;
            O_r0kh         <= O_r0kh         ;
            O_r0hindex     <= O_r0hindex     ;  
            O_r1hfirst     <= O_r1hfirst     ;
            O_r1kh         <= O_r1kh         ;
            O_r1hindex     <= O_r1hindex     ;  
            O_r2hfirst     <= O_r2hfirst     ;
            O_r2kh         <= O_r2kh         ;
            O_r2hindex     <= O_r2hindex     ;  
            O_r3hfirst     <= O_r3hfirst     ;
            O_r3kh         <= O_r3kh         ;
            O_r3hindex     <= O_r3hindex     ;  
        end
    end
    else begin
            O_r0hfirst     <= {C_DSIZE{1'b0}};
            O_r0kh         <= {C_DSIZE{1'b0}};
            O_r0hindex     <= {C_DSIZE{1'b0}};  
            O_r1hfirst     <= {C_DSIZE{1'b0}};
            O_r1kh         <= {C_DSIZE{1'b0}};
            O_r1hindex     <= {C_DSIZE{1'b0}};  
            O_r2hfirst     <= {C_DSIZE{1'b0}};
            O_r2kh         <= {C_DSIZE{1'b0}};
            O_r2hindex     <= {C_DSIZE{1'b0}};  
            O_r3hfirst     <= {C_DSIZE{1'b0}};
            O_r3kh         <= {C_DSIZE{1'b0}};
            O_r3hindex     <= {C_DSIZE{1'b0}};  
    end
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

