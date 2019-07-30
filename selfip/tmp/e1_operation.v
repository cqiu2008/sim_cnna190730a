//FILE_HEADER-------------------------------------------------------
//ZTE Copyright(C)
// ZTE Company Confidential
//------------------------------------------------------------------
// Project Name : ZXLTE xxxx
// FILE NAME    : e1_operation.v
// AUTHOR       : yuan,xuelong
// Department   : ZTE-BBU System Department
// Email        : yuan.xuelong@zte.com.cn
//------------------------------------------------------------------
// Module Hiberarchy:
//x                 |----tx_cpri_timing
//x                 |----tx_cpri_iq_map   
//x tx_cpri_top-----|----tx_cpri_spec_cw   
//x                 |----tx_cpri_vendor_cw
//x                 |----tx_cpri_framing 
//-----------------------------------------------------------------
// Release History:
//-----------------------------------------------------------------
// Version      Date      Author        Description
// 1.0        2-23-2012   yuanxuelong   initial version
// 1.1        mm-dd-yyyy   Author       修改、增减的主要内容描述
//-----------------------------------------------------------------
//Main Function:
// a) Insert basic spec ctrl words,mac or hdlc data and iq data into cpri frame.
//-----------------------------------------------------------------
//REUSE ISSUES: xxxxxxxx          
//Reset Strategy: asynchronous reset
//Clock Strategy: xxxxxxxx
//Critical Timing: xxxxxxxx
//Asynchronous Interface: xxxxxxxx
//END_HEADER--------------------------------------------------------

module e1_operation
    #(parameter          C_E1_CHS_NUM = 6'd16,
                         C_FRAME_DADA_NUM = 7'd111
    )
(
    input                        I_cpu_cs_n     ,///cpu片选信号
    input                        I_cpu_rd_n     ,///cpu读使能信号
    input                        I_cpu_wr_n     ,///cpu写使能信号
    input     [15:0]             I_cpu_addr     ,///cpu地址
    input     [15:0]             I_cpu_data_in  ,///cpu输入数据

///========================clk  rst  interface ===========================================
    input                        I_125m_clk     ,/// 125M时钟
    input                        I_rst          ,/// 复位信号，高有效

///========================2916 input interface ==========================================

    input    [C_E1_CHS_NUM-1:0]  I_e1_bpv       ,///输入编码违例信号

///=========================GMII     rx        interface ===================================
    input                        I_gmii_rxen    ,///GMII RX EN
    input                        I_gmii_rxer    ,///GMII RX ERROR
    input      [7:0]             I_gmii_din     ,///GMII RX DATA

///========================e1 loss input    interface ===================================
    input                        I_liu1_clke1    ,   ///clk_e1
    input                        I_liu1_llos     ,   ///loss
    input                        I_liu1_llos0    ,   ///start of loss
    
    input      [C_E1_CHS_NUM-1:0]            I_e1_clk_status ,   ///输入各路e1时钟状态
    
    input                        I_3001_2m_clk           ,///输入时钟
    input     [C_E1_CHS_NUM-1:0] I_rclk                  ,///输入接收e1时钟
    input     [C_E1_CHS_NUM-1:0] I_rdp                   ,///输入接收e1数据
    
///=====================new add==========================//by saibin 20111220
    input                          I_liu1_refa           , ///LIU REFCLK_A,2.048Mhz
    input                          I_liu1_refb           , ///LIU REFCLK_B,2.048Mhz

///=========================GMII     tx        interface ===================================
    output                       O_gmii_txer            ,/// GMII TX ERROR
    output                       O_gmii_txen            ,/// GMII TX EN
    output     [7:0]             O_gmii_dout            ,/// GMII TX DATA
    
///========================2916 output   interface ==========================================
    output   [15:0]              O_cpu_data_out         ,///cpu输出数据

    output   [C_E1_CHS_NUM-1:0]  O_tclk                 , ///输出发送e1时钟
    output   [C_E1_CHS_NUM-1:0]  O_tdp                  , ///输出发送e1数据
    
///========================e1 loss ===================================
    output   [C_E1_CHS_NUM-1:0]  O_liu1_los             , ///LIU LOSS

///================new add===================///by saibin 20111220
    output                       O_50hz_clk, ///选择提取E1线路时钟分频到50Hz输出，送给时钟同步模块
    output                       O_mclk_liu, ///提供给2916芯片的工作时钟，2.048Mhz
    output    [3:0]              O_liu_mclk_sel ///2916芯片工作时钟配置信号
    );

    reg      [C_E1_CHS_NUM-1:0]  S_ram_extrm ;///

///=================ais_detect  output    interface =======================================
    wire     [C_E1_CHS_NUM-1:0]  S_ais_alarm    ;///ais告警检测值
///=================code_rate_adjust  output    interface =======================================
    wire     [C_E1_CHS_NUM-1:0]  S_chs_downfifo_wr  ;///下行ram写使能
    wire     [C_E1_CHS_NUM-1:0]  S_chs_downbag_wrend;///下行ram写完成信号
    wire       [7:0]             S_chs_downfifo_din [C_E1_CHS_NUM-1:0];////下行ram写数据
///==================dnram_ctrl   output    interface ====================================
    wire       [2:0]             S_chs_downfifo_frame_cnt[C_E1_CHS_NUM-1:0]; ////下行ram 帧个数
    wire       [7:0]             S_chs_downfifo_dout[C_E1_CHS_NUM-1:0];////下行ram 读数据
///===========================e1_tx_mux   output    interface ====================================
    wire     [C_E1_CHS_NUM-1:0]  S_chs_downfifo_rd  ;///下行ram读使能
    wire     [C_E1_CHS_NUM-1:0]  S_chs_downbag_rdend;///下行ram读完成信号
    wire                         S_txfifo_full      ;///下行fifo满标志
    wire                         S_e1_tx_trigger    ;///打包触发信号
    wire       [7:0]             S_dat_to_gmii      ;///打包数据
    wire                         S_txmux_state_idle ;///打包idle状态
    wire       [6:0]             S_chsnum_ram_addrb ;///通道号ram读地址
    wire       [7:0]             S_ais_alarm_ecid   ;///ecid数据
///================xilinx_tdram_512x8  output    interface ====================================
    wire       [7:0]             S_da_ram_doutb     ;///目的地址ram读数据
