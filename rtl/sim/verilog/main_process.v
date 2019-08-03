//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : main_process.v
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
module main_process #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_POWER_OF_RDBPIX       = 1         , 
    C_DATA_WIDTH            = 8         , 
    C_QIBUF_WIDTH           = 12        , 
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_RAM_ADDR_WIDTH        = 9         ,
    C_RAM_DATA_WIDTH        = 128       
)(
// clk
input                               I_clk               ,
input                               I_rst               ,
input                               I_ap_start          ,
output                              O_ap_done           ,
// reg
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr         ,
input       [C_M_AXI_ADDR_WIDTH-1:0]I_ipara_addr_img_in ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_h          ,
input       [     C_CNV_K_WIDTH-1:0]I_kernel_w          ,//
input       [     C_CNV_K_WIDTH-1:0]I_stride_h          ,
input       [     C_CNV_K_WIDTH-1:0]I_stride_w          ,//
input       [     C_CNV_K_WIDTH-1:0]I_pad_h             ,
input       [     C_CNV_K_WIDTH-1:0]I_pad_w             ,//
input       [       C_DIM_WIDTH-1:0]I_opara_width       ,//
input       [       C_DIM_WIDTH-1:0]I_opara_height      ,
input       [    C_CNV_CH_WIDTH-1:0]I_opara_co          ,
input       [    C_CNV_CH_WIDTH-1:0]I_ipara_ci          ,
input       [       C_DIM_WIDTH-1:0]I_ipara_width       ,
input       [       C_DIM_WIDTH-1:0]I_ipara_height      ,
// fi master channel
output      [C_M_AXI_LEN_WIDTH-1 :0]O_fimaxi_arlen      ,
input                               I_fimaxi_arready    ,   
output                              O_fimaxi_arvalid    ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_fimaxi_araddr     ,
output                              O_fimaxi_rready     ,
input                               I_fimaxi_rvalid     ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_fimaxi_rdata      , 
// fo master channel
output reg  [C_M_AXI_LEN_WIDTH-1 :0]O_fomaxi_awlen      ,
input                               I_fomaxi_awready    ,   
output                              O_fomaxi_awvalid    ,
output reg  [C_M_AXI_ADDR_WIDTH-1:0]O_fomaxi_awaddr     ,
input                               I_fomaxi_wready     ,
output reg                          O_fomaxi_wvalid     ,
output      [C_M_AXI_DATA_WIDTH-1:0]O_fomaxi_wdata      ,   
input                               I_fomaxi_bvalid     ,
output reg                          O_fomaxi_bready     
);

parameter    C_PEPIX          = {1'b1,{C_POWER_OF_PEPIX{1'b0}}}     ;
localparam   C_WO_GROUP       = C_DIM_WIDTH - C_POWER_OF_PEPIX + 1  ;
localparam   C_CI_GROUP       = C_CNV_CH_WIDTH - C_POWER_OF_1ADOTS+1; 
localparam   C_RAM_LDATA_WIDTH= C_RAM_DATA_WIDTH * C_PEPIX          ;
localparam   C_LQIBUF_WIDTH   = C_QIBUF_WIDTH * C_PEPIX             ;


