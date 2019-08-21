`timescale 1ns / 1ps
/*
rd_fdepth = wog*KW*CIG + kx*CIG + cig
rd_wdepth = (k*CIG*COALIGN + cig*COALIGN + co)/32
where co = 0.32.0.32...
*/

module rd_addr_ctl#(
    parameter            AXIWIDTH    = 32,
    parameter            DEPTHWIDTH  = 9,
    parameter            CH_IN       = 16,
    parameter            CH_OUT      = 32,
    parameter            PIX         = 8,
    parameter            KWIDTH      = 4
)(
    input                         I_clk,
    input                         I_rst,
    input                         I_ap_start,
    input                         I_f_rdy,
    input                         I_weight_load_done,
    
    input       [AXIWIDTH-1:0]    I_ci_num,
    input       [AXIWIDTH-1:0]    I_co_num,
    input       [AXIWIDTH-1:0]    I_kx_num,
    input       [AXIWIDTH-1:0]    I_ky_num,
    input       [AXIWIDTH-1:0]    I_owidth_num,
    input       [DEPTHWIDTH:0]    I_hindex,
    input       [KWIDTH-1:0]      I_ky,
    input                         I_compute_en,
   
    input       [DEPTHWIDTH:0]    I_coAlign,
    input       [DEPTHWIDTH:0]    I_ciAlign,
    input       [DEPTHWIDTH-1:0]  I_woGroup,
    input       [DEPTHWIDTH-1:0]  I_coGroup,
    input       [DEPTHWIDTH-1:0]  I_ciGroup,
    
    output reg  [DEPTHWIDTH-1:0]  O_rd_wdepth = 0,
    output reg  [DEPTHWIDTH-1:0]  O_rd_fdepth = 0,
    output reg                    O_rd_dv = 0,
    output reg                    O_rd_new_en = 0
);

reg [2:0]   S_cnt_en=0;

localparam    C_CI_ALIGN_WIDTH  = GETASIZE(CH_IN);
localparam    C_CO_ALIGN_WIDTH  = GETASIZE(CH_OUT);

reg     [DEPTHWIDTH-1:0]    S_cig_cnt = 0;   
reg     [DEPTHWIDTH-1:0]    S_kx_cnt  = 0;    
reg     [DEPTHWIDTH-1:0]    S_cog_cnt = 0;
reg     [DEPTHWIDTH-1:0]    S_wog_cnt = 0;

reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp0 = 0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp1 = 0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2 = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp0 = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1 = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2 = 0;

wire    [DEPTHWIDTH-1:0]    S_fdepth_tmp0_true;
wire    [DEPTHWIDTH-1:0]    S_fdepth_tmp1_true;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp1_true_d0=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp1_true_d1=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp1_true_d2=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp1_true_d3=0; 
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true = 0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d0=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d1=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d2=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d3=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d4=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d5=0;
reg     [DEPTHWIDTH-1:0]    S_fdepth_tmp2_true_d6=0;
wire    [47:0]              S_ciAlignxcoAlign;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp0_true = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp0_true_d0=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp0_true_d1=0;

reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true_d0=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true_d1=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true_d2=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true_d3=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp1_true_d4=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true = 0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d0=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d1=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d2=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d3=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d4=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d5=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d6=0;
reg     [DEPTHWIDTH-1:0]    S_wdepth_tmp2_true_d7=0;

reg                         S_f_rdy_en    = 0;
reg     [1:0]               S_ap_start    = 0;
reg                         S_rd_start    = 0;
reg     [9:0]               S_rd_en       = 0;


always@ (posedge I_clk)
begin
    if (!S_ap_start[1] && S_ap_start[0])
        S_cnt_en <= 1'b0;
    else if (S_cnt_en=='d2)
        S_cnt_en <= 'd2;
    else if (O_rd_new_en)
        S_cnt_en <= S_cnt_en + 'd1;
end

always@ (posedge I_clk)
begin
    if (S_rd_start)
        S_f_rdy_en <= 1'b0;
    else if (I_f_rdy)
        S_f_rdy_en <= 1'b1;
end
    
wire   S_cig_flag;
wire   S_kx_flag;
wire   S_cog_flag;
wire   S_wog_flag;

assign    S_cig_flag = (S_cig_cnt==I_ciGroup-1) ? 1'b1 : 1'b0;
assign    S_kx_flag = (S_kx_cnt==I_kx_num-1) ? 1'b1 : 1'b0;
assign    S_cog_flag = (S_cog_cnt==I_coGroup-1) ? 1'b1 : 1'b0;
assign    S_wog_flag = (S_wog_cnt==I_woGroup-1) ? 1'b1 : 1'b0;

always@ (posedge I_clk)
begin
    S_ap_start <= {S_ap_start[1:0],I_ap_start};
    S_rd_start <= S_f_rdy_en && I_weight_load_done;
       
    if (S_cig_flag && S_kx_flag && S_cog_flag && S_wog_flag)
        S_rd_en[0] <= 1'b0;
    else if (~S_rd_start && S_f_rdy_en && I_weight_load_done && I_compute_en)
        S_rd_en[0] <= 1'b1;
end

always@ (posedge I_clk)
begin
    if (!I_compute_en)
        S_cig_cnt <= 'd0;
    else 
    if (!S_ap_start[1] && S_ap_start[0])
        S_cig_cnt <= 'd0;
    else if (S_cig_flag)
        S_cig_cnt <= 'd0;
    else if (S_rd_en[0])
        S_cig_cnt <= S_cig_cnt + 'd1;
        
    if (!I_compute_en)
        S_kx_cnt <= 'd0;
    else 
    if (!S_ap_start[1] && S_ap_start[0])
        S_kx_cnt <= 'd0;
    else if (S_cig_flag && S_kx_flag)
        S_kx_cnt <= 'd0;
    else if (S_rd_en[0] && S_cig_flag)
        S_kx_cnt <= S_kx_cnt + 'd1;
        
    if (!I_compute_en)
        S_cog_cnt <= 'd0;
    else 
    if (!S_ap_start[1] && S_ap_start[0])
        S_cog_cnt <= 'd0;
    else if (S_cig_flag && S_kx_flag && S_cog_flag)
        S_cog_cnt <= 'd0;
    else if (S_rd_en[0] && S_cig_flag && S_kx_flag)
        S_cog_cnt <= S_cog_cnt + 'd1;
        
    if (!I_compute_en)
        S_wog_cnt <= 'd0;
    else if (!S_ap_start[1] && S_ap_start[0])
        S_wog_cnt <= 'd0;
    else if (S_cig_flag && S_kx_flag && S_cog_flag && S_wog_flag)
        S_wog_cnt <= 'd0;
    else if (S_rd_en[0] && S_cig_flag && S_kx_flag && S_cog_flag)
        S_wog_cnt <= S_wog_cnt + 'd1;

end

wire  [47:0] S_fdepth_t0;
wire  [47:0] S_fdepth_t1;
wire  [47:0] S_fdepth_t2;
wire  [47:0] S_fdepth_t3;

dsp_unit1 dsp_unit_inst0(
    .I_clk              (I_clk),
    .I_weight_l         ({21'd0,S_wog_cnt}),
    .I_weight_h         (27'd0),
    .I_1feature         (I_kx_num),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_fdepth_t0)
    );
    
dsp_unit1 dsp_unit_inst1(
    .I_clk              (I_clk),
    .I_weight_l         (S_fdepth_t0),
    .I_weight_h         (27'd0),
    .I_1feature         (({16'd0,I_ciAlign}>>C_CI_ALIGN_WIDTH)),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_fdepth_tmp0_true)
    );
    
dsp_unit1 dsp_unit_inst2(
    .I_clk              (I_clk),
    .I_weight_l         ({21'd0,S_kx_cnt}),
    .I_weight_h         (27'd0),
    .I_1feature         (({16'd0,I_ciAlign}>>C_CI_ALIGN_WIDTH)),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_fdepth_tmp1_true)
    );

dsp_unit1 dsp_unit_inst3(
    .I_clk              (I_clk),
    .I_weight_l         ({20'd0,I_coAlign}),
    .I_weight_h         (27'd0),
    .I_1feature         (({16'd0,I_ciAlign}>>C_CI_ALIGN_WIDTH)),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_ciAlignxcoAlign)
    );


dsp_unit1 dsp_unit_inst4(
    .I_clk              (I_clk),
    .I_weight_l         (I_kx_num),
    .I_weight_h         (27'd0),
    .I_1feature         ({{14{I_ky[KWIDTH-1]}},I_ky}),
    .I_pi_cas           ({39'd0,S_kx_cnt}),
    .O_pi               (),
    .O_p                (S_fdepth_t1)
    );
    
dsp_unit1 dsp_unit_inst5(
    .I_clk              (I_clk),
    .I_weight_l         (S_fdepth_t1),
    .I_weight_h         (27'd0),
    .I_1feature         (S_ciAlignxcoAlign),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_fdepth_t2)
    );

dsp_unit1 dsp_unit_inst6(
    .I_clk              (I_clk),
    .I_weight_l         ({21'd0,S_cig_cnt}),
    .I_weight_h         (27'd0),
    .I_1feature         ({8'd0,I_coAlign}),
    .I_pi_cas           (48'd0),
    .O_pi               (),
    .O_p                (S_fdepth_t3)
    );


always@ (posedge I_clk)
begin
//    S_fdepth_tmp0_true <= S_wog_cnt*I_kx_num*(I_ciAlign>>C_CI_ALIGN_WIDTH);
//    S_fdepth_tmp1_true <= S_kx_cnt*(I_ciAlign>>C_CI_ALIGN_WIDTH);

    S_fdepth_tmp1_true_d0 <= S_fdepth_tmp1_true;
    S_fdepth_tmp1_true_d1 <= S_fdepth_tmp1_true_d0;
    S_fdepth_tmp1_true_d2 <= S_fdepth_tmp1_true_d1;
    S_fdepth_tmp1_true_d3 <= S_fdepth_tmp1_true_d2;

    S_fdepth_tmp2_true <= S_cig_cnt;
    S_fdepth_tmp2_true_d0 <= S_fdepth_tmp2_true;
    S_fdepth_tmp2_true_d1 <= S_fdepth_tmp2_true_d0;
    S_fdepth_tmp2_true_d2 <= S_fdepth_tmp2_true_d1;
    S_fdepth_tmp2_true_d3 <= S_fdepth_tmp2_true_d2;
    S_fdepth_tmp2_true_d4 <= S_fdepth_tmp2_true_d3;
    S_fdepth_tmp2_true_d5 <= S_fdepth_tmp2_true_d4;
    S_fdepth_tmp2_true_d6 <= S_fdepth_tmp2_true_d5;
    
//    S_ciAlignxcoAlign  <= (I_ciAlign>>C_CI_ALIGN_WIDTH)*I_coAlign;
    
    S_wdepth_tmp0_true <= S_fdepth_t2>>C_CO_ALIGN_WIDTH;
    S_wdepth_tmp0_true_d0 <= S_wdepth_tmp0_true;
    S_wdepth_tmp0_true_d1 <= S_wdepth_tmp0_true_d0;
    S_wdepth_tmp1_true <= S_fdepth_t3>>C_CO_ALIGN_WIDTH;
    S_wdepth_tmp1_true_d0 <= S_wdepth_tmp1_true;
    S_wdepth_tmp1_true_d1 <= S_wdepth_tmp1_true_d0;
    S_wdepth_tmp1_true_d2 <= S_wdepth_tmp1_true_d1;
    S_wdepth_tmp1_true_d3 <= S_wdepth_tmp1_true_d2;
    S_wdepth_tmp1_true_d4 <= S_wdepth_tmp1_true_d3;
    S_wdepth_tmp2_true <= S_cog_cnt;
    S_wdepth_tmp2_true_d0 <= S_wdepth_tmp2_true;
    S_wdepth_tmp2_true_d1 <= S_wdepth_tmp2_true_d0;
    S_wdepth_tmp2_true_d2 <= S_wdepth_tmp2_true_d1;
    S_wdepth_tmp2_true_d3 <= S_wdepth_tmp2_true_d2;
    S_wdepth_tmp2_true_d4 <= S_wdepth_tmp2_true_d3;
    S_wdepth_tmp2_true_d5 <= S_wdepth_tmp2_true_d4;
    S_wdepth_tmp2_true_d6 <= S_wdepth_tmp2_true_d5;
    S_wdepth_tmp2_true_d7 <= S_wdepth_tmp2_true_d6;
end

always@ (posedge I_clk)
begin
    S_fdepth_tmp0 <= S_rd_en[9] ? S_fdepth_tmp0_true : 'd0;
    S_fdepth_tmp1 <= S_rd_en[9] ? S_fdepth_tmp1_true_d3 : 'd0;
    S_fdepth_tmp2 <= S_rd_en[9] ? S_fdepth_tmp2_true_d5 : 'd0;
    O_rd_fdepth <= S_fdepth_tmp0 + S_fdepth_tmp1 + S_fdepth_tmp2;

    S_wdepth_tmp0 <= S_rd_en[8] ? S_wdepth_tmp0_true_d0 : 'd0;
    S_wdepth_tmp1 <= S_rd_en[8] ? S_wdepth_tmp1_true_d3 : 'd0;
    S_wdepth_tmp2 <= S_rd_en[8] ? S_wdepth_tmp2_true_d6 : 'd0;
    O_rd_wdepth <= S_wdepth_tmp0+ S_wdepth_tmp1+ S_wdepth_tmp2;
end

always@ (posedge I_clk)
begin
    S_rd_en[1] <= S_rd_en[0];
    S_rd_en[2] <= S_rd_en[1];
    S_rd_en[3] <= S_rd_en[2];
    S_rd_en[4] <= S_rd_en[3];
    S_rd_en[5] <= S_rd_en[4];
    S_rd_en[6] <= S_rd_en[5];
    S_rd_en[7] <= S_rd_en[6];
    S_rd_en[8] <= S_rd_en[7];
    S_rd_en[9] <= S_rd_en[8];
    O_rd_dv <= S_rd_en[9];
end

always@ (posedge I_clk)
begin
    if (!S_ap_start[1] && S_ap_start[0])
        O_rd_new_en <= 'd0;
    else if (S_cnt_en=='d2 || S_cnt_en=='d1)
        O_rd_new_en <= 'd0;
    else if (S_cig_flag && S_kx_flag && S_cog_flag && S_wog_flag)
        O_rd_new_en <= 'd1;
    else
        O_rd_new_en <= 'd0;

end
    
function integer GETASIZE;
input integer a;
integer i;
begin
    for(i=1;(2**i)<a;i=i+1)
      begin
      end
    GETASIZE = i;
end
endfunction

endmodule
