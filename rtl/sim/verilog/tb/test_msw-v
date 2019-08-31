//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : test_msw.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_main_process.v
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_main_process
//--------------------------------------------------------------------------------------------------
//Relaese History :
//--------------------------------------------------------------------------------------------------
//Version         Date           Author        Description
// 1.1           july-30-2019                    
//--------------------------------------------------------------------------------------------------
//Main Function:
//a)Get the data from ddr chip using axi master bus
//b)Write it to the ibuf ram
//--------------------------------------------------------------------------------------------------
//REUSE ISSUES: none
//Reset Strategy: synchronization 
//Clock Strategy: one common clock 
//Critical Timing: none 
//Asynchronous Interface: none 
//END_HEADER----------------------------------------------------------------------------------------
module test_msw #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_POWER_OF_RDBPIX       = 1         , 
    C_PEPIX                 = 8         ,
    C_DATA_WIDTH            = 8         ,
    C_QIBUF_WIDTH           = 12        ,
    C_LQIBUF_WIDTH          = 12*8      ,       
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_RAM_ADDR_WIDTH        = 9         ,
    C_RAM_DATA_WIDTH        = 128       , 
    C_RAM_LDATA_WIDTH       = 128*8       
)(
// clk
input                               I_clk               ,
input                               I_rst               ,
input                               I_allap_start       ,
input                               I_ap_start          ,
output                              O_ap_done           ,
//sbuf
output      [C_RAM_ADDR_WIDTH-1  :0]O_sraddr0           ,//dly=0
output      [C_RAM_ADDR_WIDTH-1  :0]O_sraddr1           , 
input       [C_RAM_LDATA_WIDTH-1 :0]I_srdata0           ,//dly=3
input       [C_RAM_LDATA_WIDTH-1 :0]I_srdata1           ,//128*8 
// reg
input       [       C_DIM_WIDTH-1:0]I_opara_height      ,
input       [       C_DIM_WIDTH-1:0]I_opara_width       ,
input       [    C_CNV_CH_WIDTH-1:0]I_opara_co          ,
// master write address channel
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr         ,
output      [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_awlen        ,
input                               I_maxi_awready      ,   
output                              O_maxi_awvalid      ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_awaddr       ,
// master write data channel
input                               I_maxi_wready       ,
output                              O_maxi_wvalid       ,
output      [C_M_AXI_DATA_WIDTH-1:0]O_maxi_wdata        ,       
// master write response
input                               I_maxi_bvalid       ,
output                              O_maxi_bready           
);

localparam   C_RDBPIX               = {1'b1,{C_POWER_OF_RDBPIX{1'b0}}}        ;
localparam   C_WOT_DIV_PEPIX        = C_DIM_WIDTH - C_POWER_OF_PEPIX+1        ;
localparam   C_WOT_DIV_RDBPIX       = C_DIM_WIDTH - C_POWER_OF_RDBPIX+1       ;
localparam   C_NCH_GROUP            = C_CNV_CH_WIDTH - C_POWER_OF_PECI + 1    ;
localparam   C_CNV_K_PEPIX          = C_CNV_K_WIDTH + C_POWER_OF_PEPIX + 1    ;
localparam   C_CNV_K_GROUP          = C_CNV_K_WIDTH + C_NCH_GROUP             ;
localparam   C_PADDING              = 6                                       ;
localparam   C_GET_RDATA_AFTER_NCLK = 4                                       ; 

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) SL_+"xx"  name type (S_layer_xxx) , means variable changed every layer   
//        such as SL_wo_total, SL_wo_group, SL_wpart ... and so on 
// (2) SR_+"xx"  name type (S_row_xxx), means variable changed every row 
//        such as SR_hindex , SR_hindex  ... and so on 
// (3) SC_+"xx"  name type (S_clock_xxx), means variable changed every clock 
//        such as SC_id , ... and so on 
////////////////////////////////////////////////////////////////////////////////////////////////////

wire [       C_NCH_GROUP-1:0]SL_co_group        ;   
reg  [       C_NCH_GROUP-1:0]SL_co_group_1d     ;   
reg  [C_M_AXI_LEN_WIDTH-1 :0]SL_maxi_awlen_p1   ;
wire [C_RAM_ADDR_WIDTH-1  :0]SL_maxi_awlen      ;
wire                         SR_ndap_start      ;
reg                          SR_mpap_start      ;
reg                          SR_mpap_start_1d   ;
wire [C_M_AXI_DATA_WIDTH-1:0]S_rdata_in_p1      ;
reg  [C_M_AXI_DATA_WIDTH-1:0]S_rdata_in         ;
wire                         S_rdata_ffen       ;
reg  [C_M_AXI_ADDR_WIDTH-1:0]SL_base_addr       ; 
reg  [       C_DIM_WIDTH-1:0]SL_cnt             ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial layer variable
////////////////////////////////////////////////////////////////////////////////////////////////////