wire         [       C_DIM_WIDTH-1:0]S_hcnt                         ;
wire         [       C_DIM_WIDTH-1:0]S_hcnt_pre                     ;
wire         [       C_DIM_WIDTH-1:0]S_hfirst[4]                    ;
wire         [       C_DIM_WIDTH-1:0]S_kh[4]                        ;
wire         [       C_DIM_WIDTH-1:0]S_hindex[4]                    ;
reg                                  S_en_wr_obuf0  = 1'b1          ;
reg                                  S_obuf_init_ok = 1'b0          ;
wire         [        C_CI_GROUP-1:0]S_ipara_ci_group               ;
reg          [        C_CI_GROUP-1:0]S_ipara_ci_group_1d            ;
reg          [C_M_AXI_ADDR_WIDTH-1:0]S_line_width_div16             ;
reg          [       C_DIM_WIDTH-1:0]S_hcnt_total_1t                ; 
reg          [       C_DIM_WIDTH-1:0]S_hcnt_total_2t                ; 
reg          [       C_DIM_WIDTH-1:0]S_hcnt_total_3t                ; 
reg          [       C_DIM_WIDTH-1:0]S_hcnt_total                   ; 
wire                                 S_tcap_start                   ;
wire                                 S_tcap_done                    ;
wire                                 S_ldap_start                   ;
wire                                 S_ldap_done                    ;
wire                                 S_swap_start                   ;
wire                                 S_swap_done                    ;
wire                                 S_peap_start                   ;
wire                                 S_peap_done                    ;
wire                                 S_pqap_start                   ;
wire                                 S_pqap_done                    ;
wire                                 S_ppap_start                   ;
wire                                 S_ppap_done                    ;
wire                                 S_mpap_start                   ;
wire                                 S_mpap_done                    ;   
reg          [C_M_AXI_ADDR_WIDTH-1:0]S_fibase_addr                  ; 
wire         [C_RAM_ADDR_WIDTH-1  :0]S_ibuf0_addr                   ; 
wire         [C_RAM_ADDR_WIDTH-1  :0]S_ibuf1_addr                   ; 
wire         [C_RAM_DATA_WIDTH-1  :0]S_ibuf0_rdata                  ; 
wire         [C_RAM_DATA_WIDTH-1  :0]S_ibuf1_rdata                  ; 

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial variable
////////////////////////////////////////////////////////////////////////////////////////////////////

ceil_power_of_2 #(
    .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
    .C_POWER2_NUM   (C_POWER_OF_1ADOTS  ))
U0_next_co_group_peco(
    .I_din (I_ipara_ci          ),
    .O_dout(S_ipara_ci_group    )   
);

always @(posedge I_clk)begin
    S_ipara_ci_group_1d <= S_ipara_ci_group                     ;
    S_line_width_div16  <= S_ipara_ci_group_1d * I_ipara_width  ; 
    S_hcnt_total_1t     <= I_opara_height * I_kernel_h          ;
    S_hcnt_total_2t     <= 3 + I_kernel_h                       ; 
    S_hcnt_total_3t     <= S_hcnt_total_1t + S_hcnt_total_2t    ; 
    S_hcnt_total        <= S_hcnt_total_3t                      ;
end

////////////////////////////////////////////////////////////////////////////////////////////////////
// main cnt ctrl and ap controller 
////////////////////////////////////////////////////////////////////////////////////////////////////

main_cnt_ctrl #(
    .C_MEM_STYLE        (C_MEM_STYLE        ),
    .C_POWER_OF_1ADOTS  (C_POWER_OF_1ADOTS  ),
    .C_POWER_OF_PECI    (C_POWER_OF_PECI    ),
    .C_POWER_OF_PECO    (C_POWER_OF_PECO    ),
    .C_POWER_OF_PEPIX   (C_POWER_OF_PEPIX   ),
    .C_POWER_OF_PECODIV (C_POWER_OF_PECODIV ),
    .C_CNV_K_WIDTH      (C_CNV_K_WIDTH      ),
    .C_CNV_CH_WIDTH     (C_CNV_CH_WIDTH     ),
    .C_DIM_WIDTH        (C_DIM_WIDTH        ))
u0_main_cnt_ctrl (
    .I_clk              (I_clk              ),
    .I_hcnt_total       (S_hcnt_total       ),
    .O_hcnt_pre         (S_hcnt_pre         ),
    .O_hcnt             (S_hcnt             ),
    .I_ap_start         (I_ap_start         ),
    .O_ap_done          (O_ap_done          ),
    .O_tcap_start       (S_tcap_start       ),
    .I_tcap_done        (S_tcap_done        ),
    .O_ldap_start       (S_ldap_start       ),
    .I_ldap_done        (S_ldap_done        ),
    .O_swap_start       (S_swap_start       ),
    .I_swap_done        (S_swap_done        ),
    .O_peap_start       (S_peap_start       ),
    .I_peap_done        (S_peap_done        ),
    .O_pqap_start       (S_pqap_start       ),
    .I_pqap_done        (S_pqap_done        ),
    .O_ppap_start       (S_ppap_start       ),
    .I_ppap_done        (S_ppap_done        ),
    .O_mpap_start       (S_mpap_start       ),
    .I_mpap_done        (S_mpap_done        )    
);


