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
   
//    input      [24*CH_OUT*PIX-1:0]  I_data_in,
//    input                           I_data_dv,
    input      [24*CH_OUT*PIX-1:0]  I_macc_data,
   
    input      [AXIWIDTH-1:0]       I_weight,
    input                           I_weight_dv,
   
    input      [LITEWIDTH-1:0]      I_imgInPos,
    input      [LITEWIDTH-1:0]      I_wghInPos,
    input      [LITEWIDTH-1:0]      I_biasInPos,
    input      [LITEWIDTH-1:0]      I_imgOutPos,
   
    input                           I_relu_en,
    input      [LITEWIDTH-1:0]      I_imgOutAddr,
    input      [DEPTHWIDTH:0]       I_h,
    input                           I_post_begin_flag,
    input                           I_wr_of,
   
    output     [AXIWIDTH-1:0]       O_cnv_data,
    output reg                      O_cnv_dv=0,
    output     [LITEWIDTH-1:0]      O_wr_DDRaddr,
    output reg                      O_line_end=0,
    
    output reg [8:0]                O_post_raddr=0
    );
   
    //-----------------------------------------------------------
    //                      pos compute
    //-----------------------------------------------------------
   
    reg    [LITEWIDTH-1:0]          halfValueCaffe=0;
    reg    [LITEWIDTH-1:0]          BIAS_POS_NEW=0;
    reg    [LITEWIDTH-1:0]          IMG_POS_NEW=0;
    reg    [LITEWIDTH-1:0]          BIAS_POS_NEW_POS=0;
    reg    [LITEWIDTH-1:0]          IMG_POS_NEW_POS=0;

    always@ (posedge I_clk)
    begin    
        halfValueCaffe   <= 1<<(I_imgInPos + I_wghInPos - I_imgOutPos - 1);
        BIAS_POS_NEW     <= I_imgInPos + I_wghInPos - I_biasInPos;
        IMG_POS_NEW      <= I_imgInPos + I_wghInPos - I_imgOutPos;
        BIAS_POS_NEW_POS <= BIAS_POS_NEW[LITEWIDTH-1] ? {1'b0,~(BIAS_POS_NEW[LITEWIDTH-2:0]-1)} : BIAS_POS_NEW;
        IMG_POS_NEW_POS  <= IMG_POS_NEW[LITEWIDTH-1] ? {1'b0,~(IMG_POS_NEW[LITEWIDTH-2:0]-1)} : IMG_POS_NEW;
    end
   
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
     
   
//    (* ram_style="block" *) reg [12*CH_OUT*PIX-1:0] ipbuf0 [511:0];
//    (* ram_style="block" *) reg [12*CH_OUT*PIX-1:0] ipbuf1 [511:0];
    reg    [8:0]                    S_waddr=0;
    
    reg                             S_we=0;
    reg    [24*CH_OUT*PIX-1:0]      S_din=0;
   
    reg    [KWIDTH-1:0]             S_ky0=0;
    reg    [KWIDTH-1:0]             S_ky1=0;
    reg    [KWIDTH-1:0]             S_ky2=0;
    wire                            S_ky_change;
    reg    [KWIDTH-1:0]             S_ky_ceil=0;

    reg                             S_we0=0,S_we1=0;
    reg    [8:0]                    S_waddr0=0,S_waddr1=0;
    reg                             S_we0_d1=0,S_we1_d1=0;
    reg    [8:0]                    S_waddr0_d1=0,S_waddr1_d1=0;
    reg    [12*CH_OUT*PIX-1:0]      S_din0=0,S_din1=0;
   
    //-----------------------------------------------------------
    //              load CONV result to ipbuf
    //-----------------------------------------------------------
   
    assign  S_ky_change = !(S_ky1==S_ky2);
    
    always@ (posedge I_clk)
        S_ky_ceil <= I_ky_num-1;
   
    always@ (posedge I_clk)
    begin
        S_ky0 <= I_ky;
        S_ky1 <= S_ky0;
        S_ky2 <= S_ky1;
       
//        if (S_ky_change)
//            S_waddr <= 'd0;
//        else if (I_data_dv)
//            S_waddr <= S_waddr + 1;
    end
   
//    always@ (posedge I_clk)
//    begin
//        S_din <= I_data_in;
//        S_we  <= I_data_dv;
//    end
    
//    always@ (posedge I_clk)
//    begin
//        S_we0_d1 <= S_we0;
//        if (I_data_dv && S_ky0==S_ky_ceil)
//            S_we0 <= 1'b1;
//        else
//            S_we0 <= 1'b0;
//    end
    
//    always@ (posedge I_clk)
//    begin
//        S_we1_d1 <= S_we1;
//        if (I_data_dv && S_ky0==S_ky_ceil)
//            S_we1 <= 1'b1;
//        else
//            S_we1 <= 1'b0;
//    end
    
    always@ (posedge I_clk)
    begin
        S_waddr0 <= S_waddr;
        S_waddr0_d1 <= S_waddr0;
    end
    
    always@ (posedge I_clk)
    begin
        S_waddr1 <= S_waddr;
        S_waddr1_d1 <= S_waddr1;
    end
        
    always@ (posedge I_clk)
        S_din0 <= S_din[3071:0];
        
    always@ (posedge I_clk)
        S_din1 <= S_din[6143:3072];
        

//    always@ (posedge I_clk)
//    begin
//        if (S_we0_d1)
//            ipbuf0[S_waddr0_d1] <= S_din0;
//    end
       
//    always@ (posedge I_clk)
//    begin
//        if (S_we1_d1)
//            ipbuf1[S_waddr1_d1] <= S_din1;
//    end
    //-----------------------------------------------------------
    //                 post process begin
    //-----------------------------------------------------------
   
    wire  [DEPTHWIDTH-1:0]   S_peCoDiv16;
    reg                      S_process_en    = 0;
    reg                      S_process_en_d1 = 0;
    reg                      S_process_en_d2 = 0;
    reg                      S_process_en_d3 = 0;
    reg                      S_process_en_d4 = 0;
    reg                      S_process_en_d5 = 0;
    reg                      S_process_en_d6 = 0;
    reg                      S_process_en_d7 = 0;
    reg                      S_process_en_d8 = 0;
    reg                      S_process_en_d9 = 0;
    reg   [4-1:0]            S_peCoDiv16_cnt = 0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d1=0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d2=0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d3=0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d4=0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d5=0;
    reg   [4-1:0]            S_peCoDiv16_cnt_d6=0;
    
    reg   [4-1:0]            S_pix_cnt       = 0;
    reg   [4-1:0]            S_pix_cnt_d1    = 0;
    reg   [4-1:0]            S_pix_cnt_d2    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt       = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d1    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d2    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d3    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d4    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d5    = 0;
    reg   [DEPTHWIDTH-1:0]   S_cog_cnt_d6    = 0;
    
    reg   [DEPTHWIDTH-1:0]   S_wog_cnt       = 0;
    reg   [DEPTHWIDTH-1:0]   S_coDiv16       = 0;
    wire  [DEPTHWIDTH-1:0]   S_depthIpbuf;
    reg   [DEPTHWIDTH-1:0]   S_depthIpbuf_d1 = 0;
    wire  [AXIWIDTH-1:0]     S_activeOut;
    wire                     S_pix_cnt_ch;
    reg                      S_pix_cnt_ch_d=0;
    reg                      S_pix_cnt_ch_d2=0;
    reg                      S_pix_cnt_ch_d3=0;
    reg                      S_pix_cnt_ch_d4=0;
    reg                      S_pix_cnt_ch_d5=0;
    reg                      S_pix_cnt_ch_d6=0;
   
    assign S_peCoDiv16 = PE_CO >> 4;
   
    always@ (posedge I_clk)
    begin
        S_process_en_d1 <= S_process_en;
        S_process_en_d2 <= S_process_en_d1;
        S_process_en_d3 <= S_process_en_d2;
        S_process_en_d4 <= S_process_en_d3;
        S_process_en_d5 <= S_process_en_d4;
        S_process_en_d6 <= S_process_en_d5;
        S_process_en_d7 <= S_process_en_d6;
        S_process_en_d8 <= S_process_en_d7;
        S_process_en_d9 <= S_process_en_d8;
   
        if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1 && S_cog_cnt==I_coGroup-1 && S_wog_cnt==I_woGroup-1)
            S_process_en <= 1'b0;
        else if (/*S_waddr=='d1 && I_ky == I_ky_num-1*/I_post_begin_flag)
            S_process_en <= 1'b1;
    end
 
  
    always@ (posedge I_clk)
    begin
        S_peCoDiv16_cnt_d1 <= S_peCoDiv16_cnt;
        S_peCoDiv16_cnt_d2 <= S_peCoDiv16_cnt_d1;
        S_peCoDiv16_cnt_d3 <= S_peCoDiv16_cnt_d2;
        S_peCoDiv16_cnt_d4 <= S_peCoDiv16_cnt_d3;
        S_peCoDiv16_cnt_d5 <= S_peCoDiv16_cnt_d4;
        S_peCoDiv16_cnt_d6 <= S_peCoDiv16_cnt_d5;
    
        if (!(|I_ky) && !S_process_en)
            S_peCoDiv16_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1)
            S_peCoDiv16_cnt <= 'd0;
        else if (S_process_en)
            S_peCoDiv16_cnt <= S_peCoDiv16_cnt + 'd1;
           
        S_pix_cnt_d1 <= S_pix_cnt;
        S_pix_cnt_d2 <= S_pix_cnt_d1;
           
        if (!(|I_ky) && !S_process_en)
            S_pix_cnt <= 'd0;
        else if (S_peCoDiv16_cnt == S_peCoDiv16-1 && S_pix_cnt == PIX-1)
            S_pix_cnt <= 'd0;
        else if (S_process_en && S_peCoDiv16_cnt == S_peCoDiv16-1)
            S_pix_cnt <= S_pix_cnt + 'd1;
           
        S_cog_cnt_d1 <= S_cog_cnt;
        S_cog_cnt_d2 <= S_cog_cnt_d1;
        S_cog_cnt_d3 <= S_cog_cnt_d2;
        S_cog_cnt_d4 <= S_cog_cnt_d3;
        S_cog_cnt_d5 <= S_cog_cnt_d4;
        S_cog_cnt_d6 <= S_cog_cnt_d5;

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
    begin
        S_pix_cnt_ch_d <= S_pix_cnt_ch;
        S_pix_cnt_ch_d2<= S_pix_cnt_ch_d;
        S_pix_cnt_ch_d3<= S_pix_cnt_ch_d2;
        S_pix_cnt_ch_d4<= S_pix_cnt_ch_d3;
        S_pix_cnt_ch_d5<= S_pix_cnt_ch_d4;
        S_pix_cnt_ch_d6<= S_pix_cnt_ch_d5;
    end
   
    always@ (posedge I_clk)
    begin
        S_coDiv16 <= S_cog_cnt*2 + S_peCoDiv16_cnt;
    end
    
    dsp_unit1 dsp_unit_inst0(
        .I_clk              (I_clk),
        .I_weight_l         ({21'd0,S_wog_cnt}),
        .I_weight_h         (27'd0),
        .I_1feature         ({9'd0,I_coGroup}),
        .I_pi_cas           ({39'd0,S_cog_cnt}),
        .O_pi               (),
        .O_p                (S_depthIpbuf)
    );
   
    wire   S_re0,S_re1;
    wire [DEPTHWIDTH-1:0] S_raddr0;
    reg  [DEPTHWIDTH-1:0] S_raddr1;
    assign S_re0 = !S_pix_cnt_ch_d4;
    assign S_re1 = S_pix_cnt_ch_d4;
    assign S_raddr0 = S_depthIpbuf;

    reg  [12*CH_OUT*PIX-1:0]  ipBufData0=0;
    reg  [12*CH_OUT*PIX-1:0]  ipBufData1=0;
    reg  [12*CH_OUT*PIX-1:0]  ipBufData0_new=0;
    reg  [12*CH_OUT*PIX-1:0]  ipBufData1_new=0;
    wire [4095:0]             ipBufData0_exp;
    wire [4095:0]             ipBufData1_exp;
    
    always@ (posedge I_clk)
        S_depthIpbuf_d1 <= S_depthIpbuf;
    
    always@ (posedge I_clk)
        S_raddr1 <= S_depthIpbuf_d1;
   
//    always@ (posedge I_clk)
//    begin
//        if (S_re0)
//            ipBufData0 <= ipbuf0[S_raddr0];
//    end
   
//    always@ (posedge I_clk)
//    begin
//        if (S_re1)
//            ipBufData1 <= ipbuf1[S_raddr1];
//    end

    always@ (posedge I_clk)
    begin
        if (S_re0)
            ipBufData0_new <= I_macc_data[3071:0];
    end
   
    always@ (posedge I_clk)
    begin
        if (S_re1)
            ipBufData1_new <= I_macc_data[6143:3072];
    end
   
    genvar gen_i;
    generate
    for(gen_i=0;gen_i<128;gen_i=gen_i+1)
    begin:expand
 
//    assign ipBufData0_exp[gen_i*32+:24] = ipBufData0[gen_i*24+:24];
    assign ipBufData0_exp[gen_i*32+:24] = ipBufData0_new[gen_i*24+:24];
    assign ipBufData0_exp[gen_i*32+24+:8] = 0;
//    assign ipBufData1_exp[gen_i*32+:24] = ipBufData1[gen_i*24+:24];
    assign ipBufData1_exp[gen_i*32+:24] = ipBufData1_new[gen_i*24+:24];
    assign ipBufData1_exp[gen_i*32+24+:8] = 0;
 
    end
    endgenerate
 
    genvar dataPerDot;
    generate for (dataPerDot=0; dataPerDot<16; dataPerDot=dataPerDot+1)
    begin:loop
   
        reg  [23:0]  biasTmp            =0;
        reg  [23:0]  biasTmp_d1         =0;
        reg  [23:0]  biasTmp_d2         =0;
        reg  [23:0]  biasTmp_d3         =0;
        reg  [23:0]  biasTmp_d4         =0;
       
        reg  [23:0]  batchData          =0;
        reg  [23:0]  batchDataRelu      =0;
        reg  [23:0]  activeDataPre      =0;
        reg  [7:0]   activeData         =0;
        wire [23:0]  ipBufData;
        reg  [23:0]  ipBufData0_use     =0;
        reg  [23:0]  ipBufData0_use_d1  =0;
        reg  [23:0]  ipBufData0_use_d2  =0;
        reg  [23:0]  ipBufData1_use     =0;
        reg  [6:0]   ipBufData0_temp    =0;
        reg  [6:0]   ipBufData0_temp_d1 =0;
        reg  [6:0]   ipBufData0_temp_d2 =0;
        reg  [6:0]   ipBufData0_temp2   =0;
        reg  [6:0]   ipBufData0_temp2_d1=0;
        reg  [6:0]   ipBufData0_temp2_d2=0;
                                                        
        always@ (posedge I_clk)
        begin
            biasTmp_d1 <= biasTmp;
            biasTmp_d2 <= biasTmp_d1;
            biasTmp_d3 <= biasTmp_d2;
            biasTmp_d4 <= biasTmp_d3;
            if (!BIAS_POS_NEW[LITEWIDTH-1])
                biasTmp <= {{(16){biasArray[S_coDiv16][dataPerDot*8+7]}},{biasArray[S_coDiv16][dataPerDot*8+:8] << BIAS_POS_NEW_POS}};
            else
                biasTmp <= {{(16){biasArray[S_coDiv16][dataPerDot*8+7]}},{biasArray[S_coDiv16][dataPerDot*8+:8] >> BIAS_POS_NEW_POS}};
        end
        
        reg   [6:0]   ipBufData0_temp_t0=0;
        reg   [6:0]   ipBufData0_temp2_t0=0;

        always@ (posedge I_clk)
        begin
            ipBufData0_temp_d1 <= ipBufData0_temp;
            ipBufData0_temp_d2 <= ipBufData0_temp_d1;
        
            ipBufData0_temp2_d1 <= ipBufData0_temp2;
            ipBufData0_temp2_d2 <= ipBufData0_temp2_d1;
            
            ipBufData0_use_d1 <= ipBufData0_use;
            ipBufData0_use_d2 <= ipBufData0_use_d1;
            
            ipBufData0_temp_t0 <= {S_peCoDiv16_cnt_d1,4'd0} +dataPerDot;
            ipBufData0_temp2_t0 <= {S_pix_cnt_d1,5'd0}-128;
            ipBufData0_temp    <= {S_pix_cnt_d2,5'd0} + ipBufData0_temp_t0;
            ipBufData0_temp2 <= ipBufData0_temp2_t0 + ipBufData0_temp_t0;
            ipBufData0_use   <= ipBufData0_exp>>{ipBufData0_temp_d2,5'd0};
            ipBufData1_use   <= ipBufData1_exp>>{ipBufData0_temp2_d2,5'd0};
        end
       
        assign ipBufData = S_pix_cnt_ch_d6 ?  ipBufData1_use : ipBufData0_use;  
                     
       
        always@ (posedge I_clk)
        begin
            batchData <= ipBufData + biasTmp_d4;
           
            if (S_process_en_d7)
            begin
                if (I_relu_en)
                    batchDataRelu <= batchData[23] ? 'd0 : batchData;
                else
                    batchDataRelu <= batchData;
            end
        end
       
//        assign activeDataPre = (!IMG_POS_NEW[LITEWIDTH-1]) ? (batchDataRelu+ halfValueCaffe)>>IMG_POS_NEW_POS :
//                                                             (batchDataRelu+ halfValueCaffe)<<IMG_POS_NEW_POS;
                                                             
        always@ (posedge I_clk)
            if (!IMG_POS_NEW[LITEWIDTH-1])
                activeDataPre <= (batchDataRelu+ halfValueCaffe)>>IMG_POS_NEW_POS;
            else
                activeDataPre <= (batchDataRelu+ halfValueCaffe)<<IMG_POS_NEW_POS;
                                                            
        always@ (posedge I_clk)
        begin
            if (S_process_en_d9)
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
   
    wire    [31:0]   S_wr_out_DDRaddr_tmp0;
    wire    [31:0]   S_wr_out_DDRaddr_tmp1;
    wire    [31:0]   S_wr_out_DDRaddr_tmp2;
    reg     [31:0]   S_wr_out_DDRaddr_tmp0_d1=0;
    reg     [31:0]   S_wr_out_DDRaddr_tmp0_d2=0;
    reg     [31:0]   S_wr_out_DDRaddr_tmp0_d3=0;
    reg     [31:0]   S_wr_out_DDRaddr_tmp0_d4=0;
    
    reg     [31:0]   S_wr_out_DDRaddr=0;
    reg     [31:0]   S_wr_out_DDRaddr_d1;
    reg     [9:0]    S_h=0;
    
    wire    [47:0]   S_wr_out_DDRaddr_tmp1_t;
    wire    [47:0]   S_wr_out_DDRaddr_tmp2_t0;
    wire    [47:0]   S_wr_out_DDRaddr_tmp2_t1;
   
    always@ (posedge I_clk)
    begin
        if (S_waddr=='d1 && I_ky == I_ky_num-1)
            S_h <= I_h;
    end
    
     dsp_unit1 dsp_unit_inst1(
        .I_clk              (I_clk),
        .I_weight_l         ({25'd0,S_pix_cnt,1'b0}),
        .I_weight_h         (27'd0),
        .I_1feature         ({9'd0,I_coGroup}),
        .I_pi_cas           ({16'd0,I_imgOutAddr}),
        .O_pi               (),
        .O_p                (S_wr_out_DDRaddr_tmp0)
        );
        
     dsp_unit1 dsp_unit_inst2(
       .I_clk              (I_clk),
       .I_weight_l         ({21'd0,S_wog_cnt}),
       .I_weight_h         (27'd0),
       .I_1feature         ({9'd0,I_coGroup}),
       .I_pi_cas           (48'd0),
       .O_pi               (),
       .O_p                (S_wr_out_DDRaddr_tmp1_t)
       );
       
     dsp_unit1 dsp_unit_inst3(
       .I_clk              (I_clk),
       .I_weight_l         (S_wr_out_DDRaddr_tmp1_t),
       .I_weight_h         (27'd0),
       .I_1feature         ({PIX,1'b0}),
       .I_pi_cas           ({39'd0,{S_cog_cnt_d6,1'b0}}),
       .O_pi               (),
       .O_p                (S_wr_out_DDRaddr_tmp1)
      );
   
     dsp_unit1 dsp_unit_inst4(
        .I_clk              (I_clk),
        .I_weight_l         ({21'd0,I_coGroup}),
        .I_weight_h         (27'd0),
        .I_1feature         ({9'd0,I_woGroup}),
        .I_pi_cas           (48'd0),
        .O_pi               (),
        .O_p                (S_wr_out_DDRaddr_tmp2_t0)
       );
   
     dsp_unit1 dsp_unit_inst5(
        .I_clk              (I_clk),
        .I_weight_l         ({20'd0,S_h}),
        .I_weight_h         (27'd0),
        .I_1feature         ({PIX,2'b00}),
        .I_pi_cas           (48'd0),
        .O_pi               (),
        .O_p                (S_wr_out_DDRaddr_tmp2_t1)
       );
       
     dsp_unit1 dsp_unit_inst6(
        .I_clk              (I_clk),
        .I_weight_l         (S_wr_out_DDRaddr_tmp2_t0),
        .I_weight_h         (27'd0),
        .I_1feature         (S_wr_out_DDRaddr_tmp2_t1),
        .I_pi_cas           ({44'd0,S_peCoDiv16_cnt_d6}),
        .O_pi               (),
        .O_p                (S_wr_out_DDRaddr_tmp2)
       );
                  
    always@ (posedge I_clk)
    begin
        S_wr_out_DDRaddr_tmp0_d1 <= S_wr_out_DDRaddr_tmp0;
        S_wr_out_DDRaddr_tmp0_d2 <= S_wr_out_DDRaddr_tmp0_d1;
        S_wr_out_DDRaddr_tmp0_d3 <= S_wr_out_DDRaddr_tmp0_d2;
        S_wr_out_DDRaddr_tmp0_d4 <= S_wr_out_DDRaddr_tmp0_d3;
    end
                              
    always@ (posedge I_clk)
    begin
//        S_wr_out_DDRaddr_tmp0 <= S_pix_cnt*I_coGroup;
//        S_wr_out_DDRaddr_tmp1 <= S_wog_cnt*PIX*I_coGroup;
//        S_wr_out_DDRaddr_tmp2 <= S_h*PIX*I_coGroup*2*I_woGroup;
//        S_wr_out_DDRaddr <= I_imgOutAddr + S_peCoDiv16_cnt_d1 + {S_wr_out_DDRaddr_tmp0[30:0],1'b0} + S_cog_cnt_d1*2 + {S_wr_out_DDRaddr_tmp1[30:0],1'b0}
//                                  + {S_wr_out_DDRaddr_tmp2[30:0],1'b0};
        S_wr_out_DDRaddr <=  S_wr_out_DDRaddr_tmp0_d4 + S_wr_out_DDRaddr_tmp1 + S_wr_out_DDRaddr_tmp2;
    end
                             
    always@ (posedge I_clk)
    begin
        S_wr_out_DDRaddr_d1 <= S_wr_out_DDRaddr;
    end
   
    assign O_wr_DDRaddr = S_wr_out_DDRaddr_d1;
    assign O_cnv_data = S_activeOut;
    always@ (posedge I_clk)
    begin
        O_cnv_dv <= S_process_en_d9;
    end
    
    reg      S_cnv_dv = 0;
    
    always@ (posedge I_clk)
    begin
        S_cnv_dv <= O_cnv_dv;
        
//        if (!S_cnv_dv && O_cnv_dv)
//            O_line_end <= 1'b0;
//        else if (O_line_end)
//            O_line_end <= 1'b0;
//        else if (S_cnv_dv && !O_cnv_dv)
//            O_line_end <= 1'b1;

        O_line_end <= I_wr_of;
    end    
    
    always@ (posedge I_clk)
        if (!S_pix_cnt_ch_d5 && S_pix_cnt_ch_d4)
            O_post_raddr <= S_depthIpbuf;

 /*
    reg [127:0]   S_obuf [1023:0];
    initial begin
    #18090
    repeat (910)
    begin
    @(posedge I_clk)
    begin
        if (O_cnv_dv)
            S_obuf[O_wr_DDRaddr-32'h2000_0000] <= O_cnv_data;
    end
    end
    end
   
    reg [31:0]    test_wr_out_addr;
    reg [127:0]   test_data_out;
    integer fp_test_wr;
    
    initial begin
    #27100
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
    fp_test_wr = $fopen("hls_dataOut0801.txt","w");
    #27100
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
    */
endmodule
