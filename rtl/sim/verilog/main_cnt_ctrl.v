//FILE_HEADER---------------------------------------------------------------------------------------
//ZTE  Copyright (C)
//ZTE Company Confidential
//--------------------------------------------------------------------------------------------------
//Project Name : cnna
//FILE NAME    : main_cnt_ctrl.v
//AUTHOR       : qiu.chao 
//Department   : Technical Planning Department/System Products/ZTE
//Email        : qiu.chao@zte.com.cn
//--------------------------------------------------------------------------------------------------
//Module Hiberarchy :
//        |--U01_main_cnt_ctrl.v
//        |--U02_axim_wddr
// cnna --|--U03_axis_reg
//        |--U04_main_cnt_ctrl
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
module main_cnt_ctrl #(
parameter 
    C_MEM_STYLE             = "block"   ,
    C_POWER_OF_1ADOTS       = 4         ,
    C_POWER_OF_PECI         = 4         ,
    C_POWER_OF_PECO         = 5         ,
    C_POWER_OF_PEPIX        = 3         ,
    C_POWER_OF_PECODIV      = 1         ,
    C_CNV_K_WIDTH           = 8         ,
    C_CNV_CH_WIDTH          = 8         ,
    C_DIM_WIDTH             = 16        
)(
// clk
input                               I_clk               ,
input       [       C_DIM_WIDTH-1:0]I_hcnt_total        ,
output reg  [       C_DIM_WIDTH-1:0]O_hcnt              ,
output      [       C_DIM_WIDTH-1:0]O_hcnt_pre          ,
input                               I_ap_start          ,
output reg                          O_ap_done           ,
output                              O_tcap_start        ,
input                               I_tcap_done         ,
output                              O_ldap_start        ,
input                               I_ldap_done         ,
output                              O_swap_start        ,
input                               I_swap_done         ,
output                              O_peap_start        ,
input                               I_peap_done         ,
output                              O_pqap_start        ,
input                               I_pqap_done         ,
output                              O_ppap_start        ,
input                               I_ppap_done         ,
output                              O_mpap_start        ,
input                               I_mpap_done             
);

localparam   C_WO_GROUP       = C_DIM_WIDTH - C_POWER_OF_PEPIX + 1  ;
localparam   C_CI_GROUP       = C_CNV_CH_WIDTH - C_POWER_OF_1ADOTS+1; 

reg                                  S_ap_start_1d       ;
wire                                 S_tcap_done_lck     ;
wire                                 S_ldap_done_lck     ;
wire                                 S_swap_done_lck     ;
wire                                 S_peap_done_lck     ;
wire                                 S_pqap_done_lck     ;
wire                                 S_ppap_done_lck     ;
wire                                 S_mpap_done_lck     ;   
wire                                 S_done_lck          ;
reg                                  S_all_done_lck      ;
reg                                  S_all_done_lck_1d   ;
reg                                  S_hcnt_valid        ;
wire                                 S_hcnt_overflag     ; 
reg                                  S_ap_done_1d        ;
reg                                  S_ap_done_2d        ;
reg                                  S_ap_start_pose     ;
reg                                  S_tcap_start_pose   ;

////////////////////////////////////////////////////////////////////////////////////////////////////
// instance  
////////////////////////////////////////////////////////////////////////////////////////////////////

ap_start_ctrl u_tcap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_tcap_start_pose ),
    .I_ap_done       (I_tcap_done       ),
    .O_ap_start      (O_tcap_start      )
);

ap_start_ctrl u_ldap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_ldap_done       ),
    .O_ap_start      (O_ldap_start      )
);

ap_start_ctrl u_swap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_swap_done       ),
    .O_ap_start      (O_swap_start      )
);

ap_start_ctrl u_peap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_peap_done       ),
    .O_ap_start      (O_peap_start      )
);

ap_start_ctrl u_pqap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_pqap_done       ),
    .O_ap_start      (O_pqap_start      )
);

ap_start_ctrl u_ppap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_ppap_done       ),
    .O_ap_start      (O_ppap_start      )
);

ap_start_ctrl u_mpap_start(
    .I_clk           (I_clk             ),
    .I_ap_start_en   (I_ap_start        ),
    .I_ap_start_pose (S_ap_start_pose   ),
    .I_ap_done       (I_mpap_done       ),
    .O_ap_start      (O_mpap_start      )
);

ap_done_lck u_tcap_done_lck(
    .I_clk          (I_clk               ),
    .I_ap_start     (I_ap_start          ),
    .I_ap_done      (I_tcap_done         ),
    .I_ap_clear     (S_ap_start_pose     ),
    .O_ap_done_lck  (S_tcap_done_lck     )  
);

