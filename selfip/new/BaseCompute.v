`timescale 1ns / 1ps

module BaseCompute#(
    parameter                     LITEWIDTH     = 32,
    parameter                     DEPTHWIDTH    = 9,
    parameter                     CH_IN         = 16,
    parameter                     CH_OUT        = 32,
    parameter                     PIX           = 8,
    parameter                     IEMEM_1ADOT   = 16
)(
    input                         I_clk,
    input       [LITEWIDTH-1:0]   I_ci_num,
    input       [LITEWIDTH-1:0]   I_co_num,
    input       [LITEWIDTH-1:0]   I_owidth_num,
    input       [DEPTHWIDTH:0]    I_coAlign,
    input       [DEPTHWIDTH:0]    I_ciAlign,
    output      [DEPTHWIDTH-1:0]  O_woGroup,
    output      [DEPTHWIDTH-1:0]  O_coGroup,
    output      [DEPTHWIDTH-1:0]  O_ciMemGroup
    );
    
localparam    C_CI_ALIGN_WIDTH  = GETASIZE(CH_IN);
localparam    C_CO_ALIGN_WIDTH  = GETASIZE(CH_OUT);
localparam    C_PIX_WIDTH       = GETASIZE(PIX);
localparam    C_MEM_DOT_WIDTH   = GETASIZE(IEMEM_1ADOT);

assign  O_woGroup = I_owidth_num >> C_PIX_WIDTH;
assign  O_coGroup = I_coAlign >> C_CO_ALIGN_WIDTH;
assign  O_ciMemGroup = (~(|I_ciAlign[C_MEM_DOT_WIDTH-1:0])) ? (I_ciAlign>>C_MEM_DOT_WIDTH) : (I_ciAlign>>C_MEM_DOT_WIDTH+1);     

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
