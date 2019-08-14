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
input                               I_clk               ,
input       [             C_CNT-1:0]I_cnt_boundary      ,
input                               I_op_en             ,
input                               I_op_rdy            ,//rdly=0
input       [             C_IN1-1:0]I_operand           ,
output                              O_result_first_flag ,
output reg                          O_result_rdy_pre4   ,
output reg  [             C_OUT-1:0]O_result        
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) SL_+"xx"  name type (S_layer_xxx) , means variable changed every layer   
//        such as SL_wo_total, SL_wo_group, SL_wpart ... and so on 
// (2) SR_+"xx"  name type (S_row_xxx), means variable changed every row 
//        such as SR_hindex , SR_hindex  ... and so on 
// (3) SC_+"xx"  name type (S_clock_xxx), means variable changed every clock 
//        such as SC_id , ... and so on 
// (4) rdly  means I_op_rdy , active delay clks, for example rdly=0,means active the same with I_op_rdy
// (5) ldly  means S_op_last, active delay clks, for example ldly=0,means active the same with S_op_last
// (6) |d0+d1| means d0+d1, |d0+.2| means d0+d1+d2 |d3+.5| means d3+d4+d5
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate parameter width 
////////////////////////////////////////////////////////////////////////////////////////////////////
//localparam C_I = C_IN/2;

reg      [C_CNT-1            :0]S_cnt               ;
wire     [C_OUT-1            :0]S_operand           ;
reg      [C_OUT-1            :0]S_a                 ;
wire     [C_OUT-1            :0]S_b                 ;
wire     [C_OUT-1            :0]S_sum               ;
reg                             S_sum_valid         ;

wire     [C_OUT-1            :0]S_c1sum             ;
wire                            S_c1sum_p4_valid    ; 

wire     [C_OUT-1            :0]S_c2sum             ;
wire                            S_c2sum_p4_valid    ; 
wire                            S_c2sum_valid       ; 

wire     [C_OUT-1            :0]S_c3sum             ;
wire                            S_c3sum_p4_valid    ; 
reg                             S_c3sum_valid       ; 

wire     [C_OUT-1            :0]S_m3sum             ;
wire                            S_m3sum_p4_valid    ; 
reg                             S_m3sum_valid       ; 

reg                             SL_equal1       ;
reg                             SL_equal2       ;
reg                             SL_equal3       ;
reg                             SL_more3        ;
reg                             S_equal         ;

wire                            SL_equal1c      ;
wire                            SL_equal2c      ;
wire                            SL_equal3c      ;
wire                            SL_more3c       ;
wire                            S_equalc        ;

reg                             S_sum_base_valid;

