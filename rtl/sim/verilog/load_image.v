//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : load_image.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_load_image
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_load_image
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
module load_image #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        ,
    C_M_AXI_LEN_WIDTH       = 32        ,
    C_M_AXI_ADDR_WIDTH      = 32        ,
    C_M_AXI_DATA_WIDTH      = 128       ,
    C_RAM_ADDR_WIDTH        = 10        ,
    C_RAM_DATA_WIDTH        = 128       
)(
// clk
input                               I_clk               ,
input       [C_M_AXI_ADDR_WIDTH-1:0]I_base_addr         ,
// ap
input                               I_allap_start       ,
input                               I_ap_start          ,
output reg                          O_ap_done           ,
// reg
input       [       C_DIM_WIDTH-1:0]I_ipara_height      ,
input       [       C_DIM_WIDTH-1:0]I_hindex            ,
input                               I_hcnt_odd          ,//1,3,5,...active
input       [C_M_AXI_ADDR_WIDTH-1:0]I_line_width_div16  ,
// mem
input       [C_RAM_ADDR_WIDTH-1  :0]I_raddr0            , 
input       [C_RAM_ADDR_WIDTH-1  :0]I_raddr1            , 
output reg  [C_RAM_DATA_WIDTH-1  :0]O_rdata0            , 
output reg  [C_RAM_DATA_WIDTH-1  :0]O_rdata1            , 
// fi master channel
output      [C_M_AXI_LEN_WIDTH-1 :0]O_fimaxi_arlen      ,
input                               I_fimaxi_arready    ,   
output                              O_fimaxi_arvalid    ,
output      [C_M_AXI_ADDR_WIDTH-1:0]O_fimaxi_araddr     ,
output                              O_fimaxi_rready     ,
input                               I_fimaxi_rvalid     ,
input       [C_M_AXI_DATA_WIDTH-1:0]I_fimaxi_rdata      
);

localparam   C_AP_START       = 16  ; 

wire [C_RAM_ADDR_WIDTH-1  :0]S_waddr            ;
wire [C_RAM_DATA_WIDTH-1  :0]S_wdata            ;
wire                         S_wr               ;
reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr0a           ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata0a          ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata0a          ;
reg                          S_wr0a             ;

reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr0b           ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata0b          ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata0b          ;
reg                          S_wr0b             ;

reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr1a           ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata1a          ;
reg                          S_wr1a             ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata1a          ;

reg  [C_RAM_ADDR_WIDTH-1  :0]S_addr1b           ;
reg  [C_RAM_DATA_WIDTH-1  :0]S_wdata1b          ;
reg                          S_wr1b             ;
wire [C_RAM_DATA_WIDTH-1  :0]S_rdata1b          ;

wire [       C_DIM_WIDTH-1:0]S_ibuf0_index      ; 
wire [       C_DIM_WIDTH-1:0]S_ibuf1_index      ; 
wire                         S_hindex_suite     ;
reg                          S_ibuf0_index_neq  ; 
reg                          S_ibuf1_index_neq  ; 
reg  [C_M_AXI_ADDR_WIDTH-1:0]S_fi_base_addr_t   ; 
reg  [C_M_AXI_ADDR_WIDTH-1:0]S_fi_base_addr     ; 
reg  [        C_AP_START-1:0]S_ap_start_shift   ; 
reg                          S_ldap_start       ;
wire                         S_ldap_done        ;
reg                          S_ibuf0_en         ;
reg                          S_ibuf1_en         ;
reg                          S_no_suite_done    ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// initial variable  
////////////////////////////////////////////////////////////////////////////////////////////////////

suite_range #(
    .C_DIM_WIDTH (C_DIM_WIDTH))
u_suite_range(
    .I_clk          (I_clk           ),
    .I_index        (I_hindex        ),
    .I_index_upper  (I_ipara_height  ),
    .O_index_suite  (S_hindex_suite  )
);

