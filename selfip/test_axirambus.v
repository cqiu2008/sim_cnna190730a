//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : test_axirambus.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_test_axirambus
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
module test_axirambus #(
parameter 
    C_M_AXI_ID_WIDTH        = 1     ,
    C_M_AXI_LEN_WIDTH       = 32    ,
    C_M_AXI_SIZE_WIDTH      = 3     ,
    C_M_AXI_USER_WIDTH      = 1     , 
    C_M_AXI_ADDR_WIDTH      = 32    ,
    C_M_AXI_DATA_WIDTH      = 128   , 
    C_RAM_ADDR_WIDTH        = 10    , 
    C_RAM_DATA_WIDTH        = 128    
)(
// clk
input                               I_clk           ,
input                               I_rst           ,
// ap signals
input                               I_ap_start      ,
output reg                          O_ap_done       ,
output reg                          O_ap_idle       ,
output reg                          O_ap_ready      ,
// reg 
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
input       [C_RAM_ADDR_WIDTH-1  :0]I_len           ,
// master read address channel
output      [C_M_AXI_USER_WIDTH-1:0]O_maxi_aruser   ,   
output      [C_M_AXI_ID_WIDTH-1  :0]O_maxi_arid     ,
output      [                   1:0]O_maxi_arburst  ,
output      [                   1:0]O_maxi_arlock   ,
output      [                   3:0]O_maxi_arcache  ,
output      [                   2:0]O_maxi_arprot   ,
output      [                   3:0]O_maxi_arqos    ,
output      [                   3:0]O_maxi_arregion ,
output      [C_M_AXI_SIZE_WIDTH-1:0]O_maxi_arsize   ,
output      [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_arlen    ,
input                               I_maxi_arready  ,   
output                              O_maxi_arvalid  ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_araddr   ,
// master read data channel
input       [C_M_AXI_ID_WIDTH-1  :0]I_maxi_rid      ,
input       [C_M_AXI_USER_WIDTH-1:0]I_maxi_ruser    ,   
input       [                   1:0]I_maxi_rresp    ,
input       [                   1:0]I_maxi_rlast    ,   
output                              O_maxi_rready   ,
input                               I_maxi_rvalid   ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_maxi_rdata    ,
// master write address channel
output      [C_M_AXI_USER_WIDTH-1:0]O_maxi_awuser   ,   
output      [C_M_AXI_ID_WIDTH-1  :0]O_maxi_awid     ,
output      [                   1:0]O_maxi_awburst  ,
output      [                   1:0]O_maxi_awlock   ,
output      [                   3:0]O_maxi_awcache  ,
output      [                   2:0]O_maxi_awprot   ,
output      [                   3:0]O_maxi_awqos    ,
output      [                   3:0]O_maxi_awregion ,
output      [C_M_AXI_SIZE_WIDTH-1:0]O_maxi_awsize   ,
output      [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_awlen    ,
input                               I_maxi_awready  ,   
output                              O_maxi_awvalid  ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_awaddr   ,
// master write data channel
output      [C_M_AXI_ID_WIDTH-1  :0]O_maxi_wid      ,
output      [C_M_AXI_USER_WIDTH-1:0]O_maxi_wuser    ,   
output      [                  15:0]O_maxi_wstrb    ,
output      [                   1:0]O_maxi_wlast    ,   
input                               I_maxi_wready   ,
output                              O_maxi_wvalid   ,
output      [C_M_AXI_DATA_WIDTH-1:0]O_maxi_wdata    ,       
// master write response
input       [C_M_AXI_ID_WIDTH-1  :0]I_maxi_bid      ,
input       [C_M_AXI_USER_WIDTH-1:0]I_maxi_buser    ,   
input       [                   1:0]I_maxi_bresp    ,
input                               I_maxi_bvalid   ,
output                              O_maxi_bready   
);

wire [  C_RAM_ADDR_WIDTH-1:0]S_waddr            ;   
wire [  C_RAM_DATA_WIDTH-1:0]S_wdata            ; 
wire                         S_wr               ;
wire [  C_RAM_ADDR_WIDTH-1:0]S_raddr            ;   
wire [  C_RAM_DATA_WIDTH-1:0]S_rdata_1d         ; 
reg  [  C_RAM_DATA_WIDTH-1:0]S_rdata_2d         ; 
reg  [  C_RAM_DATA_WIDTH-1:0]S_rdata_3d         ; 
reg  [  C_RAM_DATA_WIDTH-1:0]S_rdata_4d         ; 
reg  [  C_RAM_DATA_WIDTH-1:0]S_rdata_5d         ; 
wire [  C_RAM_DATA_WIDTH-1:0]S_rdata_in         ; 

wire                         S_rdata_ffen       ;
wire                         S_rd               ;
reg                          S_ap1_start        ;
wire                         S_ap1_done         ;
wire                         S_ap1_idle         ;
wire                         S_ap1_ready        ;
reg                          S_ap2_start        ;
wire                         S_ap2_done         ;
reg                          S_ap2_done_1d      ;
wire                         S_ap2_idle         ;
wire                         S_ap2_ready        ;
reg  [                   3:0]S_ap_cnt           ;
reg                          S_ap_start_1d      ; 

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(I_ap_start && (!S_ap_start_1d))begin
            S_ap_cnt <= 4'b0010;
        end
        else if(S_ap1_done)begin
            S_ap_cnt <= 4'b0100;
        end
        else if(S_ap2_done)begin
            S_ap_cnt <= 4'b1000;
        end
        else begin
            S_ap_cnt <= S_ap_cnt ; 
        end
    end
    else begin
        S_ap_cnt <= 4'b0001;
    end
end

always @(posedge I_clk)begin
    S_ap1_start <= S_ap_cnt[1];
    S_ap2_start <= S_ap_cnt[2];
end

always @(posedge I_clk)begin
    S_ap_start_1d <=  I_ap_start;
    S_ap2_done_1d <=  S_ap2_done;
end

always @(posedge I_clk)begin
    if(I_ap_start && (!S_ap_start_1d))begin
        O_ap_idle   <= 1'b0         ; 
    end
    else if(O_ap_done || (!I_ap_start))begin
        O_ap_idle   <= 1'b1         ; 
    end
    else begin
        O_ap_idle   <= O_ap_idle    ; 
    end
end

always @(posedge I_clk)begin
    O_ap_done  <= ~S_ap2_done_1d && S_ap2_done ;
    O_ap_ready <= ~S_ap2_done_1d && S_ap2_done ;
end

axibus2rambus #( 
    .C_M_AXI_ID_WIDTH       (C_M_AXI_ID_WIDTH       ),
    .C_M_AXI_LEN_WIDTH      (C_M_AXI_LEN_WIDTH      ),
    .C_M_AXI_SIZE_WIDTH     (C_M_AXI_SIZE_WIDTH     ),
    .C_M_AXI_USER_WIDTH     (C_M_AXI_USER_WIDTH     ),
    .C_M_AXI_ADDR_WIDTH     (C_M_AXI_ADDR_WIDTH     ),
    .C_M_AXI_DATA_WIDTH     (C_M_AXI_DATA_WIDTH     ),
    .C_RAM_ADDR_WIDTH       (C_RAM_ADDR_WIDTH       ), 
    .C_RAM_DATA_WIDTH       (C_RAM_DATA_WIDTH       ))
U0_axibus2rambus(
.I_clk           (I_clk           ),
.I_ap_start      (S_ap1_start     ),
.O_ap_done       (S_ap1_done      ),
.O_ap_idle       (S_ap1_idle      ),
.O_ap_ready      (S_ap1_ready     ),
.I_base_addr     (I_base_addr     ),
.I_len           (I_len           ),
.O_waddr         (S_waddr         ),
.O_wdata         (S_wdata         ),
.O_wr            (S_wr            ),
.O_maxi_aruser   (O_maxi_aruser   ),   
.O_maxi_arid     (O_maxi_arid     ),
.O_maxi_arburst  (O_maxi_arburst  ),
.O_maxi_arlock   (O_maxi_arlock   ),
.O_maxi_arcache  (O_maxi_arcache  ),
.O_maxi_arprot   (O_maxi_arprot   ),
.O_maxi_arqos    (O_maxi_arqos    ),
.O_maxi_arregion (O_maxi_arregion ),
.O_maxi_arsize   (O_maxi_arsize   ),
.O_maxi_arlen    (O_maxi_arlen    ),
.I_maxi_arready  (I_maxi_arready  ),   
.O_maxi_arvalid  (O_maxi_arvalid  ),
.O_maxi_araddr   (O_maxi_araddr   ),
.I_maxi_rid      (I_maxi_rid      ),
.I_maxi_ruser    (I_maxi_ruser    ),   
.I_maxi_rresp    (I_maxi_rresp    ),
.I_maxi_rlast    (I_maxi_rlast    ),   
.O_maxi_rready   (O_maxi_rready   ),
.I_maxi_rvalid   (I_maxi_rvalid   ),
.I_maxi_rdata    (I_maxi_rdata    )
);
// ram instance 
sdpram #(
    .MEM_STYLE("block"),
    .DSIZE(C_RAM_DATA_WIDTH),
    .ASIZE(C_RAM_ADDR_WIDTH))
