//`timescale 1ns / 1ps

//module CnvAdd#(
//    parameter           CH_IN       = 16,
//    parameter           CH_OUT      = 32,
//    parameter           PIX         = 8,
//    parameter           KWIDTH      = 4,
//    parameter           DEPTHWIDTH  = 9,
//    parameter           PWIDTH      = 2
//)(
//    input                           I_clk                  ,
//    input                           I_rst                  ,
    
//    input      [KWIDTH-1:0]         I_kx                   ,
//    input      [KWIDTH-1:0]         I_ky                   ,
//    input                           I_compute_en           ,
//    input                           I_cpt_dv               ,
//    input                           I_line_end             ,
//    input      [DEPTHWIDTH-1:0]     I_coGroup              ,
//    input      [DEPTHWIDTH-1:0]     I_woGroup              ,
//    input      [24*CH_OUT*PIX-1:0]  I_result_tmp           ,
//    input                           I_result_dv            ,
    
//    output     [48*CH_IN*PIX-1:0]   O_line_out_data        ,
//    output reg                      O_line_end_flag     = 0,
//    output                          O_kx_end_flag          ,
//    output reg [24*CH_OUT*PIX-1:0]  O_result_0          = 0,
//    output reg [24*CH_OUT*PIX-1:0]  O_result_1          = 0,
//    output reg                      O_data_dv           = 0,
//    output reg [24*CH_OUT*PIX-1:0]  O_macc_data 
//    );

//reg                       S_data_dv                     =0;
//reg                       S_result_dv                   =0;  
//reg                       S_result_dv_d1                =0;
//reg                       S_result_dv_d2                =0;
//reg                       S_result_dv_d3                =0;
//reg                       S_result_dv_d4                =0;
//reg                       S_result_dv_d5                =0;
//reg                       S_result_dv_d6                =0;
//reg                       S_result_dv_d7                =0;
//reg                       S_result_dv_d8                =0;
//reg  [KWIDTH-1:0]         S_cnt_k                       =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d1                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d2                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d3                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d4                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d5                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d6                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d7                    =0;
//reg  [KWIDTH-1:0]         S_cnt_k_d8                    =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt                     =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d1                  =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d2                  =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d3                  =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d4                  =0;
//reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d5                  =0;

//reg  [DEPTHWIDTH-1:0]     S_wog_cnt                     =0;
//wire [DEPTHWIDTH-1:0]     S_obuf_depth                    ;
//reg  [DEPTHWIDTH-1:0]     S_obuf_depth_d1               =0;
//reg  [DEPTHWIDTH-1:0]     S_obuf_depth_d2               =0;
//reg  [DEPTHWIDTH-1:0]     S_obuf_depth_d3               =0;
//reg  [DEPTHWIDTH-1:0]     S_obuf_depth_d4               =0;

//reg  [24*CH_OUT*PIX-1:0]  S_result_kx                     ;
//reg                       S_compute_en                  =0;
//reg                       S_1st_add_en                  =0;
//reg                       S_1st_add_en_d1               =0;
//reg                       S_1st_add_en_d2               =0;
//reg                       S_1st_add_en_d3               =0;
//reg                       S_1st_add_en_d4               =0;
//reg                       S_1st_add_en_d5               =0;

//reg  [KWIDTH-1:0]         S_kx_ceil                     =0;
//wire                      S_1st_add                       ;
//reg                       S_1st_add_d1                  =0;
//reg                       S_result_cnt_en_d1            =0;
//reg                       S_result_cnt_en_d2            =0;
//reg                       S_result_cnt_en_d3            =0;
//reg                       S_result_cnt_en_d4            =0;
//reg                       S_result_cnt_en_d5            =0;
//reg                       S_result_cnt_en_d6            =0;
//reg                       S_result_cnt_en_d7            =0;

//assign S_1st_add = S_1st_add_en_d1 || S_1st_add_en_d2 || S_1st_add_en_d3 || S_1st_add_en_d4 || S_1st_add_en_d5;

//always@ (posedge I_clk)
//    S_1st_add_d1 <= S_1st_add;

//always@ (posedge I_clk)
//    S_kx_ceil <= I_kx-1;

//always@ (posedge I_clk)
//    S_data_dv <= O_data_dv;

//always@ (posedge I_clk)
//begin
//    S_result_cnt_en_d2 <= S_result_cnt_en_d1;
//    S_result_cnt_en_d3 <= S_result_cnt_en_d2;
//    S_result_cnt_en_d4 <= S_result_cnt_en_d3;
//    S_result_cnt_en_d5 <= S_result_cnt_en_d4;
//    S_result_cnt_en_d6 <= S_result_cnt_en_d5;
//    S_result_cnt_en_d7 <= S_result_cnt_en_d6;

//    if (S_result_dv_d1 && S_cnt_k_d1==S_kx_ceil)
//        S_result_cnt_en_d1 <= 1'b1;
//    else
//        S_result_cnt_en_d1 <= 1'b0;
//end

//always@ (posedge I_clk)
//begin
//    S_compute_en <= I_compute_en;
    
//    S_1st_add_en_d1 <= S_1st_add_en;
//    S_1st_add_en_d2 <= S_1st_add_en_d1;
//    S_1st_add_en_d3 <= S_1st_add_en_d2;
//    S_1st_add_en_d4 <= S_1st_add_en_d3;
//    S_1st_add_en_d5 <= S_1st_add_en_d4;
    
//    if (O_line_end_flag)
//        S_1st_add_en <= 1'b0;
//    else if (!S_compute_en && I_compute_en)
//        S_1st_add_en <= 1'b1;
//    else if (I_line_end)
//        S_1st_add_en <= 1'b1;
//end

//always@ (posedge I_clk)
//begin
//    if (S_cnt_k_d8==S_kx_ceil && S_cog_cnt_d5=='d1)
//        O_result_0 <= S_result_kx;
//    else
//        O_result_0 <= O_result_0;
//end

//always@ (posedge I_clk)
//begin
//    if (S_cnt_k_d8==S_kx_ceil && S_cog_cnt_d5=='d0)
//        O_result_1 <= S_result_kx;
//    else
//        O_result_1 <= O_result_1;
//end

//always@ (posedge I_clk)
//begin
//    if (S_cnt_k_d2==S_kx_ceil && S_cog_cnt_d1=='d1)
//        O_macc_data <= S_result_kx;
//    else if (S_cnt_k_d2==S_kx_ceil && S_cog_cnt_d1=='d0)
//        O_macc_data <= S_result_kx;
//end 

//dsp_unit1 dsp_unit_inst0(
//    .I_clk              (I_clk),
//    .I_weight_l         ({21'd0,S_wog_cnt}),
//    .I_weight_h         (27'd0),
//    .I_1feature         ({9'd0,I_coGroup}),
//    .I_pi_cas           ({39'd0,S_cog_cnt}),
//    .O_pi               (),
//    .O_p                (S_obuf_depth)
//    );

//always@ (posedge I_clk)
//begin
//    S_obuf_depth_d1 <= S_obuf_depth;
//    S_obuf_depth_d2 <= S_obuf_depth_d1;
//    S_obuf_depth_d3 <= S_obuf_depth_d2;
//    S_obuf_depth_d4 <= S_obuf_depth_d3;
//end

//always@ (posedge I_clk)
//begin
//    S_result_dv <= I_result_dv;
//    S_result_dv_d1 <= S_result_dv;
//    S_result_dv_d2 <= S_result_dv_d1;
//    S_result_dv_d3 <= S_result_dv_d2;
//    S_result_dv_d4 <= S_result_dv_d3;
//    S_result_dv_d5 <= S_result_dv_d4;
//    S_result_dv_d6 <= S_result_dv_d5;
//    S_result_dv_d7 <= S_result_dv_d6;
//    S_result_dv_d8 <= S_result_dv_d7;
    
//    S_cnt_k_d1 <= S_cnt_k;
//    S_cnt_k_d2 <= S_cnt_k_d1;
//    S_cnt_k_d3 <= S_cnt_k_d2;
//    S_cnt_k_d4 <= S_cnt_k_d3;
//    S_cnt_k_d5 <= S_cnt_k_d4;
//    S_cnt_k_d6 <= S_cnt_k_d5;
//    S_cnt_k_d7 <= S_cnt_k_d6;
//    S_cnt_k_d8 <= S_cnt_k_d7;
    
//    if (~S_result_dv && I_result_dv)
//        S_cnt_k <= 'd0;
//    else if (I_result_dv && S_cnt_k==S_kx_ceil)
//        S_cnt_k <= 'd0;
//    else if (I_result_dv)
//        S_cnt_k <= S_cnt_k + 'd1;
        
//    S_cog_cnt_d1 <= S_cog_cnt;
//    S_cog_cnt_d2 <= S_cog_cnt_d1;
//    S_cog_cnt_d3 <= S_cog_cnt_d2;
//    S_cog_cnt_d4 <= S_cog_cnt_d3;
//    S_cog_cnt_d5 <= S_cog_cnt_d4;
        
//    if (~S_result_dv && I_result_dv)
//        S_cog_cnt <= 'd0;
//    else if (S_cnt_k==S_kx_ceil && S_cog_cnt==I_coGroup-1)
//        S_cog_cnt <= 'd0;
//    else if (S_cnt_k==S_kx_ceil && I_result_dv)
//        S_cog_cnt <= S_cog_cnt + 'd1;
        
        
//    if (~S_result_dv && I_result_dv)
//        S_wog_cnt <= 'd0;
//    else if (S_cnt_k==S_kx_ceil && S_cog_cnt==I_coGroup-1 && I_result_dv)
//        S_wog_cnt <= S_wog_cnt + 'd1;
//end


//always@ (posedge I_clk)
//begin
//    if (!S_result_dv_d7 && S_result_dv_d8)
//        O_line_end_flag <= 1'b1;
//    else
//        O_line_end_flag <= 1'b0;
//end

//genvar gen_i,gen_j;
//generate for (gen_i=0; gen_i<PIX; gen_i=gen_i+1)
//begin:outer_loop
//    for (gen_j=0; gen_j<CH_IN; gen_j=gen_j+1)
//    begin:inner_loop

//    reg [47:0]    S_add = 0;
//    reg [47:0]    S_add_d1 = 0;
//    reg [47:0]    S_add_d2 = 0;
//    reg [47:0]    S_add_d3 = 0;
//    reg [47:0]    S_add_d4 = 0;
//    reg [47:0]    S_add_d5 = 0;
//    (*ram_style="block"*) reg [47:0]    S_obuf_test [511:0];
    