ap_done_lck u_ldap_done_lck(
    .I_clk          (I_clk               ),
    .I_ap_start     (I_ap_start          ),
    .I_ap_done      (I_ldap_done         ),
    .I_ap_clear     (S_ap_start_pose     ),
    .O_ap_done_lck  (S_ldap_done_lck     )  
);


ap_done_lck u_swap_done_lck(
    .I_clk         (I_clk                ),
    .I_ap_start    (I_ap_start           ),
    .I_ap_done     (I_swap_done          ),
    .I_ap_clear    (S_ap_start_pose      ),
    .O_ap_done_lck (S_swap_done_lck      )  
);

ap_done_lck u_peap_done_lck(
    .I_clk         (I_clk                ),
    .I_ap_start    (I_ap_start           ),
    .I_ap_done     (I_peap_done          ),
    .I_ap_clear    (S_ap_start_pose      ),
    .O_ap_done_lck (S_peap_done_lck      )  
);


ap_done_lck u_pqap_done_lck(
    .I_clk         (I_clk                ),
    .I_ap_start    (I_ap_start           ),
    .I_ap_done     (I_pqap_done          ),
    .I_ap_clear    (S_ap_start_pose      ),
    .O_ap_done_lck (S_pqap_done_lck      )  
);

ap_done_lck u_ppap_done_lck(
    .I_clk         (I_clk                ),
    .I_ap_start    (I_ap_start           ),
    .I_ap_done     (I_ppap_done          ),
    .I_ap_clear    (S_ap_start_pose      ),
    .O_ap_done_lck (S_ppap_done_lck      )  
);

ap_done_lck u_mpap_done_lck(
    .I_clk         (I_clk                ),
    .I_ap_start    (I_ap_start           ),
    .I_ap_done     (I_mpap_done          ),
    .I_ap_clear    (S_ap_start_pose      ),
    .O_ap_done_lck (S_mpap_done_lck      )     
);

assign S_done_lck = S_tcap_done_lck & 
                    S_ldap_done_lck & 
                    S_swap_done_lck ; 
always @(posedge I_clk)begin
    //S_all_done_lck  <=  S_ldap_done_lck & 
    //                    S_swap_done_lck & 
    //                    S_peap_done_lck & 
    //                    S_pqap_done_lck & 
    //                    S_ppap_done_lck & 
    //                    S_mpap_done_lck ;
    S_all_done_lck  <= S_done_lck || (S_tcap_done_lck && (O_hcnt_pre=={(C_DIM_WIDTH){1'b0}})); 
    S_all_done_lck_1d <= S_all_done_lck ;
end

always @(posedge I_clk)begin
    if(I_ap_start)begin
        S_hcnt_valid <= S_all_done_lck &&  (~S_all_done_lck_1d);
    end
    else begin
        S_hcnt_valid <= 1'b0;
    end
end

always @(posedge I_clk)begin
    S_ap_start_1d       <= I_ap_start                                       ;
    S_tcap_start_pose   <= S_hcnt_valid || (I_ap_start && (!S_ap_start_1d)) ;
    S_ap_start_pose     <= S_hcnt_valid                                     ; 
end

cm_cnt #(
    .C_WIDTH(C_DIM_WIDTH))
u0_hcnt(
    .I_clk               (I_clk             ),
    .I_cnt_en            (I_ap_start        ),
    .I_lowest_cnt_valid  (1'b1              ),
    .I_cnt_valid         (S_hcnt_valid      ),
    .I_cnt_upper         (I_hcnt_total      ),
    .O_over_flag         (S_hcnt_overflag   ),
    .O_cnt               (O_hcnt_pre        ) 
);

initial begin
    O_hcnt = {(C_DIM_WIDTH){1'b0}}; 
end

always @(posedge I_clk)begin
    if(S_hcnt_valid)begin
        O_hcnt <= O_hcnt_pre    ;
    end
    else begin
        O_hcnt <= O_hcnt        ; 
    end

end

always @(posedge I_clk)begin
    S_ap_done_2d <= S_ap_done_1d    ;
end

always @(posedge I_clk)begin
    if(S_hcnt_overflag && S_hcnt_valid)begin
        S_ap_done_1d      <= 1'b1; 
    end
    else begin
        S_ap_done_1d      <= 1'b0; 
    end
end

always @(posedge I_clk)begin
    O_ap_done <= (~S_ap_done_2d) && S_ap_done_1d    ;
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
