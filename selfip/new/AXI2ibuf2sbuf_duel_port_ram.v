`timescale 1ns / 1ps

module AXI2ibuf2sbuf_update#(
    parameter                        AXIWIDTH      = 128,
    parameter                        LITEWIDTH     = 32,
    parameter                        W_WIDTH       = 10,
    parameter                        PIX           = 8,
    parameter                        RDB_PIX       = 2,
    parameter                        DEPTHWIDTH    = 9
)(
    input                            I_clk,
    input                            I_rst,
    input                            I_ap_start,
    input      [AXIWIDTH-1:0]        I_feature,
    input                            I_feature_dv,
    input                            I_hcnt_flag,
    input      [LITEWIDTH-1:0]       I_iheight,
    input      [LITEWIDTH-1:0]       I_iwidth,
    input      [W_WIDTH-1:0]         I_hindex,
    input                            I_compute_en,
    input      [4:0]                 I_k_w,
    input      [4:0]                 I_stride_w,
    input      [4:0]                 I_pad_w,
    input      [DEPTHWIDTH-1:0]      I_ciGroup,
    input      [7:0]                 I_rd_fdepth,
    input                            I_rd_dv,
    output  reg                      O_f_rdy = 0,
    output  reg [AXIWIDTH*PIX-1:0]   O_feature_out = 0,
    output  reg                      O_feature_out_dv = 0
    );
    
    localparam  PWIDTH     = GETASIZE(PIX);
    localparam  RDB_PWIDTH = GETASIZE(RDB_PIX);
    localparam  IBUF_DEPTH = 1024;
    localparam  SBUF_DEPTH = 512;
    localparam  IBUFWIDTH  = GETASIZE(IBUF_DEPTH);
    
    ///  AXI TO IBUF
    reg                         S_rd_dv           = 0;
    reg      [7:0]              S_rd_fdepth       = 0;
    reg                         S_rd_dv_d2        = 0;
    reg                         S_rd_dv_d3        = 0;
    reg                         S_rd_dv_d4        = 0;
    reg                         S_rd_dv_d5        = 0;
    reg                         S_rd_dv_d6        = 0;
    reg                         S_rd_dv_d7        = 0;
    reg                         S_rd_dv_d8        = 0;
    reg                         S_rd_dv_d9        = 0;
    reg                         S_rd_dv_d10       = 0;
    reg                         S_rd_dv_d11       = 0;
    reg      [7:0]              S_rd_fdepth_d2    = 0;
    reg                         S_ap_start        = 0;
    reg                         S_buf_ch          = 0;
    (*ram_style="block"*)  reg   [AXIWIDTH-1:0]     S_ibuf0 [IBUF_DEPTH-1:0];
    (*ram_style="block"*)  reg   [AXIWIDTH-1:0]     S_ibuf1 [IBUF_DEPTH-1:0];
    reg      [AXIWIDTH-1:0]     S_feature         = 0;
    reg                         S_ibuf_wr_en      = 0;
    reg      [IBUFWIDTH-1:0]    S_ibuf_wr_addr    = 0;
    reg                         S_sbuf_trans_en   = 0;
    reg      [LITEWIDTH-1:0]    S_split_minus     = 0;
    reg                         S_split_en        = 0;
    reg      [LITEWIDTH-1:0]    S_woTotal_pre     = 0;
    reg      [W_WIDTH-1:0]      S_woTotal         = 0;
    reg      [W_WIDTH-1:0]      S_minus_h         = 0;
    reg      [W_WIDTH-1:0]      S_hindex          = 0;
    reg                         S_load_en         = 0;
    reg      [6:0]              S_wog             = 0;
    reg      [6:0]              S_wog_d0          = 0;
    reg      [6:0]              S_wog_d1          = 0;
    reg      [6:0]              S_wog_d2          = 0;
    reg      [6:0]              S_wog_d3          = 0;
    reg      [5:0]              S_woc             = 0;
    reg      [6:0]              S_cig             = 0;
    reg      [6:0]              S_cig_d1          = 0;
    reg      [6:0]              S_cig_d2          = 0;
    reg      [6:0]              S_cig_d3          = 0;
    reg      [6:0]              S_cig_d4          = 0;
    reg      [6:0]              S_cig_d5          = 0;
    reg      [W_WIDTH-3:0]      S_woConsume_pre   = 0;
    reg      [W_WIDTH-3:0]      S_woConsume       = 0;
    reg      [W_WIDTH-3:0]      S_woGroup         = 0;
    reg      [PWIDTH-1:0]       S_woHigh          = 0;
    reg      [7:0]              S_wPart           = 0;
    reg      [7:0]              S_wPart_d1        = 0;
    wire     [47:0]             S_w                  ;
    reg      [8:0]              S_w_d1            = 0;
    reg      [8:0]              S_w_d2            = 0;
    reg      [8:0]              S_w_d3            = 0;
    reg      [8:0]              S_w_d4            = 0;
    reg      [8:0]              S_w_d5            = 0;
    reg      [8:0]              S_w_d6            = 0;
    reg      [8:0]              S_w_d7            = 0;
    reg      [8:0]              S_w_d8            = 0;
    reg      [8:0]              S_w_d9            = 0;
    reg      [8:0]              S_w_d10           = 0;
    reg      [W_WIDTH-1:0]      S_wr_depth_cnt    = 0;
    
    reg      [W_WIDTH-1:0]      S_wIndex_minus0   = 0;
    reg      [W_WIDTH-1:0]      S_wIndex_minus1   = 0;
    wire     [W_WIDTH-1:0]      S_wThreshold_adder;
    wire     [7:0]              S_depth_adder;
    reg      [7:0]              S_depth_adder_d1=0;

    reg      [7:0]              S_id[RDB_PIX-1:0];
    reg      [7:0]              S_id_d0[RDB_PIX-1:0];
    reg      [7:0]              S_id_d1[RDB_PIX-1:0];
    reg      [7:0]              S_id_d2[RDB_PIX-1:0];
    reg      [7:0]              S_id_d3[RDB_PIX-1:0];
    reg      [7:0]              S_id_d4[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wIndex[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wIndex_d0[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wIndex_d1[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wIndex_d2[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wIndex_d3[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wRemainder[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wRemainder_d0[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wRemainder_d1[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wRemainder_d2[RDB_PIX-1:0];
    reg      [W_WIDTH-1:0]      S_wRemainder_d3[RDB_PIX-1:0];
    
    
    wire     [47:0]             S_ibufAddr[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d0[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d1[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d2[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d3[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d4[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d5[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d6[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d7[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d8[RDB_PIX-1:0];
    reg      [9:0]              S_ibufAddr_d9[RDB_PIX-1:0];
    
    wire     [47:0]             S_wThreshold[PIX-1:0];
    
    wire     [7:0]              S_q0;
    wire     [7:0]              S_r0;
    wire     [7:0]              S_q1;
    wire     [7:0]              S_r1;
    
    reg      S_f_rdy=0;
    reg      S_f_rdy_d1,S_f_rdy_d2,S_f_rdy_d3,S_f_rdy_d4,S_f_rdy_d5,S_f_rdy_d6,S_f_rdy_d7,S_f_rdy_d8,S_f_rdy_d9,S_f_rdy_d10,S_f_rdy_d11,S_f_rdy_d12;
    
    always@ (posedge I_clk)
    begin
        S_rd_dv <= I_rd_dv;
        S_rd_dv_d2 <= S_rd_dv;
        S_rd_dv_d3 <= S_rd_dv_d2;
        S_rd_dv_d4 <= S_rd_dv_d3;
        S_rd_dv_d5 <= S_rd_dv_d4;
        S_rd_dv_d6 <= S_rd_dv_d5;
        S_rd_dv_d7 <= S_rd_dv_d6;
        S_rd_dv_d8 <= S_rd_dv_d7;
        S_rd_dv_d9 <= S_rd_dv_d8;
        S_rd_dv_d10 <= S_rd_dv_d9;
        S_rd_dv_d11 <= S_rd_dv_d10;
        
        S_rd_fdepth <= I_rd_fdepth;
        S_rd_fdepth_d2 <= S_rd_fdepth;
    end
    
    always@ (posedge I_clk)
    begin
        if (I_feature_dv)
            S_ibuf_wr_en <= 1'b1;
        else
            S_ibuf_wr_en <= 1'b0;
            
        if (O_f_rdy)
            S_ibuf_wr_addr <= 'd0;
        else if (S_ibuf_wr_en)
            S_ibuf_wr_addr <= S_ibuf_wr_addr + 'd1;
            
        S_feature <= I_feature;
            
        if (S_ibuf_wr_en)
            S_ibuf0[S_ibuf_wr_addr] <= S_feature;
    end
    
    
    always@ (posedge I_clk)
    begin
        S_ap_start <= I_ap_start;
    
        if (~S_ap_start && I_ap_start)
            S_sbuf_trans_en <= 1'b0;
        else if (O_f_rdy && S_ibuf_wr_addr == I_iwidth)
            S_sbuf_trans_en <= 1'b0;
        else if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1 && S_wog == S_woGroup-1)
            S_sbuf_trans_en <= 1'b0;
        else if (S_ibuf_wr_addr == I_iwidth-'d1)
            S_sbuf_trans_en <= 1'b1;
    end
    
    /// if (hindex>=0 && hindex<iheight && line-change)


   always@ (posedge I_clk)
   begin
       S_split_minus <= I_stride_w<<PWIDTH - I_k_w;
       S_split_en <= S_split_minus[LITEWIDTH-1];
   end
   
   always@ (posedge I_clk)
   begin
       S_woTotal_pre <= {I_pad_w[3:0],1'b0} + I_iwidth;
//       S_woTotal <= ({I_pad_w[3:0],1'b0} + I_iwidth - I_k_w)/I_stride_w + 1;
       S_woTotal <= ({I_pad_w[3:0],1'b0} + I_iwidth - I_k_w) + 1;
       
       if (S_split_en)
           S_woGroup <= !(|S_woTotal[PWIDTH-1:0]) ? S_woTotal >> PWIDTH : S_woTotal >> PWIDTH + 1;
       else 
           S_woGroup <= !(|S_woTotal_pre[RDB_PWIDTH-1:0]) ? S_woTotal_pre >> RDB_PWIDTH : S_woTotal_pre >> RDB_PWIDTH + 1;
   
       S_woConsume_pre <= (PIX-1)*I_stride_w + I_k_w;
       
       if (S_split_en)
           S_woConsume <= !(|S_woConsume_pre[RDB_PWIDTH-1:0]) ? S_woConsume_pre >> RDB_PWIDTH : S_woConsume_pre >> RDB_PWIDTH + 1;
       else 
           S_woConsume <= 'd1;
           
       if (S_split_en)
           S_woHigh <= PIX;
       else
           S_woHigh <= RDB_PIX;
           
       S_wPart <= I_stride_w<<PWIDTH;
       //S_wPart_d1 <= S_wPart;
   end

    always@ (posedge I_clk)
    begin
        S_hindex <= I_hindex;
        
        if (~S_ap_start && I_ap_start)
            S_minus_h <= 'd0;
        else 
            S_minus_h <= I_hindex - I_iheight;
            
            
        if (~S_ap_start && I_ap_start)
            S_load_en <= 'd0;
        else if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1 && S_wog == S_woGroup-1)
            S_load_en <= 'd0;
        else if (I_compute_en && !I_hindex[W_WIDTH-1] && S_minus_h[W_WIDTH-1] && (S_hindex[0]^I_hindex[0]))
            S_load_en <= 'd1;         
    end

    /// cig ,woc, wog count
    
   always@ (posedge I_clk)
    begin
        S_cig_d1 <= S_cig;
        S_cig_d2 <= S_cig_d1;
        S_cig_d3 <= S_cig_d2;
        S_cig_d4 <= S_cig_d3;
        S_cig_d5 <= S_cig_d4;
        if (S_sbuf_trans_en)
        begin
            if (S_cig == I_ciGroup-1)
                S_cig <= 'd0;
            else
                S_cig <= S_cig + 'd1;
        end
        
        if (S_sbuf_trans_en)
        begin
            if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1)
                S_woc <= 'd0;
            else if (S_cig == I_ciGroup-1)
                S_woc <= S_woc + 'd1;
        end

        S_wog_d0 <= S_wog;
        S_wog_d1 <= S_wog_d0;
        S_wog_d2 <= S_wog_d1;
        S_wog_d3 <= S_wog_d2;
        if (S_sbuf_trans_en)
        begin
            if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1 && S_wog == S_woGroup-1)
                S_wog <= 'd0;
            else if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1)
                S_wog <= S_wog + 'd1;
        end
    end
    
    
    wire  [17:0]   S_neg_stride;
    assign S_neg_stride = {1'b1,12'b1111_1111_1111,{~I_stride_w+1}};
    
    dsp_unit1 dsp_unit0(
        .I_clk         (I_clk),
        .I_weight_l    ({23'd0,S_wog}),
        .I_weight_h    ('d0),
        .I_1feature    ({15'd0,S_woHigh}),
        .I_pi_cas      ({42'd0,S_woc[4:0],1'b0}),
        .O_pi          (),
        .O_p           (S_w)
        );

    dsp_unit1 dsp_unit1(
        .I_clk         (I_clk),
        .I_weight_l    ({30'd0,PIX}),
        .I_weight_h    ('d0),
        .I_1feature    (S_neg_stride),
        .I_pi_cas      ({43'd0,I_k_w}),
        .O_pi          (),
        .O_p           (S_wThreshold_adder)
        );

    dsp_unit1 dsp_unit2(
        .I_clk         (I_clk),
        .I_weight_l    ({25'd0,I_k_w}),
        .I_weight_h    ('d0),
        .I_1feature    ({9'd0,I_ciGroup}),
        .I_pi_cas      ('d0),
        .O_pi          (),
        .O_p           (S_depth_adder)
        );

//    assign S_w = S_wog*S_woHigh + {S_woc[4:0],1'b0};
//    assign S_wThreshold_adder = I_k_w - PIX*I_stride_w;
//    assign S_depth_adder = I_k_w*I_ciGroup;
    
    always@ (posedge I_clk)
    begin
        S_w_d1 <= S_w;
        S_w_d2 <= S_w_d1;
        S_w_d3 <= S_w_d2;
        S_w_d4 <= S_w_d3;
        S_w_d5 <= S_w_d4;
        S_w_d6 <= S_w_d5;
        S_w_d7 <= S_w_d6;
        S_w_d8 <= S_w_d7;
        S_w_d9 <= S_w_d8;
        S_w_d10 <= S_w_d9;
        S_depth_adder_d1 <= S_depth_adder;
    end
    /// ibuf to sbuf
    
    dsp_unit1 dsp_unit3(
        .I_clk         (I_clk),
        .I_weight_l    ({20'd0,S_wIndex[0]}),
        .I_weight_h    ('d0),
        .I_1feature    ({9'd0,I_ciGroup}),
        .I_pi_cas      ({41'd0,S_cig_d5}),
        .O_pi          (),
        .O_p           (S_ibufAddr[0])
        );
        
    dsp_unit1 dsp_unit4(
        .I_clk         (I_clk),
        .I_weight_l    ({20'd0,S_wIndex[1]}),
        .I_weight_h    ('d0),
        .I_1feature    ({9'd0,I_ciGroup}),
        .I_pi_cas      ({41'd0,S_cig_d5}),
        .O_pi          (),
        .O_p           (S_ibufAddr[1])
    );
    
    always@ (posedge I_clk)
    begin
        S_ibufAddr_d0[0] <= S_ibufAddr[0];
        S_ibufAddr_d0[1] <= S_ibufAddr[1];
        S_ibufAddr_d1[0] <= S_ibufAddr_d0[0];
        S_ibufAddr_d1[1] <= S_ibufAddr_d0[1];
        S_ibufAddr_d2[0] <= S_ibufAddr_d1[0];
        S_ibufAddr_d2[1] <= S_ibufAddr_d1[1];
        S_ibufAddr_d3[0] <= S_ibufAddr_d2[0];
        S_ibufAddr_d3[1] <= S_ibufAddr_d2[1];
        S_ibufAddr_d4[0] <= S_ibufAddr_d3[0];
        S_ibufAddr_d4[1] <= S_ibufAddr_d3[1];
        S_ibufAddr_d5[0] <= S_ibufAddr_d4[0];
        S_ibufAddr_d5[1] <= S_ibufAddr_d4[1];
        S_ibufAddr_d6[0] <= S_ibufAddr_d5[0];
        S_ibufAddr_d6[1] <= S_ibufAddr_d5[1];
        S_ibufAddr_d7[0] <= S_ibufAddr_d6[0];
        S_ibufAddr_d7[1] <= S_ibufAddr_d6[1];
        S_ibufAddr_d8[0] <= S_ibufAddr_d7[0];
        S_ibufAddr_d8[1] <= S_ibufAddr_d7[1];  
        S_ibufAddr_d9[0] <= S_ibufAddr_d8[0];
        S_ibufAddr_d9[1] <= S_ibufAddr_d8[1];       
    end
    
    always@ (posedge I_clk)
    begin
//        S_id[0] <= S_split_en ? S_wog : (S_w+0)/S_wPart;
//        S_id[1] <= S_split_en ? S_wog : (S_w+1)/S_wPart;
        S_id[0] <= S_split_en ? S_wog_d3 : (S_w+0)>>3;
        S_id[1] <= S_split_en ? S_wog_d3 : (S_w+1)>>3;
        S_id_d0[0] <= S_id[0];
        S_id_d0[1] <= S_id[1];
        S_id_d1[0] <= S_id_d0[0];
        S_id_d1[1] <= S_id_d0[1];
        S_id_d2[0] <= S_id_d1[0];
        S_id_d2[1] <= S_id_d1[1];
        S_id_d3[0] <= S_id_d2[0];
        S_id_d3[1] <= S_id_d2[1];
        S_id_d4[0] <= S_id_d3[0];
        S_id_d4[1] <= S_id_d3[1];
        
        S_wIndex[0] <= S_w+0-I_pad_w;
        S_wIndex[1] <= S_w+1-I_pad_w;
        S_wIndex_d0[0] <= S_wIndex[0];
        S_wIndex_d0[1] <= S_wIndex[1];
        S_wIndex_d1[0] <= S_wIndex_d0[0];
        S_wIndex_d1[1] <= S_wIndex_d0[1];
        S_wIndex_d2[0] <= S_wIndex_d1[0];
        S_wIndex_d2[1] <= S_wIndex_d1[1];
        S_wIndex_d3[0] <= S_wIndex_d2[0];
        S_wIndex_d3[1] <= S_wIndex_d2[1];
        
//        S_wRemainder[0] <= (S_w+0)%S_wPart;
//        S_wRemainder[1] <= (S_w+1)%S_wPart; 
        S_wRemainder[0] <= (S_w+0)&9'b00000_0111;
        S_wRemainder[1] <= (S_w+1)&9'b00000_0111; 
        S_wRemainder_d0[0] <= S_wRemainder[0];
        S_wRemainder_d0[1] <= S_wRemainder[1];
        S_wRemainder_d1[0] <= S_wRemainder_d0[0];
        S_wRemainder_d1[1] <= S_wRemainder_d0[1];
        S_wRemainder_d2[0] <= S_wRemainder_d1[0];
        S_wRemainder_d2[1] <= S_wRemainder_d1[1];
        S_wRemainder_d3[0] <= S_wRemainder_d2[0];
        S_wRemainder_d3[1] <= S_wRemainder_d2[1];
    end

//    assign S_wIndex_minus0 = S_wIndex[0] - I_iwidth;
//    assign S_wIndex_minus1 = S_wIndex[1] - I_iwidth;
    
    always@ (posedge I_clk)
    begin
        S_wIndex_minus0 <= S_wIndex[0] - I_iwidth;
        S_wIndex_minus1 <= S_wIndex[1] - I_iwidth;
    end
    
    
    genvar pix;
    generate for (pix=0; pix<PIX; pix=pix+1)
    begin:pix_loop
    
        (*ram_style="block"*)  reg   [AXIWIDTH-1:0] S_sbuf0 [SBUF_DEPTH-1:0];
        reg     [AXIWIDTH-1:0]  S_buf0_dout=0;
        
        wire    [4:0]  S_idForPix0;
        wire    [4:0]  S_idForPix1;
        reg     [4:0]  S_idForPix0_d0=0;
        reg     [4:0]  S_idForPix1_d0=0;
        reg     [4:0]  S_idForPix0_d1=0;
        reg     [4:0]  S_idForPix1_d1=0;
        reg     [4:0]  S_idForPix0_d2=0;
        reg     [4:0]  S_idForPix1_d2=0;
        reg     [4:0]  S_idForPix0_d3=0;
        reg     [4:0]  S_idForPix1_d3=0;
        reg     [4:0]  S_idForPix0_d4=0;
        reg     [4:0]  S_idForPix1_d4=0;
        reg     [4:0]  S_idForPix0_d5=0;
        reg     [4:0]  S_idForPix1_d5=0;
        reg     [4:0]  S_idForPix0_d6=0;
        reg     [4:0]  S_idForPix1_d6=0;
        wire    [47:0] S_pFirst0;
        wire    [47:0] S_pFirst1;
        reg     [47:0] S_pFirst0_d0=0;
        reg     [47:0] S_pFirst1_d0=0;
        reg     [47:0] S_pFirst0_d1=0;
        reg     [47:0] S_pFirst1_d1=0;
        reg     [47:0] S_pFirst0_d2=0;
        reg     [47:0] S_pFirst1_d2=0;
        wire    [47:0] S_k_tmp;
        reg     [3:0]  S_k0=0;
        reg     [3:0]  S_k1=0;
        reg     [3:0]  S_k0_d0=0;
        reg     [3:0]  S_k1_d0=0;
        reg     [7:0]  S_depth0=0;
        reg     [7:0]  S_depth1=0;
        reg     [3:0]  S_k_minus0=0;
        reg     [3:0]  S_k_minus1=0;
        reg            S_op00=0,S_op10=0;
        reg            S_op00_d0=0,S_op01_d0=0;
        reg            S_op01=0,S_op11=0;
        reg            S_op10_d0=0,S_op10_d1=0,S_op10_d2=0,S_op10_d3=0,S_op10_d4=0,S_op10_d5=0,S_op10_d6=0,S_op10_d7=0,S_op10_d8=0,S_op10_d9=0,S_op10_d10=0,S_op10_d11=0,S_op10_d12=0,S_op10_d13=0;
        reg            S_op11_d0=0,S_op11_d1=0,S_op11_d2=0,S_op11_d3=0,S_op11_d4=0,S_op11_d5=0,S_op11_d6=0,S_op11_d7=0,S_op11_d8=0,S_op11_d9=0,S_op11_d10=0,S_op11_d11=0,S_op11_d12=0;
        reg     [3:0]  S_wRemain_minus0=0;
        reg     [3:0]  S_wRemain_minus1=0;   
        
//        always@ (posedge I_clk)
//            S_wThreshold[pix] = pix*I_stride_w + S_wThreshold_adder;
            
        dsp_unit1 dsp_unit5(
            .I_clk         (I_clk),
            .I_weight_l    ({16'd0,pix}),
            .I_weight_h    ('d0),
            .I_1feature    ({13'd0,I_stride_w}),
            .I_pi_cas      (S_wThreshold_adder),
            .O_pi          (),
            .O_p           (S_wThreshold[pix])
        );
        
//        assign S_wRemain_minus0 = S_wRemainder_d3[0]-S_wThreshold[pix];
//        assign S_wRemain_minus1 = S_wRemainder_d3[1]-S_wThreshold[pix];
        
        always@ (posedge I_clk)
        begin
            S_wRemain_minus0 <= S_wRemainder_d3[0]-S_wThreshold[pix][9:0];
            S_wRemain_minus1 <= S_wRemainder_d3[1]-S_wThreshold[pix][9:0];
        end
        
        dsp_unit1 dsp_unit6(
            .I_clk         (I_clk),
            .I_weight_l    ({{(25){S_idForPix0[4]}},{S_idForPix0}}),
            .I_weight_h    ('d0),
            .I_1feature    ({{10{S_wPart[7]}},S_wPart}),
            .I_pi_cas      (48'd0),
            .O_pi          (),
            .O_p           (S_pFirst0)
        );
        
        dsp_unit1 dsp_unit7(
            .I_clk         (I_clk),
            .I_weight_l    ({{(25){S_idForPix1[4]}},{S_idForPix1}}),
            .I_weight_h    ('d0),
            .I_1feature    ({{10{S_wPart[7]}},S_wPart}),
            .I_pi_cas      (48'd0),
            .O_pi          (),
            .O_p           (S_pFirst1)
        );
                
        dsp_unit1 dsp_unit8(
            .I_clk         (I_clk),
            .I_weight_l    (pix),
            .I_weight_h    ('d0),
            .I_1feature    (S_neg_stride),
            .I_pi_cas      ({39'd0,S_w_d10}),
            .O_pi          (),
            .O_p           (S_k_tmp)
        );
        
        always@ (posedge I_clk)
        begin
            S_pFirst0_d0 <= S_pFirst0;
            S_pFirst1_d0 <= S_pFirst1;
            S_pFirst0_d1 <= S_pFirst0_d0;
            S_pFirst1_d1 <= S_pFirst1_d0;
            S_pFirst0_d2 <= S_pFirst0_d1;
            S_pFirst1_d2 <= S_pFirst1_d1;
        
            S_k0 <= S_k_tmp - S_pFirst0_d1;
            S_k1 <= S_k_tmp - S_pFirst1_d1 + 1;
        end
        
        
        assign S_idForPix0 = (!S_id_d4[0][7] && S_wRemain_minus0[3] && !S_split_en) ? S_id_d4[0]-1 : S_id_d4[0];
        assign S_idForPix1 = (!S_id_d4[1][7] && S_wRemain_minus1[3] && !S_split_en) ? S_id_d4[1]-1 : S_id_d4[1];
//        assign S_pFirst0 = S_idForPix0*S_wPart_d1;
//        assign S_pFirst1 = S_idForPix1*S_wPart_d1;
//        assign S_k0 = (S_w_d10+0) - S_pFirst0 - pix*I_stride_w;
//        assign S_k1 = (S_w_d10+1) - S_pFirst1 - pix*I_stride_w;

        always@ (posedge I_clk)
        begin
            S_idForPix0_d0 <= S_idForPix0;
            S_idForPix1_d0 <= S_idForPix1;
            S_idForPix0_d1 <= S_idForPix0_d0;
            S_idForPix1_d1 <= S_idForPix1_d0;
            S_idForPix0_d2 <= S_idForPix0_d1;
            S_idForPix1_d2 <= S_idForPix1_d1;
            S_idForPix0_d3 <= S_idForPix0_d2;
            S_idForPix1_d3 <= S_idForPix1_d2;
            S_idForPix0_d4 <= S_idForPix0_d3;
            S_idForPix1_d4 <= S_idForPix1_d3;
            S_idForPix0_d5 <= S_idForPix0_d4;
            S_idForPix1_d5 <= S_idForPix1_d4;
            S_idForPix0_d6 <= S_idForPix0_d5;
            S_idForPix1_d6 <= S_idForPix1_d5;
        end
        
        always@ (posedge I_clk)
        begin
            S_depth0 <= S_idForPix0_d6*S_depth_adder_d1 + S_k0*I_ciGroup + S_cig_d5;
            S_depth1 <= S_idForPix1_d6*S_depth_adder_d1 + S_k1*I_ciGroup + S_cig_d5;
        end
        
//        assign S_k_minus0 = S_k0 - I_k_w;
//        assign S_k_minus1 = S_k1 - I_k_w;
        
        always@ (posedge I_clk)
        begin
            S_k_minus0 <= S_k0 - I_k_w;
            S_k_minus1 <= S_k1 - I_k_w;
        end
        
        always@ (posedge I_clk)
        begin
            S_k0_d0 <= S_k0;
            S_k1_d0 <= S_k1;
        end
        
        always@ (posedge I_clk)
        begin
            S_op00 <= !S_k0_d0[3] && S_k_minus0[3];
            S_op10 <= !S_wIndex[0][W_WIDTH-1] && S_wIndex_minus0[W_WIDTH-1];
            S_op01 <= !S_k1_d0[3] && S_k_minus1[3];
            S_op11 <= !S_wIndex[1][W_WIDTH-1] && S_wIndex_minus1[W_WIDTH-1];          
        end
        
        always@ (posedge I_clk)
        begin
            S_op10_d0 <= S_op10;
            S_op10_d1 <= S_op10_d0;
            S_op10_d2 <= S_op10_d1;
            S_op10_d3 <= S_op10_d2;
            S_op10_d4 <= S_op10_d3;
            S_op10_d5 <= S_op10_d4;
            S_op10_d6 <= S_op10_d5;
            S_op10_d7 <= S_op10_d6;
            S_op10_d8 <= S_op10_d7;
            S_op10_d9 <= S_op10_d8;
            S_op10_d10 <= S_op10_d9;
            S_op10_d11 <= S_op10_d10;
            S_op10_d12 <= S_op10_d11;
            S_op10_d13 <= S_op10_d12;
            
            S_op11_d0 <= S_op11;
            S_op11_d1 <= S_op11_d0;
            S_op11_d2 <= S_op11_d1;
            S_op11_d3 <= S_op11_d2;
            S_op11_d4 <= S_op11_d3;
            S_op11_d5 <= S_op11_d4;
            S_op11_d6 <= S_op11_d5;
            S_op11_d7 <= S_op11_d6;
            S_op11_d8 <= S_op11_d7;
            S_op11_d9 <= S_op11_d8;
            S_op11_d10 <= S_op11_d9;
            S_op11_d11 <= S_op11_d10;
            S_op11_d12 <= S_op11_d11;
        end
        
        reg   [7:0] addra=0;
        reg   [7:0] addra_d0;
        reg   [7:0] addrb=0;
        reg   [7:0] addrb_d0;
        
        always@ (posedge I_clk)
        begin
            addra <= S_depth0;
            addra_d0 <= addra;
        end
        
        always@ (posedge I_clk)
        begin
            addrb <= S_rd_dv_d2 ? S_rd_fdepth_d2 : S_depth1;
            addrb_d0 <= addrb;
        end
        
        reg   [127:0]   datatmp0=0;
        reg   [127:0]   datatmp1=0;


        always@ (posedge I_clk)
        begin
//            if (S_op00 && S_op10_d12 && !S_rd_dv_d2)
                datatmp0 <= S_ibuf0[S_ibufAddr_d9[0]];
//            else if (S_op00 && !S_rd_dv_d2)
//                datatmp0 <= 'd0;
        end
        
        always@ (posedge I_clk)
        begin
//            if (S_op01 && S_op11_d11 && !S_rd_dv_d2)
                datatmp1 <= S_ibuf0[S_ibufAddr_d9[1]];
//            else if (S_op01 && !S_rd_dv_d2)
//                datatmp1 <= 'd0;
        end
        
        always@ (posedge I_clk)
        begin
            S_op00_d0 <= S_op00;
            S_op01_d0 <= S_op01;
        end
        
        always@ (posedge I_clk)
        begin
            if (S_op00_d0 && S_op10_d13 && !S_rd_dv_d3)
                S_sbuf0[addra_d0] <= datatmp0;
            else if (S_op00_d0 && !S_rd_dv_d3)
                S_sbuf0[addra_d0] <= 'd0;
        end
        
        always@ (posedge I_clk)
        begin
            if (S_op01_d0 && S_op11_d12 && !S_rd_dv_d3)
                S_sbuf0[addrb_d0] <= datatmp1;
            else if (S_op01_d0 && !S_rd_dv_d3)
                S_sbuf0[addrb_d0] <= 'd0;
        end
        
        always@ (posedge I_clk)
            S_buf0_dout <= S_sbuf0[addrb_d0];
            
            
        always@ (posedge I_clk)
        begin
            if (S_rd_dv_d5)
                O_feature_out[pix*AXIWIDTH+:AXIWIDTH] <= S_buf0_dout;    
        end
        
    end //pix
    endgenerate
    
    always@ (posedge I_clk)
//        O_feature_out_dv <= I_rd_dv;
        O_feature_out_dv <= S_rd_dv_d2;
    
    always@ (posedge I_clk)
    begin
        if (O_f_rdy)
            S_wr_depth_cnt <= 'd0;
        else if (S_sbuf_trans_en)
            S_wr_depth_cnt <= S_wr_depth_cnt + 'd1;
            
            
        S_f_rdy_d1 <= S_f_rdy;
        S_f_rdy_d2 <= S_f_rdy_d1;
        S_f_rdy_d3 <= S_f_rdy_d2;
        S_f_rdy_d4 <= S_f_rdy_d3;
        S_f_rdy_d5 <= S_f_rdy_d4;
        S_f_rdy_d6 <= S_f_rdy_d5;
        S_f_rdy_d7 <= S_f_rdy_d6;
        S_f_rdy_d8 <= S_f_rdy_d7;
        S_f_rdy_d9 <= S_f_rdy_d8;
        S_f_rdy_d10 <= S_f_rdy_d9;
        S_f_rdy_d11 <= S_f_rdy_d10;
        S_f_rdy_d12 <= S_f_rdy_d11;
        O_f_rdy <= S_f_rdy_d12;
            
        if (S_wr_depth_cnt == S_woGroup && I_compute_en)
            S_f_rdy <= 1'b1;
        else
            S_f_rdy <= 1'b0;
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