////    always@ (posedge I_clk)
////    begin
////        if (I_result_dv)begin
////            if (S_cnt_k==S_kx_ceil) 
////            begin
////                S_add[23:0] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
////                S_add[47:24] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
////            end
////            else 
////            begin
////                S_add[23:0] <= S_add[23:0] + {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
////                S_add[47:24] <= S_add[47:24] + {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
////            end
////        end
////    end 

//    always@ (posedge I_clk)
//    begin
//        S_add[23:0] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
//        S_add[47:24] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
//    end 
    
//    always@ (posedge I_clk)
//    begin
//        S_add_d1 <= S_add;
//        S_add_d2 <= S_add_d1;
//        S_add_d3 <= S_add_d2;
//        S_add_d4 <= S_add_d3;
//        S_add_d5 <= S_add_d4;
//    end
//    //---------------------------------------------------------------------------------------------------
//    //                                          use bram for obuf
//    //--------------------------------------------------------------------------------------------------- 
    
//    reg          rd_en=0;
//    reg          wr_en=0;
//    reg  [47:0]  dout_reg;
//    reg  [DEPTHWIDTH-1:0]     rd_addr=0;
//    reg  [DEPTHWIDTH-1:0]     wr_addr=0;
//    reg  [47:0]  data_in=0;
    
//    reg                    S_obuf_wr_en   = 0;
//    reg  [DEPTHWIDTH-1:0]  S_obuf_wr_addr = 0;
//    reg  [47:0]            S_obuf_wr_data = 0;
//    reg                    S_obuf_rd_en   = 0;
//    reg  [DEPTHWIDTH-1:0]  S_obuf_rd_addr = 0;
//    reg  [47:0]            S_obuf_rd_data = 0;
    
//    always@ (posedge I_clk)
//    begin
//        if (S_1st_add_en_d1 && S_result_cnt_en_d1)
//            S_obuf_wr_en <= 1'b1;
//        else if (!S_1st_add && S_result_cnt_en_d5)
//            S_obuf_wr_en <= 1'b1;
//        else
//            S_obuf_wr_en <= 1'b0;
//    end
    
//    always@ (posedge I_clk)
//    begin
//        if (S_1st_add_en_d1 && S_result_cnt_en_d1)
//            S_obuf_wr_addr <= S_obuf_depth;
//        else if (S_result_cnt_en_d5)
//            S_obuf_wr_addr <= S_obuf_depth_d4;
//    end
    
//    always@ (posedge I_clk)
//    begin
//        if (S_1st_add_en_d1 && S_result_cnt_en_d1)
//            S_obuf_wr_data <= S_add_d2;
//        else if (!S_1st_add_en_d1 && S_result_cnt_en_d5)
//            S_obuf_wr_data <= data_in;
//    end
    
//    always@ (posedge I_clk)
//        if (S_obuf_wr_en)
//            S_obuf_test[S_obuf_wr_addr] <= S_obuf_wr_data;
    
//    always@ (posedge I_clk)
//    begin
//        if (!S_1st_add_en_d1 && S_result_cnt_en_d1)
//            S_obuf_rd_en <= 1'b1;
//        else
//            S_obuf_rd_en <= 1'b0;
//    end
    
//    always@ (posedge I_clk)
//    begin
//        if (!S_1st_add_en_d1 && S_result_cnt_en_d1)
//            S_obuf_rd_addr <= S_obuf_depth;
//        else if (S_1st_add && S_result_cnt_en_d3)
//            S_obuf_rd_addr <= S_obuf_depth_d2;
//    end
    
//    always@ (posedge I_clk)
//        S_obuf_rd_data <= S_obuf_test[S_obuf_rd_addr];


//    always@ (posedge I_clk)
//        dout_reg <= S_obuf_rd_data;
    
    
//    always@ (posedge I_clk)
//    begin
//        data_in[23:0] <= S_add_d5[23:0] + dout_reg[23:0];
//        data_in[47:24]<= S_add_d5[47:24] + dout_reg[47:24];
//    end
    
//    assign  O_line_out_data[gen_i*16*48+gen_j*48+:48] = {{5{dout_reg[47]}},dout_reg[47:24],dout_reg[18:0]};

//    always@ (posedge I_clk)
//    begin
//        if (S_1st_add_d1 && S_result_cnt_en_d6)
//            S_result_kx[gen_i*16*48+gen_j*48+:48] <= dout_reg;
//        else if (!S_1st_add && S_result_cnt_en_d5)
//            S_result_kx[gen_i*16*48+gen_j*48+:48] <= data_in;
//    end 
    
//    end//innerloop
//end
//endgenerate 


//always@ (posedge I_clk)
//begin
//    if (S_result_cnt_en_d7)
//        O_data_dv <= 1'b1;
//    else
//        O_data_dv <= 1'b0;
//end   


//reg outflag=0;
//always@ (posedge I_clk)
//begin
//    if (!S_result_dv && I_result_dv)
//        outflag <= 1'b0;
//    else if (O_data_dv)
//        outflag <= outflag + 1'b1;
//end

//assign O_kx_end_flag = (I_ky==S_kx_ceil) ? 1'b0 : O_line_end_flag;
//endmodule

