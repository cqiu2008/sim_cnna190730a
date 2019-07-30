`timescale 1ns / 1ps

module ComputeMA#(
    parameter CH_IN     = 16,
    parameter DWIDTH    = 8,
    parameter CH_OUT    = 32,
    parameter PIX       = 8,
    parameter ADD_WIDTH = 19
)(
    input                                      I_clk,
    input        [CH_IN*PIX*DWIDTH-1:0]        I_feature,
    input        [CH_OUT*CH_IN*DWIDTH-1:0]     I_weight,
    input                                      I_cpt_dv,
    output       [24*CH_OUT*PIX-1:0]           O_data,
    output reg                                 O_data_dv=1
    );


reg  [DWIDTH*CH_IN*PIX-1:0]                       S_feature [CH_IN-2:0];//5 batch data
reg  [DWIDTH*CH_IN*CH_OUT-1:0]                    S_weight [CH_IN-1:0];
//wire [24*CH_IN*CH_OUT*PIX-1:0]                    S_p;
//wire [24*CH_OUT*PIX-1:0]                          S_p;
//wire [24*CH_OUT*PIX-1:0]                          S_pi_result;//(chout*pix*48)/2
reg  [17:0]                                       S_data_dv = 0;

always@ (posedge I_clk)
begin
    S_weight[0] <= I_weight;
    S_weight[1] <= S_weight[0];
    S_weight[2] <= S_weight[1];
    S_weight[3] <= S_weight[2];
    S_weight[4] <= S_weight[3];
    S_weight[5] <= S_weight[4];
    S_weight[6] <= S_weight[5];
    S_weight[7] <= S_weight[6];
    S_weight[8] <= S_weight[7];
    S_weight[9] <= S_weight[8];
    S_weight[10] <= S_weight[9];
    S_weight[11] <= S_weight[10];
    S_weight[12] <= S_weight[11];
    S_weight[13] <= S_weight[12];
    S_weight[14] <= S_weight[13];
    S_weight[15] <= S_weight[14];
end

always@ (posedge I_clk)
begin
    S_feature[0] <= I_cpt_dv ? I_feature : 'd0;
    S_feature[1] <= S_feature[0];
    S_feature[2] <= S_feature[1];
    S_feature[3] <= S_feature[2];
    S_feature[4] <= S_feature[3];
    S_feature[5] <= S_feature[4];
    S_feature[6] <= S_feature[5];
    S_feature[7] <= S_feature[6];
    S_feature[8] <= S_feature[7];
    S_feature[9] <= S_feature[8];
    S_feature[10] <= S_feature[9];
    S_feature[11] <= S_feature[10];
    S_feature[12] <= S_feature[11];
    S_feature[13] <= S_feature[12];
    S_feature[14] <= S_feature[13];
end
    
genvar gen_i,gen_j;
generate for(gen_i=0; gen_i<PIX; gen_i=gen_i+1)
begin:outer_loop

    for (gen_j=0; gen_j<CH_IN; gen_j= gen_j+1)
    begin:inner_loop
    
wire [48*(CH_IN+1)-1:0]    S_p;
wire [48*(CH_IN+1)-1:0]    S_pi;//[47:0][47:0][47:0][47:0][47:0]
assign S_p[47:0] = 48'd0;
assign S_pi[47:0] = 48'd0;

dsp_unit0 inst_dsp_unit0(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){I_weight[(0*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},I_weight[(0*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[0][(0*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){I_feature[gen_i*128+0*DWIDTH+DWIDTH-1]}},I_feature[gen_i*128+0*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*0+:48]),
    .O_pi        (S_pi[48*(1+0)+:48]),
    .O_p         (S_p[48*(1+0)+:48])
);
    
dsp_unit inst_dsp_unit1(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[0][(2*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[0][(2*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[1][(2*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[0][gen_i*128+1*DWIDTH+DWIDTH-1]}},S_feature[0][gen_i*128+1*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*1+:48]),
    .O_pi        (S_pi[48*(1+1)+:48]),
    .O_p         (S_p[48*(1+1)+:48])
);

dsp_unit inst_dsp_unit2(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[1][(4*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[1][(4*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[2][(4*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[1][gen_i*128+2*DWIDTH+DWIDTH-1]}},S_feature[1][gen_i*128+2*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*2+:48]),
    .O_pi        (S_pi[48*(1+2)+:48]),
    .O_p         (S_p[48*(1+2)+:48])
);

dsp_unit inst_dsp_unit3(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[2][(6*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[2][(6*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[3][(6*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[2][gen_i*128+3*DWIDTH+DWIDTH-1]}},S_feature[2][gen_i*128+3*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*3+:48]),
    .O_pi        (S_pi[48*(1+3)+:48]),
    .O_p         (S_p[48*(1+3)+:48])
);

dsp_unit inst_dsp_unit4(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[3][(8*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[3][(8*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[4][(8*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[3][gen_i*128+4*DWIDTH+DWIDTH-1]}},S_feature[3][gen_i*128+4*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*4+:48]),
    .O_pi        (S_pi[48*(1+4)+:48]),
    .O_p         (S_p[48*(1+4)+:48])
);

dsp_unit inst_dsp_unit5(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[4][(10*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[4][(10*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[5][(10*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[4][gen_i*128+5*DWIDTH+DWIDTH-1]}},S_feature[4][gen_i*128+5*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*5+:48]),
    .O_pi        (S_pi[48*(1+5)+:48]),
    .O_p         (S_p[48*(1+5)+:48])
);

dsp_unit inst_dsp_unit6(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[5][(12*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[5][(12*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[6][(12*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[5][gen_i*128+6*DWIDTH+DWIDTH-1]}},S_feature[5][gen_i*128+6*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*6+:48]),
    .O_pi        (S_pi[48*(1+6)+:48]),
    .O_p         (S_p[48*(1+6)+:48])
);

dsp_unit inst_dsp_unit7(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[6][(14*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[6][(14*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[7][(14*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[6][gen_i*128+7*DWIDTH+DWIDTH-1]}},S_feature[6][gen_i*128+7*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*7+:48]),
    .O_pi        (S_pi[48*(1+7)+:48]),
    .O_p         (S_p[48*(1+7)+:48])
);

dsp_unit inst_dsp_unit8(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[7][(16*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[7][(16*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[8][(16*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[7][gen_i*128+8*DWIDTH+DWIDTH-1]}},S_feature[7][gen_i*128+8*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*8+:48]),
    .O_pi        (S_pi[48*(1+8)+:48]),
    .O_p         (S_p[48*(1+8)+:48])
);

dsp_unit inst_dsp_unit9(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[8][(18*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[8][(18*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[9][(18*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[8][gen_i*128+9*DWIDTH+DWIDTH-1]}},S_feature[8][gen_i*128+9*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*9+:48]),
    .O_pi        (S_pi[48*(1+9)+:48]),
    .O_p         (S_p[48*(1+9)+:48])
);

dsp_unit inst_dsp_unit10(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[9][(20*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[9][(20*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[10][(20*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[9][gen_i*128+10*DWIDTH+DWIDTH-1]}},S_feature[9][gen_i*128+10*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*10+:48]),
    .O_pi        (S_pi[48*(1+10)+:48]),
    .O_p         (S_p[48*(1+10)+:48])
);

dsp_unit inst_dsp_unit11(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[10][(22*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[10][(22*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[11][(22*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[10][gen_i*128+11*DWIDTH+DWIDTH-1]}},S_feature[10][gen_i*128+11*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*11+:48]),
    .O_pi        (S_pi[48*(1+11)+:48]),
    .O_p         (S_p[48*(1+11)+:48])
);

dsp_unit inst_dsp_unit12(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[11][(24*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[11][(24*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[12][(24*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[11][gen_i*128+12*DWIDTH+DWIDTH-1]}},S_feature[11][gen_i*128+12*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*12+:48]),
    .O_pi        (S_pi[48*(1+12)+:48]),
    .O_p         (S_p[48*(1+12)+:48])
);

dsp_unit inst_dsp_unit13(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[12][(26*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[12][(26*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[13][(26*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[12][gen_i*128+13*DWIDTH+DWIDTH-1]}},S_feature[12][gen_i*128+13*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*13+:48]),
    .O_pi        (S_pi[48*(1+13)+:48]),
    .O_p         (S_p[48*(1+13)+:48])
);

dsp_unit inst_dsp_unit14(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[13][(28*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[13][(28*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[14][(28*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[13][gen_i*128+14*DWIDTH+DWIDTH-1]}},S_feature[13][gen_i*128+14*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*14+:48]),
    .O_pi        (S_pi[48*(1+14)+:48]),
    .O_p         (S_p[48*(1+14)+:48])
);

dsp_unit inst_dsp_unit15(
    .I_clk       (I_clk),
    .I_weight_l  ({{(22){S_weight[14][(30*CH_IN*DWIDTH+2*DWIDTH*gen_j)+DWIDTH-1]}},S_weight[14][(30*CH_IN*DWIDTH+2*DWIDTH*gen_j)+:DWIDTH]}),
    .I_weight_h  ({S_weight[15][(30*CH_IN*DWIDTH+2*DWIDTH*gen_j+DWIDTH)+:DWIDTH],19'b000_0000_0000_0000_0000}),
    .I_1feature  ({{(10){S_feature[14][gen_i*128+15*DWIDTH+DWIDTH-1]}},S_feature[14][gen_i*128+15*DWIDTH+:DWIDTH]}),//18-bit
    .I_pi_cas    (S_pi[48*15+:48]),
    .O_pi        (S_pi[48*(1+15)+:48]),
    .O_p         (S_p[48*(1+15)+:48])
);

//assign O_data[gen_i*16*48+gen_j*48+:48] = S_pi[48*(1+15)+18] ? S_pi[48*(1+15)+:48]+20'b1_000_0000_0000_0000_0000 : S_pi[48*(1+15)+:48];
assign O_data[gen_i*16*48+gen_j*48+:48] = S_p[48*(1+15)+18] ? S_p[48*(1+15)+:48]+20'b1_000_0000_0000_0000_0000 : S_p[48*(1+15)+:48];

    end//inner loop
end
endgenerate

always@ (posedge I_clk)
begin
    S_data_dv <= {S_data_dv[17:0],I_cpt_dv};
    O_data_dv <= S_data_dv[17];
end

endmodule

