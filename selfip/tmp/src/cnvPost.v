`timescale 1ns / 1ps
module cnvPost#(
    parameter            CH_OUT    = 32,
    parameter            PIX       = 8,
    parameter            DWIDTH    = 8,
    parameter            AXIWIDTH  = 128,
    parameter            LITEWIDTH = 32,
    parameter            KWIDTH    = 2,
    parameter            DEPTHWIDTH= 9,
    parameter            PE_CO     = 32
)(
    input                           I_clk,
    input                           I_rst,
   
    input                           I_ap_start,
    input      [KWIDTH-1:0]         I_ky,
    input      [LITEWIDTH-1:0]      I_ky_num,
    input      [DEPTHWIDTH-1:0]     I_coGroup,
    input      [DEPTHWIDTH-1:0]     I_woGroup,
   
    input      [24*CH_OUT*PIX-1:0]  I_result_0,
    input      [24*CH_OUT*PIX-1:0]  I_result_1,
    input                           I_data_dv,
   
    input      [AXIWIDTH-1:0]       I_weight,
    input                           I_weight_dv,
   
    input      [LITEWIDTH-1:0]      I_imgInPos,
    input      [LITEWIDTH-1:0]      I_wghInPos,
    input      [LITEWIDTH-1:0]      I_biasInPos,
    input      [LITEWIDTH-1:0]      I_imgOutPos,
   
    input                           I_relu_en,
    input      [LITEWIDTH-1:0]      I_imgOutAddr,
    input      [DEPTHWIDTH:0]       I_h,
   
    output     [AXIWIDTH-1:0]       O_cnv_data,
    output reg                      O_cnv_dv=0,
    output     [LITEWIDTH-1:0]      O_wr_DDRaddr,
    output reg                      O_line_end=0
    );
   
    //-----------------------------------------------------------
    //                      pos compute
    //-----------------------------------------------------------
   
    wire   [LITEWIDTH-1:0]          halfValueCaffe;
    wire   [LITEWIDTH-1:0]          BIAS_POS_NEW;
    wire   [LITEWIDTH-1:0]          IMG_POS_NEW;
    wire   [LITEWIDTH-1:0]          BIAS_POS_NEW_POS;
    wire   [LITEWIDTH-1:0]          IMG_POS_NEW_POS;
   
    assign halfValueCaffe = 1<<(I_imgInPos + I_wghInPos - I_imgOutPos - 1);
    assign BIAS_POS_NEW = I_imgInPos + I_wghInPos - I_biasInPos;
    assign IMG_POS_NEW = I_imgInPos + I_wghInPos - I_imgOutPos;
    assign BIAS_POS_NEW_POS = BIAS_POS_NEW[LITEWIDTH-1] ? {1'b0,~(BIAS_POS_NEW[LITEWIDTH-2:0]-1)} : BIAS_POS_NEW;
    assign IMG_POS_NEW_POS = IMG_POS_NEW[LITEWIDTH-1] ? {1'b0,~(IMG_POS_NEW[LITEWIDTH-2:0]-1)} : IMG_POS_NEW;
   
    //-----------------------------------------------------------
    //                       load bias
    //-----------------------------------------------------------
    reg                             S_ap_start=0;
    reg    [AXIWIDTH-1:0]           biasArray  [63:0];
    reg    [5:0]                    biasAddr=0;
   
    always@ (posedge I_clk)
    begin
        S_ap_start <= I_ap_start;
   
        if (!S_ap_start && I_ap_start)
            biasAddr <= 'd0;
        else if (I_weight_dv)
            biasAddr <= biasAddr + 'd1;
               
        if (I_weight_dv)
            biasArray[biasAddr] <= I_weight;
    end  
     
   
    (*ram_style="block"*) reg [12*CH_OUT*PIX-1:0] ipbuf0 [511:0];
    (*ram_style="block"*) reg [12*CH_OUT*PIX-1:0] ipbuf1 [511:0];
    reg    [8:0]                    S_waddr=0;
    wire                            S_we;
    wire   [24*CH_OUT*PIX-1:0]      S_din;
   
    reg    [KWIDTH-1:0]             S_ky0=0;
    reg    [KWIDTH-1:0]             S_ky1=0;
    reg    [KWIDTH-1:0]             S_ky2=0;
    wire                            S_ky_change;
   
    wire                            S_we0,S_we1;
    wire   [12*CH_OUT*PIX-1:0]      S_din0,S_din1;
    wire   [8:0]                    S_waddr0,S_waddr1;
   
    //-----------------------------------------------------------
    //              load CONV result to ipbuf
    //-----------------------------------------------------------
   
    assign  S_ky_change = !(S_ky1==S_ky2);
   
    always@ (posedge I_clk)
    begin
        S_ky0 <= I_ky;
        S_ky1 <= S_ky0;
        S_ky2 <= S_ky1;
       
        if (S_ky_change)
            S_waddr <= 'd0;
        else if (I_data_dv)
            S_waddr <= S_waddr + 1;
    end
   
    assign S_din = S_waddr[0] ? I_result_1 : I_result_0;
    assign S_we = I_data_dv && S_ky0==I_ky_num-1;
   
    assign S_we0 = S_we;
    assign S_we1 = S_we;
    assign S_waddr0 = S_waddr;
    assign S_waddr1 = S_waddr;
    assign S_din0= S_din[3071:0];
    assign S_din1= S_din[6143:3072];
       
    always@ (posedge I_clk)
    begin
        if (S_we0)
            ipbuf0[S_waddr0] <= S_din0;
    end
   
       
    always@ (posedge I_clk)
    begin
        if (S_we1)
            ipbuf1[S_waddr1] <= S_din1;
    end
    //-----------------------------------------------------------
    //                 post process begin
    //-----------------------------------------------------------
   
    wire  [DEPTHWIDTH-1:0]   S_peCoDiv16;
    reg                      S_process_en    = 0;
    reg                      S_process_en_d1 = 0;
    reg                      S_process_en_d2 = 0;
    reg                      S_process_en_d3 = 0;
    reg                      S_process_en_d4 = 0;
    reg   [4-1:0]   S_peCoDiv16_cnt = 0;
    reg   [4-1:0]   S_peCoDiv16_cnt_d1=0;
    reg   [4-1:0]   S_pix_cnt       = 0;
    reg   [4-1:0]   S_pix_cnt_d1    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt       = 0;
    reg   [DEPTHWIDTH-1:0]   S_wog_cnt       = 0;
    reg   [DEPTHWIDTH-1:0]   S_coDiv16       = 0;
    wire  [DEPTHWIDTH-1:0]   S_depthIpbuf;
    wire  [AXIWIDTH-1:0]     S_activeOut;
    wire                     S_pix_cnt_ch;
    reg                      S_pix_cnt_ch_d=0;
   
   
    assign S_peCoDiv16 = PE_CO >> 4;
   
    always@ (posedge I_clk)
    begin
        S_process_en_d1 <= S_process_en;
        S_process_en_d2 <= S_process_en_d1;
        S_process_en_d3 <= S_process_en_d2;
   
        if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1 && S_cog_cnt==I_coGroup-1 && S_wog_cnt==I_woGroup-1)
            S_process_en <= 1'b0;
        else if (S_waddr=='d1 && I_ky == I_ky_num-1)
            S_process_en <= 1'b1;
    end
 
  
    always@ (posedge I_clk)
    begin
        S_peCoDiv16_cnt_d1 <= S_peCoDiv16_cnt;
    
        if (!(|I_ky) && !S_process_en)
            S_peCoDiv16_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1)
            S_peCoDiv16_cnt <= 'd0;
        else if (S_process_en)
            S_peCoDiv16_cnt <= S_peCoDiv16_cnt + 'd1;
           
        S_pix_cnt_d1 <= S_pix_cnt;
           
        if (!(|I_ky) && !S_process_en)
            S_pix_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1)
            S_pix_cnt <= 'd0;
        else if (S_process_en && S_peCoDiv16_cnt == S_peCoDiv16-1)
            S_pix_cnt <= S_pix_cnt + 'd1;
           
        if (!(|I_ky) && !S_process_en)
            S_cog_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1 && S_cog_cnt==I_coGroup-1)
            S_cog_cnt <= 'd0;
        else if (S_process_en && S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1)
            S_cog_cnt <= S_cog_cnt + 'd1;
           
        if (!(|I_ky) && !S_process_en)
            S_wog_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1 && S_cog_cnt==I_coGroup-1 && S_wog_cnt==I_woGroup-1)
            S_wog_cnt <= 'd0;
        else if (S_process_en && S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1 && S_cog_cnt==I_coGroup-1)
            S_wog_cnt <= S_wog_cnt + 'd1;
    end
   
    assign  S_pix_cnt_ch = !(|S_pix_cnt[2]) ? 1'b0 : 1'b1;
   
    always@ (posedge I_clk)
        S_pix_cnt_ch_d <= S_pix_cnt_ch;
   
    always@ (posedge I_clk)
    begin
        S_coDiv16 <= S_cog_cnt*2 + S_peCoDiv16_cnt;
    end
   
    assign        S_depthIpbuf = S_wog_cnt*I_coGroup + S_cog_cnt;
   
    wire   S_re0,S_re1;
    wire [DEPTHWIDTH-1:0] S_raddr0,S_raddr1;
    assign S_re0 = !S_pix_cnt_ch;
    assign S_re1 = S_pix_cnt_ch;
    assign S_raddr0 = S_depthIpbuf;
    assign S_raddr1 = S_depthIpbuf;
    reg  [12*CH_OUT*PIX-1:0]  ipBufData0=0;
    reg  [12*CH_OUT*PIX-1:0]  ipBufData1=0;
 wire  [4095:0] ipBufData0_exp;
 wire  [4095:0] ipBufData1_exp;
   
    always@ (posedge I_clk)
    begin
        if (S_re0)
            ipBufData0 <= ipbuf0[S_raddr0];
    end
   
    always@ (posedge I_clk)
    begin
        if (S_re1)
            ipBufData1 <= ipbuf1[S_raddr1];
    end 
   
 genvar gen_i;
 generate
 for(gen_i=0;gen_i<128;gen_i=gen_i+1)
 begin:expand
 
 assign ipBufData0_exp[gen_i*32+:24] = ipBufData0[gen_i*24+:24];
 assign ipBufData0_exp[gen_i*32+24+:8] = 0;
 assign ipBufData1_exp[gen_i*32+:24] = ipBufData1[gen_i*24+:24];
 assign ipBufData1_exp[gen_i*32+24+:8] = 0;
 
 end
 endgenerate
 
    genvar dataPerDot;
    generate for (dataPerDot=0; dataPerDot<16; dataPerDot=dataPerDot+1)
    begin:loop
   
        wire [23:0]  biasTmp;
       
        reg  [23:0]  batchData=0;
        reg  [23:0]  batchDataRelu=0;
        wire [23:0]  activeDataPre;
        reg  [7:0]   activeData=0;
        wire [23:0]  ipBufData;
        wire [23:0]  ipBufData0_use;
        wire [23:0]  ipBufData1_use;
        wire [6:0] ipBufData0_temp;
  wire [6:0] ipBufData0_temp2;
       
        assign biasTmp = (!BIAS_POS_NEW[LITEWIDTH-1]) ? {{(16){biasArray[S_coDiv16][dataPerDot*8+7]}},{biasArray[S_coDiv16][dataPerDot*8+:8] << BIAS_POS_NEW_POS}} :
                                                        {{(16){biasArray[S_coDiv16][dataPerDot*8+7]}},{biasArray[S_coDiv16][dataPerDot*8+:8] >> BIAS_POS_NEW_POS}};
       
  assign ipBufData0_temp = (32*S_pix_cnt_d1 + 16*S_peCoDiv16_cnt_d1 +dataPerDot);
  assign ipBufData0_temp2 = (32*(S_pix_cnt_d1-4) + 16*S_peCoDiv16_cnt_d1 +dataPerDot);
  assign ipBufData0_use = ipBufData0_exp>>{ipBufData0_temp,5'd0};
        assign ipBufData1_use = ipBufData1_exp>>{ipBufData0_temp2,5'd0};
       
        assign ipBufData = S_pix_cnt_ch_d ?  ipBufData1_use : ipBufData0_use;                     
       
        always@ (posedge I_clk)
        begin
            batchData <= ipBufData + biasTmp;
           
           
            if (S_process_en_d2)
            begin
                if (I_relu_en)
                    batchDataRelu <= batchData[23] ? 'd0 : batchData;
                else
                    batchDataRelu <= batchData;
            end
        end
       
        assign activeDataPre = (!IMG_POS_NEW[LITEWIDTH-1]) ? (batchDataRelu+ halfValueCaffe)>>IMG_POS_NEW_POS :
                                                             (batchDataRelu+ halfValueCaffe)<<IMG_POS_NEW_POS;
                                                            
        always@ (posedge I_clk)
        begin
            if (S_process_en_d3)
            begin
                if (!activeDataPre[23] && |activeDataPre[22:7])
                    activeData <= 'd127;
                else if (activeDataPre[23] && !(&activeDataPre[22:7]))
                    activeData <= 8'b1000_0000;
                else
                    activeData <= activeDataPre;
            end
        end
       
        assign S_activeOut[8*dataPerDot+:8] = activeData;
   
    end
    endgenerate
   
    wire    [31:0]   S_wr_out_DDRaddr;
    reg     [31:0]   S_wr_out_DDRaddr_d1;
    reg     [31:0]   S_wr_out_DDRaddr_d2;
    reg     [31:0]   S_wr_out_DDRaddr_d3;
    reg     [31:0]   S_wr_out_DDRaddr_d4;
    reg     [9:0]    S_h=0;
   
    always@ (posedge I_clk)
    begin
//        if (S_process_en && !S_process_en_d2)
//            S_h <= I_h;
        if (S_waddr=='d1 && I_ky == I_ky_num-1)
            S_h <= I_h;
    end
   
    assign S_wr_out_DDRaddr = I_imgOutAddr + S_peCoDiv16_cnt + S_pix_cnt*I_coGroup*2 + S_cog_cnt*2 + S_wog_cnt*PIX*2*I_coGroup
                              + S_h*PIX*I_coGroup*2*I_woGroup;
                             
    always@ (posedge I_clk)
    begin
        S_wr_out_DDRaddr_d1 <= S_wr_out_DDRaddr;
        S_wr_out_DDRaddr_d2 <= S_wr_out_DDRaddr_d1;
        S_wr_out_DDRaddr_d3 <= S_wr_out_DDRaddr_d2;
        S_wr_out_DDRaddr_d4 <= S_wr_out_DDRaddr_d3;
    end
   
    assign O_wr_DDRaddr = S_wr_out_DDRaddr_d4;
    assign O_cnv_data = S_activeOut;
    always@ (posedge I_clk)
    begin
        O_cnv_dv <= S_process_en_d3;
    end
    
    reg      S_cnv_dv = 0;
    
    always@ (posedge I_clk)
    begin
        S_cnv_dv <= O_cnv_dv;
        
        if (!S_cnv_dv && O_cnv_dv)
            O_line_end <= 1'b0;
        else if (O_line_end)
            O_line_end <= 1'b0;
        else if (S_cnv_dv && !O_cnv_dv)
            O_line_end <= 1'b1;
    end    
    



    reg [127:0]   S_obuf [1023:0];
    initial begin
    #14885
    repeat (910)
    begin
    @(posedge I_clk)
    begin
        if (O_cnv_dv)
            S_obuf[O_wr_DDRaddr-32'h0000_cf48] <= O_cnv_data;
    end
    end
    end
    
    reg [31:0]    test_wr_out_addr;
    reg [127:0]   test_data_out;
    integer fp_test_wr;
    
    initial begin
    #23865
    test_wr_out_addr=0;
    test_data_out=0;
    @(posedge I_clk)
    repeat(896)begin
    @(posedge I_clk)
    begin
        test_data_out <= S_obuf[test_wr_out_addr];
        test_wr_out_addr <= test_wr_out_addr + 1;
    end
    end
    end
    
    initial begin
    fp_test_wr = $fopen("myhlsfinal_dataOut.txt","w");
    #23865
    repeat(896) begin

    @(posedge I_clk)
    begin
    $fwrite(fp_test_wr,"%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d%8d\n",
             $signed(test_data_out[8*0+:8]),$signed(test_data_out[8*1+:8]),
             $signed(test_data_out[8*2+:8]),$signed(test_data_out[8*3+:8]),
             $signed(test_data_out[8*4+:8]),$signed(test_data_out[8*5+:8]),
             $signed(test_data_out[8*6+:8]),$signed(test_data_out[8*7+:8]),
             $signed(test_data_out[8*8+:8]),$signed(test_data_out[8*9+:8]),
             $signed(test_data_out[8*10+:8]),$signed(test_data_out[8*11+:8]),
             $signed(test_data_out[8*12+:8]),$signed(test_data_out[8*13+:8]),
             $signed(test_data_out[8*14+:8]),$signed(test_data_out[8*15+:8]));
    end
    end//repeat
    end
    
    
endmodule