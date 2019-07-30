`timescale 1ns / 1ps
//--------------------------------------------------------------------------
// write in addr function
// [127:0]WBRAM[depth_addr][ci_addr][co_addr]([127:0]WBRAM[511:0][15:0][1:0])
// depth_addr = (k*ciGroup*coAlign + cig*coAlign + co)/32,co=0,32,64... 
// ci_addr <= ci%16
// co_addr <= (co/16)%2
//--------------------------------------------------------------------------

module weight_load_update#(
    parameter             AXIWIDTH   = 128,
    parameter             LITEWIDTH  = 32,
    parameter             CH_IN      = 16,
    parameter             CH_OUT     = 32,
    parameter             PIX        = 8,
    parameter             LAYERWIDTH = 8,
    parameter             KWIDTH     = 4,
    parameter             COWIDTH    = 10,
    parameter             DWIDTH     = 8
)(

    input                               I_clk,
    input                               I_rst,
    //load-in
    input      [LAYERWIDTH-1:0]         I_layer_num,
    input      [LITEWIDTH-1:0]          I_ci_num,
    input      [LITEWIDTH-1:0]          I_co_num,
    input      [LITEWIDTH-1:0]          I_kxk_num,
    input                               I_ap_start,
    input      [AXIWIDTH-1:0]           I_weight,
    input                               I_weight_dv,
    input                               I_rd_dv,
    //read-out
    input      [COWIDTH-2:0]            I_rd_wdepth,
    
    output reg                          O_load_done=0,
    output     [CH_IN*CH_OUT*DWIDTH-1:0]O_weight
    );

localparam    WBRAM_DEPTH       = 512;
localparam    WBRAM_CI          = 16;
localparam    WBRAM_CO          = 2;
localparam    C_DEPTH_WIDTH     = GETASIZE(WBRAM_DEPTH);
localparam    C_CI_WIDTH        = GETASIZE(WBRAM_CI);
localparam    C_CO_WIDTH        = GETASIZE(WBRAM_CO);
localparam    C_CI_ALIGN_WIDTH  = GETASIZE(CH_IN);
localparam    C_CO_ALIGN_WIDTH  = GETASIZE(CH_OUT);


reg [COWIDTH:0]                 S_co_div32      = 0;
reg [COWIDTH:0]                 S_ci_div16      = 0;
reg [1:0]                       S_layer_num     = 0;
reg                             S_wr_ch         = 0;
reg [1:0]                       S_ap_start      = 0;
reg                             S_ap_start_pos  = 0;

reg [COWIDTH-1-4:0]             S_co_align16    = 0;
reg [COWIDTH-1-4:0]             S_co_cnt        = 0;
reg [COWIDTH-1:0]               S_co_num        = 0;
reg [KWIDTH-1:0]                S_kk_cnt        = 0;
reg [COWIDTH-1:0]               S_ci_cnt        = 0;
reg [COWIDTH-1-4:0]             S_cigroup       = 0;

reg [COWIDTH:0]                 S_wr_depth_addr = 0;
reg [C_CI_WIDTH-1:0]            S_wr_ci_addr    = 0;
reg [C_CO_WIDTH-1:0]            S_wr_co_addr    = 0;

reg [AXIWIDTH-1:0]              S_weight        = 0;
reg                             S_weight_dv     = 0;

reg [COWIDTH:0]                 S_depth_addr_t  = 0;
reg [C_CI_WIDTH-1:0]            S_ci_addr_t     = 0;
reg [C_CO_WIDTH-1:0]            S_co_addr_t     = 0;

reg [COWIDTH:0]                 S_rd_depth      = 0;
reg                             S_wbram_rd_ch   = 0;
reg                             S_done_d1       = 0;
reg                             S_weight_rd_en  = 0;


always@ (posedge I_clk)
begin
    S_co_div32 <= (~(|I_co_num[C_CO_ALIGN_WIDTH-1:0])) ? I_co_num : (((I_co_num+CH_OUT)>>C_CO_ALIGN_WIDTH)<<C_CO_ALIGN_WIDTH);
    S_ci_div16 <= (~(|I_ci_num[C_CI_ALIGN_WIDTH-1:0])) ? I_ci_num : (((I_ci_num+CH_IN)>>C_CI_ALIGN_WIDTH)<<C_CI_ALIGN_WIDTH);
end

always@ (posedge I_clk)
begin
    S_layer_num <= {S_layer_num[0],I_layer_num[0]};
    S_wr_ch <= (^S_layer_num) ? ~S_wr_ch : S_wr_ch;
end

always@ (posedge I_clk)
begin
    S_ap_start <= {S_ap_start[0],I_ap_start};
    S_ap_start_pos <= S_ap_start[0] && ~S_ap_start[1];
end

always@ (posedge I_clk)
begin
    S_co_align16 <= I_co_num >> 'd4;
    
    if (S_ap_start_pos)
        S_co_cnt <= 'd0;
    else if (S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_co_cnt <= 'd0;
    else if (I_weight_dv)
        S_co_cnt <= S_co_cnt + 'd1;
        
    if (S_ap_start_pos)
        S_co_num <= 'd0;
    else if (S_co_num==S_co_div32-CH_OUT && S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_co_num <= 'd0;
    else if (S_co_cnt[0] && I_weight_dv)
        S_co_num <= S_co_num + CH_OUT;
        
    if (S_ap_start_pos)
        S_ci_cnt <= 'd0;
    else if (S_ci_cnt == I_ci_num-1 && S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_ci_cnt <= 'd0;
    else if (S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_ci_cnt <= S_ci_cnt + 'd1;
        
    if (S_ap_start_pos)
        S_kk_cnt <= 'd0;
    else if (S_kk_cnt == I_kxk_num-1 && S_co_cnt==S_co_align16-1 && S_ci_cnt == I_ci_num-1 && I_weight_dv)
        S_kk_cnt <= 'd0;
    else if (S_ci_cnt == I_ci_num-1 && S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_kk_cnt <= S_kk_cnt + 'd1;
        

        
    if (S_ap_start_pos)
        S_cigroup <= 'd0;
    else if (&S_ci_cnt[C_CI_ALIGN_WIDTH-1:0] && S_kk_cnt == I_kxk_num-1 && S_co_cnt==S_co_align16-1 && I_weight_dv)
        S_cigroup <= S_cigroup + 'd1;
end

always@ (posedge I_clk)
begin
    if (I_rst)
        S_wr_co_addr <= 'd0;
    else if (S_ap_start_pos)
        S_wr_co_addr <= 'd0;
    else if (I_weight_dv)
        S_wr_co_addr <= S_co_cnt[0];
        
    if (I_rst)
        S_wr_ci_addr <= 'd0;
    else if (S_ap_start_pos)
        S_wr_ci_addr <= 'd0;
    else if (I_weight_dv)
        S_wr_ci_addr <= S_ci_cnt[C_CI_ALIGN_WIDTH-1:0];
        
    if (I_rst)
        S_wr_depth_addr <= 'd0;
    else if (S_ap_start_pos)
        S_wr_depth_addr <= 'd0;
    else if (I_weight_dv)
        S_wr_depth_addr <= (S_kk_cnt*(S_ci_div16 >> C_CI_ALIGN_WIDTH)*(S_co_div32) + S_cigroup*(S_co_div32) + S_co_num)>>C_CO_ALIGN_WIDTH;

end

always@ (posedge I_clk)
begin
    S_weight <= I_weight;
    S_weight_dv <= I_weight_dv;
end

always@ (posedge I_clk)
begin
    S_depth_addr_t <= (((I_kxk_num)*(S_ci_div16 >> C_CI_ALIGN_WIDTH)-1)*(S_co_div32) + (S_co_div32-CH_OUT))>>C_CO_ALIGN_WIDTH;
    S_ci_addr_t <= I_ci_num[3:0]-1;
    S_co_addr_t <= ~S_co_align16[0];
    
    S_done_d1 <= O_load_done;
    
    if (S_ap_start_pos) 
        O_load_done <= 1'b0;
    else if (S_wr_depth_addr==S_depth_addr_t && S_wr_ci_addr==S_ci_addr_t && S_wr_co_addr==S_co_addr_t)
        O_load_done <= 1'b1;  
    
end

always@ (posedge I_clk)
    if (S_ap_start_pos)
        S_weight_rd_en <= 1'b0;
    else if (!S_done_d1 && O_load_done)
        S_weight_rd_en <= 1'b1;


genvar gen_i,gen_j;
generate
for (gen_i=0; gen_i<WBRAM_CI; gen_i=gen_i+1)
begin:outer_loop
    for (gen_j=0; gen_j<WBRAM_CO; gen_j=gen_j+1)
    begin:inner_loop
    
   (*ram_style="block"*) reg [AXIWIDTH-1:0] WBRAM0 [WBRAM_DEPTH-1:0];
   (*ram_style="block"*) reg [AXIWIDTH-1:0] WBRAM1 [WBRAM_DEPTH-1:0];
   wire wea;
   wire web;
   reg [AXIWIDTH-1:0] dout_reg0 = 0;
   reg [AXIWIDTH-1:0] dout_reg1 = 0;
   
    //load paragraph
 
    assign wea = gen_i==S_wr_ci_addr && gen_j==S_wr_co_addr && !S_wr_ch && ~O_load_done && S_weight_dv;
    assign web = gen_i==S_wr_ci_addr && gen_j==S_wr_co_addr && S_wr_ch && ~O_load_done && S_weight_dv;
    
    always@ (posedge I_clk)
    begin
        if (wea)
            WBRAM0[S_wr_depth_addr]<= S_weight;
    end
    
    always@ (posedge I_clk)
    begin
        if (web)
            WBRAM1[S_wr_depth_addr]<= S_weight;
    end
    
    //read paragraph
    
    always@ (posedge I_clk)
    begin
        if (I_rst)
            dout_reg0 <= 'd0;
        else if (/*!S_wbram_rd_ch*/S_wbram_rd_ch)
            dout_reg0 <= WBRAM0[I_rd_wdepth];
    end
    
    always@ (posedge I_clk)
    begin
        if (I_rst)
            dout_reg1 <= 'd0;
        else if (S_wbram_rd_ch)
            dout_reg1 <= WBRAM1[I_rd_wdepth];
    end
    
    always@ (posedge I_clk)
    begin
        if (S_ap_start_pos)
            S_wbram_rd_ch <= !S_wbram_rd_ch;
    end
    
    assign O_weight[(WBRAM_CO*gen_i+gen_j)*AXIWIDTH+:AXIWIDTH] = I_rd_dv ? ((/*!S_wbram_rd_ch*/S_wbram_rd_ch) ? dout_reg0 : dout_reg1) : 4096'd0;
    
    end//inner loop
end//outer loop
endgenerate

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