// calcuate SL_co_group_1d
ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_1ADOTS  ))
U0_co_group(
    .I_din (I_opara_co),
    .O_dout(SL_co_group )   
);

always @(posedge I_clk)begin
    SL_co_group_1d <= SL_co_group;
end

// calcuate SL_maxi_awlen_p1       ;
always @(posedge I_clk)begin
    SL_maxi_awlen_p1<=  I_opara_width * SL_co_group_1d    ; 
end

align #(
    .C_IN_WIDTH (C_M_AXI_LEN_WIDTH  ),
    .C_OUT_WIDTH(C_RAM_ADDR_WIDTH   ))
u_maxi_awlen (
    .I_din      (SL_maxi_awlen_p1   ),
    .O_dout     (SL_maxi_awlen      )
);

// calcuate SL_base_addr;
//reg  [       C_DIM_WIDTH-1:0]SL_cnt             ;
always @(posedge I_clk)begin
    if(I_allap_start)begin
        
        if(SR_mpap_start_1d && (~SR_mpap_start))begin
            if(SL_cnt <(I_opara_height-1))begin
                SL_cnt   <= SL_cnt + {{(C_DIM_WIDTH-1){1'b0}},1'b1};
            end
        end
        
    end
    else begin
        SL_cnt   <= {C_DIM_WIDTH{1'b0}};
    end
end

always @(posedge I_clk)begin
    SR_mpap_start_1d    <= SR_mpap_start ; 
    SL_base_addr        <= I_base_addr + SL_cnt * SL_maxi_awlen_p1; 
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// generate dly ap_start 
////////////////////////////////////////////////////////////////////////////////////////////////////

dly #(
    .C_DATA_WIDTH   (1          ), 
    .C_DLY_NUM      (3          ))
u_start_dly(
    .I_clk     (I_clk           ),
    .I_din     (I_ap_start      ),
    .O_dout    (SR_ndap_start    )
);
always @(posedge I_clk)begin
    if(I_allap_start)begin
        if(O_ap_done)begin
            SR_mpap_start <= 1'b0           ;
        end
        else if(SR_ndap_start)begin
            SR_mpap_start <= 1'b1           ; 
        end
        else begin
            SR_mpap_start <= SR_mpap_start  ; 
        end
    end
    else begin
            SR_mpap_start <= 1'b0           ; 
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// generate S_rdata_in 
////////////////////////////////////////////////////////////////////////////////////////////////////

genvar idx;
generate
    begin:idx_s1
        for(idx=0;idx<C_RAM_DATA_WIDTH;idx=idx+1)begin
            assign S_rdata_in_p1[idx]= ^I_srdata0[C_PEPIX*(idx+1)-1:C_PEPIX*idx] ;
        end
    end
endgenerate

always @(posedge I_clk)begin
    S_rdata_in <=  S_rdata_in_p1    ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// instance 
////////////////////////////////////////////////////////////////////////////////////////////////////

rambus2axibus #( 
    .C_M_AXI_LEN_WIDTH      (C_M_AXI_LEN_WIDTH      ),
    .C_M_AXI_ADDR_WIDTH     (C_M_AXI_ADDR_WIDTH     ),
    .C_M_AXI_DATA_WIDTH     (C_M_AXI_DATA_WIDTH     ),
    .C_RAM_ADDR_WIDTH       (C_RAM_ADDR_WIDTH       ), 
    .C_RAM_DATA_WIDTH       (C_RAM_DATA_WIDTH       ),
    .C_GET_RDATA_AFTER_NCLK (C_GET_RDATA_AFTER_NCLK ))///3 should be 2,3,4....
U0_rambus2axibus(
.I_clk           (I_clk             ),
.I_ap_start      (SR_mpap_start     ),
.O_ap_done       (O_ap_done         ),
.O_ap_idle       (                  ),
.O_ap_ready      (                  ),
.I_base_addr     (SL_base_addr      ),
.I_len           (SL_maxi_awlen     ),
.O_raddr         (O_sraddr0         ),
.O_rd            (                  ),
.O_rdata_ffen    (S_rdata_ffen      ),
.I_rdata         (S_rdata_in        ),///3clk after O_rd
.O_maxi_awlen    (O_maxi_awlen      ),
.I_maxi_awready  (I_maxi_awready    ),   
.O_maxi_awvalid  (O_maxi_awvalid    ),
.O_maxi_awaddr   (O_maxi_awaddr     ),
.I_maxi_wready   (I_maxi_wready     ),
.O_maxi_wvalid   (O_maxi_wvalid     ),
.O_maxi_wdata    (O_maxi_wdata      ),       
.I_maxi_bresp    (2'b0              ),
.I_maxi_bvalid   (I_maxi_bvalid     ),
.O_maxi_bready   (O_maxi_bready     )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