////////////////////////////////////////////////////////////////////////////////////////////////////
// transform_hcnt_wrapper 
////////////////////////////////////////////////////////////////////////////////////////////////////
transform_hcnt_wrapper #(
    .C_DSIZE           (C_DIM_WIDTH         ),
    .C_CNV_CH_WIDTH    (C_CNV_CH_WIDTH      ), 
    .C_CNV_K_WIDTH     (C_CNV_K_WIDTH       ))
u_transform_hcnt_wrapper(
    .I_clk              (I_clk                 ),
    .I_allap_start      (I_ap_start            ),
    .I_ap_start         (S_tcap_start          ),
    .O_ap_done          (S_tcap_done           ),
    .I_kernel_h         (I_kernel_h            ),
    .I_stride_h         (I_stride_h            ),
    .I_pad_h            (I_pad_h               ),
    .I_hcnt             (S_hcnt_pre            ),
    .O_r0hfirst         (S_hfirst[0]           ),
    .O_r0kh             (S_kh[0]               ),
    .O_r0hindex         (S_hindex[0]           ),                
    .O_r1hfirst         (S_hfirst[1]           ),              
    .O_r1kh             (S_kh[1]               ),                  
    .O_r1hindex         (S_hindex[1]           ),               
    .O_r2hfirst         (S_hfirst[2]           ),              
    .O_r2kh             (S_kh[2]               ),                  
    .O_r2hindex         (S_hindex[2]           ),               
    .O_r3hfirst         (S_hfirst[3]           ),              
    .O_r3kh             (S_kh[3]               ),                  
    .O_r3hindex         (S_hindex[3]           )
);
    

////////////////////////////////////////////////////////////////////////////////////////////////////
// load_image  
////////////////////////////////////////////////////////////////////////////////////////////////////

always @(posedge I_clk)begin
    S_fibase_addr   <= I_base_addr + I_ipara_addr_img_in    ;
end

load_image #(
    .C_MEM_STYLE          (C_MEM_STYLE           ),
    .C_POWER_OF_1ADOTS    (C_POWER_OF_1ADOTS     ),
    .C_POWER_OF_PECI      (C_POWER_OF_PECI       ),
    .C_POWER_OF_PECO      (C_POWER_OF_PECO       ),
    .C_POWER_OF_PEPIX     (C_POWER_OF_PEPIX      ),
    .C_POWER_OF_PECODIV   (C_POWER_OF_PECODIV    ),
    .C_CNV_K_WIDTH        (C_CNV_K_WIDTH         ),
    .C_CNV_CH_WIDTH       (C_CNV_CH_WIDTH        ),
    .C_DIM_WIDTH          (C_DIM_WIDTH           ),
    .C_M_AXI_LEN_WIDTH    (C_M_AXI_LEN_WIDTH     ),
    .C_M_AXI_ADDR_WIDTH   (C_M_AXI_ADDR_WIDTH    ),
    .C_M_AXI_DATA_WIDTH   (C_M_AXI_DATA_WIDTH    ),
    .C_RAM_ADDR_WIDTH     (C_RAM_ADDR_WIDTH      ),
    .C_RAM_DATA_WIDTH     (C_RAM_DATA_WIDTH      ))