/*
`timescale 1ns / 1ps

module CnvAdd#(
    parameter           CH_IN       = 16,
    parameter           CH_OUT      = 32,
    parameter           PIX         = 8,
    parameter           KWIDTH      = 4,
    parameter           DEPTHWIDTH  = 9,
    parameter           PWIDTH      = 2
)(
    input                           I_clk                  ,
    input                           I_rst                  ,
    
    input      [KWIDTH-1:0]         I_kx                   ,
    input      [KWIDTH-1:0]         I_ky                   ,
    input                           I_compute_en           ,
    input                           I_cpt_dv               ,
    input                           I_line_end             ,
    input      [DEPTHWIDTH-1:0]     I_coGroup              ,
    input      [DEPTHWIDTH-1:0]     I_woGroup              ,
    input      [24*CH_OUT*PIX-1:0]  I_result_tmp           ,
    input                           I_result_dv            ,
    
    output reg [48*CH_IN*PIX-1:0]   O_line_out_data     = 0,
    output reg                      O_line_out_dv       = 0,
    output reg                      O_line_end_flag     = 0,
    output                          O_kx_end_flag          ,
//    output reg [24*CH_OUT*PIX-1:0]  O_result_0          = 0,
//    output reg [24*CH_OUT*PIX-1:0]  O_result_1          = 0,
    output     [24*CH_OUT*PIX-1:0]  O_data_out             ,
    output                          O_data_dv              ,
    output reg [24*CH_OUT*PIX-1:0]  O_macc_data 
    );

reg    [24*CH_OUT*PIX-1:0]   S_result_tmp    = 0; 
reg                          S_result_dv     = 0;
reg    [3:0]                 S_kx_cnt        = 0;
reg                          S_obuf_wr_en    = 0;
reg    [8:0]                 S_obuf_waddr    = 0;
//reg                          S_obuf_rd_en    = 0;
reg    [8:0]                 S_obuf_raddr    = 0;
reg                          S_compute_en    = 0;
reg                          S_1st_add_en    = 0;
reg    [3:0]                 S_kx_rd_cnt     = 0;
reg                          S_cpt_dv        = 0;
reg                          S_cpt_dv_d1     = 0;
reg    [24*CH_OUT*PIX-1:0]   S_result_kx     = 0;
reg                          S_result_kx_dv  = 0;

reg                          S_ky_flag       = 0;
reg                          S_kx_cnt_flag   = 0;
        
always@ (posedge I_clk)
begin
    if (I_result_dv) begin
        if (!S_result_dv)
            S_kx_cnt <= 'd0;
        else if (S_kx_cnt == I_kx-1)
            S_kx_cnt <= 'd0;
        else
            S_kx_cnt <= S_kx_cnt + 'd1;
    end    
end

always@ (posedge I_clk)
begin
    if ((I_cpt_dv||S_cpt_dv) && !S_1st_add_en) begin
        if (!S_cpt_dv)
            S_kx_rd_cnt <= 'd0;
        else if (S_kx_rd_cnt == I_kx-1)
            S_kx_rd_cnt <= 'd0;
        else
            S_kx_rd_cnt <= S_kx_rd_cnt + 'd1;
    end    
end

always@ (posedge I_clk)
    if (S_kx_cnt == I_kx-2)
        S_obuf_wr_en <= 1'b1;
    else
        S_obuf_wr_en <= 1'b0;
        
always@ (posedge I_clk)
begin
    S_result_tmp <= I_result_tmp;
    S_result_dv  <= I_result_dv;
    S_cpt_dv     <= I_cpt_dv;
    S_cpt_dv_d1  <= S_cpt_dv;
end

always@ (posedge I_clk)
    if (!S_result_dv && I_result_dv)
        S_obuf_waddr <= 'd0;
    else if (S_obuf_wr_en)
        S_obuf_waddr <= S_obuf_waddr + 'd1;
        
always@ (posedge I_clk)
begin
    if (!S_cpt_dv && I_cpt_dv)
        S_obuf_raddr <= 'd0;
    else if (!S_1st_add_en && S_cpt_dv)
    begin
        if (S_kx_rd_cnt == I_kx-1)
            S_obuf_raddr <= S_obuf_raddr + 'd1; 
    end
end

always@ (posedge I_clk)
    S_compute_en <= I_compute_en;

always@ (posedge I_clk)
    if (O_line_end_flag)
        S_1st_add_en <= 1'b0;
    else if (!S_compute_en && I_compute_en)
        S_1st_add_en <= 1'b1;
    else if (I_line_end)
        S_1st_add_en <= 1'b1;

always@ (posedge I_clk)
    if (!I_compute_en)
        O_line_end_flag <= 1'b0;
    else if (S_result_dv && !I_result_dv)
        O_line_end_flag <= 1'b1;
    else
        O_line_end_flag <= 1'b0;
        
always@ (posedge I_clk)
    if (!S_1st_add_en && S_cpt_dv_d1 && I_ky==I_kx-1)
        O_line_out_dv <= 1'b1;
    else
        O_line_out_dv <= 1'b0;
        
always@ (posedge I_clk)
    if (I_ky== I_kx-1)
        S_ky_flag <= 1'b1;
    else
        S_ky_flag <= 1'b0;
   
always@ (posedge I_clk)
    if (S_kx_cnt==I_kx-2)
        S_kx_cnt_flag <= 1'b1;
    else
        S_kx_cnt_flag <= 1'b0;

genvar gen_i,gen_j;
generate for (gen_i=0; gen_i<PIX; gen_i=gen_i+1)
begin:outer_loop
    for (gen_j=0; gen_j<CH_IN; gen_j=gen_j+1)
    begin:inner_loop

    reg [47:0]    S_add      = 0;
    reg [47:0]    S_data_reg = 0;

    always@ (posedge I_clk)
    begin
        S_add[23:0] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
        S_add[47:24] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
    end
    
    (* ram_style="block"*) reg [47:0]    S_obuf_test [511:0];
    
    always@ (posedge I_clk)
    begin
        if (S_obuf_wr_en)
            S_obuf_test[S_obuf_waddr] <= S_add;
    end
    
    always@ (posedge I_clk)
        S_data_reg <= S_obuf_test[S_obuf_raddr];
        
    always@ (posedge I_clk)
    begin
        if (!S_1st_add_en && S_cpt_dv_d1)
        begin
            if (!(|S_kx_rd_cnt))
                O_line_out_data[gen_i*16*48+gen_j*48+:48] <= {{5{S_data_reg[47]}},S_data_reg[47:24],S_data_reg[18:0]};
            else
                O_line_out_data[gen_i*16*48+gen_j*48+:48] <= 'd0;
        end
        else 
            O_line_out_data[gen_i*16*48+gen_j*48+:48] <= 'd0;
    end
    
    always@ (posedge I_clk)
        if (S_ky_flag && S_kx_cnt_flag)
            S_result_kx[gen_i*16*48+gen_j*48+:48] <= S_add;
    end//innerloop
end
endgenerate 

always@ (posedge I_clk)
begin
    if (S_result_dv) begin
        if (S_ky_flag && S_kx_cnt_flag)
            S_result_kx_dv <= 1'b1;
        else
            S_result_kx_dv <= 1'b0;
    end
    else
        S_result_kx_dv <= 1'b0;
end

assign O_data_out = S_result_kx;
assign O_data_dv  = S_result_kx_dv; 
assign O_kx_end_flag = (I_ky==I_kx-1) ? 1'b0 : O_line_end_flag;

////////////////////////////////////////////////////////////////////////////////

reg  [6143:0]  S_o_data = 0;
reg            S_cnt    = 0;
reg            S_o_dv   = 0;
reg            S_o_dv_d1= 0;
reg            S_o_dv_d2= 0;

always@ (posedge I_clk)
begin
    S_o_data <= O_data_out;
    S_o_dv   <= O_data_dv;
    S_o_dv_d1<= S_o_dv;
    S_o_dv_d2<= S_o_dv_d1;
end
    
always@ (posedge I_clk)
    if (!S_compute_en && I_compute_en)
        S_cnt <= 0;
    else if (O_data_dv)
        S_cnt <= S_cnt + 'd1;
 
        integer line2;
        
        initial begin
        line2 = $fopen("line2_dataOut.txt","w");
        #9425
        forever 
        @(posedge I_clk)
        begin
            if (S_o_dv_d2 && S_cnt)
            begin
            
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                 $signed(S_o_data[24*0+:24]),$signed(S_o_data[24*1+:24]),
                 $signed(S_o_data[24*2+:24]),$signed(S_o_data[24*3+:24]),
                 $signed(S_o_data[24*4+:24]),$signed(S_o_data[24*5+:24]),
                 $signed(S_o_data[24*6+:24]),$signed(S_o_data[24*7+:24]),
                 $signed(S_o_data[24*8+:24]),$signed(S_o_data[24*9+:24]),
                 $signed(S_o_data[24*10+:24]),$signed(S_o_data[24*11+:24]),
                 $signed(S_o_data[24*12+:24]),$signed(S_o_data[24*13+:24]),
                 $signed(S_o_data[24*14+:24]),$signed(S_o_data[24*15+:24]),
                 $signed(S_o_data[24*16+:24]),$signed(S_o_data[24*17+:24]),
                 $signed(S_o_data[24*18+:24]),$signed(S_o_data[24*19+:24]),
                 $signed(S_o_data[24*20+:24]),$signed(S_o_data[24*21+:24]),
                 $signed(S_o_data[24*22+:24]),$signed(S_o_data[24*23+:24]),
                 $signed(S_o_data[24*24+:24]),$signed(S_o_data[24*25+:24]),
                 $signed(S_o_data[24*26+:24]),$signed(S_o_data[24*27+:24]),
                 $signed(S_o_data[24*28+:24]),$signed(S_o_data[24*29+:24]),
                 $signed(S_o_data[24*30+:24]),$signed(S_o_data[24*31+:24]));   
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                 $signed(O_data_out[24*0+:24]),$signed(O_data_out[24*1+:24]),
                 $signed(O_data_out[24*2+:24]),$signed(O_data_out[24*3+:24]),
                 $signed(O_data_out[24*4+:24]),$signed(O_data_out[24*5+:24]),
                 $signed(O_data_out[24*6+:24]),$signed(O_data_out[24*7+:24]),
                 $signed(O_data_out[24*8+:24]),$signed(O_data_out[24*9+:24]),
                 $signed(O_data_out[24*10+:24]),$signed(O_data_out[24*11+:24]),
                 $signed(O_data_out[24*12+:24]),$signed(O_data_out[24*13+:24]),
                 $signed(O_data_out[24*14+:24]),$signed(O_data_out[24*15+:24]),
                 $signed(O_data_out[24*16+:24]),$signed(O_data_out[24*17+:24]),
                 $signed(O_data_out[24*18+:24]),$signed(O_data_out[24*19+:24]),
                 $signed(O_data_out[24*20+:24]),$signed(O_data_out[24*21+:24]),
                 $signed(O_data_out[24*22+:24]),$signed(O_data_out[24*23+:24]),
                 $signed(O_data_out[24*24+:24]),$signed(O_data_out[24*25+:24]),
                 $signed(O_data_out[24*26+:24]),$signed(O_data_out[24*27+:24]),
                 $signed(O_data_out[24*28+:24]),$signed(O_data_out[24*29+:24]),
                 $signed(O_data_out[24*30+:24]),$signed(O_data_out[24*31+:24]));        
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                 $signed(S_o_data[24*32+:24]),$signed(S_o_data[24*33+:24]),
                 $signed(S_o_data[24*34+:24]),$signed(S_o_data[24*35+:24]),
                 $signed(S_o_data[24*36+:24]),$signed(S_o_data[24*37+:24]),
                 $signed(S_o_data[24*38+:24]),$signed(S_o_data[24*39+:24]),
                 $signed(S_o_data[24*40+:24]),$signed(S_o_data[24*41+:24]),
                 $signed(S_o_data[24*42+:24]),$signed(S_o_data[24*43+:24]),
                 $signed(S_o_data[24*44+:24]),$signed(S_o_data[24*45+:24]),
                 $signed(S_o_data[24*46+:24]),$signed(S_o_data[24*47+:24]),
                 $signed(S_o_data[24*48+:24]),$signed(S_o_data[24*49+:24]),
                 $signed(S_o_data[24*50+:24]),$signed(S_o_data[24*51+:24]),
                 $signed(S_o_data[24*52+:24]),$signed(S_o_data[24*53+:24]),
                 $signed(S_o_data[24*54+:24]),$signed(S_o_data[24*55+:24]),
                 $signed(S_o_data[24*56+:24]),$signed(S_o_data[24*57+:24]),
                 $signed(S_o_data[24*58+:24]),$signed(S_o_data[24*59+:24]),
                 $signed(S_o_data[24*60+:24]),$signed(S_o_data[24*61+:24]),
                 $signed(S_o_data[24*62+:24]),$signed(S_o_data[24*63+:24]));
            
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                 $signed(O_data_out[24*32+:24]),$signed(O_data_out[24*33+:24]),
                 $signed(O_data_out[24*34+:24]),$signed(O_data_out[24*35+:24]),
                 $signed(O_data_out[24*36+:24]),$signed(O_data_out[24*37+:24]),
                 $signed(O_data_out[24*38+:24]),$signed(O_data_out[24*39+:24]),
                 $signed(O_data_out[24*40+:24]),$signed(O_data_out[24*41+:24]),
                 $signed(O_data_out[24*42+:24]),$signed(O_data_out[24*43+:24]),
                 $signed(O_data_out[24*44+:24]),$signed(O_data_out[24*45+:24]),
                 $signed(O_data_out[24*46+:24]),$signed(O_data_out[24*47+:24]),
                 $signed(O_data_out[24*48+:24]),$signed(O_data_out[24*49+:24]),
                 $signed(O_data_out[24*50+:24]),$signed(O_data_out[24*51+:24]),
                 $signed(O_data_out[24*52+:24]),$signed(O_data_out[24*53+:24]),
                 $signed(O_data_out[24*54+:24]),$signed(O_data_out[24*55+:24]),
                 $signed(O_data_out[24*56+:24]),$signed(O_data_out[24*57+:24]),
                 $signed(O_data_out[24*58+:24]),$signed(O_data_out[24*59+:24]),
                 $signed(O_data_out[24*60+:24]),$signed(O_data_out[24*61+:24]),
                 $signed(O_data_out[24*62+:24]),$signed(O_data_out[24*63+:24]));  
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*64+:24]),$signed(S_o_data[24*65+:24]),
                $signed(S_o_data[24*66+:24]),$signed(S_o_data[24*67+:24]),
                $signed(S_o_data[24*68+:24]),$signed(S_o_data[24*69+:24]),
                $signed(S_o_data[24*70+:24]),$signed(S_o_data[24*71+:24]),
                $signed(S_o_data[24*72+:24]),$signed(S_o_data[24*73+:24]),
                $signed(S_o_data[24*74+:24]),$signed(S_o_data[24*75+:24]),
                $signed(S_o_data[24*76+:24]),$signed(S_o_data[24*77+:24]),
                $signed(S_o_data[24*78+:24]),$signed(S_o_data[24*79+:24]),
                $signed(S_o_data[24*80+:24]),$signed(S_o_data[24*81+:24]),
                $signed(S_o_data[24*82+:24]),$signed(S_o_data[24*83+:24]),
                $signed(S_o_data[24*84+:24]),$signed(S_o_data[24*85+:24]),
                $signed(S_o_data[24*86+:24]),$signed(S_o_data[24*87+:24]),
                $signed(S_o_data[24*88+:24]),$signed(S_o_data[24*89+:24]),
                $signed(S_o_data[24*90+:24]),$signed(S_o_data[24*91+:24]),
                $signed(S_o_data[24*92+:24]),$signed(S_o_data[24*93+:24]),
                $signed(S_o_data[24*94+:24]),$signed(S_o_data[24*95+:24]));
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*64+:24]),$signed(O_data_out[24*65+:24]),
                $signed(O_data_out[24*66+:24]),$signed(O_data_out[24*67+:24]),
                $signed(O_data_out[24*68+:24]),$signed(O_data_out[24*69+:24]),
                $signed(O_data_out[24*70+:24]),$signed(O_data_out[24*71+:24]),
                $signed(O_data_out[24*72+:24]),$signed(O_data_out[24*73+:24]),
                $signed(O_data_out[24*74+:24]),$signed(O_data_out[24*75+:24]),
                $signed(O_data_out[24*76+:24]),$signed(O_data_out[24*77+:24]),
                $signed(O_data_out[24*78+:24]),$signed(O_data_out[24*79+:24]),
                $signed(O_data_out[24*80+:24]),$signed(O_data_out[24*81+:24]),
                $signed(O_data_out[24*82+:24]),$signed(O_data_out[24*83+:24]),
                $signed(O_data_out[24*84+:24]),$signed(O_data_out[24*85+:24]),
                $signed(O_data_out[24*86+:24]),$signed(O_data_out[24*87+:24]),
                $signed(O_data_out[24*88+:24]),$signed(O_data_out[24*89+:24]),
                $signed(O_data_out[24*90+:24]),$signed(O_data_out[24*91+:24]),
                $signed(O_data_out[24*92+:24]),$signed(O_data_out[24*93+:24]),
                $signed(O_data_out[24*94+:24]),$signed(O_data_out[24*95+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*96+:24]), $signed(S_o_data[24*97+:24]),
                $signed(S_o_data[24*98+:24]), $signed(S_o_data[24*99+:24]),
                $signed(S_o_data[24*100+:24]),$signed(S_o_data[24*101+:24]),
                $signed(S_o_data[24*102+:24]),$signed(S_o_data[24*103+:24]),
                $signed(S_o_data[24*104+:24]),$signed(S_o_data[24*105+:24]),
                $signed(S_o_data[24*106+:24]),$signed(S_o_data[24*107+:24]),
                $signed(S_o_data[24*108+:24]),$signed(S_o_data[24*109+:24]),
                $signed(S_o_data[24*110+:24]),$signed(S_o_data[24*111+:24]),
                $signed(S_o_data[24*112+:24]),$signed(S_o_data[24*113+:24]),
                $signed(S_o_data[24*114+:24]),$signed(S_o_data[24*115+:24]),
                $signed(S_o_data[24*116+:24]),$signed(S_o_data[24*117+:24]),
                $signed(S_o_data[24*118+:24]),$signed(S_o_data[24*119+:24]),
                $signed(S_o_data[24*120+:24]),$signed(S_o_data[24*121+:24]),
                $signed(S_o_data[24*122+:24]),$signed(S_o_data[24*123+:24]),
                $signed(S_o_data[24*124+:24]),$signed(S_o_data[24*125+:24]),
                $signed(S_o_data[24*126+:24]),$signed(S_o_data[24*127+:24])); 
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*96+:24]),$signed(O_data_out[24*97+:24]),
                $signed(O_data_out[24*98+:24]),$signed(O_data_out[24*99+:24]),
                $signed(O_data_out[24*100+:24]),$signed(O_data_out[24*101+:24]),
                $signed(O_data_out[24*102+:24]),$signed(O_data_out[24*103+:24]),
                $signed(O_data_out[24*104+:24]),$signed(O_data_out[24*105+:24]),
                $signed(O_data_out[24*106+:24]),$signed(O_data_out[24*107+:24]),
                $signed(O_data_out[24*108+:24]),$signed(O_data_out[24*109+:24]),
                $signed(O_data_out[24*110+:24]),$signed(O_data_out[24*111+:24]),
                $signed(O_data_out[24*112+:24]),$signed(O_data_out[24*113+:24]),
                $signed(O_data_out[24*114+:24]),$signed(O_data_out[24*115+:24]),
                $signed(O_data_out[24*116+:24]),$signed(O_data_out[24*117+:24]),
                $signed(O_data_out[24*118+:24]),$signed(O_data_out[24*119+:24]),
                $signed(O_data_out[24*120+:24]),$signed(O_data_out[24*121+:24]),
                $signed(O_data_out[24*122+:24]),$signed(O_data_out[24*123+:24]),
                $signed(O_data_out[24*124+:24]),$signed(O_data_out[24*125+:24]),
                $signed(O_data_out[24*126+:24]),$signed(O_data_out[24*127+:24]));  
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*128+:24]),$signed(S_o_data[24*129+:24]),
                $signed(S_o_data[24*130+:24]),$signed(S_o_data[24*131+:24]),
                $signed(S_o_data[24*132+:24]),$signed(S_o_data[24*133+:24]),
                $signed(S_o_data[24*134+:24]),$signed(S_o_data[24*135+:24]),
                $signed(S_o_data[24*136+:24]),$signed(S_o_data[24*137+:24]),
                $signed(S_o_data[24*138+:24]),$signed(S_o_data[24*139+:24]),
                $signed(S_o_data[24*140+:24]),$signed(S_o_data[24*141+:24]),
                $signed(S_o_data[24*142+:24]),$signed(S_o_data[24*143+:24]),
                $signed(S_o_data[24*144+:24]),$signed(S_o_data[24*145+:24]),
                $signed(S_o_data[24*146+:24]),$signed(S_o_data[24*147+:24]),
                $signed(S_o_data[24*148+:24]),$signed(S_o_data[24*149+:24]),
                $signed(S_o_data[24*150+:24]),$signed(S_o_data[24*151+:24]),
                $signed(S_o_data[24*152+:24]),$signed(S_o_data[24*153+:24]),
                $signed(S_o_data[24*154+:24]),$signed(S_o_data[24*155+:24]),
                $signed(S_o_data[24*156+:24]),$signed(S_o_data[24*157+:24]),
                $signed(S_o_data[24*158+:24]),$signed(S_o_data[24*159+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*128+:24]),$signed(O_data_out[24*129+:24]),
                $signed(O_data_out[24*130+:24]),$signed(O_data_out[24*131+:24]),
                $signed(O_data_out[24*132+:24]),$signed(O_data_out[24*133+:24]),
                $signed(O_data_out[24*134+:24]),$signed(O_data_out[24*135+:24]),
                $signed(O_data_out[24*136+:24]),$signed(O_data_out[24*137+:24]),
                $signed(O_data_out[24*138+:24]),$signed(O_data_out[24*139+:24]),
                $signed(O_data_out[24*140+:24]),$signed(O_data_out[24*141+:24]),
                $signed(O_data_out[24*142+:24]),$signed(O_data_out[24*143+:24]),
                $signed(O_data_out[24*144+:24]),$signed(O_data_out[24*145+:24]),
                $signed(O_data_out[24*146+:24]),$signed(O_data_out[24*147+:24]),
                $signed(O_data_out[24*148+:24]),$signed(O_data_out[24*149+:24]),
                $signed(O_data_out[24*150+:24]),$signed(O_data_out[24*151+:24]),
                $signed(O_data_out[24*152+:24]),$signed(O_data_out[24*153+:24]),
                $signed(O_data_out[24*154+:24]),$signed(O_data_out[24*155+:24]),
                $signed(O_data_out[24*156+:24]),$signed(O_data_out[24*157+:24]),
                $signed(O_data_out[24*158+:24]),$signed(O_data_out[24*159+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*160+:24]),$signed(S_o_data[24*161+:24]),
                $signed(S_o_data[24*162+:24]),$signed(S_o_data[24*163+:24]),
                $signed(S_o_data[24*164+:24]),$signed(S_o_data[24*165+:24]),
                $signed(S_o_data[24*166+:24]),$signed(S_o_data[24*167+:24]),
                $signed(S_o_data[24*168+:24]),$signed(S_o_data[24*169+:24]),
                $signed(S_o_data[24*170+:24]),$signed(S_o_data[24*171+:24]),
                $signed(S_o_data[24*172+:24]),$signed(S_o_data[24*173+:24]),
                $signed(S_o_data[24*174+:24]),$signed(S_o_data[24*175+:24]),
                $signed(S_o_data[24*176+:24]),$signed(S_o_data[24*177+:24]),
                $signed(S_o_data[24*178+:24]),$signed(S_o_data[24*179+:24]),
                $signed(S_o_data[24*180+:24]),$signed(S_o_data[24*181+:24]),
                $signed(S_o_data[24*182+:24]),$signed(S_o_data[24*183+:24]),
                $signed(S_o_data[24*184+:24]),$signed(S_o_data[24*185+:24]),
                $signed(S_o_data[24*186+:24]),$signed(S_o_data[24*187+:24]),
                $signed(S_o_data[24*188+:24]),$signed(S_o_data[24*189+:24]),
                $signed(S_o_data[24*190+:24]),$signed(S_o_data[24*191+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*160+:24]),$signed(O_data_out[24*161+:24]),
                $signed(O_data_out[24*162+:24]),$signed(O_data_out[24*163+:24]),
                $signed(O_data_out[24*164+:24]),$signed(O_data_out[24*165+:24]),
                $signed(O_data_out[24*166+:24]),$signed(O_data_out[24*167+:24]),
                $signed(O_data_out[24*168+:24]),$signed(O_data_out[24*169+:24]),
                $signed(O_data_out[24*170+:24]),$signed(O_data_out[24*171+:24]),
                $signed(O_data_out[24*172+:24]),$signed(O_data_out[24*173+:24]),
                $signed(O_data_out[24*174+:24]),$signed(O_data_out[24*175+:24]),
                $signed(O_data_out[24*176+:24]),$signed(O_data_out[24*177+:24]),
                $signed(O_data_out[24*178+:24]),$signed(O_data_out[24*179+:24]),
                $signed(O_data_out[24*180+:24]),$signed(O_data_out[24*181+:24]),
                $signed(O_data_out[24*182+:24]),$signed(O_data_out[24*183+:24]),
                $signed(O_data_out[24*184+:24]),$signed(O_data_out[24*185+:24]),
                $signed(O_data_out[24*186+:24]),$signed(O_data_out[24*187+:24]),
                $signed(O_data_out[24*188+:24]),$signed(O_data_out[24*189+:24]),
                $signed(O_data_out[24*190+:24]),$signed(O_data_out[24*191+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*192+:24]),$signed(S_o_data[24*193+:24]),
                $signed(S_o_data[24*194+:24]),$signed(S_o_data[24*195+:24]),
                $signed(S_o_data[24*196+:24]),$signed(S_o_data[24*197+:24]),
                $signed(S_o_data[24*198+:24]),$signed(S_o_data[24*199+:24]),
                $signed(S_o_data[24*200+:24]),$signed(S_o_data[24*201+:24]),
                $signed(S_o_data[24*202+:24]),$signed(S_o_data[24*203+:24]),
                $signed(S_o_data[24*204+:24]),$signed(S_o_data[24*205+:24]),
                $signed(S_o_data[24*206+:24]),$signed(S_o_data[24*207+:24]),
                $signed(S_o_data[24*208+:24]),$signed(S_o_data[24*209+:24]),
                $signed(S_o_data[24*210+:24]),$signed(S_o_data[24*211+:24]),
                $signed(S_o_data[24*212+:24]),$signed(S_o_data[24*213+:24]),
                $signed(S_o_data[24*214+:24]),$signed(S_o_data[24*215+:24]),
                $signed(S_o_data[24*216+:24]),$signed(S_o_data[24*217+:24]),
                $signed(S_o_data[24*218+:24]),$signed(S_o_data[24*219+:24]),
                $signed(S_o_data[24*220+:24]),$signed(S_o_data[24*221+:24]),
                $signed(S_o_data[24*222+:24]),$signed(S_o_data[24*223+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*192+:24]),$signed(O_data_out[24*193+:24]),
                $signed(O_data_out[24*194+:24]),$signed(O_data_out[24*195+:24]),
                $signed(O_data_out[24*196+:24]),$signed(O_data_out[24*197+:24]),
                $signed(O_data_out[24*198+:24]),$signed(O_data_out[24*199+:24]),
                $signed(O_data_out[24*200+:24]),$signed(O_data_out[24*201+:24]),
                $signed(O_data_out[24*202+:24]),$signed(O_data_out[24*203+:24]),
                $signed(O_data_out[24*204+:24]),$signed(O_data_out[24*205+:24]),
                $signed(O_data_out[24*206+:24]),$signed(O_data_out[24*207+:24]),
                $signed(O_data_out[24*208+:24]),$signed(O_data_out[24*209+:24]),
                $signed(O_data_out[24*210+:24]),$signed(O_data_out[24*211+:24]),
                $signed(O_data_out[24*212+:24]),$signed(O_data_out[24*213+:24]),
                $signed(O_data_out[24*214+:24]),$signed(O_data_out[24*215+:24]),
                $signed(O_data_out[24*216+:24]),$signed(O_data_out[24*217+:24]),
                $signed(O_data_out[24*218+:24]),$signed(O_data_out[24*219+:24]),
                $signed(O_data_out[24*220+:24]),$signed(O_data_out[24*221+:24]),
                $signed(O_data_out[24*222+:24]),$signed(O_data_out[24*223+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data[24*224+:24]),$signed(S_o_data[24*225+:24]),
                $signed(S_o_data[24*226+:24]),$signed(S_o_data[24*227+:24]),
                $signed(S_o_data[24*228+:24]),$signed(S_o_data[24*229+:24]),
                $signed(S_o_data[24*230+:24]),$signed(S_o_data[24*231+:24]),
                $signed(S_o_data[24*232+:24]),$signed(S_o_data[24*233+:24]),
                $signed(S_o_data[24*234+:24]),$signed(S_o_data[24*235+:24]),
                $signed(S_o_data[24*236+:24]),$signed(S_o_data[24*237+:24]),
                $signed(S_o_data[24*238+:24]),$signed(S_o_data[24*239+:24]),
                $signed(S_o_data[24*240+:24]),$signed(S_o_data[24*241+:24]),
                $signed(S_o_data[24*242+:24]),$signed(S_o_data[24*243+:24]),
                $signed(S_o_data[24*244+:24]),$signed(S_o_data[24*245+:24]),
                $signed(S_o_data[24*246+:24]),$signed(S_o_data[24*247+:24]),
                $signed(S_o_data[24*248+:24]),$signed(S_o_data[24*249+:24]),
                $signed(S_o_data[24*250+:24]),$signed(S_o_data[24*251+:24]),
                $signed(S_o_data[24*252+:24]),$signed(S_o_data[24*253+:24]),
                $signed(S_o_data[24*254+:24]),$signed(S_o_data[24*255+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*224+:24]),$signed(O_data_out[24*225+:24]),
                $signed(O_data_out[24*226+:24]),$signed(O_data_out[24*227+:24]),
                $signed(O_data_out[24*228+:24]),$signed(O_data_out[24*229+:24]),
                $signed(O_data_out[24*230+:24]),$signed(O_data_out[24*231+:24]),
                $signed(O_data_out[24*232+:24]),$signed(O_data_out[24*233+:24]),
                $signed(O_data_out[24*234+:24]),$signed(O_data_out[24*235+:24]),
                $signed(O_data_out[24*236+:24]),$signed(O_data_out[24*237+:24]),
                $signed(O_data_out[24*238+:24]),$signed(O_data_out[24*239+:24]),
                $signed(O_data_out[24*240+:24]),$signed(O_data_out[24*241+:24]),
                $signed(O_data_out[24*242+:24]),$signed(O_data_out[24*243+:24]),
                $signed(O_data_out[24*244+:24]),$signed(O_data_out[24*245+:24]),
                $signed(O_data_out[24*246+:24]),$signed(O_data_out[24*247+:24]),
                $signed(O_data_out[24*248+:24]),$signed(O_data_out[24*249+:24]),
                $signed(O_data_out[24*250+:24]),$signed(O_data_out[24*251+:24]),
                $signed(O_data_out[24*252+:24]),$signed(O_data_out[24*253+:24]),
                $signed(O_data_out[24*254+:24]),$signed(O_data_out[24*255+:24]));
            end
        end
        end       

endmodule
*/

