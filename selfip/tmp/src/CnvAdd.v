`timescale 1ns / 1ps

module CnvAdd#(
    parameter           CH_IN       = 16,
    parameter           CH_OUT      = 32,
    parameter           PIX         = 8,
    parameter           KWIDTH      = 4,
    parameter           DEPTHWIDTH  = 9,
    parameter           PWIDTH      = 2
)(
    input                           I_clk,
    input                           I_rst,
    
    input      [KWIDTH-1:0]         I_kx,
    input      [KWIDTH-1:0]         I_ky,
    input      [PWIDTH-1:0]         I_pad,
    input                           I_compute_en,
    input                           I_line_end,
    input      [DEPTHWIDTH-1:0]     I_coGroup,
    input      [DEPTHWIDTH-1:0]     I_woGroup,
    input      [24*CH_OUT*PIX-1:0]  I_result_tmp,
    input                           I_result_dv,
    
    output reg                      O_line_end_flag=0,
    output                          O_kx_end_flag,
    output     [24*CH_OUT*PIX-1:0]  O_result_0,
    output     [24*CH_OUT*PIX-1:0]  O_result_1,
    output reg                      O_data_dv=0,
    output reg [24*CH_OUT*PIX-1:0]  O_macc_data
    );

reg                       S_result_dv    =0;  
reg                       S_result_dv_d1 =0;
reg                       S_result_dv_d2 =0;
reg                       S_result_dv_d3 =0;
reg  [KWIDTH-1:0]         S_cnt_k        =0;
reg  [KWIDTH-1:0]         S_cnt_k_d1     =0;
reg  [KWIDTH-1:0]         S_cnt_k_d2     =0;
reg  [DEPTHWIDTH-1:0]     S_cog_cnt      =0;
reg  [DEPTHWIDTH-1:0]     S_cog_cnt_d1   =0;
reg  [DEPTHWIDTH-1:0]     S_wog_cnt      =0;
wire [DEPTHWIDTH-1:0]     S_obuf_depth;
reg  [DEPTHWIDTH-1:0]     S_obuf_depth_d1=0;

reg  [24*CH_OUT*PIX-1:0]  S_result_kx;
reg                       S_compute_en   =0;
reg                       S_1st_add_en   =0;

reg S_data_dv=0;
always@ (posedge I_clk)
begin
    S_data_dv <= O_data_dv;
end

always@ (posedge I_clk)
begin
    S_compute_en <= I_compute_en;
    if (O_line_end_flag)
        S_1st_add_en <= 1'b0;
    else if (!S_compute_en && I_compute_en)
        S_1st_add_en <= 1'b1;
    else if (I_line_end)
        S_1st_add_en <= 1'b1;
end


//for TB, print-out, every kx-direct add result
assign O_result_0 = (S_cnt_k_d2==I_kx-1 && S_cog_cnt_d1=='d1) ? S_result_kx : O_result_0;
assign O_result_1 = (S_cnt_k_d2==I_kx-1 && S_cog_cnt_d1=='d0) ? S_result_kx : O_result_1;

always@ (posedge I_clk)
begin
    if (S_cnt_k_d2==I_kx-1 && S_cog_cnt_d1=='d1)
        O_macc_data <= S_result_kx;
    else if (S_cnt_k_d2==I_kx-1 && S_cog_cnt_d1=='d0)
        O_macc_data <= S_result_kx;
end 


assign S_obuf_depth = S_wog_cnt * I_coGroup + S_cog_cnt;
always@ (posedge I_clk)
begin
    S_obuf_depth_d1 <= S_obuf_depth;
end

always@ (posedge I_clk)
begin
    S_result_dv <= I_result_dv;
    S_result_dv_d1 <= S_result_dv;
    S_result_dv_d2 <= S_result_dv_d1;
    S_result_dv_d3 <= S_result_dv_d2;
    
    S_cnt_k_d1 <= S_cnt_k;
    S_cnt_k_d2 <= S_cnt_k_d1;
    
    if (~S_result_dv && I_result_dv)
        S_cnt_k <= 'd0;
    else if (I_result_dv && S_cnt_k==I_kx-1)
        S_cnt_k <= 'd0;
    else if (I_result_dv)
        S_cnt_k <= S_cnt_k + 'd1;
        
    S_cog_cnt_d1 <= S_cog_cnt;
        
    if (~S_result_dv && I_result_dv)
        S_cog_cnt <= 'd0;
    else if (S_cnt_k==I_kx-1 && S_cog_cnt==I_coGroup-1)
        S_cog_cnt <= 'd0;
    else if (S_cnt_k==I_kx-1 && I_result_dv)
        S_cog_cnt <= S_cog_cnt + 'd1;
        
        
    if (~S_result_dv && I_result_dv)
        S_wog_cnt <= 'd0;
    else if (S_cnt_k==I_kx-1 && S_cog_cnt==I_coGroup-1 && I_result_dv)
        S_wog_cnt <= S_wog_cnt + 'd1;
end
    
    
always@ (posedge I_clk)
begin
    if (S_wog_cnt == I_woGroup-1 && S_cog_cnt==I_coGroup-1 && S_cnt_k==I_kx-1)
        O_line_end_flag <= 1'b1;
    else
        O_line_end_flag <= 1'b0;
end

genvar gen_i,gen_j;
generate for (gen_i=0; gen_i<PIX; gen_i=gen_i+1)
begin:outer_loop
    for (gen_j=0; gen_j<CH_IN; gen_j=gen_j+1)
    begin:inner_loop

    reg [47:0]    S_add = 0;
    (*ram_style="block"*) reg [47:0]    S_obuf_test [511:0];
    
    wire [47:0]    S_result_tmp_test;
    assign S_result_tmp_test[23:0]= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
    assign S_result_tmp_test[47:24]=  {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
    
    always@ (posedge I_clk)
    begin
        if (I_result_dv)begin
            if (S_cnt_k==I_kx-1) 
            begin
                S_add[23:0] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
                S_add[47:24] <= {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
            end
            else 
            begin
                S_add[23:0] <= S_add[23:0] + {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+:19]};
                S_add[47:24] <= S_add[47:24] + {{(5){I_result_tmp[gen_i*16*48+gen_j*48+19+19-1]}},I_result_tmp[gen_i*16*48+gen_j*48+19+:19]};
            end
        end
    end
    
    
//    always@ (posedge I_clk)
//    begin
//        if (S_result_dv) begin
//            if (I_ky==1 && S_cnt_k==I_kx-1)
//                S_obuf_test[S_obuf_depth] <= S_add;
//            else if (S_cnt_k==I_kx-1) begin
//                S_obuf_test[S_obuf_depth][23:0] <= S_add[23:0] + S_obuf_test[S_obuf_depth][23:0];
//                S_obuf_test[S_obuf_depth][47:24]<= S_add[47:24] + S_obuf_test[S_obuf_depth][47:24];
//            end
//        end
//    end 
    
//    always@ (posedge I_clk)
//    begin
//        if (S_result_dv_d1 && S_cnt_k_d1==I_kx-1)
//            S_result_kx[gen_i*16*48+gen_j*48+:48] <= S_obuf_test[S_obuf_depth_d1];
//    end  
    
    //---------------------------------------------------------------------------------------------------
    //                                          use bram for obuf
    //--------------------------------------------------------------------------------------------------- 
    
    wire [23:0]  tmp_data0;
    wire [23:0]  tmp_data1;
    
    assign tmp_data0 = S_add[23:0];
    assign tmp_data1 = S_add[47:24];
    
    wire         rd_en;
    wire         wr_en;
    reg  [47:0]  dout_reg;
    wire [DEPTHWIDTH-1:0]     rd_addr;
    wire [DEPTHWIDTH-1:0]     wr_addr;
    wire [47:0]  data_in;
    assign rd_en = (S_cnt_k==I_kx-2) && S_result_dv;
    assign rd_addr = S_obuf_depth;
    
    assign wr_en = S_result_dv && (S_cnt_k==I_kx-1);
    assign wr_addr = S_obuf_depth;
    
    always@ (posedge I_clk)
    begin
        if (rd_en)
        begin
            if (/*I_ky>I_pad*/!S_1st_add_en)
                dout_reg <= S_obuf_test[rd_addr];
        end
    end
    
    assign data_in[23:0] = S_add[23:0] + dout_reg[23:0];
    assign data_in[47:24]= S_add[47:24] + dout_reg[47:24];
    
    always@ (posedge I_clk)
    begin
        if (wr_en)
            if (/*I_ky==I_pad*/S_1st_add_en)
                S_obuf_test[wr_addr] <= S_add;
            else
                S_obuf_test[wr_addr] <= data_in;
    end
    
    always@ (posedge I_clk)
    begin
        if (S_result_dv_d3 && S_cnt_k_d1==I_kx-1)
            S_result_kx[gen_i*16*48+gen_j*48+:48] <= S_obuf_test[S_obuf_depth_d1];
    end 
    
    end//innerloop
end
endgenerate 


always@ (posedge I_clk)
begin
    if (S_result_dv_d3 && S_cnt_k_d1==I_kx-1)
        O_data_dv <= 1'b1;
    else
        O_data_dv <= 1'b0;
end   


reg outflag=0;
always@ (posedge I_clk)
begin
    if (!S_result_dv && I_result_dv)
        outflag <= 1'b0;
    else if (O_data_dv)
        outflag <= outflag + 1'b1;
end

assign O_kx_end_flag = (I_ky==I_kx-1) ? 1'b0 : O_line_end_flag;


integer line2;

initial begin
line2 = $fopen("line2_dataOut.txt","w");
#9425
forever 
@(posedge I_clk)
begin
    if (O_data_dv && !S_data_dv && outflag)
    begin
    
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
         $signed(O_result_0[24*0+:24]),$signed(O_result_0[24*1+:24]),
         $signed(O_result_0[24*2+:24]),$signed(O_result_0[24*3+:24]),
         $signed(O_result_0[24*4+:24]),$signed(O_result_0[24*5+:24]),
         $signed(O_result_0[24*6+:24]),$signed(O_result_0[24*7+:24]),
         $signed(O_result_0[24*8+:24]),$signed(O_result_0[24*9+:24]),
         $signed(O_result_0[24*10+:24]),$signed(O_result_0[24*11+:24]),
         $signed(O_result_0[24*12+:24]),$signed(O_result_0[24*13+:24]),
         $signed(O_result_0[24*14+:24]),$signed(O_result_0[24*15+:24]),
         $signed(O_result_0[24*16+:24]),$signed(O_result_0[24*17+:24]),
         $signed(O_result_0[24*18+:24]),$signed(O_result_0[24*19+:24]),
         $signed(O_result_0[24*20+:24]),$signed(O_result_0[24*21+:24]),
         $signed(O_result_0[24*22+:24]),$signed(O_result_0[24*23+:24]),
         $signed(O_result_0[24*24+:24]),$signed(O_result_0[24*25+:24]),
         $signed(O_result_0[24*26+:24]),$signed(O_result_0[24*27+:24]),
         $signed(O_result_0[24*28+:24]),$signed(O_result_0[24*29+:24]),
         $signed(O_result_0[24*30+:24]),$signed(O_result_0[24*31+:24]));   

$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
         $signed(O_result_1[24*0+:24]),$signed(O_result_1[24*1+:24]),
         $signed(O_result_1[24*2+:24]),$signed(O_result_1[24*3+:24]),
         $signed(O_result_1[24*4+:24]),$signed(O_result_1[24*5+:24]),
         $signed(O_result_1[24*6+:24]),$signed(O_result_1[24*7+:24]),
         $signed(O_result_1[24*8+:24]),$signed(O_result_1[24*9+:24]),
         $signed(O_result_1[24*10+:24]),$signed(O_result_1[24*11+:24]),
         $signed(O_result_1[24*12+:24]),$signed(O_result_1[24*13+:24]),
         $signed(O_result_1[24*14+:24]),$signed(O_result_1[24*15+:24]),
         $signed(O_result_1[24*16+:24]),$signed(O_result_1[24*17+:24]),
         $signed(O_result_1[24*18+:24]),$signed(O_result_1[24*19+:24]),
         $signed(O_result_1[24*20+:24]),$signed(O_result_1[24*21+:24]),
         $signed(O_result_1[24*22+:24]),$signed(O_result_1[24*23+:24]),
         $signed(O_result_1[24*24+:24]),$signed(O_result_1[24*25+:24]),
         $signed(O_result_1[24*26+:24]),$signed(O_result_1[24*27+:24]),
         $signed(O_result_1[24*28+:24]),$signed(O_result_1[24*29+:24]),
         $signed(O_result_1[24*30+:24]),$signed(O_result_1[24*31+:24]));	    

$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
         $signed(O_result_0[24*32+:24]),$signed(O_result_0[24*33+:24]),
         $signed(O_result_0[24*34+:24]),$signed(O_result_0[24*35+:24]),
         $signed(O_result_0[24*36+:24]),$signed(O_result_0[24*37+:24]),
         $signed(O_result_0[24*38+:24]),$signed(O_result_0[24*39+:24]),
         $signed(O_result_0[24*40+:24]),$signed(O_result_0[24*41+:24]),
         $signed(O_result_0[24*42+:24]),$signed(O_result_0[24*43+:24]),
         $signed(O_result_0[24*44+:24]),$signed(O_result_0[24*45+:24]),
         $signed(O_result_0[24*46+:24]),$signed(O_result_0[24*47+:24]),
         $signed(O_result_0[24*48+:24]),$signed(O_result_0[24*49+:24]),
         $signed(O_result_0[24*50+:24]),$signed(O_result_0[24*51+:24]),
         $signed(O_result_0[24*52+:24]),$signed(O_result_0[24*53+:24]),
         $signed(O_result_0[24*54+:24]),$signed(O_result_0[24*55+:24]),
         $signed(O_result_0[24*56+:24]),$signed(O_result_0[24*57+:24]),
         $signed(O_result_0[24*58+:24]),$signed(O_result_0[24*59+:24]),
         $signed(O_result_0[24*60+:24]),$signed(O_result_0[24*61+:24]),
         $signed(O_result_0[24*62+:24]),$signed(O_result_0[24*63+:24]));
    
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
         $signed(O_result_1[24*32+:24]),$signed(O_result_1[24*33+:24]),
         $signed(O_result_1[24*34+:24]),$signed(O_result_1[24*35+:24]),
         $signed(O_result_1[24*36+:24]),$signed(O_result_1[24*37+:24]),
         $signed(O_result_1[24*38+:24]),$signed(O_result_1[24*39+:24]),
         $signed(O_result_1[24*40+:24]),$signed(O_result_1[24*41+:24]),
         $signed(O_result_1[24*42+:24]),$signed(O_result_1[24*43+:24]),
         $signed(O_result_1[24*44+:24]),$signed(O_result_1[24*45+:24]),
         $signed(O_result_1[24*46+:24]),$signed(O_result_1[24*47+:24]),
         $signed(O_result_1[24*48+:24]),$signed(O_result_1[24*49+:24]),
         $signed(O_result_1[24*50+:24]),$signed(O_result_1[24*51+:24]),
         $signed(O_result_1[24*52+:24]),$signed(O_result_1[24*53+:24]),
         $signed(O_result_1[24*54+:24]),$signed(O_result_1[24*55+:24]),
         $signed(O_result_1[24*56+:24]),$signed(O_result_1[24*57+:24]),
         $signed(O_result_1[24*58+:24]),$signed(O_result_1[24*59+:24]),
         $signed(O_result_1[24*60+:24]),$signed(O_result_1[24*61+:24]),
         $signed(O_result_1[24*62+:24]),$signed(O_result_1[24*63+:24]));  
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*64+:24]),$signed(O_result_0[24*65+:24]),
        $signed(O_result_0[24*66+:24]),$signed(O_result_0[24*67+:24]),
        $signed(O_result_0[24*68+:24]),$signed(O_result_0[24*69+:24]),
        $signed(O_result_0[24*70+:24]),$signed(O_result_0[24*71+:24]),
        $signed(O_result_0[24*72+:24]),$signed(O_result_0[24*73+:24]),
        $signed(O_result_0[24*74+:24]),$signed(O_result_0[24*75+:24]),
        $signed(O_result_0[24*76+:24]),$signed(O_result_0[24*77+:24]),
        $signed(O_result_0[24*78+:24]),$signed(O_result_0[24*79+:24]),
        $signed(O_result_0[24*80+:24]),$signed(O_result_0[24*81+:24]),
        $signed(O_result_0[24*82+:24]),$signed(O_result_0[24*83+:24]),
        $signed(O_result_0[24*84+:24]),$signed(O_result_0[24*85+:24]),
        $signed(O_result_0[24*86+:24]),$signed(O_result_0[24*87+:24]),
        $signed(O_result_0[24*88+:24]),$signed(O_result_0[24*89+:24]),
        $signed(O_result_0[24*90+:24]),$signed(O_result_0[24*91+:24]),
        $signed(O_result_0[24*92+:24]),$signed(O_result_0[24*93+:24]),
        $signed(O_result_0[24*94+:24]),$signed(O_result_0[24*95+:24]));

$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*64+:24]),$signed(O_result_1[24*65+:24]),
        $signed(O_result_1[24*66+:24]),$signed(O_result_1[24*67+:24]),
        $signed(O_result_1[24*68+:24]),$signed(O_result_1[24*69+:24]),
        $signed(O_result_1[24*70+:24]),$signed(O_result_1[24*71+:24]),
        $signed(O_result_1[24*72+:24]),$signed(O_result_1[24*73+:24]),
        $signed(O_result_1[24*74+:24]),$signed(O_result_1[24*75+:24]),
        $signed(O_result_1[24*76+:24]),$signed(O_result_1[24*77+:24]),
        $signed(O_result_1[24*78+:24]),$signed(O_result_1[24*79+:24]),
        $signed(O_result_1[24*80+:24]),$signed(O_result_1[24*81+:24]),
        $signed(O_result_1[24*82+:24]),$signed(O_result_1[24*83+:24]),
        $signed(O_result_1[24*84+:24]),$signed(O_result_1[24*85+:24]),
        $signed(O_result_1[24*86+:24]),$signed(O_result_1[24*87+:24]),
        $signed(O_result_1[24*88+:24]),$signed(O_result_1[24*89+:24]),
        $signed(O_result_1[24*90+:24]),$signed(O_result_1[24*91+:24]),
        $signed(O_result_1[24*92+:24]),$signed(O_result_1[24*93+:24]),
        $signed(O_result_1[24*94+:24]),$signed(O_result_1[24*95+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*96+:24]), $signed(O_result_0[24*97+:24]),
        $signed(O_result_0[24*98+:24]), $signed(O_result_0[24*99+:24]),
        $signed(O_result_0[24*100+:24]),$signed(O_result_0[24*101+:24]),
        $signed(O_result_0[24*102+:24]),$signed(O_result_0[24*103+:24]),
        $signed(O_result_0[24*104+:24]),$signed(O_result_0[24*105+:24]),
        $signed(O_result_0[24*106+:24]),$signed(O_result_0[24*107+:24]),
        $signed(O_result_0[24*108+:24]),$signed(O_result_0[24*109+:24]),
        $signed(O_result_0[24*110+:24]),$signed(O_result_0[24*111+:24]),
        $signed(O_result_0[24*112+:24]),$signed(O_result_0[24*113+:24]),
        $signed(O_result_0[24*114+:24]),$signed(O_result_0[24*115+:24]),
        $signed(O_result_0[24*116+:24]),$signed(O_result_0[24*117+:24]),
        $signed(O_result_0[24*118+:24]),$signed(O_result_0[24*119+:24]),
        $signed(O_result_0[24*120+:24]),$signed(O_result_0[24*121+:24]),
        $signed(O_result_0[24*122+:24]),$signed(O_result_0[24*123+:24]),
        $signed(O_result_0[24*124+:24]),$signed(O_result_0[24*125+:24]),
        $signed(O_result_0[24*126+:24]),$signed(O_result_0[24*127+:24])); 

$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*96+:24]),$signed(O_result_1[24*97+:24]),
        $signed(O_result_1[24*98+:24]),$signed(O_result_1[24*99+:24]),
        $signed(O_result_1[24*100+:24]),$signed(O_result_1[24*101+:24]),
        $signed(O_result_1[24*102+:24]),$signed(O_result_1[24*103+:24]),
        $signed(O_result_1[24*104+:24]),$signed(O_result_1[24*105+:24]),
        $signed(O_result_1[24*106+:24]),$signed(O_result_1[24*107+:24]),
        $signed(O_result_1[24*108+:24]),$signed(O_result_1[24*109+:24]),
        $signed(O_result_1[24*110+:24]),$signed(O_result_1[24*111+:24]),
        $signed(O_result_1[24*112+:24]),$signed(O_result_1[24*113+:24]),
        $signed(O_result_1[24*114+:24]),$signed(O_result_1[24*115+:24]),
        $signed(O_result_1[24*116+:24]),$signed(O_result_1[24*117+:24]),
        $signed(O_result_1[24*118+:24]),$signed(O_result_1[24*119+:24]),
        $signed(O_result_1[24*120+:24]),$signed(O_result_1[24*121+:24]),
        $signed(O_result_1[24*122+:24]),$signed(O_result_1[24*123+:24]),
        $signed(O_result_1[24*124+:24]),$signed(O_result_1[24*125+:24]),
        $signed(O_result_1[24*126+:24]),$signed(O_result_1[24*127+:24]));  
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*128+:24]),$signed(O_result_0[24*129+:24]),
        $signed(O_result_0[24*130+:24]),$signed(O_result_0[24*131+:24]),
        $signed(O_result_0[24*132+:24]),$signed(O_result_0[24*133+:24]),
        $signed(O_result_0[24*134+:24]),$signed(O_result_0[24*135+:24]),
        $signed(O_result_0[24*136+:24]),$signed(O_result_0[24*137+:24]),
        $signed(O_result_0[24*138+:24]),$signed(O_result_0[24*139+:24]),
        $signed(O_result_0[24*140+:24]),$signed(O_result_0[24*141+:24]),
        $signed(O_result_0[24*142+:24]),$signed(O_result_0[24*143+:24]),
        $signed(O_result_0[24*144+:24]),$signed(O_result_0[24*145+:24]),
        $signed(O_result_0[24*146+:24]),$signed(O_result_0[24*147+:24]),
        $signed(O_result_0[24*148+:24]),$signed(O_result_0[24*149+:24]),
        $signed(O_result_0[24*150+:24]),$signed(O_result_0[24*151+:24]),
        $signed(O_result_0[24*152+:24]),$signed(O_result_0[24*153+:24]),
        $signed(O_result_0[24*154+:24]),$signed(O_result_0[24*155+:24]),
        $signed(O_result_0[24*156+:24]),$signed(O_result_0[24*157+:24]),
        $signed(O_result_0[24*158+:24]),$signed(O_result_0[24*159+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*128+:24]),$signed(O_result_1[24*129+:24]),
        $signed(O_result_1[24*130+:24]),$signed(O_result_1[24*131+:24]),
        $signed(O_result_1[24*132+:24]),$signed(O_result_1[24*133+:24]),
        $signed(O_result_1[24*134+:24]),$signed(O_result_1[24*135+:24]),
        $signed(O_result_1[24*136+:24]),$signed(O_result_1[24*137+:24]),
        $signed(O_result_1[24*138+:24]),$signed(O_result_1[24*139+:24]),
        $signed(O_result_1[24*140+:24]),$signed(O_result_1[24*141+:24]),
        $signed(O_result_1[24*142+:24]),$signed(O_result_1[24*143+:24]),
        $signed(O_result_1[24*144+:24]),$signed(O_result_1[24*145+:24]),
        $signed(O_result_1[24*146+:24]),$signed(O_result_1[24*147+:24]),
        $signed(O_result_1[24*148+:24]),$signed(O_result_1[24*149+:24]),
        $signed(O_result_1[24*150+:24]),$signed(O_result_1[24*151+:24]),
        $signed(O_result_1[24*152+:24]),$signed(O_result_1[24*153+:24]),
        $signed(O_result_1[24*154+:24]),$signed(O_result_1[24*155+:24]),
        $signed(O_result_1[24*156+:24]),$signed(O_result_1[24*157+:24]),
        $signed(O_result_1[24*158+:24]),$signed(O_result_1[24*159+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*160+:24]),$signed(O_result_0[24*161+:24]),
        $signed(O_result_0[24*162+:24]),$signed(O_result_0[24*163+:24]),
        $signed(O_result_0[24*164+:24]),$signed(O_result_0[24*165+:24]),
        $signed(O_result_0[24*166+:24]),$signed(O_result_0[24*167+:24]),
        $signed(O_result_0[24*168+:24]),$signed(O_result_0[24*169+:24]),
        $signed(O_result_0[24*170+:24]),$signed(O_result_0[24*171+:24]),
        $signed(O_result_0[24*172+:24]),$signed(O_result_0[24*173+:24]),
        $signed(O_result_0[24*174+:24]),$signed(O_result_0[24*175+:24]),
        $signed(O_result_0[24*176+:24]),$signed(O_result_0[24*177+:24]),
        $signed(O_result_0[24*178+:24]),$signed(O_result_0[24*179+:24]),
        $signed(O_result_0[24*180+:24]),$signed(O_result_0[24*181+:24]),
        $signed(O_result_0[24*182+:24]),$signed(O_result_0[24*183+:24]),
        $signed(O_result_0[24*184+:24]),$signed(O_result_0[24*185+:24]),
        $signed(O_result_0[24*186+:24]),$signed(O_result_0[24*187+:24]),
        $signed(O_result_0[24*188+:24]),$signed(O_result_0[24*189+:24]),
        $signed(O_result_0[24*190+:24]),$signed(O_result_0[24*191+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*160+:24]),$signed(O_result_1[24*161+:24]),
        $signed(O_result_1[24*162+:24]),$signed(O_result_1[24*163+:24]),
        $signed(O_result_1[24*164+:24]),$signed(O_result_1[24*165+:24]),
        $signed(O_result_1[24*166+:24]),$signed(O_result_1[24*167+:24]),
        $signed(O_result_1[24*168+:24]),$signed(O_result_1[24*169+:24]),
        $signed(O_result_1[24*170+:24]),$signed(O_result_1[24*171+:24]),
        $signed(O_result_1[24*172+:24]),$signed(O_result_1[24*173+:24]),
        $signed(O_result_1[24*174+:24]),$signed(O_result_1[24*175+:24]),
        $signed(O_result_1[24*176+:24]),$signed(O_result_1[24*177+:24]),
        $signed(O_result_1[24*178+:24]),$signed(O_result_1[24*179+:24]),
        $signed(O_result_1[24*180+:24]),$signed(O_result_1[24*181+:24]),
        $signed(O_result_1[24*182+:24]),$signed(O_result_1[24*183+:24]),
        $signed(O_result_1[24*184+:24]),$signed(O_result_1[24*185+:24]),
        $signed(O_result_1[24*186+:24]),$signed(O_result_1[24*187+:24]),
        $signed(O_result_1[24*188+:24]),$signed(O_result_1[24*189+:24]),
        $signed(O_result_1[24*190+:24]),$signed(O_result_1[24*191+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*192+:24]),$signed(O_result_0[24*193+:24]),
        $signed(O_result_0[24*194+:24]),$signed(O_result_0[24*195+:24]),
        $signed(O_result_0[24*196+:24]),$signed(O_result_0[24*197+:24]),
        $signed(O_result_0[24*198+:24]),$signed(O_result_0[24*199+:24]),
        $signed(O_result_0[24*200+:24]),$signed(O_result_0[24*201+:24]),
        $signed(O_result_0[24*202+:24]),$signed(O_result_0[24*203+:24]),
        $signed(O_result_0[24*204+:24]),$signed(O_result_0[24*205+:24]),
        $signed(O_result_0[24*206+:24]),$signed(O_result_0[24*207+:24]),
        $signed(O_result_0[24*208+:24]),$signed(O_result_0[24*209+:24]),
        $signed(O_result_0[24*210+:24]),$signed(O_result_0[24*211+:24]),
        $signed(O_result_0[24*212+:24]),$signed(O_result_0[24*213+:24]),
        $signed(O_result_0[24*214+:24]),$signed(O_result_0[24*215+:24]),
        $signed(O_result_0[24*216+:24]),$signed(O_result_0[24*217+:24]),
        $signed(O_result_0[24*218+:24]),$signed(O_result_0[24*219+:24]),
        $signed(O_result_0[24*220+:24]),$signed(O_result_0[24*221+:24]),
        $signed(O_result_0[24*222+:24]),$signed(O_result_0[24*223+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*192+:24]),$signed(O_result_1[24*193+:24]),
        $signed(O_result_1[24*194+:24]),$signed(O_result_1[24*195+:24]),
        $signed(O_result_1[24*196+:24]),$signed(O_result_1[24*197+:24]),
        $signed(O_result_1[24*198+:24]),$signed(O_result_1[24*199+:24]),
        $signed(O_result_1[24*200+:24]),$signed(O_result_1[24*201+:24]),
        $signed(O_result_1[24*202+:24]),$signed(O_result_1[24*203+:24]),
        $signed(O_result_1[24*204+:24]),$signed(O_result_1[24*205+:24]),
        $signed(O_result_1[24*206+:24]),$signed(O_result_1[24*207+:24]),
        $signed(O_result_1[24*208+:24]),$signed(O_result_1[24*209+:24]),
        $signed(O_result_1[24*210+:24]),$signed(O_result_1[24*211+:24]),
        $signed(O_result_1[24*212+:24]),$signed(O_result_1[24*213+:24]),
        $signed(O_result_1[24*214+:24]),$signed(O_result_1[24*215+:24]),
        $signed(O_result_1[24*216+:24]),$signed(O_result_1[24*217+:24]),
        $signed(O_result_1[24*218+:24]),$signed(O_result_1[24*219+:24]),
        $signed(O_result_1[24*220+:24]),$signed(O_result_1[24*221+:24]),
        $signed(O_result_1[24*222+:24]),$signed(O_result_1[24*223+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
        $signed(O_result_0[24*224+:24]),$signed(O_result_0[24*225+:24]),
        $signed(O_result_0[24*226+:24]),$signed(O_result_0[24*227+:24]),
        $signed(O_result_0[24*228+:24]),$signed(O_result_0[24*229+:24]),
        $signed(O_result_0[24*230+:24]),$signed(O_result_0[24*231+:24]),
        $signed(O_result_0[24*232+:24]),$signed(O_result_0[24*233+:24]),
        $signed(O_result_0[24*234+:24]),$signed(O_result_0[24*235+:24]),
        $signed(O_result_0[24*236+:24]),$signed(O_result_0[24*237+:24]),
        $signed(O_result_0[24*238+:24]),$signed(O_result_0[24*239+:24]),
        $signed(O_result_0[24*240+:24]),$signed(O_result_0[24*241+:24]),
        $signed(O_result_0[24*242+:24]),$signed(O_result_0[24*243+:24]),
        $signed(O_result_0[24*244+:24]),$signed(O_result_0[24*245+:24]),
        $signed(O_result_0[24*246+:24]),$signed(O_result_0[24*247+:24]),
        $signed(O_result_0[24*248+:24]),$signed(O_result_0[24*249+:24]),
        $signed(O_result_0[24*250+:24]),$signed(O_result_0[24*251+:24]),
        $signed(O_result_0[24*252+:24]),$signed(O_result_0[24*253+:24]),
        $signed(O_result_0[24*254+:24]),$signed(O_result_0[24*255+:24]));
        
$fwrite(line2,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d\n",
        $signed(O_result_1[24*224+:24]),$signed(O_result_1[24*225+:24]),
        $signed(O_result_1[24*226+:24]),$signed(O_result_1[24*227+:24]),
        $signed(O_result_1[24*228+:24]),$signed(O_result_1[24*229+:24]),
        $signed(O_result_1[24*230+:24]),$signed(O_result_1[24*231+:24]),
        $signed(O_result_1[24*232+:24]),$signed(O_result_1[24*233+:24]),
        $signed(O_result_1[24*234+:24]),$signed(O_result_1[24*235+:24]),
        $signed(O_result_1[24*236+:24]),$signed(O_result_1[24*237+:24]),
        $signed(O_result_1[24*238+:24]),$signed(O_result_1[24*239+:24]),
        $signed(O_result_1[24*240+:24]),$signed(O_result_1[24*241+:24]),
        $signed(O_result_1[24*242+:24]),$signed(O_result_1[24*243+:24]),
        $signed(O_result_1[24*244+:24]),$signed(O_result_1[24*245+:24]),
        $signed(O_result_1[24*246+:24]),$signed(O_result_1[24*247+:24]),
        $signed(O_result_1[24*248+:24]),$signed(O_result_1[24*249+:24]),
        $signed(O_result_1[24*250+:24]),$signed(O_result_1[24*251+:24]),
        $signed(O_result_1[24*252+:24]),$signed(O_result_1[24*253+:24]),
        $signed(O_result_1[24*254+:24]),$signed(O_result_1[24*255+:24]));
    end
end
end 
    
endmodule
