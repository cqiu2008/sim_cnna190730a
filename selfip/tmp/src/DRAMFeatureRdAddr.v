`timescale 1ns / 1ps

module DRAMFeatureRdAddr#(
    parameter                  W_WIDTH     = 10,
    parameter                  LITEWIDTH   = 32,
    parameter                  DEPTHWIDTH  = 9,
    parameter                  AXIWIDTH    = 128
)(
    input                          I_clk,
    input                          I_rst,
    input                          I_ap_start,
    input                          I_f_rdy,
    input       [DEPTHWIDTH:0]     I_ciAlign,
    input       [DEPTHWIDTH-1:0]   I_ciMemGroup,
    input       [LITEWIDTH-1:0]    I_feature_base_addr,
    input       [W_WIDTH-1:0]      I_hindex,
    input                          I_compute_en,
    input       [W_WIDTH-1:0]      I_iheight,
    input       [W_WIDTH-1:0]      I_iwidth,
    output reg  [LITEWIDTH-1:0]    O_dram_feature_rd_addr,
    output reg                     O_dram_feature_rd_flag
    );
    
   reg                         S_ap_start       = 0;
   reg                         S_f_rdy          = 0;
   reg                         S_ap_start_d1    = 0;
   reg      [LITEWIDTH-1:0]    S_base_addr_buf0 = 0;
   reg      [LITEWIDTH-1:0]    S_base_addr_buf1 = 0;
   reg                         S_buf_ch         = 0;
   
   always@ (posedge I_clk)
   begin
       S_ap_start <= I_ap_start;
       S_ap_start_d1 <= S_ap_start;
       
       if (!S_ap_start_d1 && S_ap_start && !I_compute_en)
           S_buf_ch <= 1'b0;
       else if(!S_ap_start_d1 && S_ap_start)
           S_buf_ch <= !S_buf_ch;
           
       if (S_ap_start_d1 && !S_ap_start && !S_buf_ch)
           S_base_addr_buf0 <= I_feature_base_addr;
           
       if (S_ap_start_d1 && !S_ap_start && S_buf_ch)
           S_base_addr_buf1 <= I_feature_base_addr;
   end
   
    
   reg      [W_WIDTH-1:0]      S_minus_h         = 0;
   reg      [W_WIDTH-1:0]      S_hindex          = 0;
   reg                         S_load_flag       = 0;
   reg      [W_WIDTH+5:0]      S_linewidth_div16 = 0;
   
   always@ (posedge I_clk)
   begin
       S_hindex <= I_hindex;
       
       if (~S_ap_start && I_ap_start)
           S_minus_h <= 'd0;
       else 
           S_minus_h <= I_iheight - I_hindex;
           
       S_load_flag <= !I_hindex[W_WIDTH-1] && !S_minus_h[W_WIDTH-1] && (S_hindex[0]^I_hindex[0]) && I_compute_en;
   end
    
   always@ (posedge I_clk)
   begin
       S_linewidth_div16 <= I_ciMemGroup*I_iwidth;
       O_dram_feature_rd_flag <= S_load_flag;
//       O_dram_feature_rd_flag <= !S_f_rdy && I_f_rdy;
   
//       if (~S_ap_start && I_ap_start)
//           O_dram_feature_rd_addr <= 'd0;
//       else if (S_load_flag && I_compute_en && S_buf_ch)
//           O_dram_feature_rd_addr <= S_base_addr_buf0 + I_hindex*S_linewidth_div16;
//       else if (S_load_flag && I_compute_en && !S_buf_ch)
//           O_dram_feature_rd_addr <= S_base_addr_buf1 + I_hindex*S_linewidth_div16;
       S_f_rdy <= I_f_rdy;

        if (~S_ap_start && I_ap_start)
            O_dram_feature_rd_addr <= I_feature_base_addr;
//        else if (~S_f_rdy && I_f_rdy)
//            O_dram_feature_rd_addr <= O_dram_feature_rd_addr + I_iwidth;
        else if (S_load_flag)
            O_dram_feature_rd_addr <= I_feature_base_addr + I_hindex*S_linewidth_div16;
   end
endmodule
