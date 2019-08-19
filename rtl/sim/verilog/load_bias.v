//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : load_bias.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_load_bias
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_main_process
//----------------------------------------------------------------------------
//Relaese History :
//----------------------------------------------------------------------------
//Version         Date           Author        Description
// 1.1           july-30-2019                    
//----------------------------------------------------------------------------
//Main Function:
//a)Get the data from ddr chip using axi master bus
//b)Write it to the ibuf ram
//----------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER------------------------------------------------------------------
`timescale 1 ns / 100 ps
module load_bias #(
parameter 
    C_M_AXI_LEN_WIDTH       = 32    ,
    C_M_AXI_ADDR_WIDTH      = 32    ,
    C_M_AXI_DATA_WIDTH      = 128   ,
    C_RAM_ADDR_WIDTH        = 10    ,
    C_RAM_DATA_WIDTH        = 128   
)(
// clk
input                               I_clk           ,
// ap signals
input                               I_ap_start      ,
output                              O_ap_done       ,
// reg 
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
input       [C_RAM_ADDR_WIDTH-1  :0]I_len           ,
// inter mem bus 
input       [  C_RAM_ADDR_WIDTH-1:0]I_braddr        ,        
output      [  C_RAM_DATA_WIDTH-1:0]O_brdata        ,
// master read address channel
output      [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_arlen    ,
input                               I_maxi_arready  ,   
output                              O_maxi_arvalid  ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_araddr   ,
// master read data channel
output                              O_stable_rready ,
input                               I_maxi_rvalid   ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_maxi_rdata    

);

// ram bus 
wire  [C_RAM_ADDR_WIDTH-1  :0]S_waddr         ;
wire  [C_RAM_DATA_WIDTH-1  :0]S_wdata         ;
wire                          S_wr            ;
reg   [C_RAM_ADDR_WIDTH-1  :0]S_waddr_1d      ;
reg   [C_RAM_DATA_WIDTH-1  :0]S_wdata_1d      ;
reg                           S_wr_1d         ;

always @(posedge I_clk)begin
    S_waddr_1d  <= I_ap_start ? S_waddr : I_braddr  ;
    S_wdata_1d  <= S_wdata                          ;
    S_wr_1d     <= S_wr                             ;
end

axibus2rambus #(
    .C_M_AXI_LEN_WIDTH   (C_M_AXI_LEN_WIDTH    ),
    .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH   ),
    .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH   ),
    .C_RAM_ADDR_WIDTH    (C_RAM_ADDR_WIDTH     ),
    .C_RAM_DATA_WIDTH    (C_RAM_DATA_WIDTH     ))
u0_axibus2rambus_bias(
    .I_clk          (I_clk           ),
    .I_ap_start     (I_ap_start      ),
    .O_ap_done      (O_ap_done       ),
    .I_base_addr    (I_base_addr     ),
    .I_len          (I_len           ),
    .O_waddr        (S_waddr         ),
    .O_wdata        (S_wdata         ),
    .O_wr           (S_wr            ),
    .O_maxi_arlen   (O_maxi_arlen    ),
    .I_maxi_arready (I_maxi_arready  ),   
    .O_maxi_arvalid (O_maxi_arvalid  ),
    .O_maxi_araddr  (O_maxi_araddr   ),
    .O_stable_rready(O_stable_rready ),
    .I_maxi_rvalid  (I_maxi_rvalid   ),
    .I_maxi_rdata   (I_maxi_rdata    )
);

spram #(
    .MEM_STYLE ( "block"            ),//"distributed"
    .ASIZE     ( C_RAM_ADDR_WIDTH   ), 
    .DSIZE     ( C_RAM_DATA_WIDTH   ))
u0_spram (
    .I_clk	 (I_clk	        ),
    .I_addr	 (S_waddr_1d	),
    .I_data	 (S_wdata_1d	),
    .I_wr	 (S_wr_1d	    ),
    .O_data	 (O_brdata      )
);

endmodule