u0_load_image(
    .I_clk                (I_clk                 ),
    .I_base_addr          (S_fibase_addr         ),
    .I_allap_start        (I_ap_start            ),
    .I_ap_start           (S_ldap_start          ),
    .O_ap_done            (S_ldap_done           ),
    .I_ipara_height       (I_ipara_height        ),
    .I_hindex             (S_hindex[0]           ),
    .I_hcnt_odd           (S_hcnt[0]             ),//1,3,5,...active
    .I_line_width_div16   (S_line_width_div16    ),
    .I_raddr0             (S_ibuf0_addr          ), 
    .I_raddr1             (S_ibuf1_addr          ), 
    .O_rdata0             (S_ibuf0_rdata         ), 
    .O_rdata1             (S_ibuf1_rdata         ), 
    .O_fimaxi_arlen       (O_fimaxi_arlen        ),
    .I_fimaxi_arready     (I_fimaxi_arready      ),   
    .O_fimaxi_arvalid     (O_fimaxi_arvalid      ),
    .O_fimaxi_araddr      (O_fimaxi_araddr       ),
    .O_fimaxi_rready      (O_fimaxi_rready       ),
    .I_fimaxi_rvalid      (I_fimaxi_rvalid       ),
    .I_fimaxi_rdata       (I_fimaxi_rdata        )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// multi_slide_windows_flatten 
////////////////////////////////////////////////////////////////////////////////////////////////////

multi_slide_windows_flatten #(
    .C_MEM_STYLE         (C_MEM_STYLE          ),
    .C_POWER_OF_1ADOTS   (C_POWER_OF_1ADOTS    ),
    .C_POWER_OF_PECI     (C_POWER_OF_PECI      ),
    .C_POWER_OF_PECO     (C_POWER_OF_PECO      ),
    .C_POWER_OF_PEPIX    (C_POWER_OF_PEPIX     ),
    .C_POWER_OF_PECODIV  (C_POWER_OF_PECODIV   ),
    .C_POWER_OF_RDBPIX   (C_POWER_OF_RDBPIX    ), 
    .C_PEPIX             (C_PEPIX              ),
    .C_DATA_WIDTH        (C_DATA_WIDTH         ),
    .C_QIBUF_WIDTH       (C_QIBUF_WIDTH        ),
    .C_LQIBUF_WIDTH      (C_LQIBUF_WIDTH       ),
    .C_CNV_K_WIDTH       (C_CNV_K_WIDTH        ),
    .C_CNV_CH_WIDTH      (C_CNV_CH_WIDTH       ),
    .C_DIM_WIDTH         (C_DIM_WIDTH          ),
    .C_M_AXI_LEN_WIDTH   (C_M_AXI_LEN_WIDTH    ),
    .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH   ),
    .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH   ),
    .C_RAM_ADDR_WIDTH    (C_RAM_ADDR_WIDTH     ),
    .C_RAM_DATA_WIDTH    (C_RAM_DATA_WIDTH     ),
    .C_RAM_LDATA_WIDTH   (C_RAM_LDATA_WIDTH    ))
u_multi_slide_windows_flatten(
    .I_clk               (I_clk                 ),
    .I_rst               (I_rst                 ),
    .I_allap_start       (I_ap_start            ),
    .I_ap_start          (S_swap_start          ),
    .O_ap_done           (S_swap_done           ),
    .O_ibuf0_addr        (S_ibuf0_addr          ), 
    .O_ibuf1_addr        (S_ibuf1_addr          ), 
    .I_ibuf0_rdata       (S_ibuf0_rdata         ), 
    .I_ibuf1_rdata       (S_ibuf1_rdata         ), 
    .I_sraddr0           (), 
    .I_sraddr1           (), 
    .O_srdata0           (), 
    .O_srdata1           (), 
    .I_ipara_height      (I_ipara_height        ),
    .I_hindex            (S_hindex[1]           ),
    .I_hcnt_odd          (S_hcnt[0]             ),//1,3,5,...active
    .I_kernel_w          (I_kernel_w            ),
    .I_stride_w          (I_stride_w            ),
    .I_pad_w             (I_pad_w               ),
    .I_ipara_width       (I_ipara_width         ),
    .I_ipara_ci          (I_ipara_ci            ) 
);



// ceil_power_of_2 #(
//     .C_DIN_WIDTH    (C_DIM_WIDTH        ),
//     .C_POWER2_NUM   (C_POWER_OF_PEPIX   ))
// U0_next_co_group_peco(
//     .I_din (I_opara_width   ),
//     .O_dout(S_wo_group      )   
// );
// 
// ceil_power_of_2 #(
//     .C_DIN_WIDTH    (C_CNV_CH_WIDTH     ),
//     .C_POWER2_NUM   (C_POWER_OF_1ADOTS  ))
// U0_next_co_group(
//     .I_din (I_next_co       ),
//     .O_dout(S_next_co_group )   
// );

////////////////////////////////////////////////////////////////////////////////////////////////////
// Naming specification                                                                         
// (1) w+"xxx" name type , means write clock domain                                             
//        such as wrst,wclk,winc,wdata, wptr, waddr,wfull, and so on                            
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                
//    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __    __
// __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  
//                                                                                                
//                                                                                                
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//        u0_wptr_full                                                                           
////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