U0_sdpram(
.I_rst  (I_rst      ),  
.I_wclk (I_clk      ),
.I_waddr(S_waddr    ),
.I_wdata(S_wdata    ),
.I_ce   (1'b1       ),
.I_wr   (S_wr       ),
.I_rclk (I_clk      ),
.I_raddr(S_raddr    ),
.I_rd   (S_rd       ),
.O_rdata(S_rdata_1d )
);

parameter C_GET_RDATA_AFTER_NCLK = 5 ;///3 should be 2,3,4....

always @(posedge I_clk)begin
    if(S_rdata_ffen)begin
        S_rdata_2d  <= S_rdata_1d;
        S_rdata_3d  <= S_rdata_2d;
        S_rdata_4d  <= S_rdata_3d;
        S_rdata_5d  <= S_rdata_4d;
    end
    else begin
        S_rdata_2d  <= S_rdata_2d;
        S_rdata_3d  <= S_rdata_3d;
        S_rdata_4d  <= S_rdata_4d;
        S_rdata_5d  <= S_rdata_5d;
    end
end

//assign S_rdata_in = S_rdata_3d;
assign S_rdata_in = S_rdata_5d;

rambus2axibus #( 
    .C_M_AXI_ID_WIDTH       (C_M_AXI_ID_WIDTH       ),
    .C_M_AXI_LEN_WIDTH      (C_M_AXI_LEN_WIDTH      ),
    .C_M_AXI_SIZE_WIDTH     (C_M_AXI_SIZE_WIDTH     ),
    .C_M_AXI_USER_WIDTH     (C_M_AXI_USER_WIDTH     ),
    .C_M_AXI_ADDR_WIDTH     (C_M_AXI_ADDR_WIDTH     ),
    .C_M_AXI_DATA_WIDTH     (C_M_AXI_DATA_WIDTH     ),
    .C_RAM_ADDR_WIDTH       (C_RAM_ADDR_WIDTH       ), 
    .C_RAM_DATA_WIDTH       (C_RAM_DATA_WIDTH       ),
    .C_GET_RDATA_AFTER_NCLK (C_GET_RDATA_AFTER_NCLK ))///3 should be 2,3,4....