always @(posedge I_clk)begin
    S_ibuf0_index_neq   <= S_ibuf0_index != I_hindex                            ; 
    S_ibuf1_index_neq   <= S_ibuf1_index != I_hindex                            ; 
    S_fi_base_addr_t    <= I_hindex * I_line_width_div16                        ; 
    S_fi_base_addr      <= S_fi_base_addr_t + I_base_addr                       ;
    S_ap_start_shift    <= {S_ap_start_shift[C_AP_START-2:0],I_ap_start}        ;
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        if(S_ap_start_shift[7:6] == 2'b01)begin
            S_ibuf0_en  <= S_hindex_suite && S_ibuf0_index_neq && (~I_hcnt_odd) ;
            S_ibuf1_en  <= S_hindex_suite && S_ibuf1_index_neq && ( I_hcnt_odd) ;
        end
        else begin
            S_ibuf0_en  <= S_ibuf0_en   ; 
            S_ibuf1_en  <= S_ibuf1_en   ; 
        end
    end
    else begin
        S_ibuf0_en <= 1'b0;
        S_ibuf1_en <= 1'b0;
    end
end

always @(posedge I_clk)begin
    S_ldap_start <= S_ibuf0_en | S_ibuf1_en;
    //if(I_ap_start)begin
    //    if(S_ap_start_shift[8:7] == 2'b01)begin
    //        S_ldap_start <= S_ibuf0_en | S_ibuf1_en;
    //    end
    //end
    //else begin
    //    S_ldap_start   <= 1'b0; 
    //end
end

always @(posedge I_clk)begin
    S_no_suite_done  = (S_ap_start_shift[9:8]==2'b01) && (~S_ldap_start); 
    O_ap_done        = S_no_suite_done || S_ldap_done                   ; 
end

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_ibuf0_index(
    .I_clk        (I_clk          ),
    .I_ap_start   (I_allap_start  ),
    .I_index_en   (S_ibuf0_en     ),
    .I_index      (I_hindex       ),
    .O_index_lck  (S_ibuf0_index  )     
);

index_lck #(
    .C_DIM_WIDTH (C_DIM_WIDTH ))
u_ibuf1_index(
    .I_clk        (I_clk          ),
    .I_ap_start   (I_allap_start  ),
    .I_index_en   (S_ibuf1_en     ),
    .I_index      (I_hindex       ),
    .O_index_lck  (S_ibuf1_index  )     
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// load image from ddr 
////////////////////////////////////////////////////////////////////////////////////////////////////

axibus2rambus #(
    .C_M_AXI_LEN_WIDTH   (C_M_AXI_LEN_WIDTH    ),
    .C_M_AXI_ADDR_WIDTH  (C_M_AXI_ADDR_WIDTH   ),
    .C_M_AXI_DATA_WIDTH  (C_M_AXI_DATA_WIDTH   ),
    .C_RAM_ADDR_WIDTH    (C_RAM_ADDR_WIDTH     ),
    .C_RAM_DATA_WIDTH    (C_RAM_DATA_WIDTH     ))
u_fiddr_to_ibuf(
    .I_clk           (I_clk             ),
    .I_ap_start      (S_ldap_start      ),
    .O_ap_done       (S_ldap_done       ),
    .I_base_addr     (S_fi_base_addr    ),
    .I_len           (I_line_width_div16[C_RAM_ADDR_WIDTH-1:0]),
    .O_waddr         (S_waddr           ),
    .O_wdata         (S_wdata           ),
    .O_wr            (S_wr              ),
    .O_maxi_arlen    (O_fimaxi_arlen    ),
    .I_maxi_arready  (I_fimaxi_arready  ),   
    .O_maxi_arvalid  (O_fimaxi_arvalid  ),
    .O_maxi_araddr   (O_fimaxi_araddr   ),
    .O_stable_rready (O_fimaxi_rready   ),
    .I_maxi_rvalid   (I_fimaxi_rvalid   ),
    .I_maxi_rdata    (I_fimaxi_rdata    )
);

////////////////////////////////////////////////////////////////////////////////////////////////////
// write to spram  
////////////////////////////////////////////////////////////////////////////////////////////////////
dpram #(
    .MEM_STYLE  (C_MEM_STYLE        ),//"distributed"
    .ASIZE      (C_RAM_ADDR_WIDTH   ),   
    .DSIZE      (C_RAM_DATA_WIDTH   ))