`timescale 1ns / 1ps

module CnvAdd#(
    parameter           CH_IN       = 16,
    parameter           CH_OUT      = 32,
    parameter           PIX         = 8,
    parameter           KWIDTH      = 4,
    parameter           DEPTHWIDTH  = 9,
    parameter           PWIDTH      = 2
)(
    input                           I_clk                  ,
    input                           I_rst                  ,
    
    input      [KWIDTH-1:0]         I_kx                   ,
    input      [KWIDTH-1:0]         I_ky                   ,
    input                           I_compute_en           ,
    input                           I_cpt_dv               ,
    input                           I_line_end             ,
    input      [DEPTHWIDTH-1:0]     I_coGroup              ,
    input      [DEPTHWIDTH-1:0]     I_woGroup              ,
    input      [24*CH_OUT*PIX-1:0]  I_result_tmp           ,
    input                           I_result_dv            ,
    input      [8:0]                I_post_raddr           ,
    output reg [48*CH_IN*PIX-1:0]   O_line_out_data     = 0,
    output reg                      O_line_out_dv       = 0,
    output reg                      O_line_end_flag     = 0,
    output                          O_kx_end_flag          ,
    output reg [24*CH_OUT*PIX-1:0]  O_data_out          = 0,
    output reg                      O_data_dv           = 0,
    output reg [24*CH_OUT*PIX-1:0]  O_macc_data            ,
    output reg                      O_post_begin_flag   = 0         
    );     

    reg  [24*CH_OUT*PIX-1:0]              S_data_in        =0;
    reg                                   S_dv_in          =0;
    reg  [24*CH_OUT*PIX-1:0]              S_data_in_d1     =0;
    reg                                   S_dv_in_d1       =0;
    reg                                   S_dv_in_d2       =0;
    reg  [3:0]                            S_kx_cnt         =0;
    reg  [3:0]                            S_kx_cnt_d1      =0;
    reg  [3:0]                            S_kx_cnt_d2      =0;
    reg                                   S_kx_end_flag    =0;
    reg                                   S_compute_en     =0;
    reg                                   S_obuf_we        =0;
    reg  [8:0]                            S_obuf_waddr     =0;
    reg                                   S_1st_add_en     =0;
    reg                                   S_1st_add_en_d1  =0;
    reg  [8:0]                            S_obuf_raddr     =0;
    reg                                   S_obuf_add_flag  =0;
    reg  [47:0]                           S_obuf_din       =0;

    
    always@ (posedge I_clk)
    begin
        S_data_in <= I_result_tmp;
        S_dv_in   <= I_result_dv;
        
        S_data_in_d1 <= S_data_in;
        S_dv_in_d1   <= S_dv_in;
        
        S_dv_in_d2 <= S_dv_in_d1;
    end
    
    always@ (posedge I_clk)
        S_compute_en <= I_compute_en;
    
    always@ (posedge I_clk)
    begin
        S_kx_cnt_d1 <= S_kx_cnt;
        S_kx_cnt_d2 <= S_kx_cnt_d1;
        if (!S_compute_en && I_compute_en)
            S_kx_cnt <= 'd0;
        else if (S_dv_in)
        begin
            if (S_kx_cnt== I_kx-1)
                S_kx_cnt <= 'd0;
            else
                S_kx_cnt <= S_kx_cnt + 'd1;
        end
    end
    
    always@ (posedge I_clk)
    begin
        if (S_dv_in && S_kx_cnt==I_kx-1)
            S_kx_end_flag <= 1'b1;
        else
            S_kx_end_flag <= 1'b0;
    end
    
    always@ (posedge I_clk)
    begin
        if (S_dv_in_d1 && S_kx_cnt_d1==I_kx-1)
            S_obuf_add_flag <= 1'b1;
        else
            S_obuf_add_flag <= 1'b0;
    end
    
    always@ (posedge I_clk)
        S_obuf_we <= S_obuf_add_flag;
    
    always@ (posedge I_clk)
        if (!S_dv_in && I_result_dv)
            S_obuf_waddr <= 'd0;
        else if (S_obuf_we)
            S_obuf_waddr <= S_obuf_waddr + 'd1;
            
    always@ (posedge I_clk)
        if (!S_dv_in_d1 && S_dv_in)
            S_obuf_raddr <= 'd0;
        else if (S_dv_in && S_kx_cnt=='d0)
            S_obuf_raddr <= S_obuf_raddr + 'd1;   
        else if (!S_dv_in)
            S_obuf_raddr <= I_post_raddr;
        
    always@ (posedge I_clk)
    begin
        S_1st_add_en_d1 <= S_1st_add_en;
        if (O_line_end_flag)
            S_1st_add_en <= 1'b0;
        else if (!S_compute_en && I_compute_en)
            S_1st_add_en <= 1'b1;
        else if (I_line_end)
            S_1st_add_en <= 1'b1;
    end
        
    always@ (posedge I_clk)
        if (!I_compute_en)
            O_line_end_flag <= 1'b0;
        else if (S_dv_in && !I_result_dv)
            O_line_end_flag <= 1'b1;
        else
            O_line_end_flag <= 1'b0;
    
    genvar i,j;
    generate for (i=0; i<PIX; i=i+1)
    begin:out
        for (j=0; j<CH_IN; j=j+1)
        begin:in
      
        reg  [47:0]      S_adder          =0;
        reg  [47:0]      S_sum            =0;
        reg  [47:0]      S_obuf_din       =0;
        wire [47:0]      S_obuf_adder       ;
        (* ram_style="block" *)reg [47:0] S_obuf [511:0];
        reg  [47:0]                       S_obuf_odata     =0;
        reg  [47:0]                       S_obuf_odata_d1  =0;
        reg  [47:0]                       S_obuf_odata_d2  =0;
        
        always@ (posedge I_clk)
        begin
            if (S_dv_in) 
            begin
                S_adder[23:0] <= {{(5){S_data_in[i*16*48+j*48+19-1]}},S_data_in[i*16*48+j*48+:19]};
                S_adder[47:24] <= {{(5){S_data_in[i*16*48+j*48+19+19-1]}},S_data_in[i*16*48+j*48+19+:19]};
            end
        end
        
        always@ (posedge I_clk)
        begin
            if (S_dv_in_d1 && S_kx_cnt_d1==0)
            begin
                S_sum[23:0] <= S_adder[23:0];
                S_sum[47:24] <= S_adder[47:24];
            end
            else if (S_dv_in_d1)
            begin
                S_sum[23:0] <= S_sum[23:0]+ S_adder[23:0];
                S_sum[47:24] <= S_sum[47:24]+ S_adder[47:24];        
            end             
        end
        
        always@ (posedge I_clk)
            S_obuf_odata <= S_obuf[S_obuf_raddr];  
            
        always@ (posedge I_clk)
        begin
            S_obuf_odata_d1 <= S_obuf_odata;
            S_obuf_odata_d2 <= S_obuf_odata_d1;
        end  
        
        assign S_obuf_adder = (S_1st_add_en||S_1st_add_en_d1) ? 'd0 : S_obuf_odata_d2;
        
        always@ (posedge I_clk)
        begin
            S_obuf_din[47:24] <= S_sum[47:24] + S_obuf_adder[47:24];
            S_obuf_din[23:0] <= S_sum[23:0] + S_obuf_adder[23:0];
        end
    
        always@ (posedge I_clk)
        begin
            if (S_obuf_we)
                S_obuf[S_obuf_waddr] <= S_obuf_din;
        end
        
        always@ (posedge I_clk)
            O_data_out[i*16*48+j*48+:48] <= S_obuf_din;
            
        always@ (posedge I_clk)
            O_macc_data[i*16*48+j*48+:48] <= S_obuf_odata_d2;
    
        end
    end
    endgenerate
    
    always@ (posedge I_clk)
    begin
        if (I_ky==I_kx-1)
            O_data_dv <= S_obuf_we;
        else
            O_data_dv <= 1'b0;
    end
    
    assign O_kx_end_flag = (I_ky==I_kx-1) ? 1'b0 : O_line_end_flag;
    
    always@ (posedge I_clk)
        if (O_line_end_flag && I_ky==I_kx-1)
            O_post_begin_flag <= 1'b1;
        else
            O_post_begin_flag <= 1'b0;
/*            
//////////////////////////////////////////////////////////////////////
reg  [6143:0]  S_o_data    =0;
reg  [6143:0]  S_o_data_d1 =0;
reg  [6143:0]  S_o_data_d2 =0;
reg            S_cnt    = 0;
reg            S_o_dv   = 0;
reg            S_o_dv_d1= 0;
reg            S_o_dv_d2= 0;

always@ (posedge I_clk)
begin
    S_o_data <= O_data_out;
    S_o_data_d1 <= S_o_data;
    S_o_data_d2 <= S_o_data_d1;
    S_o_dv   <= O_data_dv;
    S_o_dv_d1<= S_o_dv;
    S_o_dv_d2<= S_o_dv_d1;
end
    
always@ (posedge I_clk)
    if (!S_compute_en && I_compute_en)
        S_cnt <= 0;
    else if (O_data_dv)
        S_cnt <= S_cnt + 'd1;
 
        integer line2;
        
        initial begin
        line2 = $fopen("line2_dataOut.txt","w");
        #9425
        forever 
        @(posedge I_clk)
        begin
            if (O_data_dv && S_cnt)
            begin
            
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                 $signed(S_o_data_d2[24*0+:24]),$signed(S_o_data_d2[24*1+:24]),
                 $signed(S_o_data_d2[24*2+:24]),$signed(S_o_data_d2[24*3+:24]),
                 $signed(S_o_data_d2[24*4+:24]),$signed(S_o_data_d2[24*5+:24]),
                 $signed(S_o_data_d2[24*6+:24]),$signed(S_o_data_d2[24*7+:24]),
                 $signed(S_o_data_d2[24*8+:24]),$signed(S_o_data_d2[24*9+:24]),
                 $signed(S_o_data_d2[24*10+:24]),$signed(S_o_data_d2[24*11+:24]),
                 $signed(S_o_data_d2[24*12+:24]),$signed(S_o_data_d2[24*13+:24]),
                 $signed(S_o_data_d2[24*14+:24]),$signed(S_o_data_d2[24*15+:24]),
                 $signed(S_o_data_d2[24*16+:24]),$signed(S_o_data_d2[24*17+:24]),
                 $signed(S_o_data_d2[24*18+:24]),$signed(S_o_data_d2[24*19+:24]),
                 $signed(S_o_data_d2[24*20+:24]),$signed(S_o_data_d2[24*21+:24]),
                 $signed(S_o_data_d2[24*22+:24]),$signed(S_o_data_d2[24*23+:24]),
                 $signed(S_o_data_d2[24*24+:24]),$signed(S_o_data_d2[24*25+:24]),
                 $signed(S_o_data_d2[24*26+:24]),$signed(S_o_data_d2[24*27+:24]),
                 $signed(S_o_data_d2[24*28+:24]),$signed(S_o_data_d2[24*29+:24]),
                 $signed(S_o_data_d2[24*30+:24]),$signed(S_o_data_d2[24*31+:24]));   
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                 $signed(O_data_out[24*0+:24]),$signed(O_data_out[24*1+:24]),
                 $signed(O_data_out[24*2+:24]),$signed(O_data_out[24*3+:24]),
                 $signed(O_data_out[24*4+:24]),$signed(O_data_out[24*5+:24]),
                 $signed(O_data_out[24*6+:24]),$signed(O_data_out[24*7+:24]),
                 $signed(O_data_out[24*8+:24]),$signed(O_data_out[24*9+:24]),
                 $signed(O_data_out[24*10+:24]),$signed(O_data_out[24*11+:24]),
                 $signed(O_data_out[24*12+:24]),$signed(O_data_out[24*13+:24]),
                 $signed(O_data_out[24*14+:24]),$signed(O_data_out[24*15+:24]),
                 $signed(O_data_out[24*16+:24]),$signed(O_data_out[24*17+:24]),
                 $signed(O_data_out[24*18+:24]),$signed(O_data_out[24*19+:24]),
                 $signed(O_data_out[24*20+:24]),$signed(O_data_out[24*21+:24]),
                 $signed(O_data_out[24*22+:24]),$signed(O_data_out[24*23+:24]),
                 $signed(O_data_out[24*24+:24]),$signed(O_data_out[24*25+:24]),
                 $signed(O_data_out[24*26+:24]),$signed(O_data_out[24*27+:24]),
                 $signed(O_data_out[24*28+:24]),$signed(O_data_out[24*29+:24]),
                 $signed(O_data_out[24*30+:24]),$signed(O_data_out[24*31+:24]));        
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                 $signed(S_o_data_d2[24*32+:24]),$signed(S_o_data_d2[24*33+:24]),
                 $signed(S_o_data_d2[24*34+:24]),$signed(S_o_data_d2[24*35+:24]),
                 $signed(S_o_data_d2[24*36+:24]),$signed(S_o_data_d2[24*37+:24]),
                 $signed(S_o_data_d2[24*38+:24]),$signed(S_o_data_d2[24*39+:24]),
                 $signed(S_o_data_d2[24*40+:24]),$signed(S_o_data_d2[24*41+:24]),
                 $signed(S_o_data_d2[24*42+:24]),$signed(S_o_data_d2[24*43+:24]),
                 $signed(S_o_data_d2[24*44+:24]),$signed(S_o_data_d2[24*45+:24]),
                 $signed(S_o_data_d2[24*46+:24]),$signed(S_o_data_d2[24*47+:24]),
                 $signed(S_o_data_d2[24*48+:24]),$signed(S_o_data_d2[24*49+:24]),
                 $signed(S_o_data_d2[24*50+:24]),$signed(S_o_data_d2[24*51+:24]),
                 $signed(S_o_data_d2[24*52+:24]),$signed(S_o_data_d2[24*53+:24]),
                 $signed(S_o_data_d2[24*54+:24]),$signed(S_o_data_d2[24*55+:24]),
                 $signed(S_o_data_d2[24*56+:24]),$signed(S_o_data_d2[24*57+:24]),
                 $signed(S_o_data_d2[24*58+:24]),$signed(S_o_data_d2[24*59+:24]),
                 $signed(S_o_data_d2[24*60+:24]),$signed(S_o_data_d2[24*61+:24]),
                 $signed(S_o_data_d2[24*62+:24]),$signed(S_o_data_d2[24*63+:24]));
            
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                 $signed(O_data_out[24*32+:24]),$signed(O_data_out[24*33+:24]),
                 $signed(O_data_out[24*34+:24]),$signed(O_data_out[24*35+:24]),
                 $signed(O_data_out[24*36+:24]),$signed(O_data_out[24*37+:24]),
                 $signed(O_data_out[24*38+:24]),$signed(O_data_out[24*39+:24]),
                 $signed(O_data_out[24*40+:24]),$signed(O_data_out[24*41+:24]),
                 $signed(O_data_out[24*42+:24]),$signed(O_data_out[24*43+:24]),
                 $signed(O_data_out[24*44+:24]),$signed(O_data_out[24*45+:24]),
                 $signed(O_data_out[24*46+:24]),$signed(O_data_out[24*47+:24]),
                 $signed(O_data_out[24*48+:24]),$signed(O_data_out[24*49+:24]),
                 $signed(O_data_out[24*50+:24]),$signed(O_data_out[24*51+:24]),
                 $signed(O_data_out[24*52+:24]),$signed(O_data_out[24*53+:24]),
                 $signed(O_data_out[24*54+:24]),$signed(O_data_out[24*55+:24]),
                 $signed(O_data_out[24*56+:24]),$signed(O_data_out[24*57+:24]),
                 $signed(O_data_out[24*58+:24]),$signed(O_data_out[24*59+:24]),
                 $signed(O_data_out[24*60+:24]),$signed(O_data_out[24*61+:24]),
                 $signed(O_data_out[24*62+:24]),$signed(O_data_out[24*63+:24]));  
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*64+:24]),$signed(S_o_data_d2[24*65+:24]),
                $signed(S_o_data_d2[24*66+:24]),$signed(S_o_data_d2[24*67+:24]),
                $signed(S_o_data_d2[24*68+:24]),$signed(S_o_data_d2[24*69+:24]),
                $signed(S_o_data_d2[24*70+:24]),$signed(S_o_data_d2[24*71+:24]),
                $signed(S_o_data_d2[24*72+:24]),$signed(S_o_data_d2[24*73+:24]),
                $signed(S_o_data_d2[24*74+:24]),$signed(S_o_data_d2[24*75+:24]),
                $signed(S_o_data_d2[24*76+:24]),$signed(S_o_data_d2[24*77+:24]),
                $signed(S_o_data_d2[24*78+:24]),$signed(S_o_data_d2[24*79+:24]),
                $signed(S_o_data_d2[24*80+:24]),$signed(S_o_data_d2[24*81+:24]),
                $signed(S_o_data_d2[24*82+:24]),$signed(S_o_data_d2[24*83+:24]),
                $signed(S_o_data_d2[24*84+:24]),$signed(S_o_data_d2[24*85+:24]),
                $signed(S_o_data_d2[24*86+:24]),$signed(S_o_data_d2[24*87+:24]),
                $signed(S_o_data_d2[24*88+:24]),$signed(S_o_data_d2[24*89+:24]),
                $signed(S_o_data_d2[24*90+:24]),$signed(S_o_data_d2[24*91+:24]),
                $signed(S_o_data_d2[24*92+:24]),$signed(S_o_data_d2[24*93+:24]),
                $signed(S_o_data_d2[24*94+:24]),$signed(S_o_data_d2[24*95+:24]));
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*64+:24]),$signed(O_data_out[24*65+:24]),
                $signed(O_data_out[24*66+:24]),$signed(O_data_out[24*67+:24]),
                $signed(O_data_out[24*68+:24]),$signed(O_data_out[24*69+:24]),
                $signed(O_data_out[24*70+:24]),$signed(O_data_out[24*71+:24]),
                $signed(O_data_out[24*72+:24]),$signed(O_data_out[24*73+:24]),
                $signed(O_data_out[24*74+:24]),$signed(O_data_out[24*75+:24]),
                $signed(O_data_out[24*76+:24]),$signed(O_data_out[24*77+:24]),
                $signed(O_data_out[24*78+:24]),$signed(O_data_out[24*79+:24]),
                $signed(O_data_out[24*80+:24]),$signed(O_data_out[24*81+:24]),
                $signed(O_data_out[24*82+:24]),$signed(O_data_out[24*83+:24]),
                $signed(O_data_out[24*84+:24]),$signed(O_data_out[24*85+:24]),
                $signed(O_data_out[24*86+:24]),$signed(O_data_out[24*87+:24]),
                $signed(O_data_out[24*88+:24]),$signed(O_data_out[24*89+:24]),
                $signed(O_data_out[24*90+:24]),$signed(O_data_out[24*91+:24]),
                $signed(O_data_out[24*92+:24]),$signed(O_data_out[24*93+:24]),
                $signed(O_data_out[24*94+:24]),$signed(O_data_out[24*95+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*96+:24]), $signed(S_o_data_d2[24*97+:24]),
                $signed(S_o_data_d2[24*98+:24]), $signed(S_o_data_d2[24*99+:24]),
                $signed(S_o_data_d2[24*100+:24]),$signed(S_o_data_d2[24*101+:24]),
                $signed(S_o_data_d2[24*102+:24]),$signed(S_o_data_d2[24*103+:24]),
                $signed(S_o_data_d2[24*104+:24]),$signed(S_o_data_d2[24*105+:24]),
                $signed(S_o_data_d2[24*106+:24]),$signed(S_o_data_d2[24*107+:24]),
                $signed(S_o_data_d2[24*108+:24]),$signed(S_o_data_d2[24*109+:24]),
                $signed(S_o_data_d2[24*110+:24]),$signed(S_o_data_d2[24*111+:24]),
                $signed(S_o_data_d2[24*112+:24]),$signed(S_o_data_d2[24*113+:24]),
                $signed(S_o_data_d2[24*114+:24]),$signed(S_o_data_d2[24*115+:24]),
                $signed(S_o_data_d2[24*116+:24]),$signed(S_o_data_d2[24*117+:24]),
                $signed(S_o_data_d2[24*118+:24]),$signed(S_o_data_d2[24*119+:24]),
                $signed(S_o_data_d2[24*120+:24]),$signed(S_o_data_d2[24*121+:24]),
                $signed(S_o_data_d2[24*122+:24]),$signed(S_o_data_d2[24*123+:24]),
                $signed(S_o_data_d2[24*124+:24]),$signed(S_o_data_d2[24*125+:24]),
                $signed(S_o_data_d2[24*126+:24]),$signed(S_o_data_d2[24*127+:24])); 
        
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*96+:24]),$signed(O_data_out[24*97+:24]),
                $signed(O_data_out[24*98+:24]),$signed(O_data_out[24*99+:24]),
                $signed(O_data_out[24*100+:24]),$signed(O_data_out[24*101+:24]),
                $signed(O_data_out[24*102+:24]),$signed(O_data_out[24*103+:24]),
                $signed(O_data_out[24*104+:24]),$signed(O_data_out[24*105+:24]),
                $signed(O_data_out[24*106+:24]),$signed(O_data_out[24*107+:24]),
                $signed(O_data_out[24*108+:24]),$signed(O_data_out[24*109+:24]),
                $signed(O_data_out[24*110+:24]),$signed(O_data_out[24*111+:24]),
                $signed(O_data_out[24*112+:24]),$signed(O_data_out[24*113+:24]),
                $signed(O_data_out[24*114+:24]),$signed(O_data_out[24*115+:24]),
                $signed(O_data_out[24*116+:24]),$signed(O_data_out[24*117+:24]),
                $signed(O_data_out[24*118+:24]),$signed(O_data_out[24*119+:24]),
                $signed(O_data_out[24*120+:24]),$signed(O_data_out[24*121+:24]),
                $signed(O_data_out[24*122+:24]),$signed(O_data_out[24*123+:24]),
                $signed(O_data_out[24*124+:24]),$signed(O_data_out[24*125+:24]),
                $signed(O_data_out[24*126+:24]),$signed(O_data_out[24*127+:24]));  
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*128+:24]),$signed(S_o_data_d2[24*129+:24]),
                $signed(S_o_data_d2[24*130+:24]),$signed(S_o_data_d2[24*131+:24]),
                $signed(S_o_data_d2[24*132+:24]),$signed(S_o_data_d2[24*133+:24]),
                $signed(S_o_data_d2[24*134+:24]),$signed(S_o_data_d2[24*135+:24]),
                $signed(S_o_data_d2[24*136+:24]),$signed(S_o_data_d2[24*137+:24]),
                $signed(S_o_data_d2[24*138+:24]),$signed(S_o_data_d2[24*139+:24]),
                $signed(S_o_data_d2[24*140+:24]),$signed(S_o_data_d2[24*141+:24]),
                $signed(S_o_data_d2[24*142+:24]),$signed(S_o_data_d2[24*143+:24]),
                $signed(S_o_data_d2[24*144+:24]),$signed(S_o_data_d2[24*145+:24]),
                $signed(S_o_data_d2[24*146+:24]),$signed(S_o_data_d2[24*147+:24]),
                $signed(S_o_data_d2[24*148+:24]),$signed(S_o_data_d2[24*149+:24]),
                $signed(S_o_data_d2[24*150+:24]),$signed(S_o_data_d2[24*151+:24]),
                $signed(S_o_data_d2[24*152+:24]),$signed(S_o_data_d2[24*153+:24]),
                $signed(S_o_data_d2[24*154+:24]),$signed(S_o_data_d2[24*155+:24]),
                $signed(S_o_data_d2[24*156+:24]),$signed(S_o_data_d2[24*157+:24]),
                $signed(S_o_data_d2[24*158+:24]),$signed(S_o_data_d2[24*159+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*128+:24]),$signed(O_data_out[24*129+:24]),
                $signed(O_data_out[24*130+:24]),$signed(O_data_out[24*131+:24]),
                $signed(O_data_out[24*132+:24]),$signed(O_data_out[24*133+:24]),
                $signed(O_data_out[24*134+:24]),$signed(O_data_out[24*135+:24]),
                $signed(O_data_out[24*136+:24]),$signed(O_data_out[24*137+:24]),
                $signed(O_data_out[24*138+:24]),$signed(O_data_out[24*139+:24]),
                $signed(O_data_out[24*140+:24]),$signed(O_data_out[24*141+:24]),
                $signed(O_data_out[24*142+:24]),$signed(O_data_out[24*143+:24]),
                $signed(O_data_out[24*144+:24]),$signed(O_data_out[24*145+:24]),
                $signed(O_data_out[24*146+:24]),$signed(O_data_out[24*147+:24]),
                $signed(O_data_out[24*148+:24]),$signed(O_data_out[24*149+:24]),
                $signed(O_data_out[24*150+:24]),$signed(O_data_out[24*151+:24]),
                $signed(O_data_out[24*152+:24]),$signed(O_data_out[24*153+:24]),
                $signed(O_data_out[24*154+:24]),$signed(O_data_out[24*155+:24]),
                $signed(O_data_out[24*156+:24]),$signed(O_data_out[24*157+:24]),
                $signed(O_data_out[24*158+:24]),$signed(O_data_out[24*159+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*160+:24]),$signed(S_o_data_d2[24*161+:24]),
                $signed(S_o_data_d2[24*162+:24]),$signed(S_o_data_d2[24*163+:24]),
                $signed(S_o_data_d2[24*164+:24]),$signed(S_o_data_d2[24*165+:24]),
                $signed(S_o_data_d2[24*166+:24]),$signed(S_o_data_d2[24*167+:24]),
                $signed(S_o_data_d2[24*168+:24]),$signed(S_o_data_d2[24*169+:24]),
                $signed(S_o_data_d2[24*170+:24]),$signed(S_o_data_d2[24*171+:24]),
                $signed(S_o_data_d2[24*172+:24]),$signed(S_o_data_d2[24*173+:24]),
                $signed(S_o_data_d2[24*174+:24]),$signed(S_o_data_d2[24*175+:24]),
                $signed(S_o_data_d2[24*176+:24]),$signed(S_o_data_d2[24*177+:24]),
                $signed(S_o_data_d2[24*178+:24]),$signed(S_o_data_d2[24*179+:24]),
                $signed(S_o_data_d2[24*180+:24]),$signed(S_o_data_d2[24*181+:24]),
                $signed(S_o_data_d2[24*182+:24]),$signed(S_o_data_d2[24*183+:24]),
                $signed(S_o_data_d2[24*184+:24]),$signed(S_o_data_d2[24*185+:24]),
                $signed(S_o_data_d2[24*186+:24]),$signed(S_o_data_d2[24*187+:24]),
                $signed(S_o_data_d2[24*188+:24]),$signed(S_o_data_d2[24*189+:24]),
                $signed(S_o_data_d2[24*190+:24]),$signed(S_o_data_d2[24*191+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*160+:24]),$signed(O_data_out[24*161+:24]),
                $signed(O_data_out[24*162+:24]),$signed(O_data_out[24*163+:24]),
                $signed(O_data_out[24*164+:24]),$signed(O_data_out[24*165+:24]),
                $signed(O_data_out[24*166+:24]),$signed(O_data_out[24*167+:24]),
                $signed(O_data_out[24*168+:24]),$signed(O_data_out[24*169+:24]),
                $signed(O_data_out[24*170+:24]),$signed(O_data_out[24*171+:24]),
                $signed(O_data_out[24*172+:24]),$signed(O_data_out[24*173+:24]),
                $signed(O_data_out[24*174+:24]),$signed(O_data_out[24*175+:24]),
                $signed(O_data_out[24*176+:24]),$signed(O_data_out[24*177+:24]),
                $signed(O_data_out[24*178+:24]),$signed(O_data_out[24*179+:24]),
                $signed(O_data_out[24*180+:24]),$signed(O_data_out[24*181+:24]),
                $signed(O_data_out[24*182+:24]),$signed(O_data_out[24*183+:24]),
                $signed(O_data_out[24*184+:24]),$signed(O_data_out[24*185+:24]),
                $signed(O_data_out[24*186+:24]),$signed(O_data_out[24*187+:24]),
                $signed(O_data_out[24*188+:24]),$signed(O_data_out[24*189+:24]),
                $signed(O_data_out[24*190+:24]),$signed(O_data_out[24*191+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*192+:24]),$signed(S_o_data_d2[24*193+:24]),
                $signed(S_o_data_d2[24*194+:24]),$signed(S_o_data_d2[24*195+:24]),
                $signed(S_o_data_d2[24*196+:24]),$signed(S_o_data_d2[24*197+:24]),
                $signed(S_o_data_d2[24*198+:24]),$signed(S_o_data_d2[24*199+:24]),
                $signed(S_o_data_d2[24*200+:24]),$signed(S_o_data_d2[24*201+:24]),
                $signed(S_o_data_d2[24*202+:24]),$signed(S_o_data_d2[24*203+:24]),
                $signed(S_o_data_d2[24*204+:24]),$signed(S_o_data_d2[24*205+:24]),
                $signed(S_o_data_d2[24*206+:24]),$signed(S_o_data_d2[24*207+:24]),
                $signed(S_o_data_d2[24*208+:24]),$signed(S_o_data_d2[24*209+:24]),
                $signed(S_o_data_d2[24*210+:24]),$signed(S_o_data_d2[24*211+:24]),
                $signed(S_o_data_d2[24*212+:24]),$signed(S_o_data_d2[24*213+:24]),
                $signed(S_o_data_d2[24*214+:24]),$signed(S_o_data_d2[24*215+:24]),
                $signed(S_o_data_d2[24*216+:24]),$signed(S_o_data_d2[24*217+:24]),
                $signed(S_o_data_d2[24*218+:24]),$signed(S_o_data_d2[24*219+:24]),
                $signed(S_o_data_d2[24*220+:24]),$signed(S_o_data_d2[24*221+:24]),
                $signed(S_o_data_d2[24*222+:24]),$signed(S_o_data_d2[24*223+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*192+:24]),$signed(O_data_out[24*193+:24]),
                $signed(O_data_out[24*194+:24]),$signed(O_data_out[24*195+:24]),
                $signed(O_data_out[24*196+:24]),$signed(O_data_out[24*197+:24]),
                $signed(O_data_out[24*198+:24]),$signed(O_data_out[24*199+:24]),
                $signed(O_data_out[24*200+:24]),$signed(O_data_out[24*201+:24]),
                $signed(O_data_out[24*202+:24]),$signed(O_data_out[24*203+:24]),
                $signed(O_data_out[24*204+:24]),$signed(O_data_out[24*205+:24]),
                $signed(O_data_out[24*206+:24]),$signed(O_data_out[24*207+:24]),
                $signed(O_data_out[24*208+:24]),$signed(O_data_out[24*209+:24]),
                $signed(O_data_out[24*210+:24]),$signed(O_data_out[24*211+:24]),
                $signed(O_data_out[24*212+:24]),$signed(O_data_out[24*213+:24]),
                $signed(O_data_out[24*214+:24]),$signed(O_data_out[24*215+:24]),
                $signed(O_data_out[24*216+:24]),$signed(O_data_out[24*217+:24]),
                $signed(O_data_out[24*218+:24]),$signed(O_data_out[24*219+:24]),
                $signed(O_data_out[24*220+:24]),$signed(O_data_out[24*221+:24]),
                $signed(O_data_out[24*222+:24]),$signed(O_data_out[24*223+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                $signed(S_o_data_d2[24*224+:24]),$signed(S_o_data_d2[24*225+:24]),
                $signed(S_o_data_d2[24*226+:24]),$signed(S_o_data_d2[24*227+:24]),
                $signed(S_o_data_d2[24*228+:24]),$signed(S_o_data_d2[24*229+:24]),
                $signed(S_o_data_d2[24*230+:24]),$signed(S_o_data_d2[24*231+:24]),
                $signed(S_o_data_d2[24*232+:24]),$signed(S_o_data_d2[24*233+:24]),
                $signed(S_o_data_d2[24*234+:24]),$signed(S_o_data_d2[24*235+:24]),
                $signed(S_o_data_d2[24*236+:24]),$signed(S_o_data_d2[24*237+:24]),
                $signed(S_o_data_d2[24*238+:24]),$signed(S_o_data_d2[24*239+:24]),
                $signed(S_o_data_d2[24*240+:24]),$signed(S_o_data_d2[24*241+:24]),
                $signed(S_o_data_d2[24*242+:24]),$signed(S_o_data_d2[24*243+:24]),
                $signed(S_o_data_d2[24*244+:24]),$signed(S_o_data_d2[24*245+:24]),
                $signed(S_o_data_d2[24*246+:24]),$signed(S_o_data_d2[24*247+:24]),
                $signed(S_o_data_d2[24*248+:24]),$signed(S_o_data_d2[24*249+:24]),
                $signed(S_o_data_d2[24*250+:24]),$signed(S_o_data_d2[24*251+:24]),
                $signed(S_o_data_d2[24*252+:24]),$signed(S_o_data_d2[24*253+:24]),
                $signed(S_o_data_d2[24*254+:24]),$signed(S_o_data_d2[24*255+:24]));
                
        $fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
                $signed(O_data_out[24*224+:24]),$signed(O_data_out[24*225+:24]),
                $signed(O_data_out[24*226+:24]),$signed(O_data_out[24*227+:24]),
                $signed(O_data_out[24*228+:24]),$signed(O_data_out[24*229+:24]),
                $signed(O_data_out[24*230+:24]),$signed(O_data_out[24*231+:24]),
                $signed(O_data_out[24*232+:24]),$signed(O_data_out[24*233+:24]),
                $signed(O_data_out[24*234+:24]),$signed(O_data_out[24*235+:24]),
                $signed(O_data_out[24*236+:24]),$signed(O_data_out[24*237+:24]),
                $signed(O_data_out[24*238+:24]),$signed(O_data_out[24*239+:24]),
                $signed(O_data_out[24*240+:24]),$signed(O_data_out[24*241+:24]),
                $signed(O_data_out[24*242+:24]),$signed(O_data_out[24*243+:24]),
                $signed(O_data_out[24*244+:24]),$signed(O_data_out[24*245+:24]),
                $signed(O_data_out[24*246+:24]),$signed(O_data_out[24*247+:24]),
                $signed(O_data_out[24*248+:24]),$signed(O_data_out[24*249+:24]),
                $signed(O_data_out[24*250+:24]),$signed(O_data_out[24*251+:24]),
                $signed(O_data_out[24*252+:24]),$signed(O_data_out[24*253+:24]),
                $signed(O_data_out[24*254+:24]),$signed(O_data_out[24*255+:24]));
            end
        end
        end       
    */
endmodule
