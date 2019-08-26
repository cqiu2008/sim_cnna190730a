//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : load_all_weights.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_load_all_weights
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
module load_all_weights #(
parameter 
    MEM_STYLE               = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_COEF_DATA             = 8*16*32   , 
    C_BIAS_DATA             = 32        , 
    C_LBIAS_WIDTH           = 32 * 16   , 
    C_RAM_ADDR_WIDTH        = 9         ,
    C_RAM_DATA_WIDTH        = 128       
)(
// clk
input                               I_clk           ,
input                               I_rst           ,
// ap 
input                               I_ap_start      ,
output reg                          O_ap_done       ,
// reg
input       [     C_CNV_K_WIDTH-1:0]I_next_kernel   ,
input       [    C_CNV_CH_WIDTH-1:0]I_next_ci       ,
input       [    C_CNV_CH_WIDTH-1:0]I_next_co       ,
input       [C_M_AXI_ADDR_WIDTH-1:0]I_next_w_addr   ,
input       [C_M_AXI_ADDR_WIDTH-1:0]I_next_b_addr   ,
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr     ,
// inter mem bus 
input       [  C_RAM_ADDR_WIDTH-1:0]I_craddr        ,        
output      [       C_COEF_DATA-1:0]O_crdata        ,
input       [  C_RAM_ADDR_WIDTH-1:0]I_braddr        ,        
output      [     C_LBIAS_WIDTH-1:0]O_brdata        ,
// master read address channel
output reg  [C_M_AXI_LEN_WIDTH-1 :0]O_maxi_arlen    ,
input                               I_maxi_arready  ,   
output                              O_maxi_arvalid  ,
output reg  [C_M_AXI_ADDR_WIDTH-1:0]O_maxi_araddr   ,
// master read data channel
output reg                          O_maxi_rready   ,
input                               I_maxi_rvalid   ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_maxi_rdata    
);

localparam   C_NCH_GROUP      = C_CNV_CH_WIDTH - C_POWER_OF_1ADOTS + 1  ;

reg  [ C_M_AXI_LEN_WIDTH-1:0]S_blen                     ;
reg  [C_M_AXI_ADDR_WIDTH-1:0]S_bbase_addr               ; 
reg  [C_M_AXI_ADDR_WIDTH-1:0]S_wbase_addr               ; 
reg  [                   2:0]S_fsm_cnt                  ;
reg  [                   7:0]S_ap_start_shift           ;
wire                         S_bap_start                ; 
wire                         S_bap_done                 ;
wire                         S_wap_start                ; 
wire                         S_wap_done                 ;
wire [C_M_AXI_LEN_WIDTH-1 :0]S_bmaxi_arlen              ;
wire [C_M_AXI_LEN_WIDTH-1 :0]S_wmaxi_arlen              ;
wire                         S_bmaxi_arvalid            ;
wire                         S_wmaxi_arvalid            ;
wire [C_M_AXI_ADDR_WIDTH-1:0]S_bmaxi_araddr             ;
wire [C_M_AXI_ADDR_WIDTH-1:0]S_wmaxi_araddr             ;
wire                         S_bmaxi_rready             ;
wire                         S_wmaxi_rready             ;
reg                          S_maxi_rvalid_1d           ; 
reg  [C_M_AXI_DATA_WIDTH-1:0]S_maxi_rdata_1d            ;
wire [  C_CNV_CH_WIDTH-1  :0]S_next_co_align            ;   
wire [     C_NCH_GROUP-1  :0]S_next_co_group            ;   