///================ xilinx_tdram_128x8     interface ====================================
    wire       [7:0]             S_chsnum_ram_doutb ;///通道号ram读数据
///=====================mac_packing     output    interface ====================================
    wire                         S_tx_dat_req       ;///数据请求，如果对接的是FIFO，
                                                    ///则在其有效后的第3个时钟上升沿数据开始有效
    wire                         S_mac_packing      ;///0指示mac_packing模块正在执行发送，忙！
    wire                         S_mac_packing_bagend;///MAC打包结束信号
    wire       [8:0]             S_da_rdaddr        ;///目的地址ram读地址
///======================mac_unpacking   output    interface ====================================
    wire       [7:0]             S_e1_rxchs_num     ;///解MAC包得到的通道号
    wire       [7:0]             S_rx_mac_data      ;////解MAC包得到的数据
///=====================e1_rx_mux  output  interface ==========================================
    wire     [C_E1_CHS_NUM-1:0]  S_chs_upfifo_wr    ;///上行fifo写使能
    wire       [7:0]             S_chs_upfifo_din[C_E1_CHS_NUM-1:0]; ///上行fifo写数据
    wire     [C_E1_CHS_NUM-1:0]  S_chs_upbag_wrend  ;///一级缓存写MAC包结束信号
///=================== upram_ctrl   output  interface ==========================================
    wire       [9:0]             S_chs_upfifo_byte_cnt[C_E1_CHS_NUM-1:0];///上行ram 帧个数
    wire       [7:0]             S_chs_upfifo_dout[C_E1_CHS_NUM-1:0];///上行ram 输出数据
    wire     [C_E1_CHS_NUM-1:0]  S_1st_ff_1st_stuff ;/// 
    wire       [15:0]            S_reconstruction_times[C_E1_CHS_NUM-1:0];///上行ram重构时间？？
    wire       [9:0]             S_byte_num_min[C_E1_CHS_NUM-1:0];///上行ram帧最小值
    wire       [9:0]             S_byte_num_max[C_E1_CHS_NUM-1:0];//上行ram帧最大值
///=====================clock_recovery output  interface =======================================
    wire     [C_E1_CHS_NUM-1:0]  S_chs_upfifo_rd    ;///上行ram 读信号
    wire     [C_E1_CHS_NUM-1:0]  S_chs_upbag_rdend  ;///上行ram 读完成
    wire     [C_E1_CHS_NUM-1:0]  S_fifo_almost_empty;///上行fifo空
    wire       [6:0]             S_bit_num_min[C_E1_CHS_NUM-1:0];///上行ram帧最小值
    wire       [6:0]             S_bit_num_max[C_E1_CHS_NUM-1:0];//上行ram帧最大值 
    wire       [6:0]             S_bit_num_now[C_E1_CHS_NUM-1:0];//上行ram帧当前值   
///================== clk_2m072_recov   output    interface ====================================
    wire     [C_E1_CHS_NUM-1:0]  S_2m072_revclk     ;///2.072恢复时钟
    ///wire       [15:0]             S_e1opt_mrst       ;///模块复位信号
    wire     [15:0]            S_mac_packing_status   ;///MAC打包状态机
    wire     [47:0]            S_mac_unpacking_status ;///MAC解包状态机
///================== localbus   output    interface ====================================
    wire                           S_fcserr_test_en      ; ///帧校验字段测试使能
    wire                           S_gmii_test_en        ; ///gmii数据测试使能
    wire      [47:0]               S_e1_sa               ; ///源地址
    wire      [15:0]               S_macbag_type         ; ///mac包类型
    wire                           S_da_ram_wren         ; ///目的地址ram写使能
    wire                           S_chsnum_ram_wren     ; ///通道号ram写使能
    wire      [9:0]                S_upram_level_m       ; ///上行ram水位设定
    wire      [9:0]                S_upram_level_h       ; ///上行ram水位上限
    wire      [9:0]                S_upram_level_l       ; ///上行ram水位下限
    wire      [15:0]               S_2m072_adjust_delay  ; ///
    wire      [15:0]               S_2m048_adjust_delay  ; ///
    wire      [1:0]                S_alarm_tpye          ; ///告警类型
    wire      [7:0]                S_chsnum_ram_douta    ; ///通道号ram数据输出
    wire      [7:0]                S_da_ram_douta        ; ///目的地址ram数据输出
    wire      [C_E1_CHS_NUM-1:0]   S_e1_txfifo_empty     ; ///各路e1发送fifo空
    wire      [C_E1_CHS_NUM-1:0]   S_fifo_crumple        ; ///各通道fifo异常
    wire      [C_E1_CHS_NUM-1:0]   S_chs_upfifo_empty    ; ///各路e1接收fifo空
    wire                           S_package_cnt_clr     ; ///包计数清零
    wire                           S_fcserr_flag         ; ///校验错误标志
    wire      [15:0]               S_gmii_txpackage_cnt  ; ///gmii数据发送包个数统计
    wire      [15:0]               S_gmii_rxpackage_cnt  ; ///gmii数据接收包个数统计
    wire      [15:0]               S_fcserr_package_cnt  ; ///fcs校验错误包个数统计
    wire                           S_snapshot_ram_clr         ; ///抓包ram清零
    ///wire                           S_grasp_mode          ; ///
  
    wire      [9:0]                S_graspram_dout       ; ///抓包ram数据输出
    ///wire                           S_e1_gmii_rxen        ; ///
    wire      [15:0]               S_e1_operation_status ; ///gmii接收与发送数据的有效与错误标志
    wire      [9:0]                S_fifo_byte_num      ; ///fifo存数帧数目
    wire      [9:0]                S_byte_num_min0      ; ///存储帧最小值
    wire      [9:0]                S_byte_num_max0      ; ///存储帧最大值
    wire      [6:0]                S_bit_num_min0      ; ///存储帧最小值
    wire      [6:0]                S_bit_num_max0      ; ///存储帧最大值
    wire      [6:0]                S_bit_num_now0      ; ///存储帧当前值
    reg                            S_ram_extrm_bit       ; ///

    wire     [C_E1_CHS_NUM-1:0]    S_chs_en              ; ///各通道使能
    wire     [C_E1_CHS_NUM-1:0]    S_liu_e1_liu_loop_en   ;///环回使能信号 
    wire     [C_E1_CHS_NUM-1:0]    S_back_e1_back_loop_en ;///环回使能信号
    wire     [C_E1_CHS_NUM-1:0]    S_e1_liu_e1_loop_en;///环回使能信号

    wire     [C_E1_CHS_NUM-1:0]    S_e1_macback_e1_en     ;    ///环回使能信号
    wire     [C_E1_CHS_NUM-1:0]    S_bits2m_chs_sel       ;    ///通道号选择信号
    wire     [C_E1_CHS_NUM-1:0]    S_e1opt_tclk           ;    ///恢复出的e1时钟
    wire     [C_E1_CHS_NUM-1:0]    S_e1opt_tdat           ;    ///恢复出的e1数据
    wire     [C_E1_CHS_NUM-1:0]    S_e1opt_rclk           ;    ///接收到的e1时钟
    wire     [C_E1_CHS_NUM-1:0]    S_e1opt_rdat           ;    ///接收到的e1数据
    
    wire                           S_prbs_err             ;    ///PRBS检测错误指示

      
    wire     [15:0]                S_err_cnt              ;    ///PRBS数据错误统计
    wire     [31:0]                S_err_bits_cnt         ;    ///PRBS误码率检测错误bits数
    wire     [31:0]                S_total_bits_cnt       ;    ///PRBS误码率检测总bits数
    
    wire                           S_e1_opt2_rst          ;   ///复位信号，暂时没用
    wire                           S_e1_opt3_rst          ;   ///复位信号，暂时没用       
    wire     [15:0]                S_module_rst           ;   ///复位信号，暂时没用 
    wire                           S_snapshot_mode        ;   ///抓包模式
    wire     [C_E1_CHS_NUM-1:0]    S_cv_cnt_rden          ;   ///编码违例读使能
    wire     [23:0]                S_cv_cnt[C_E1_CHS_NUM-1:0];///编码违例计数  
    wire                           S_e1_opt_rst_tmp       ;   ///e1各模块复位信号
    
    wire                           S_prbs_chk_clr_en      ;   ///PRBS检测错误计数器清零信号
    wire                           S_ber_cnt_clr          ;   ///PRBS误码率统计清零信号
    wire     [C_E1_CHS_NUM-1:0]    S_prbs_ber_ch_sel      ;   ///PRBS误码率统计通道选择信号
    
    wire     [C_E1_CHS_NUM-1:0]    S_e1_get_line_prbs_en  ;   ///
    wire     [C_E1_CHS_NUM-1:0]    S_insert_sys_ais_en    ;   ///
    wire     [C_E1_CHS_NUM-1:0]    S_insert_line_ais_en   ;   ///
    
    wire     [5:0]                 S_fpga_50hz_sel        ; ///add by saibin 20111120 50hz时钟选取信号
        
