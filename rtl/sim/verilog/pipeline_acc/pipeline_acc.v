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
module pipeline_acc #(
parameter   
    C_CNT       = 8         ,
    C_IN1       = 12        ,
    C_OUT       = 13        
)(
input                               I_rst           ,
input                               I_clk           ,
input       [             C_IN1-1:0]I_operand       ,
input       [             C_CNT-1:0]I_cnt_boundary  ,
input                               I_op_en         ,
input                               I_op_rdy        ,
output                              O_result_rdy    ,
output      [             C_OUT-1:0]O_result        
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate parameter width 
////////////////////////////////////////////////////////////////////////////////////////////////////
//localparam C_I = C_IN/2;

reg  [C_CNT-1             :0]S_cnt          ;
wire [C_OUT-1             :0]S_operand      ;
reg  [C_OUT-1             :0]S_a            ;
wire [C_OUT-1             :0]S_b            ;
wire [C_OUT-1             :0]S_sum          ;
reg                          S_sum_valid    ; 
reg                          S_equal        ;
reg                          SL_equal2      ;
reg                          SL_equal3      ;
reg                          SL_more3       ;
reg                          S_equal_1d     ;
reg                          SL_equal2_1d   ;
reg                          SL_equal3_1d   ;
reg                          SL_more3_1d    ;
wire                         S_sum_valid3   ; 
wire                         S_sum_valid2   ; 
wire                         S_sum_valid5   ; 
////////////////////////////////////////////////////////////////////////////////////////////////////
// S_sum_valid
////////////////////////////////////////////////////////////////////////////////////////////////////
assign S_equal   = (I_cnt_boundary == S_cnt                    ) ? 1'b1 : 1'b0 
assign SL_equal2 = (I_cnt_boundary == {{(C_CNT-2){1'b0}},2'b10}) ? 1'b1 : 1'b0 
assign SL_equal3 = (I_cnt_boundary == {{(C_CNT-2){1'b0}},2'b11}) ? 1'b1 : 1'b0 
assign SL_more3  = (I_cnt_boundary >  {{(C_CNT-2){1'b0}},2'b11}) ? 1'b1 : 1'b0 

always @(posedge I_clk)begin
    S_equal_1d   <= S_equal     ;
    SL_equal2_1d <= SL_equal2   ;
    SL_equal3_1d <= SL_equal3   ;
    SL_more3_1d  <= SL_more3    ;
end

dly #(
    .C_DATA_WIDTH (1    ) , 
    .C_DLY_NUM    (1    ))
u_sum_valid3(
    .I_clk        (I_clk                    ),
    .I_din        (SL_equal3_1d&&S_equal_1d ),
    .O_dout       (S_sum_valid3             )
);

dly #(
    .C_DATA_WIDTH (1    ) , 
    .C_DLY_NUM    (3    ))
u_sum_valid3(
    .I_clk        (I_clk                    ),
    .I_din        (SL_equal5_1d&&S_equal_1d ),
    .O_dout       (S_sum_valid5             )
);

assign S_sum_valid2 = SL_equal2_1d && S_equal_1d;

always @(posedge I_clk)begin
    S_sum_valid <= S_sum_valid2 | S_sum_valid3 | S_sum_valid5; 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// S_cnt 
////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge I_clk)begin
    if(I_op_en)begin
        if(S_cnt == I_cnt_boundary)begin
            S_cnt <= {C_CNT{1'b0}};
        end
        else begin
            S_cnt <= S_cnt + {{(C_CNT-1){1'b0}},1'b1};
        end
    end
    else begin
        S_cnt <= {C_CNT{1'b0}};
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// S_a,S_b generate 
////////////////////////////////////////////////////////////////////////////////////////////////////
align #(
    .C_IN_WIDTH (C_IN1      ), 
    .C_OUT_WIDTH(C_OUT      ))
u_operand(
    .I_din      (I_operand  ),
    .O_dout     (S_operand  )
);

always @(posedge I_clk)begin
    if(~S_cnt[0])begin
        S_a <= S_operand    ;
    end
    else begin
        S_a <= S_sum        
    end
end

assign S_b == S_sum_valid ? {C_OUT{1'b0}} : S_cnt[0] ? S_operand : S_sum ;  

////////////////////////////////////////////////////////////////////////////////////////////////////
// adder pipeline 
////////////////////////////////////////////////////////////////////////////////////////////////////
adder_pp2 #(
    .C_IN1  (C_OUT  ),
    .C_IN2  (C_OUT  ),
    .C_OUT  (C_OUT  ))
u_addr_pp2(
    .I_clk  (I_clk  ),
    .I_a    (S_a    ),
    .I_b    (S_b    ),
    .O_dout (S_sum  )   
);

assign O_result = S_sum ;     

endmodule