U0_rambus2axibus(
.I_clk           (I_clk           ),
.I_ap_start      (S_ap2_start     ),
.O_ap_done       (S_ap2_done      ),
.O_ap_idle       (S_ap2_idle      ),
.O_ap_ready      (S_ap2_ready     ),
.I_base_addr     (I_base_addr+I_len ),
.I_len           (I_len           ),
.O_raddr         (S_raddr         ),
.O_rd            (S_rd            ),
.O_rdata_ffen    (S_rdata_ffen    ),
.I_rdata         (S_rdata_in      ),///3clk after O_rd
.O_maxi_awuser   (O_maxi_awuser   ),   
.O_maxi_awid     (O_maxi_awid     ),
.O_maxi_awburst  (O_maxi_awburst  ),
.O_maxi_awlock   (O_maxi_awlock   ),
.O_maxi_awcache  (O_maxi_awcache  ),
.O_maxi_awprot   (O_maxi_awprot   ),
.O_maxi_awqos    (O_maxi_awqos    ),
.O_maxi_awregion (O_maxi_awregion ),
.O_maxi_awsize   (O_maxi_awsize   ),
.O_maxi_awlen    (O_maxi_awlen    ),
.I_maxi_awready  (I_maxi_awready  ),   
.O_maxi_awvalid  (O_maxi_awvalid  ),
.O_maxi_awaddr   (O_maxi_awaddr   ),
.O_maxi_wid      (O_maxi_wid      ),
.O_maxi_wuser    (O_maxi_wuser    ),   
.O_maxi_wstrb    (O_maxi_wstrb    ),
.O_maxi_wlast    (O_maxi_wlast    ),   
.I_maxi_wready   (I_maxi_wready   ),
.O_maxi_wvalid   (O_maxi_wvalid   ),
.O_maxi_wdata    (O_maxi_wdata    ),       
.I_maxi_bid      (I_maxi_bid      ),
.I_maxi_buser    (I_maxi_buser    ),   
.I_maxi_bresp    (I_maxi_bresp    ),
.I_maxi_bvalid   (I_maxi_bvalid   ),
.O_maxi_bready   (O_maxi_bready   )
);

endmodule