///=================new add===============================///by saibin 20111221
    wire                            S_2m072_clk            ;///2.072Mhz时钟
    wire                            S_gmii_inloop_en       ;///内环回使能
    wire                            S_gmii_outloop_en      ;///外环回使能
    wire     [7:0]                  S_gmii_dout            ;///gmii数据输出
    wire                            S_gmii_txen            ;///gmii数据输出有效信号 
    wire                            S_gmii_txer               ;///gmii数据输入错误信号 
    wire     [7:0]                  S_gmii_din             ;///gmii数据输出            
    wire                            S_gmii_rxer            ;///gmii数据输出错误信号         
    wire                            S_gmii_rxen            ;///gmii数据输入有效信号  
    wire     [5:0]                  S_txpackidlecnt_min    ;///发送最小包间隔数量
    wire      [5:0]                 S_rxpackidlecnt_min    ; ///接收最小包间隔数量
    wire    [6:0]                   S_upfifo_almost_empty_level ; ///E1时钟恢复FIFO接近空门限
    wire    [6:0]                   S_upfifo_recovery_level     ; ///E1时钟恢复调整使能门限  
    wire    [6:0]                   S_upfifo_level_l       ;///E1时钟恢复FIFO水位低门限
    wire    [6:0]                   S_upfifo_level_m       ;///E1时钟恢复FIFO水位中门限
    wire    [6:0]                   S_upfifo_level_h       ;///E1时钟恢复FIFO水位高门限
    ///wire    [13:0]                  S_2m72_ajust_step      ;///2.072mhz时钟调整步长
    ///wire    [13:0]                  S_2m48_ajust_step      ;///2.048mhz时钟调整步长
    ///multi Frame
     wire                            S_soft_clr           ;///
    wire                            S_soft_switch        ;///
    wire    [C_E1_CHS_NUM-1:0]      S_multi_frame_ch_sel ;///
    wire                            S_multi_frame_dir_sel;///
    wire                            S_FAS                ;///
    wire    [15:0]                  S_crc_num            ;///
 
    genvar                       i                  ;///i
    integer                      m                  ;///m
  
    assign  S_e1_operation_status = {12'h000,I_gmii_rxen,I_gmii_rxer,O_gmii_txen,O_gmii_txer};
    assign  S_fifo_byte_num = S_chs_upfifo_byte_cnt[0];
    assign  S_byte_num_min0 = S_byte_num_min[0];
    assign  S_byte_num_max0 = S_byte_num_max[0];
    assign  S_bit_num_min0 = S_bit_num_min[0];
    assign  S_bit_num_max0 = S_bit_num_max[0]; 
    assign  S_bit_num_now0 = S_bit_num_now[0]; 
      
    assign  O_mclk_liu = I_3001_2m_clk;
    ///assign  O_ch0_2m072_clk = S_2m072_revclk[0];

    e1_reg   u_e1_reg  (
    ///common singal interface
         .I_125m_clk              (I_125m_clk              ),
         .I_rst                   (I_rst                   ),     
         .I_cpu_cs_n              (I_cpu_cs_n              ),
         .I_cpu_rd_n              (I_cpu_rd_n              ),
         .I_cpu_wr_n              (I_cpu_wr_n              ),
         .I_cpu_addr              (I_cpu_addr              ),
         .I_cpu_data_in           (I_cpu_data_in           ),
         .I_liu1_los              (O_liu1_los              ),
         .I_e1_bpv                (I_e1_bpv                ),     
         .I_e1_clk_status         (I_e1_clk_status         ),
         .I_e1_liu_e1_loop_err_cnt(S_err_cnt               ),
         .I_prbs_err              (S_prbs_err              ), 
         .I_operation_status      (S_e1_operation_status   ),
         .I_mac_packing_status    (S_mac_packing_status    ),
         .I_mac_unpacking_status  (S_mac_unpacking_status  ),
         .I_fifo_byte_num        (S_fifo_byte_num        ),
         .I_reconstruction_times  (S_reconstruction_times[0]),
         .I_frame_num_min         (S_byte_num_min0        ),
         .I_frame_num_max         (S_byte_num_max0        ),
         .I_bit_num_min           (S_bit_num_min0          ),
         .I_bit_num_max           (S_bit_num_max0          ),
         .I_bit_num_now           (S_bit_num_now0          ),
         .I_gmii_txpackage_cnt    (S_gmii_txpackage_cnt    ),
         .I_gmii_rxpackage_cnt    (S_gmii_rxpackage_cnt    ),
         .I_fcserr_package_cnt    (S_fcserr_package_cnt    ),
         .I_e1_txfifo_empty       (S_e1_txfifo_empty       ),
         .I_e1_rxfifo_empty       (S_chs_upfifo_empty      ),
         .I_fifo_crumple          (S_fifo_crumple          ),
         .I_chsnum_ram_dout       (S_chsnum_ram_douta      ),
         .I_da_ram_dout           (S_da_ram_douta          ),
         .I_graspram_dout         (S_graspram_dout         ),
         .I_ram_extrm             (S_ram_extrm_bit         ),        
         .I_txpackidlecnt_min     (S_txpackidlecnt_min     ),                       
         .I_rxpackidlecnt_min     (S_rxpackidlecnt_min     ),          
         .I_e1_tx_mux_status      (S_chsnum_ram_addrb      ),
         .I_cv_cnt_0              (S_cv_cnt[0 ]            ),
         .I_cv_cnt_1              (S_cv_cnt[1 ]            ),
         .I_cv_cnt_2              (S_cv_cnt[2 ]            ),
         .I_cv_cnt_3              (S_cv_cnt[3 ]            ),
         .I_cv_cnt_4              (S_cv_cnt[4 ]            ),
         .I_cv_cnt_5              (S_cv_cnt[5 ]            ),
         .I_cv_cnt_6              (S_cv_cnt[6 ]            ),
         .I_cv_cnt_7              (S_cv_cnt[7 ]            ),
         .I_cv_cnt_8              (S_cv_cnt[8 ]            ),
         .I_cv_cnt_9              (S_cv_cnt[9 ]            ),
         .I_cv_cnt_10             (S_cv_cnt[10]            ),
         .I_cv_cnt_11             (S_cv_cnt[11]            ),
         .I_cv_cnt_12             (S_cv_cnt[12]            ),
         .I_cv_cnt_13             (S_cv_cnt[13]            ),
         .I_cv_cnt_14             (S_cv_cnt[14]            ),
         .I_cv_cnt_15             (S_cv_cnt[15]            ),
         .I_ais_alarm             (S_ais_alarm             ),
         .I_err_bits_cnt          (S_err_bits_cnt          ),  
         .I_total_bits_cnt        (S_total_bits_cnt        ),                  
         .O_cpu_data_out          (O_cpu_data_out          ),
         .O_upram_level_m         (S_upram_level_m         ),
         .O_upram_level_h         (S_upram_level_h         ),
         .O_upram_level_l         (S_upram_level_l         ),
         .O_e1_macback_e1_en      (S_e1_macback_e1_en      ),
         .O_bits2m_chs_sel        (S_bits2m_chs_sel        ),
         
         //E1 multiFrame
         .O_soft_clr             (S_soft_clr),
         .O_soft_switch          (S_soft_switch),
         .O_multi_frame_ch_sel   (S_multi_frame_ch_sel),
         .O_multi_frame_dir_sel  (S_multi_frame_dir_sel),
         .I_FAS                  (S_FAS),
         .I_crc_num              (S_crc_num),

         .O_chs_en                (S_chs_en                ),
         .O_fpga_50hz_sel         (S_fpga_50hz_sel         ),
         .O_liu_e1_liu_loop_en    (S_liu_e1_liu_loop_en    ),
         .O_liu_mac_liu_loop_en   (S_gmii_inloop_en        ), 
         .O_back_e1_back_loop_en  (S_back_e1_back_loop_en  ), 
         .O_back_mac_back_loop_en (S_gmii_outloop_en ),
         .O_e1_liu_e1_loop_en (S_e1_liu_e1_loop_en ),
         .O_low_adjust_delay      (S_2m048_adjust_delay    ),
         .O_high_adjust_delay     (S_2m072_adjust_delay    ),
         .O_e1_sa                 (S_e1_sa                 ),
         .O_mac_type              (S_macbag_type           ),
         .O_da_ram_wren           (S_da_ram_wren           ),
         .O_chsnum_ram_wren       (S_chsnum_ram_wren       ),
         .O_fcserr_test_en        (S_fcserr_test_en        ),
         .O_gmii_test_en          (S_gmii_test_en          ),
         .O_e1_alarm_type         (S_alarm_tpye            ),
         .O_package_cnt_clr       (S_package_cnt_clr       ),
         .O_snapshot_ram_clr      (S_snapshot_ram_clr      ),
         .O_snapshot_mode         (S_snapshot_mode         ),
         .O_e1_opt1_rst           (S_e1_opt_rst_tmp        ),
         .O_e1_opt2_rst           (S_e1_opt2_rst           ),
         .O_e1_opt3_rst           (S_e1_opt3_rst           ),                  
         .O_module_rst            (S_module_rst            ), ///CAUTION 暂未使用
         .O_cv_cnt_rden           (S_cv_cnt_rden           ),
         .O_liu_mclk_sel      (O_liu_mclk_sel          ),
         .O_prbs_chk_clr_en       (S_prbs_chk_clr_en       ),
         .O_ber_cnt_clr           (S_ber_cnt_clr),
         .O_prbs_ber_ch_sel       (S_prbs_ber_ch_sel),
         .O_upfifo_almost_empty_level(S_upfifo_almost_empty_level),
         .O_upfifo_recovery_level    (S_upfifo_recovery_level    ),  
         .O_upfifo_level_l        (S_upfifo_level_l        ),
         .O_upfifo_level_m        (S_upfifo_level_m        ),
         .O_upfifo_level_h        (S_upfifo_level_h        ),
         ///.O_2m72_ajust_step       (S_2m72_ajust_step       ) ///2.072mhz时钟调整步长
         ///.O_2m48_ajust_step       (S_2m48_ajust_step       )  ///2.048mhz时钟调整步长
         .O_e1_get_line_prbs_en   (S_e1_get_line_prbs_en   ),
         .O_insert_sys_ais_en     (S_insert_sys_ais_en     ), 
         .O_insert_line_ais_en    (S_insert_line_ais_en    )                  
    );

///novas -22265:12 
//novas -27351:14
//novas -27363:13
always@( * )
  begin
   for (m=0;m<C_E1_CHS_NUM;m=m+32'b1) ///saibin modified for lint 22265 
      begin
         if((~S_1st_ff_1st_stuff[m]) &&((S_chs_upfifo_byte_cnt[m]<10'd55)
                                    ||(S_chs_upfifo_byte_cnt[m]>10'd277)) && (S_chs_en[m]) )
                S_ram_extrm[m]<=1'b1;
         else
                  S_ram_extrm[m]<=1'b0;
       end
    end


always @ (posedge I_125m_clk or posedge I_rst)
begin
    if(I_rst)
     begin
         S_ram_extrm_bit <= 1'b0;
     end
     else
     begin
         S_ram_extrm_bit <= |S_ram_extrm;
     end
end
///assign   S_ram_extrm_bit=|S_ram_extrm;

//novas -27363:51
//novas -22105:51
//novas -21047:51
    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : gen_e1_ais_detect
             e1_ais_detect  u_e1_ais_detect
            (
                .I_125m_clk         ( I_125m_clk             ),
                .I_rst              ( S_e1_opt_rst_tmp       ),
                .I_chs_en           ( S_chs_en[i]            ),
                .I_e1_clkin         ( S_e1opt_rclk[i]        ),
                .I_e1_din           ( S_e1opt_rdat[i]        ),
                .I_alarm_tpye       ( 2'b10                  ),
                .O_ais_alarm        (S_ais_alarm[i]          )
               );
        end
    endgenerate ///gen_e1_ais_detect

    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : gen_code_rate_adjust
            code_rate_adjust u_code_rate_adjust
                (
                .I_125m_clk         ( I_125m_clk             ),
                .I_rst              ( S_e1_opt_rst_tmp       ),
                .I_chs_en           ( S_chs_en[i]            ),
                .I_e1_clkin         ( S_e1opt_rclk[i]        ),
                .I_e1_din           ( S_e1opt_rdat[i]        ),
                .I_2m072_clk        ( S_2m072_clk            ),
                .O_storage_wren     ( S_chs_downfifo_wr[i]   ),
                .O_packege_wrend    ( S_chs_downbag_wrend[i] ),
                .O_shift_para_out   ( S_chs_downfifo_din[i]  )
            );
        end
    endgenerate ///gen_code_rate_adjust
//novas -27363:15
//novas -22105:15
//novas -21047:15

    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : dnram_ctrl
            dnram_ctrl u_downram_ctrl
            (
                .I_125m_clk       ( I_125m_clk                  ),
                .I_rst            ( S_e1_opt_rst_tmp            ),
                .I_wren           ( S_chs_downfifo_wr[i]        ),
                .I_packege_wrend  ( S_chs_downbag_wrend[i]      ),
                .I_packege_rdend  ( S_chs_downbag_rdend[i]      ),
                .I_rden           ( S_chs_downfifo_rd[i]        ),
                .I_fifo_din       ( S_chs_downfifo_din[i]       ),

                .O_fifo_dout      ( S_chs_downfifo_dout[i]      ),
                .O_fifo_frame_num ( S_chs_downfifo_frame_cnt[i] )
            );
        end
    endgenerate ///e1_downfifo

    e1_tx_mux
        #(C_E1_CHS_NUM,C_FRAME_DADA_NUM)
    u_e1_tx_mux
    (
        .I_125m_clk             ( I_125m_clk                    ),
        .I_rst                  ( S_e1_opt_rst_tmp              ),
        .I_ch00_downfifo_dout   ( S_chs_downfifo_dout[0 ]       ),
        .I_ch01_downfifo_dout   ( S_chs_downfifo_dout[1 ]       ),
        .I_ch02_downfifo_dout   ( S_chs_downfifo_dout[2 ]       ),
        .I_ch03_downfifo_dout   ( S_chs_downfifo_dout[3 ]       ),
        .I_ch04_downfifo_dout   ( S_chs_downfifo_dout[4 ]       ),
        .I_ch05_downfifo_dout   ( S_chs_downfifo_dout[5 ]       ),
        .I_ch06_downfifo_dout   ( S_chs_downfifo_dout[6 ]       ),
        .I_ch07_downfifo_dout   ( S_chs_downfifo_dout[7 ]       ),
        .I_ch08_downfifo_dout   ( S_chs_downfifo_dout[8 ]       ),
        .I_ch09_downfifo_dout   ( S_chs_downfifo_dout[9 ]       ),
        .I_ch10_downfifo_dout   ( S_chs_downfifo_dout[10]       ),
        .I_ch11_downfifo_dout   ( S_chs_downfifo_dout[11]       ),
        .I_ch12_downfifo_dout   ( S_chs_downfifo_dout[12]       ),
        .I_ch13_downfifo_dout   ( S_chs_downfifo_dout[13]       ),
        .I_ch14_downfifo_dout   ( S_chs_downfifo_dout[14]       ),
        .I_ch15_downfifo_dout   ( S_chs_downfifo_dout[15]       ),
        
        .I_ch00_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[0 ]  ),
        .I_ch01_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[1 ]  ),
        .I_ch02_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[2 ]  ),
        .I_ch03_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[3 ]  ),
        .I_ch04_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[4 ]  ),
        .I_ch05_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[5 ]  ),
        .I_ch06_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[6 ]  ),
        .I_ch07_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[7 ]  ),
        .I_ch08_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[8 ]  ),
        .I_ch09_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[9 ]  ),
        .I_ch10_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[10]  ),
        .I_ch11_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[11]  ),
        .I_ch12_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[12]  ),
        .I_ch13_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[13]  ),
        .I_ch14_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[14]  ),
        .I_ch15_downfifo_frame_cnt  ( S_chs_downfifo_frame_cnt[15]  ),
         
        .I_tx_dat_req               ( S_tx_dat_req                  ),
        .I_mac_packing              ( S_mac_packing                 ),
        .I_mac_package_end          ( S_mac_packing_bagend          ),
        .I_ais_alarm                ( S_ais_alarm                   ),
        .O_chsnum_ram_rdaddr        ( S_chsnum_ram_addrb            ),
        .O_txmux_state_idle         ( S_txmux_state_idle            ),
        .O_txfifo_full              ( S_txfifo_full                 ),
        .O_chs_downfifo_rd          ( S_chs_downfifo_rd             ),
        .O_chs_package_rdend        ( S_chs_downbag_rdend           ),
        .O_e1_tx_trigger            ( S_e1_tx_trigger               ),
        .O_dat_to_gmii              ( S_dat_to_gmii                 ),
        .O_ais_alarm_ecid           ( S_ais_alarm_ecid              )
    );

    alt_tdram_512x8    alt_tdram_512x8_inst    ///DA ram
    (
        .aclr_a       ( I_rst ),
        .aclr_b       ( I_rst ),
        .address_a    ( I_cpu_addr[8:0]  ),
        .address_b    ( S_da_rdaddr ),
        .clock_a      ( I_125m_clk ),
        .clock_b      ( I_125m_clk ),
        .data_a       ( I_cpu_data_in[7:0]  ),
        .data_b       ( 8'h0   ),
        .wren_a       ( S_da_ram_wren ),
        .wren_b       ( 1'b0  ),
        .q_a          ( S_da_ram_douta ),
        .q_b          ( S_da_ram_doutb )
    );
       
    alt_tdram_128x8    alt_tdram_128x8_inst   ///chsnum_ram
    (
        .aclr_a         ( I_rst ),
        .aclr_b         ( I_rst ),
        .address_a      ( I_cpu_addr[6:0]   ),
        .address_b      ( S_chsnum_ram_addrb ),
        .clock_a        ( I_125m_clk ),
        .clock_b        ( I_125m_clk ),
        .data_a         ( I_cpu_data_in[7:0] ),
        .data_b         ( 8'h0   ),
        .wren_a         ( S_chsnum_ram_wren ),
        .wren_b         ( 1'b0    ),
        .q_a            ( S_chsnum_ram_douta ),
        .q_b            ( S_chsnum_ram_doutb )
    );


    mac_packing
        #(C_FRAME_DADA_NUM)
    u_mac_packing
    (
        ///clock and reset
        .I_125m_clk             ( I_125m_clk             ),
        .I_rst                  ( S_e1_opt_rst_tmp       ),
        ///interface with e1_tx_mux.v
        .I_e1_txchs_num         ( S_chsnum_ram_doutb     ),
        .I_e1_tx_trigger        ( S_e1_tx_trigger        ),
        .I_tx_mac_data          ( S_dat_to_gmii          ),
        .I_txfifo_full          ( S_txfifo_full          ),
        .I_txmux_state_idle     ( S_txmux_state_idle     ),
        ///mac source address
        .I_reg_sa               ( S_e1_sa                ),
        .I_macbag_type          ( S_macbag_type          ),
        .I_gmii_test_en         ( S_gmii_test_en         ),
        .I_fcserr_test_en       ( S_fcserr_test_en       ), 
        .I_da_ram_dout          ( S_da_ram_doutb         ),
        .I_ais_alarm_ecid       ( S_ais_alarm_ecid       ),
        ///signals to gmii transport
        .O_gmii_dout            ( S_gmii_dout            ),
        .O_gmii_txer            ( S_gmii_txer            ),
        .O_gmii_txen            ( S_gmii_txen            ),
        ///mac destination address
        .O_da_ram_rdaddr        ( S_da_rdaddr            ),
        ///signals connect with the down ram ctrl
        .O_tx_dat_req           ( S_tx_dat_req           ),
        .O_mac_packing          ( S_mac_packing          ),
        .O_mac_package_end      ( S_mac_packing_bagend   ),
        .O_mac_packing_status   ( S_mac_packing_status   )

    );

    mac_unpacking
        #(C_E1_CHS_NUM,C_FRAME_DADA_NUM)
    U_mac_unpacking (
        .I_125m_clk             ( I_125m_clk             ),
        .I_rst                  ( S_e1_opt_rst_tmp       ),
        .I_gmii_din             ( S_gmii_din             ),
        .I_gmii_rxer            ( S_gmii_rxer            ),
        .I_gmii_rxen            ( S_gmii_rxen            ),
        .I_macbag_type          ( S_macbag_type          ), ///MAC包类型        
        .I_board_addr           ( S_e1_sa                ),
        .I_gmii_test_en         ( S_gmii_test_en         ),
        .O_mac_unpacking_status ( S_mac_unpacking_status ),
        .O_e1_rxchs_num         ( S_e1_rxchs_num         ),
        .O_rx_mac_data          ( S_rx_mac_data          ),
        .O_crc_check_err        ( S_fcserr_flag        )
       
    );


    e1_rx_mux
        #(C_E1_CHS_NUM,C_FRAME_DADA_NUM)
    U_e1_rx_mux
    (
        .I_125m_clk          ( I_125m_clk           ),
        .I_rst               ( S_e1_opt_rst_tmp     ),

        .I_e1_rxchs_num      ( S_e1_rxchs_num       ),
        .I_rx_mac_data       ( S_rx_mac_data        ),
        .O_ch00_upfifo_din   ( S_chs_upfifo_din[0 ] ),
        .O_ch01_upfifo_din   ( S_chs_upfifo_din[1 ] ),
        .O_ch02_upfifo_din   ( S_chs_upfifo_din[2 ] ),
        .O_ch03_upfifo_din   ( S_chs_upfifo_din[3 ] ),
        .O_ch04_upfifo_din   ( S_chs_upfifo_din[4 ] ),
        .O_ch05_upfifo_din   ( S_chs_upfifo_din[5 ] ),
        .O_ch06_upfifo_din   ( S_chs_upfifo_din[6 ] ),
        .O_ch07_upfifo_din   ( S_chs_upfifo_din[7 ] ),
        .O_ch08_upfifo_din   ( S_chs_upfifo_din[8 ] ),
        .O_ch09_upfifo_din   ( S_chs_upfifo_din[9 ] ),
        .O_ch10_upfifo_din   ( S_chs_upfifo_din[10] ),
        .O_ch11_upfifo_din   ( S_chs_upfifo_din[11] ),
        .O_ch12_upfifo_din   ( S_chs_upfifo_din[12] ),
        .O_ch13_upfifo_din   ( S_chs_upfifo_din[13] ),
        .O_ch14_upfifo_din   ( S_chs_upfifo_din[14] ),
        .O_ch15_upfifo_din   ( S_chs_upfifo_din[15] ),
           
        .O_chs_package_wrend ( S_chs_upbag_wrend    ),
        .O_chs_upfifo_wr     ( S_chs_upfifo_wr      )
    );

//novas -27363:51
//novas -22105:51
//novas -21047:51
    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : up_ram
            upram_ctrl u_upram_ctr
            (
                .I_125m_clk                 ( I_125m_clk                    ),
                .I_rst                      ( S_e1_opt_rst_tmp                 ),
                .I_txfifo_empty             ( S_e1_txfifo_empty[i]          ),
                .I_wren                     ( S_chs_upfifo_wr[i]            ),
                .I_packege_wrend            ( S_chs_upbag_wrend[i]          ),
                .I_packege_rdend            ( S_chs_upbag_rdend[i]          ),
                .I_rden                     ( S_chs_upfifo_rd[i]            ),
                .I_fifo_din                 ( S_chs_upfifo_din[i]           ),
                .I_upram_level_m            ( S_upram_level_m               ),
                .I_upram_level_h            ( S_upram_level_h               ),
                .I_upram_level_l            ( S_upram_level_l               ),
                .O_fifo_empty               ( S_chs_upfifo_empty[i]         ),
                .O_fifo_dout                ( S_chs_upfifo_dout[i]          ),
                .O_fifo_crumple             ( S_fifo_crumple[i]             ),
                .O_fifo_byte_num           ( S_chs_upfifo_byte_cnt[i]     ),
                .O_byte_num_min            ( S_byte_num_min[i]            ),
                .O_byte_num_max            ( S_byte_num_max[i]            ),
                .O_reconstruction_times     ( S_reconstruction_times[i]     ),
                .O_1st_ff_1st_stuff         ( S_1st_ff_1st_stuff[i]       )
            );
        end
    endgenerate ///e1_upfifo

    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : gen_clock_recovery
            clock_recovery
            u_clock_recovery
            (
                .I_125m_clk                 ( I_125m_clk                    ),
                .I_rst                      ( S_e1_opt_rst_tmp                 ),
                .I_2m072_clk                ( S_2m072_revclk[i]             ),
                .I_fifo_crumple             ( S_fifo_crumple[i]             ),
                .I_upfifo_empty             ( S_chs_upfifo_empty[i]         ),
                .I_2m048_adjust_delay       ( S_2m048_adjust_delay          ),
                .I_1st_ff_1st_stuff         ( S_1st_ff_1st_stuff[i]         ),
                .I_upfifo_dout              ( S_chs_upfifo_dout[i]          ),
                .I_upfifo_almost_empty_level( S_upfifo_almost_empty_level   ),
                .I_upfifo_recovery_level    ( S_upfifo_recovery_level       ),    
                .I_upfifo_level_l           ( S_upfifo_level_l              ),
                .I_upfifo_level_m           ( S_upfifo_level_m              ),
                .I_upfifo_level_h           ( S_upfifo_level_h              ), 
                ///.I_2m48_ajust_step          ( S_2m48_ajust_step             ),
                .O_e1_txfifo_empty          ( S_e1_txfifo_empty[i]          ),
                .O_upfifo_rd                ( S_chs_upfifo_rd[i]            ),
                .O_uppack_rdend             ( S_chs_upbag_rdend[i]          ),
                .O_2m048_clk                ( S_e1opt_tclk[i]               ),
                .O_e1_dout                  ( S_e1opt_tdat[i]               ),
                .O_bit_num_min              ( S_bit_num_min[i]              ),
                .O_bit_num_max              ( S_bit_num_max[i]              ),
                .O_bit_num_now              ( S_bit_num_now[i]              ),
                .O_fifo_almost_empty        (S_fifo_almost_empty[i]         )
            );
        end
    endgenerate ///gen_clock_recovery

//novas -27363:26
//novas -22105:26
//novas -21047:26
    generate
        for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
        begin : gen_clk_2m072_recov
            clk_2m072_recov    u_clk_2m072_recov
            ///    #(parameter
            ///    )
            (
                /// 时钟与复位
                .I_125m_clk       (I_125m_clk), ///系统时钟，125MHZ
                .I_rst           (S_e1_opt_rst_tmp), ///FPGA E1业务复位
              /// 来自cpu的配置信息
                .I_level_l       (S_upram_level_l), ///2.072mhz时钟时钟恢复的低门限
                .I_level_h       (S_upram_level_h), ///2.072mhz时钟时钟恢复的高门限
                .I_2m072_adjust_delay  (S_2m072_adjust_delay) ,
                ///与upram_ctrl模块的接口
                .I_1st_ff_1st_stuff ( S_1st_ff_1st_stuff[i]         ),
                .I_fifo_byte_num(S_chs_upfifo_byte_cnt[i]), ///一级FIFO缓存的包数量
                ///与clock_recovery模块的接口
                .I_fifo_almost_empty (S_fifo_almost_empty[i]),
                ///.I_2m72_ajust_step (S_2m72_ajust_step),
                .O_2m072_revclk  (S_2m072_revclk[i]) ///恢复出来的2.072mhz

            );
        end
    endgenerate///gen_clk_2m072_recov

e1_loss     u_e1_loss
(
    .I_125m_clk      (I_125m_clk      ),   ///125M系统时钟
    .I_rst           (I_rst           ),   ///复位信号
    .I_liu1_clke1    (I_liu1_clke1    ),   ///clk_e1
    .I_liu1_llos     (I_liu1_llos     ),   ///loss
    .I_liu1_llos0    (I_liu1_llos0    ),   ///start of loss
    .O_liu1_los      (O_liu1_los      )    ///LIU1 loss
  );


package_cnt u_package_cnt(
    .I_125m_clk             (I_125m_clk                  ),
    .I_rst                  (I_rst                       ),
    .I_package_cnt_clr      (S_package_cnt_clr           ),
    .I_eth_rx_state_reg     (S_mac_unpacking_status[3:0] ),
    .I_eth_tx_state_reg     (S_mac_packing_status[3:0]   ),
    .I_fcserr_flag          (S_fcserr_flag               ),
    .O_gmii_txpackage_cnt   (S_gmii_txpackage_cnt        ),
    .O_gmii_rxpackage_cnt   (S_gmii_rxpackage_cnt        ),
    .O_fcserr_package_cnt   (S_fcserr_package_cnt        )
);

mac_pack_snapshot   u_mac_pack_snapshot   (
        .I_125m_clk          (I_125m_clk      ),
        .I_rst               (I_rst           ),
        .I_snapshot_ram_clr  (S_snapshot_ram_clr   ),
        .I_snapshot_mode     (S_snapshot_mode ),
        .I_fcs_check_err     (S_fcserr_flag   ),
        .I_gmii_rxen         (S_gmii_rxen     ),
        .I_gmii_rxdat        (S_gmii_din      ),
        .I_unpacking_state   (S_mac_unpacking_status[3:0] ),
        .I_inner_fcs_dout    (S_mac_unpacking_status[47:16] ),
        .I_ram_rdaddr        (I_cpu_addr[11:0]),
        .O_ram_dout          (S_graspram_dout )
    );


port_check_top   #(   C_E1_CHS_NUM   )
        u_port_check_top
    
( 
    ///clock and reset
    .I_125m_clk             (I_125m_clk      ),  
    .I_2m_clk               (I_3001_2m_clk   ),  
    .I_logic_rst            (I_rst           ), /// 

    ///prbs configuration signals
    .I_prbscnt_clr          (S_prbs_chk_clr_en ), 
    .I_ber_cnt_clr          (S_ber_cnt_clr     ), 
    .I_prbs_ber_ch_sel      (S_prbs_ber_ch_sel ),
    .I_e1_macback_e1_en     (S_e1_macback_e1_en  ),  
    .I_liu_e1_liu_loop_en   (S_liu_e1_liu_loop_en),/// add by wzy
    .I_back_e1_back_loop_en (S_back_e1_back_loop_en),/// add by wzy
    .I_e1_liu_e1_loop_en    (S_e1_liu_e1_loop_en),/// add by wzy
    .I_bits2m_chs_sel       (S_bits2m_chs_sel), 
    .I_e1_get_line_prbs_en  (S_e1_get_line_prbs_en),    
    .I_insert_sys_ais_en    (S_insert_sys_ais_en     ),
    .I_insert_line_ais_en   (S_insert_line_ais_en    ), 
    ///E1 port connected with 2386  
    .I_e1_rclk              (I_rclk         ),  
    .I_e1_rdat              (I_rdp          ),  
    .I_e1opt_tclk           (S_e1opt_tclk   ),  
    .I_e1opt_tdat           (S_e1opt_tdat   ),  
                                                    
    .I_soft_clr             (S_soft_clr           ),
    .I_soft_switch          (S_soft_switch        ),
    .I_multi_frame_ch_sel   (S_multi_frame_ch_sel ),
    .I_multi_frame_dir_sel  (S_multi_frame_dir_sel),
    .O_FAS                  (S_FAS                ),
    .O_crc_num              (S_crc_num            ),
    
    .O_e1_tclk              (O_tclk          ),  
    .O_e1_tdat              (O_tdp           ),  
    .O_e1opt_rclk           (S_e1opt_rclk    ),  
    .O_e1opt_rdat           (S_e1opt_rdat    ),
    .O_check_out            (S_prbs_err      ),      
    .O_err_cnt              (S_err_cnt       ),  
    .O_err_bits_cnt         (S_err_bits_cnt  ), 
    .O_total_bits_cnt       (S_total_bits_cnt) 
   
); 


//novas -27363:15
//novas -22105:15
//novas -21047:15
    generate
    for (i=0;i<C_E1_CHS_NUM;i=i+1'b1)
    begin : gen_cv_cnt
        cv_cnt U_cv_cnt
            (
            .I_125m_clk       ( I_125m_clk             ),
        .I_e1_los         ( O_liu1_los[i]          ),
            .I_e1_clk         ( S_e1opt_rclk[i]        ),
            .I_rst            ( S_e1_opt_rst_tmp       ), ///S_master_rst_n
            .I_cv             ( I_e1_bpv[i]            ),
            .I_cv_cnt_rden    ( S_cv_cnt_rden[i]       ),
            .O_cv_cnt         ( S_cv_cnt[i]            )

        );
    end
    endgenerate ///gen_cv_cnt


///=======================new add==================///20111220 by saibin     

e1_clk_factory U_e1_clk_factory
(
.I_125m_clk(I_125m_clk), ///
.I_rst(I_rst),      ///
.O_2m072_clk(S_2m072_clk) ///

);


    gen_clk50hz_top 
        #(C_E1_CHS_NUM)
    U_gen_clk50hz_top
    (   
        .I_125m_clk           (I_125m_clk),          
        .I_rst                (S_e1_opt_rst_tmp),  
        .I_e1_clkin           (I_rclk), /// E1接收时钟随路时钟，2.048MHz 
        .I_cpu_sel_50hz       (S_fpga_50hz_sel), /// 50Hz时钟源选择信号
        .I_liu1_refa_clk      (I_liu1_refa),
        .I_liu1_refb_clk      (I_liu1_refb), 
        .O_fpga_test          (),///test signal            
        .O_rtu_out_50hz       (O_50hz_clk) ///50hz clock output 
    ); 
      
    
gmii_ctrl_top U_gmii_ctrl_top(
    .I_125m_clk            (I_125m_clk),   
    .I_rst                 (I_rst),  
    .I_gmii_inloop_en      (S_gmii_inloop_en),   
    .I_gmii_outloop_en     (S_gmii_outloop_en),   
    .I_gmii_rxd            (I_gmii_din),   
    .I_gmii_rx_dv          (I_gmii_rxen),   
    .I_gmii_rx_er          (I_gmii_rxer),  
    .I_gmii_txd            (S_gmii_dout),  
    .I_gmii_txen           (S_gmii_txen),   
    .I_gmii_txer           (S_gmii_txer),   
    .O_gmii_rxen           (S_gmii_rxen),  
    .O_gmii_rxer           (S_gmii_rxer),   
    .O_gmii_rxd            (S_gmii_din),   
    .O_gmii_txen           (O_gmii_txen),   
    .O_gmii_txer           (O_gmii_txer),   
    .O_gmii_txd            (O_gmii_dout),     
    .O_txpackidlecnt_min   (S_txpackidlecnt_min),   
    .O_rxpackidlecnt_min   (S_rxpackidlecnt_min)    
);

endmodule
