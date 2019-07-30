//FILE_HEADER-----------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//----------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : axibus2rambus.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//----------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_axibus2rambus
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
module axibus2rambus #(
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
output reg                          O_ap_done       ,
// reg 
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
input       [C_RAM_ADDR_WIDTH-1  :0]I_len           ,
// ram bus 
output reg  [C_RAM_ADDR_WIDTH-1  :0]O_waddr         ,
output reg  [C_RAM_DATA_WIDTH-1  :0]O_wdata         ,
output reg                          O_wr            ,
// master read address channel
output reg  [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_arlen    ,
input                               I_maxi_arready  ,   
output                              O_maxi_arvalid  ,
output reg  [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_araddr   ,
// master read data channel
output reg                          O_stable_rready ,
input                               I_maxi_rvalid   ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_maxi_rdata    

);


reg                          S_ap_start_1d      ;
reg  [  C_RAM_ADDR_WIDTH-1:0]S_len              ;   
reg  [  C_RAM_ADDR_WIDTH-1:0]S_wcnt             ; 
wire                         S_wcnt_valid       ;
reg                          S_wcnt_en          ;
reg                          S_wcnt_en_1d       ;
wire [  C_RAM_ADDR_WIDTH-1:0]S_waddr            ;
wire [  C_RAM_DATA_WIDTH-1:0]S_wdata            ;
wire                         S_wr               ;

//// write ram process 
// master axi araddr channel 

axvalid_ctrl U0_arvalid(
.I_clk     (I_clk           ),
.I_ap_start(I_ap_start      ),
.I_axready (I_maxi_arready  ),
.O_axvalid (O_maxi_arvalid  )
);

always @(posedge I_clk)begin
    O_maxi_araddr   <= I_base_addr ;
end

// master axi rdata channel 

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(I_maxi_arready && O_maxi_arvalid)begin
            S_wcnt_en <= 1'b1;
        end
        else if(S_wcnt_valid && (S_wcnt == (S_len-1)))begin
            S_wcnt_en <= 1'b0;
        end
        else begin
            S_wcnt_en <= S_wcnt_en  ; 
        end
    end
    else begin
        S_wcnt_en <= 1'b0;
    end
end

assign S_wcnt_valid = O_stable_rready && I_maxi_rvalid && S_wcnt_en;

always @(posedge I_clk)begin
    if(I_ap_start)begin
        O_stable_rready <= 1'b1;
    end
    else begin
        O_stable_rready <= 1'b0; 
    end
end

always @(posedge I_clk)begin
    S_len           <= I_len[C_RAM_ADDR_WIDTH-1:0];
    O_maxi_arlen    <= I_len[C_RAM_ADDR_WIDTH-1:0];
end

always @(posedge I_clk)begin
    if(S_wcnt_en)begin 
        if(S_wcnt_valid)begin
            S_wcnt <= S_wcnt + 16'd1    ;
        end
        else begin
            S_wcnt <= S_wcnt            ; 
        end
    end
    else begin
        S_wcnt <= 16'h0                 ;
    end
end

always @(I_clk)begin
    O_waddr <= S_wcnt[C_RAM_ADDR_WIDTH-1:0] ;
    O_wdata <= I_maxi_rdata                 ;
    O_wr    <= S_wcnt_valid                 ;
end

//// ap bus process

always @(posedge I_clk)begin
    S_ap_start_1d <= I_ap_start     ;
    S_wcnt_en_1d  <= S_wcnt_en      ; 
end

always @(posedge I_clk)begin
    if(I_ap_start && (S_wcnt_en_1d) && (!S_wcnt_en))begin
        O_ap_done     <= 1'b1;
    end
    else begin
        O_ap_done     <= 1'b0;
    end
end

endmodule