assign S_next_co_align = {S_next_co_group,{(C_POWER_OF_1ADOTS){1'b0}}};

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_1ADOTS  ))
U0_next_co_group(
    .I_din (I_next_co       ),
    .O_dout(S_next_co_group )   
);
    
always @(posedge I_clk)begin
    S_bbase_addr     <= I_next_b_addr + I_base_addr                                     ;
    S_wbase_addr     <= I_next_w_addr + I_base_addr                                     ;
    S_blen           <= {{(C_M_AXI_LEN_WIDTH-C_CNV_CH_WIDTH){1'b0}},S_next_co_align}    ;
    S_ap_start_shift <= {S_ap_start_shift[6:0],I_ap_start}                              ;
    O_ap_done        <= S_wap_done ; 
end

assign S_bap_start = S_fsm_cnt[1];
assign S_wap_start = S_fsm_cnt[2];

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_ap_start_shift[7:6]==2'b01)begin
            S_fsm_cnt <= 3'b010;
        end
        else if(S_bap_done)begin
            S_fsm_cnt <= 3'b100;
        end
        else if(S_wap_done)begin
            S_fsm_cnt <= 3'b001;
        end
        else begin
            S_fsm_cnt <= S_fsm_cnt ;
        end
    end
    else begin
        S_fsm_cnt <= 3'b001; 
    end
end

load_bias #(
    .C_M_AXI_LEN_WIDTH   (C_M_AXI_LEN_WIDTH     ),
    .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH    ),
    .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH    ),
    .C_LBIAS_WIDTH       (C_LBIAS_WIDTH         ), 
    .C_RAM_ADDR_WIDTH    (C_RAM_ADDR_WIDTH      ),
    .C_RAM_DATA_WIDTH    (C_RAM_DATA_WIDTH      ))
u0_load_bias (
    .I_clk          (I_clk                          ),
    .I_ap_start     (S_bap_start                    ),
    .O_ap_done      (S_bap_done                     ),
    .I_base_addr    (S_bbase_addr                   ),
    .I_len          (S_blen[C_RAM_ADDR_WIDTH-1:0]   ),
    .I_braddr       (I_braddr                       ),        
    .O_brdata       (O_brdata                       ),
    .O_maxi_arlen   (S_bmaxi_arlen                  ),
    .I_maxi_arready (I_maxi_arready                 ),   
    .O_maxi_arvalid (S_bmaxi_arvalid                ),
    .O_maxi_araddr  (S_bmaxi_araddr                 ),
    .O_stable_rready(S_bmaxi_rready                 ),
    .I_maxi_rvalid  (S_maxi_rvalid_1d               ),
    .I_maxi_rdata   (S_maxi_rdata_1d                )
);

load_weights #(
    .MEM_STYLE          (MEM_STYLE          ),
    .C_POWER_OF_1ADOTS  (C_POWER_OF_1ADOTS  ),
    .C_POWER_OF_PECI    (C_POWER_OF_PECI    ),
    .C_POWER_OF_PECO    (C_POWER_OF_PECO    ),
    .C_POWER_OF_PECODIV (C_POWER_OF_PECODIV ),
    .C_CNV_K_WIDTH      (C_CNV_K_WIDTH      ),
    .C_CNV_CH_WIDTH     (C_CNV_CH_WIDTH     ),
    .C_M_AXI_LEN_WIDTH  (C_M_AXI_LEN_WIDTH  ),
    .C_M_AXI_ADDR_WIDTH (C_M_AXI_ADDR_WIDTH ),
    .C_M_AXI_DATA_WIDTH (C_M_AXI_DATA_WIDTH ),
    .C_COEF_DATA        (C_COEF_DATA        ), 
    .C_RAM_ADDR_WIDTH   (C_RAM_ADDR_WIDTH   ),
    .C_RAM_DATA_WIDTH   (C_RAM_DATA_WIDTH   ))
u0_load_weights(
    .I_clk              (I_clk              ),
    .I_rst              (I_rst              ),
    .I_ap_start         (S_wap_start        ),
    .O_ap_done          (S_wap_done         ),
    .I_next_kernel      (I_next_kernel      ),
    .I_next_ci          (I_next_ci          ),
    .I_next_co          (I_next_co          ),
    .I_next_mem_addr    (I_next_w_addr      ),
    .I_base_addr        (S_wbase_addr       ),
    .I_craddr           (I_craddr           ),        
    .O_crdata           (O_crdata           ),
    .O_maxi_arlen       (S_wmaxi_arlen      ),
    .I_maxi_arready     (I_maxi_arready     ),   
    .O_maxi_arvalid     (S_wmaxi_arvalid    ),
    .O_maxi_araddr      (S_wmaxi_araddr     ),
    .O_stable_rready    (S_wmaxi_rready     ),
    .I_maxi_rvalid      (S_maxi_rvalid_1d   ),
    .I_maxi_rdata       (S_maxi_rdata_1d    )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// master axi araddr channel 
////////////////////////////////////////////////////////////////////////////////////////////////////
assign O_maxi_arvalid = S_bmaxi_arvalid | S_wmaxi_arvalid;

always @(posedge I_clk)begin
    if(S_bap_start)begin
        O_maxi_araddr <= S_bmaxi_araddr ;
    end
    else begin
        O_maxi_araddr <= S_wmaxi_araddr ;
    end
end

always @(posedge I_clk)begin
    if(S_bap_start)begin
        O_maxi_arlen <= S_bmaxi_arlen   ;
    end
    else begin
        O_maxi_arlen <= S_wmaxi_arlen  ;
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// master axi rdata channel 
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    if(S_bap_start)begin
        O_maxi_rready <= S_bmaxi_rready ;
    end
    else begin
        O_maxi_rready <= S_wmaxi_rready ;
    end
end

always @(posedge I_clk)begin
    S_maxi_rvalid_1d  <= I_maxi_rvalid  ; 
    S_maxi_rdata_1d   <= I_maxi_rdata   ;
end

endmodule

