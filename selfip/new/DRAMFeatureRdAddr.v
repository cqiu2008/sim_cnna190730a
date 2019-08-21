`timescale 1ns / 1ps

module DRAMFeatureRdAddr#(
    parameter                  W_WIDTH     = 10,
    parameter                  LITEWIDTH   = 32,
    parameter                  DEPTHWIDTH  = 9,
    parameter                  AXIWIDTH    = 128,
    parameter                  C_KWIDTH    = 4
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
   reg                         S_load_flag_d1    = 0;
   reg                         S_load_flag_d2    = 0;
   reg                         S_load_flag_d3    = 0;
//   reg                         S_load_flag_d4    = 0;
//   reg                         S_load_flag_d5    = 0;
   wire     [W_WIDTH+5:0]      S_linewidth_div16;
   wire     [W_WIDTH+5:0]      S_feature_rd_addr_tmp;
   
   always@ (posedge I_clk)
   begin
       S_hindex <= I_hindex;
       
       if (~S_ap_start && I_ap_start)
           S_minus_h <= 'd0;
       else 
           S_minus_h <= I_iheight - I_hindex;
   end
   
   always@ (posedge I_clk)
   begin
       S_load_flag_d1 <= S_load_flag;
       S_load_flag_d2 <= S_load_flag_d1;
       S_load_flag_d3 <= S_load_flag_d2;
//       S_load_flag_d4 <= S_load_flag_d3;
//       S_load_flag_d5 <= S_load_flag_d4;
       S_load_flag <= !I_hindex[W_WIDTH-1] && !S_minus_h[W_WIDTH-1] && (S_hindex[0]^I_hindex[0]) && I_compute_en;
   end
   
   dsp_unit1 dsp_unit_inst0(
       .I_clk              (I_clk),
       .I_weight_l         ({{21{I_ciMemGroup[DEPTHWIDTH-1]}},I_ciMemGroup}),
       .I_weight_h         (27'd0),
       .I_1feature         ({{8{I_iwidth[C_KWIDTH-1]}},I_iwidth}),
       .I_pi_cas           (48'd0),
       .O_pi               (),
       .O_p                (S_linewidth_div16)
       );
       
   dsp_unit1 dsp_unit_inst1(
           .I_clk              (I_clk),
           .I_weight_l         ({{14{S_linewidth_div16[W_WIDTH+5]}},S_linewidth_div16}),
           .I_weight_h         (27'd0),
           .I_1feature         ({{8{I_hindex[W_WIDTH-1]}},I_hindex}),
           .I_pi_cas           (48'd0),
           .O_pi               (),
           .O_p                (S_feature_rd_addr_tmp)
           );
    
   always@ (posedge I_clk)
   begin
     //  S_linewidth_div16 <= I_ciMemGroup*I_iwidth;
       O_dram_feature_rd_flag <= S_load_flag_d3;

       S_f_rdy <= I_f_rdy;
       
//       S_feature_rd_addr_tmp <= I_hindex*S_linewidth_div16;

        if (~S_ap_start && I_ap_start)
            O_dram_feature_rd_addr <= I_feature_base_addr;

        else if (S_load_flag_d3)
            O_dram_feature_rd_addr <= I_feature_base_addr + S_feature_rd_addr_tmp;
   end
endmodule
