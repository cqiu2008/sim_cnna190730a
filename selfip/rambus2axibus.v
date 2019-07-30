//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : rambus2axibus.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_rambus2axibus
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
module rambus2axibus #(
parameter 
    C_M_AXI_ID_WIDTH        = 1     ,
    C_M_AXI_LEN_WIDTH       = 32    ,
    C_M_AXI_SIZE_WIDTH      = 3     ,
    C_M_AXI_USER_WIDTH      = 1     , 
    C_M_AXI_ADDR_WIDTH      = 32    ,
    C_M_AXI_DATA_WIDTH      = 128   ,
    C_RAM_ADDR_WIDTH        = 10    ,
    C_RAM_DATA_WIDTH        = 128   , 
    C_GET_RDATA_AFTER_NCLK  = 3      //should be 2,3,4....
)(
// clk
input                               I_clk           ,
// ap signals
input                               I_ap_start      ,
output reg                          O_ap_done       ,
output reg                          O_ap_idle       ,
output reg                          O_ap_ready      ,
// reg 
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
input       [C_RAM_ADDR_WIDTH-1  :0]I_len           ,
// ram bus 
output reg  [C_RAM_ADDR_WIDTH-1  :0]O_raddr         ,
output reg                          O_rd            ,
output                              O_rdata_ffen    ,
input       [C_RAM_DATA_WIDTH-1  :0]I_rdata         ,///3clk after O_rd

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
output reg  [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_awlen    ,
input                               I_maxi_awready  ,   
output                              O_maxi_awvalid  ,
output reg  [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_awaddr   ,
// master write data channel
output      [C_M_AXI_ID_WIDTH-1  :0]O_maxi_wid      ,
output      [C_M_AXI_USER_WIDTH-1:0]O_maxi_wuser    ,   
output      [                  15:0]O_maxi_wstrb    ,
output      [                   1:0]O_maxi_wlast    ,   
input                               I_maxi_wready   ,
output reg                          O_maxi_wvalid   ,
output      [C_M_AXI_DATA_WIDTH-1:0]O_maxi_wdata    ,       
// master write response
input       [C_M_AXI_ID_WIDTH-1  :0]I_maxi_bid      ,
input       [C_M_AXI_USER_WIDTH-1:0]I_maxi_buser    ,   
input       [                   1:0]I_maxi_bresp    ,
input                               I_maxi_bvalid   ,
output reg                          O_maxi_bready   
);

function integer clogb2;
    input integer value;
    begin
        for(clogb2=0;value>0;clogb2=clogb2+1)
            value = value>>1;
    end
endfunction

localparam C_RCNT_EXTEND_WIDTH = clogb2(C_GET_RDATA_AFTER_NCLK-1);

reg  [      C_RAM_ADDR_WIDTH-1:0]S_len              ;   
reg                              S_ap_start_1d      ;
reg  [      C_RAM_ADDR_WIDTH-1:0]S_rcnt             ;
reg                              S_rcnt_en          ;
reg  [C_GET_RDATA_AFTER_NCLK-1:0]S_rcnt_en_shift    ;
reg                              S_rcnt_extend_en   ;
reg  [   C_RCNT_EXTEND_WIDTH-1:0]S_rcnt_extend      ; 
reg                              S_has_handshake_aw ; 
   
//// write ram process 

always @(posedge I_clk)begin
    S_len           <= I_len[C_RAM_ADDR_WIDTH-1:0];
    O_maxi_awlen    <= I_len[C_RAM_ADDR_WIDTH-1:0];
end

//// read ram process 
// master axi awaddr channel 

assign O_maxi_awuser    = {C_M_AXI_USER_WIDTH{1'b0}};
assign O_maxi_awid      = {C_M_AXI_ID_WIDTH{1'b0}};
assign O_maxi_awburst   = {2{1'b0}};
assign O_maxi_awlock    = {2{1'b0}};
assign O_maxi_awcache   = {4{1'b0}};
assign O_maxi_awprot    = {3{1'b0}};
assign O_maxi_awqos     = {4{1'b0}};
assign O_maxi_awregion  = {4{1'b0}};
assign O_maxi_awsize    = {C_M_AXI_SIZE_WIDTH{1'b0}};

always @(posedge I_clk)begin
    O_maxi_awaddr   <= I_base_addr ;
end

axvalid_ctrl U1_awvalid(
.I_clk     (I_clk           ),
.I_ap_start(I_ap_start      ),
.I_axready (I_maxi_awready  ),
.O_axvalid (O_maxi_awvalid  )
);

// master axi wdata channel 

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(I_maxi_awready && O_maxi_awvalid)begin
            S_has_handshake_aw <= 1'b1;
        end
        else if(S_rcnt_en)begin
            S_has_handshake_aw <= 1'b0;
        end
        else begin
            S_has_handshake_aw <= S_has_handshake_aw ;
        end
    end
    else begin
        S_has_handshake_aw <= 1'b0;
    end
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_has_handshake_aw)begin
            S_rcnt_en <= 1'b1;
        end
        else if( O_rd && (S_rcnt == S_len-1) )begin
            S_rcnt_en <= 1'b0;
        end
        else begin
            S_rcnt_en <= S_rcnt_en;
        end
    end
    else begin
        S_rcnt_en <= 1'b0;
    end
end

assign O_raddr = S_rcnt;
assign O_rd = S_rcnt_en && I_maxi_wready; 
assign O_rdata_ffen = I_maxi_wready ; 
assign O_maxi_wdata = I_rdata       ;

always @(posedge I_clk)begin
    if(S_rcnt_en)begin
        if(O_rd)begin
            S_rcnt      <= S_rcnt + 16'd1   ;
        end
        else begin
            S_rcnt      <= S_rcnt           ; 
        end
    end
    else begin
        S_rcnt      <= 16'd0                ; 
    end
end

always @(posedge I_clk)begin
    S_rcnt_en_shift <= {S_rcnt_en_shift[C_GET_RDATA_AFTER_NCLK-2:0],S_rcnt_en};
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_rcnt_en_shift[0] && (!S_rcnt_en))begin
            S_rcnt_extend[C_RCNT_EXTEND_WIDTH-1:1] <= {(C_RCNT_EXTEND_WIDTH-1){1'b0}};
            S_rcnt_extend[0] <= I_maxi_wready ;

        end
        else if(S_rcnt_extend_en && I_maxi_wready)begin
            S_rcnt_extend <= S_rcnt_extend + 1'b1; 
        end
    end
    else begin
        S_rcnt_extend <= {(C_RCNT_EXTEND_WIDTH){1'b0}};
    end
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_rcnt_en_shift[0] && (!S_rcnt_en))begin
            S_rcnt_extend_en <= 1'b1;
        end
        else if((S_rcnt_extend == C_GET_RDATA_AFTER_NCLK-1) && I_maxi_wready)begin
            S_rcnt_extend_en <= 1'b0;
        end
        else begin
            S_rcnt_extend_en <= S_rcnt_extend_en ;
        end
    end
    else begin
        S_rcnt_extend_en <= 1'b0;
    end
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        ///S_rcnt_en_shift[0],x=2'b01;, after 1clk ,Need change
        ///S_rcnt_en_shift[1:0]=2'b01;, after 2clk ,C_GET_RDATA_AFTER_NCLK=2
        ///S_rcnt_en_shift[2:1]=2'b01;, after 3clk ,C_GET_RDATA_AFTER_NCLK=3
        ///S_rcnt_en_shift[3:2]=2'b01;, after 4clk ,C_GET_RDATA_AFTER_NCLK=4
        if(S_rcnt_en_shift[C_GET_RDATA_AFTER_NCLK-1:C_GET_RDATA_AFTER_NCLK-2]==2'b01)begin
            O_maxi_wvalid <= 1'b1;
        end
        else if((S_rcnt_extend == C_GET_RDATA_AFTER_NCLK-1) && I_maxi_wready)begin
            O_maxi_wvalid <= 1'b0;
        end
        else begin
            O_maxi_wvalid <= O_maxi_wvalid ;
        end
    end
    else begin
        O_maxi_wvalid <= 1'b0; 
    end
end

// master axi wresponse channel 

assign O_maxi_wid       = {C_M_AXI_ID_WIDTH{1'b0}}  ;
assign O_maxi_wuser     = {C_M_AXI_USER_WIDTH{1'b0}};
assign O_maxi_wstrb     = {16{1'b0}}                ;
assign O_maxi_wlast     = {2{1'b0}}                 ;

always @(posedge I_clk)begin
    if(I_ap_start && I_maxi_bvalid)begin
        O_maxi_bready <= 1'b1;
        O_ap_done     <= 1'b1;
        O_ap_ready    <= 1'b1;
    end
    else begin
        O_maxi_bready <= 1'b0;
        O_ap_done     <= 1'b0;
        O_ap_ready    <= 1'b0;
    end
end

always @(posedge I_clk)begin
    S_ap_start_1d <=  I_ap_start;
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

endmodule

