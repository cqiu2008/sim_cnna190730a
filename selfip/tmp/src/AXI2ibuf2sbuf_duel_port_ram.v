`timescale 1ns / 1ps

module AXI2ibuf2sbuf_update#(
    parameter                   AXIWIDTH      = 128,
    parameter                   LITEWIDTH     = 32,
    parameter                   W_WIDTH       = 10,
    parameter                   PIX           = 8,
    parameter                   RDB_PIX       = 2,
    parameter                   DEPTHWIDTH    = 9
)(
    input                       I_clk,
    input                       I_rst,
    input                       I_ap_start,
    input      [AXIWIDTH-1:0]   I_feature,
    input                       I_feature_dv,
    input                       I_hcnt_flag,
    input      [LITEWIDTH-1:0]  I_iheight,
    input      [LITEWIDTH-1:0]  I_iwidth,
    input      [W_WIDTH-1:0]    I_hindex,
    input                       I_compute_en,
    input      [4:0]  I_k_w,
    input      [4:0]  I_stride_w,
    input      [4:0]  I_pad_w,
    input      [DEPTHWIDTH-1:0] I_ciGroup,
    input      [7:0]  I_rd_fdepth,
    input                       I_rd_dv,
    output  reg                 O_f_rdy = 0,
    output  reg [AXIWIDTH*PIX-1:0]   O_feature_out = 0,
    output  reg                      O_feature_out_dv = 0
    );
    
    localparam  PWIDTH     = GETASIZE(PIX);
    localparam  RDB_PWIDTH = GETASIZE(RDB_PIX);
    localparam  IBUF_DEPTH = 1024;
    localparam  SBUF_DEPTH = 512;
    localparam  IBUFWIDTH  = GETASIZE(IBUF_DEPTH);
    
    ///  AXI TO IBUF
    
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
    reg      [6:0]      S_wog             = 0;
    reg      [5:0]      S_woc             = 0;
    reg      [6:0]      S_cig             = 0;
    reg      [W_WIDTH-3:0]      S_woConsume_pre   = 0;
    reg      [W_WIDTH-3:0]      S_woConsume       = 0;
    reg      [W_WIDTH-3:0]      S_woGroup         = 0;
    reg      [PWIDTH-1:0]       S_woHigh          = 0;
    reg      [7:0]      S_wPart           = 0;
    wire     [8:0]      S_w                  ;
    reg      [W_WIDTH-1:0]      S_wr_depth_cnt    = 0;
    
    wire     [7:0]      S_id[RDB_PIX-1:0]    ;
    wire     [W_WIDTH-1:0]      S_wIndex[RDB_PIX-1:0];
    wire     [W_WIDTH-1:0]      S_wRemainder[RDB_PIX-1:0];
    wire     [W_WIDTH-1:0]      S_ibufAddr[RDB_PIX-1:0];
    wire     [W_WIDTH-1:0]      S_wThreshold[PIX-1:0];
    wire     [W_WIDTH-1:0]      S_wIndex_minus0;
    wire     [W_WIDTH-1:0]      S_wIndex_minus1;
      
    reg [AXIWIDTH-1:0] ram_data_a = {AXIWIDTH{1'b0}};
    reg [AXIWIDTH-1:0] ram_data_b = {AXIWIDTH{1'b0}};

    
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
//        else if (I_hcnt_flag)
//            S_sbuf_trans_en <= 1'b0;
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
       S_woTotal <= ({I_pad_w[3:0],1'b0} + I_iwidth - I_k_w)/I_stride_w + 1;
       
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
        if (S_sbuf_trans_en /*&& S_load_en*/)
        begin
            if (S_cig == I_ciGroup-1)
                S_cig <= 'd0;
            else
                S_cig <= S_cig + 'd1;
        end
        
        if (S_sbuf_trans_en /*&& S_load_en*/)
        begin
            if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1)
                S_woc <= 'd0;
            else if (S_cig == I_ciGroup-1)
                S_woc <= S_woc + 'd1;
        end

        
        if (S_sbuf_trans_en /*&& S_load_en*/)
        begin
            if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1 && S_wog == S_woGroup-1)
                S_wog <= 'd0;
            else if (S_woc == S_woConsume-1 && S_cig == I_ciGroup-1)
                S_wog <= S_wog + 'd1;
        end
    end

    assign S_w = S_wog*S_woHigh + /*S_woc*2*/{S_woc[4:0],1'b0};
    
    /// ibuf to sbuf
    
    assign S_id[0] = S_split_en ? S_wog : (S_w+0)/S_wPart;
    assign S_id[1] = S_split_en ? S_wog : (S_w+1)/S_wPart;
    assign S_wIndex[0] = S_w+0-I_pad_w;
    assign S_wIndex[1] = S_w+1-I_pad_w;
    assign S_wRemainder[0] = (S_w+0)%S_wPart;
    assign S_wRemainder[1] = (S_w+1)%S_wPart; 
    assign S_ibufAddr[0] = S_wIndex[0]*I_ciGroup + S_cig;
    assign S_ibufAddr[1] = S_wIndex[1]*I_ciGroup + S_cig;
    assign S_wIndex_minus0 = S_wIndex[0] - I_iwidth;
    assign S_wIndex_minus1 = S_wIndex[1] - I_iwidth;
    
    genvar pix;
    generate for (pix=0; pix<PIX; pix=pix+1)
    begin:pix_loop
    
        (*ram_style="block"*)  reg   [AXIWIDTH-1:0] S_sbuf0 [SBUF_DEPTH-1:0];
        
        wire    [4:0]  S_idForPix0;
        wire    [4:0]  S_idForPix1;
        wire    [DEPTHWIDTH-1:0]  S_pFirst0;
        wire    [DEPTHWIDTH-1:0]  S_pFirst1;
        wire    [3:0]  S_k0;
        wire    [3:0]  S_k1;
        wire    [7:0]  S_depth0;
        wire    [7:0]  S_depth1;
        
        wire    [3:0]  S_k_minus0;
        wire    [3:0]  S_k_minus1;
        wire           S_op00,S_op10;
        wire           S_op01,S_op11;
        
        wire    [3:0]  S_wRemain_minus0;
        wire    [3:0]  S_wRemain_minus1;   
        
        assign S_wThreshold[pix] = pix*I_stride_w + I_k_w - PIX*I_stride_w;
        
        assign S_wRemain_minus0 = S_wRemainder[0]-S_wThreshold[pix];
        assign S_wRemain_minus1 = S_wRemainder[1]-S_wThreshold[pix];
        
        assign S_idForPix0 = (!S_id[0][7] && S_wRemain_minus0[3] && !S_split_en) ? S_id[0]-1 : S_id[0];
        assign S_idForPix1 = (!S_id[1][7] && S_wRemain_minus1[3] && !S_split_en) ? S_id[1]-1 : S_id[1];
        assign S_pFirst0 = S_idForPix0*S_wPart;
        assign S_pFirst1 = S_idForPix1*S_wPart;
        assign S_k0 = (S_w+0) - S_pFirst0 - pix*I_stride_w;
        assign S_k1 = (S_w+1) - S_pFirst1 - pix*I_stride_w;
        
        assign S_depth0 = S_idForPix0*I_k_w*I_ciGroup + S_k0*I_ciGroup + S_cig;
        assign S_depth1 = S_idForPix1*I_k_w*I_ciGroup + S_k1*I_ciGroup + S_cig;
        
        assign S_k_minus0 = S_k0 - I_k_w;
        assign S_k_minus1 = S_k1 - I_k_w;
        
        assign S_op00 = !S_k0[3] && S_k_minus0[3];
        assign S_op10 = !S_wIndex[0][W_WIDTH-1] && S_wIndex_minus0[W_WIDTH-1];
        assign S_op01 = !S_k1[3] && S_k_minus1[3];
        assign S_op11 = !S_wIndex[1][W_WIDTH-1] && S_wIndex_minus1[W_WIDTH-1];
        
        wire  [7:0] addra;
        wire  [7:0] addrb;
        
        assign addra = S_depth0;
        assign addrb = I_rd_dv ? I_rd_fdepth : S_depth1;
        
        
        always@ (posedge I_clk)
        begin
            if (S_op00 && !I_rd_dv)
            begin
                if (S_op10)
                    S_sbuf0[addra] <= S_ibuf0[S_ibufAddr[0]];
                else
                    S_sbuf0[addra] <= 'd0;
            end
        end       
        

        always@ (posedge I_clk)
        begin
            if (S_op01 && !I_rd_dv)
            begin
                if (S_op11)
                    S_sbuf0[addrb] <= S_ibuf0[S_ibufAddr[1]];
                else
                    S_sbuf0[addrb] <= 'd0;
            end
        end
        
            
        always@ (posedge I_clk)
        begin
            if (I_rd_dv)
                O_feature_out[pix*AXIWIDTH+:AXIWIDTH] <= S_sbuf0[addrb];
        end
        
    end //pix
    endgenerate
    
    always@ (posedge I_clk)
        O_feature_out_dv <= I_rd_dv;
    
    always@ (posedge I_clk)
    begin
        if (O_f_rdy)
            S_wr_depth_cnt <= 'd0;
        else if (S_sbuf_trans_en)
            S_wr_depth_cnt <= S_wr_depth_cnt + 'd1;
            
        if (S_wr_depth_cnt == S_woGroup && I_compute_en)
            O_f_rdy <= 1'b1;
        else
            O_f_rdy <= 1'b0;
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