//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : iemem_sum.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_iemem_sum
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
module iemem_sum #(
parameter 
    C_IEMEM_WIDTH =  128, 
    C_SPLIT_WIDTH =    8,
    C_DATA_WIDTH  =   12 
    )(
input                               I_clk   ,
input       [     C_IEMEM_WIDTH-1:0]I_din   ,
output reg  [      C_DATA_WIDTH-1:0]O_dout  
);

localparam C_SPLIT_NUM = C_IEMEM_WIDTH/C_SPLIT_WIDTH  ;

genvar idx;

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial  
////////////////////////////////////////////////////////////////////////////////////////////////////

wire [C_SPLIT_WIDTH-1:0]S_data_tmp[C_SPLIT_NUM];

generate
    begin:iemem_data_tmp_initial
        for(idx=0;idx<C_SPLIT_NUM;idx=idx+1)begin
            assign S_data_tmp[idx]   = I_din[(idx+1)*C_SPLIT_WIDTH-1:idx*C_SPLIT_WIDTH];
        end
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// S_data_tmp_t1  
////////////////////////////////////////////////////////////////////////////////////////////////////

reg [C_SPLIT_WIDTH:0]S_data_tmp_t1[C_SPLIT_NUM/2];//8

generate
    begin:iemem_data_tmp_t1
        for(idx=0;idx<C_SPLIT_NUM/2;idx=idx+1)begin
            always @(posedge I_clk)begin
                S_data_tmp_t1[idx] <= S_data_tmp[idx] + S_data_tmp[idx+C_SPLIT_NUM/2] ;
            end
        end
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// S_data_tmp_t2
////////////////////////////////////////////////////////////////////////////////////////////////////

reg  [C_SPLIT_WIDTH+1:0]S_data_tmp_t2[C_SPLIT_NUM/4];//4

generate
    begin:iemem_data_tmp_t2
        for(idx=0;idx<C_SPLIT_NUM/4;idx=idx+1)begin
            always @(posedge I_clk)begin
                S_data_tmp_t2[idx] <= S_data_tmp_t1[idx] + S_data_tmp_t1[idx+C_SPLIT_NUM/4] ;
            end
        end
    end
endgenerate

////////////////////////////////////////////////////////////////////////////////////////////////////
// S_data_tmp_t3
////////////////////////////////////////////////////////////////////////////////////////////////////

reg  [C_SPLIT_WIDTH+2:0]S_data_tmp_t3[C_SPLIT_NUM/8];//2

generate
    begin:iemem_data_tmp_t3
        for(idx=0;idx<C_SPLIT_NUM/8;idx=idx+1)begin
            always @(posedge I_clk)begin
                S_data_tmp_t3[idx] <= S_data_tmp_t2[idx] + S_data_tmp_t2[idx+C_SPLIT_NUM/8] ;
            end
        end
    end
endgenerate

always @(posedge I_clk)begin
    O_dout <= S_data_tmp_t3[0]+S_data_tmp_t3[1]   ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//        u0_wptr_full                                                                           
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