u_ibuf0(
    .I_clk0     (I_clk              ),
    .I_addr0    (S_addr0a           ),
    .I_wdata0   (S_wdata0a          ),
    .I_ce0      (1'b1               ),
    .I_wr0      (S_wr0a             ),
    .O_rdata0   (S_rdata0a          ),
    .I_clk1     (I_clk              ),
    .I_addr1    (S_addr0b           ),
    .I_wdata1   (S_wdata0b          ),
    .I_ce1      (1'b1               ),
    .I_wr1      (S_wr0b             ),
    .O_rdata1   (S_rdata0b          ) 
);

dpram #(
    .MEM_STYLE  (C_MEM_STYLE        ),//"distributed"
    .ASIZE      (C_RAM_ADDR_WIDTH   ),   
    .DSIZE      (C_RAM_DATA_WIDTH   ))
u_ibuf1(
    .I_clk0     (I_clk              ),
    .I_addr0    (S_addr1a           ),
    .I_wdata0   (S_wdata1a          ),
    .I_ce0      (1'b1               ),
    .I_wr0      (S_wr1a             ),
    .O_rdata0   (S_rdata1a          ),
    .I_clk1     (I_clk              ),
    .I_addr1    (S_addr1b           ),
    .I_wdata1   (S_wdata1b          ),
    .I_ce1      (1'b1               ),
    .I_wr1      (S_wr1b             ),
    .O_rdata1   (S_rdata1b          ) 
);

// spram #(
//     .MEM_STYLE  (MEM_STYLE          ),//"distributed"
//     .ASIZE      (C_RAM_ADDR_WIDTH   ),   
//     .DSIZE      (C_RAM_DATA_WIDTH   ))
// u_ibuf0(
//     .I_rst      (I_rst              ),   
//     .I_clk      (I_clk              ),
//     .I_addr     (S_addr0            ),
//     .I_data     (S_wdata0           ),
//     .I_wr       (S_wr0              ),
//     .O_data     (S_rdata0           )
// );
// 
// spram #(
//     .MEM_STYLE   (MEM_STYLE         ),//"distributed"
//     .ASIZE       (C_RAM_ADDR_WIDTH  ),   
//     .DSIZE       (C_RAM_DATA_WIDTH  ))
// u_ibuf1(
//     .I_rst       (I_rst         ),   
//     .I_clk       (I_clk         ),
//     .I_addr      (S_addr1       ),
//     .I_data      (S_wdata1      ),
//     .I_wr        (S_wr1         ),
//     .O_data      (S_rdata1      )
// );

always @(posedge I_clk)begin

    S_addr0a    <= S_ibuf0_en ? S_waddr : I_raddr0      ;
    S_wdata0a   <= S_wdata                              ;
    S_wr0a      <= S_wr && S_ibuf0_en                   ;        

    S_addr0b    <= I_raddr1                             ;
    S_wdata0b   <= {C_RAM_DATA_WIDTH{1'b0}}             ; 
    S_wr0b      <= 1'b0                                 ; 

    S_addr1a    <= S_ibuf1_en ? S_waddr : I_raddr0      ;
    S_wdata1a   <= S_wdata                              ;
    S_wr1a      <= S_wr && S_ibuf1_en                   ;        

    S_addr1b    <= I_raddr1                             ;
    S_wdata1b   <= {C_RAM_DATA_WIDTH{1'b0}}             ; 
    S_wr1b      <= 1'b0                                 ; 

    O_rdata0    <= (~I_hcnt_odd)? S_rdata1a : S_rdata0a ;
    O_rdata1    <= (~I_hcnt_odd)? S_rdata1b : S_rdata0b ;

end

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