////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate cases of 4 
////////////////////////////////////////////////////////////////////////////////////////////////////
assign SL_equal1c = (I_cnt_boundary == {{(C_CNT-2){1'b0}},2'b01})        ? 1'b1 : 1'b0 
assign SL_equal2c = (I_cnt_boundary == {{(C_CNT-2){1'b0}},2'b10})        ? 1'b1 : 1'b0 
assign SL_equal3c = (I_cnt_boundary == {{(C_CNT-2){1'b0}},2'b11})        ? 1'b1 : 1'b0 
assign SL_more3c  = (I_cnt_boundary >  {{(C_CNT-2){1'b0}},2'b11})        ? 1'b1 : 1'b0 
assign S_equalc   = (I_cnt_boundary == S_cnt+{(C_CNT-2){1'b0}},2'b01} )  ? 1'b1 : 1'b0 

always @(posedge I_clk)begin
    SL_equal1   <= SL_equal1c   ;
    SL_equal2   <= SL_equal2c   ;
    SL_equal3   <= SL_equal3c   ;
    SL_more3    <= SL_more3c    ;
    S_equal     <= S_equalc     ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// main S_cnt 
////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge I_clk)begin
    if(I_op_en)begin
        if(S_equalc)begin
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

always @(posedge I_clk)begin
    if(I_op_en)begin
        if(S_equalc&&I_op_rdy)begin
            S_sum_base_valid    <= 1'b1;
        end
        else begin
            S_sum_base_valid    <= 1'b0;
        end
    end
    else begin
            S_sum_base_valid    <= 1'b0;
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// process pipeline addr 
////////////////////////////////////////////////////////////////////////////////////////////////////
// S_a,S_b generate 
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

always @(posedge I_clk)begin
    S_sum_valid <= (~I_op_rdy) | S_c2sum_valid | S_c3sum_valid | S_m3sum_valid ; 
end

assign S_b == S_sum_valid ? {C_OUT{1'b0}} : S_cnt[0] ? S_operand : S_sum ;  

// instance adder pipeline 
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

////////////////////////////////////////////////////////////////////////////////////////////////////
// cases of 1: I_cnt_boundary == 1 
// for case 1, S_sum_valid is -1 dly than S_sum_base_valid ,detail for the wave graph
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//
// cnt_boundary  (const 1 at layer  ... 
//                _______________________
// op_rdy  ______|
//                _______________________
// equalc   _____| 
//
// cnt        0  | 0   | 0   | 0   |
//                      ______________
// sum_base_valid _____|
//          S_sum_valid is ( -1 ) dly than S_sum_base_valid 
//                _________________
// sum_valid_____|
//
// operand       | d0  | d1  |
//
// sum(result)   | d0  | d1  | 
////////////////////////////////////////////////////////////////////////////////////////////////////
assign S_c1sum_p4_valid  = S_sum_base_valid  ; 

dly #(
    .C_DATA_WIDTH   (C_OUT      ), 
    .C_DLY_NUM      (4-(-1)     ))
u_c1sum(
    .I_clk     (I_clk           ),
    .I_din     (S_operand       ),
    .O_dout    (S_c1sum         )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// cases of 2: I_cnt_boundary == 2 
// for case 2, S_sum_valid is 1 dly than S_sum_base_valid ,detail for the wave graph
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//
// cnt_boundary  (const 2 at layer  ... 
//                _____________________________________
// op_rdy  ______|
//                      _____       _____       _____
// equalc   ___________|     |_____|     |_____|     |
//
// cnt        0  | 0   | 1   | 0   | 1   | 0
//                            _____       _____
// sum_base_valid ___________|     |_____|     |_____|
//
// operand       | d0  | d1  | e0  | e1  | f0  | f1  |
//       a         x   | d0  |     | e0  |     | f0  |
//       b         x   | d1  |     | e1  |     | f1  |
//     sum                     x   |d0+d1|     |e0+e1|
//              S_sum_valid is ( 1 ) dly than S_sum_base_valid 
//                                  _____       _____
// sum_valid_______________________|     |_____|     |_____
// 
////////////////////////////////////////////////////////////////////////////////////////////////////
assign S_c2sum_p4_valid  = S_sum_base_valid  ; 
assign S_c2sum_valid     = S_sum_base_valid  ;

dly #(
    .C_DATA_WIDTH   (C_OUT      ), 
    .C_DLY_NUM      (4-(1)      ))
u_c2sum(
    .I_clk     (I_clk           ),
    .I_din     (S_sum           ),
    .O_dout    (S_c2sum         )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// cases of 3: I_cnt_boundary == 3 
// for case 3, S_sum_valid is 1 dly than S_sum_base_valid ,detail for the wave graph
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//
// cnt_boundary  (const 3 at layer  ... 
//                ________________________________________________________
// op_rdy  ______|
//                            _____             _____             _____
// equalc   _________________|     |___________|     |___________|     |
//
// cnt        0  | 0   | 1   | 2   | 0   | 1   | 2   | 0   | 1   | 2 
//                                  _____             _____             _____
// sum_base_valid _________________|     |___________|     |___________|     |
//
// operand       | d0  | d1  | d2  | e0  | e1  | e2  | f0  | f1  | f2   | g0  |
//       a         x   | d0  |     | d2  | e0  |     | e2  | f0  |      | f2  |
//       b         x   | d1  |     |d0+d1| e1  |     |e0+e1| f1  |      |f0+f1|
//     sum                     x   |d0+d1|     |d0+.2|e0+e1|     |e0+.2 |f0+f1|
//              S_sum_valid is ( 2 ) dly than S_sum_base_valid 
//                                               _____             _____
// sum_valid____________________________________|     |___________|     |_____
// 
////////////////////////////////////////////////////////////////////////////////////////////////////

assign S_c3sum_p4_valid  = S_sum_base_valid  ; 

always @(posedge I_clk)begin
    S_c3sum_valid  <= S_sum_base_valid  ;
end

dly #(
    .C_DATA_WIDTH   (C_OUT      ), 
    .C_DLY_NUM      (4-(2)      ))
u_c3sum(
    .I_clk     (I_clk           ),
    .I_din     (S_sum           ),
    .O_dout    (S_c3sum         )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// cases of 4: I_cnt_boundary == 4,5,6,7...... 
// for case 4, S_sum_valid is 1 dly than S_sum_base_valid ,detail for the wave graph
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//
// cnt_boundary  (const 4 at layer  ... 
//                ________________________________________________________________________
// op_rdy  ______|
//                                  _____                   _____             _____
// equalc   _______________________|     |_________________|     |___________|     |______
//
// cnt        0  | 0   | 1   | 2   | 3   | 0   | 1   | 2   | 3   | 0 
//                                        _____                   _____             _____
// sum_base_valid________________________|     |_________________|     |___________|     |
//
// operand       | d0  | d1  | d2  | d3  | e0  | e1  | e2  | e3  | f0   | f1  |
//       a         x   | d0  |     | d2  |d0+d1| e0  | e2  | f0  |      | f2  |
//       b         x   | d1  |     | d3  |     | e1  |e0+e1| f1  |      |f0+f1|
//     sum                     x   |d0+d1|0    |d2+d3|e0+e1|     |e0+.2 |f0+f1|
//              S_sum_valid is ( 2 ) dly than S_sum_base_valid 
//                                               _____             _____
// sum_valid____________________________________|     |___________|     |_____
// 
////////////////////////////////////////////////////////////////////////////////////////////////////

assign S_c3sum_p4_valid  = S_sum_base_valid  ; 

always @(posedge I_clk)begin
    S_c3sum_valid  <= S_sum_base_valid  ;
end

dly #(
    .C_DATA_WIDTH   (C_OUT      ), 
    .C_DLY_NUM      (4-(2)      ))
u_c3sum(
    .I_clk     (I_clk           ),
    .I_din     (S_sum           ),
    .O_dout    (S_c3sum         )


// write here by cqiu 2019-08-14

////////////////////////////////////////////////////////////////////////////////////////////////////
// process O_result_rdy_pre4 and O_result 
////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge I_clk)begin
    if(SL_equal1)begin
        O_result_rdy_pre4   <= S_c1sum_p4_valid ;
        O_result            <= S_c1sum          ; 
    end
    else if(SL_equal2)begin
        O_result_rdy_pre4   <= S_c2sum_p4_valid ;
        O_result            <= S_c2sum          ; 
    end
    else if(SL_equal3)begin
        O_result_rdy_pre4   <= S_c3sum_p4_valid ;
        O_result            <= S_c3sum          ; 
    end
    else if(SL_more3)begin
        O_result_rdy_pre4   <= S_m3sum_p4_valid ;
        O_result            <= S_m3sum          ; 
    end
    else begin
        O_result_rdy_pre4   <= 1'b0             ;
        O_result            <= {C_OUT{1'b0}}    ;
    end
end


// rubbish 
dly #(
    .C_DATA_WIDTH (1    ) , 
    .C_DLY_NUM    (1    ))
u_sum_valid3(
    .I_clk        (I_clk                ),
    .I_din        (SL_equal3 && S_equal ),
    .O_dout       (S_sum_valid3         )
);

dly #(
    .C_DATA_WIDTH (1    ) , 
    .C_DLY_NUM    (3    ))
u_sum_valid3(
    .I_clk        (I_clk                    ),
    .I_din        (SL_equal5_1d&&S_equal_1d ),
    .O_dout       (S_sum_valid5             )
);





assign O_result = S_sum ;     

endmodule

