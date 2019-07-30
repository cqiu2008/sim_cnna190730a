`timescale 1ns / 1ps


module axi_test_top#(
parameter
    C_AXIWIDTH                             = 128,
    C_ADDR_WIDTH                           = 32,
    C_LITE_DWIDTH                          = 32
)(
    input                                    I_aclk,
    input                                    I_arst,
    //axi_mem0,read weight
    input                                    I_awready0,
    input              [1:0]                 I_bresp0,
    input                                    I_bvalid0,
    input                                    I_wready0,
    input              [3:0]                 I_bid0,
    output                                   O_awlock0,
    output             [3:0]                 O_awid0,
    output             [1:0]                 O_awburst0,
    output             [3:0]                 O_awcache0,
    output             [2:0]                 O_awprot0,
    output             [2:0]                 O_awsize0,
    output                                   O_bready0,
    output             [C_AXIWIDTH/8-1:0]    O_wstrb0,
    output             [C_ADDR_WIDTH-1:0]    O_awaddr0,
    output             [7:0]                 O_awlen0,
    output                                   O_awvalid0,
    output             [C_AXIWIDTH-1:0]      O_wdata0,
    output                                   O_wlast0,
    output                                   O_wvalid0,
    input                                    I_arready0,
    input              [C_AXIWIDTH-1:0]      I_rdata0,
    input                                    I_rvalid0,
    input                                    I_rlast0,
    input              [1:0]                 I_rresp0,
    input              [3:0]                 I_rid0,
    output             [1:0]                 O_arburst0,
    output             [3:0]                 O_arcache0,
    output             [2:0]                 O_arprot0,
    output             [2:0]                 O_arsize0,
    output             [3:0]                 O_arid0,
    output                                   O_arlock0,
    output             [C_ADDR_WIDTH-1:0]    O_araddr0,
    output             [7:0]                 O_arlen0,
    output                                   O_arvalid0,
    output                                   O_rready0,
    
    //axi mem1,read feature
    input                                    I_awready1,
    input              [1:0]                 I_bresp1,
    input                                    I_bvalid1,
    input                                    I_wready1,
    input              [3:0]                 I_bid1,
    output                                   O_awlock1,
    output             [3:0]                 O_awid1,
    output             [1:0]                 O_awburst1,
    output             [3:0]                 O_awcache1,
    output             [2:0]                 O_awprot1,
    output             [2:0]                 O_awsize1,
    output                                   O_bready1,
    output             [C_AXIWIDTH/8-1:0]    O_wstrb1,
    output             [C_ADDR_WIDTH-1:0]    O_awaddr1,
    output             [7:0]                 O_awlen1,
    output                                   O_awvalid1,
    output             [C_AXIWIDTH-1:0]      O_wdata1,
    output                                   O_wlast1,
    output                                   O_wvalid1,
    input                                    I_arready1,
    input              [C_AXIWIDTH-1:0]      I_rdata1,
    input                                    I_rvalid1,
    input                                    I_rlast1,
    input              [1:0]                 I_rresp1,
    input              [3:0]                 I_rid1,
    output             [1:0]                 O_arburst1,
    output             [3:0]                 O_arcache1,
    output             [2:0]                 O_arprot1,
    output             [2:0]                 O_arsize1,
    output             [3:0]                 O_arid1,
    output                                   O_arlock1,
    output             [C_ADDR_WIDTH-1:0]    O_araddr1,
    output             [7:0]                 O_arlen1,
    output                                   O_arvalid1,
    output                                   O_rready1,
    //axi_mem2,write result
    input                                    I_awready2,
    input              [1:0]                 I_bresp2,
    input                                    I_bvalid2,
    input                                    I_wready2,
    input              [3:0]                 I_bid2,
    output                                   O_awlock2,
    output             [3:0]                 O_awid2,
    output             [1:0]                 O_awburst2,
    output             [3:0]                 O_awcache2,
    output             [2:0]                 O_awprot2,
    output             [2:0]                 O_awsize2,
    output                                   O_bready2,
    output             [C_AXIWIDTH/8-1:0]    O_wstrb2,
    output             [C_ADDR_WIDTH-1:0]    O_awaddr2,
    output             [7:0]                 O_awlen2,
    output                                   O_awvalid2,
    output             [C_AXIWIDTH-1:0]      O_wdata2,
    output                                   O_wlast2,
    output                                   O_wvalid2,
    input                                    I_arready2,
    input              [C_AXIWIDTH-1:0]      I_rdata2,
    input                                    I_rvalid2,
    input                                    I_rlast2,
    input              [1:0]                 I_rresp2,
    input              [3:0]                 I_rid2,
    output             [1:0]                 O_arburst2,
    output             [3:0]                 O_arcache2,
    output             [2:0]                 O_arprot2,
    output             [2:0]                 O_arsize2,
    output             [3:0]                 O_arid2,
    output                                   O_arlock2,
    output             [C_ADDR_WIDTH-1:0]    O_araddr2,
    output             [7:0]                 O_arlen2,
    output                                   O_arvalid2,
    output                                   O_rready2,
    //axi lite
    output                                   O_lite_awready,
    input              [C_ADDR_WIDTH-1:0]    I_lite_awaddr,
    input                                    I_lite_awvalid,
    output                                   O_lite_wready,
    input              [C_LITE_DWIDTH-1:0]   I_lite_wdata,
    input                                    I_lite_wvalid,
    input              [C_LITE_DWIDTH/8-1:0] I_lite_wstrb,
    input                                    I_lite_bready,
    output             [1:0]                 O_lite_bresp,//okay
    output                                   O_lite_bvalid,
    output                                   O_lite_arready,
    input              [C_ADDR_WIDTH-1:0]    I_lite_araddr,
    input                                    I_lite_arvalid,
    input                                    I_lite_rready,
    output             [C_LITE_DWIDTH-1:0]   O_lite_rdata,
    output                                   O_lite_rvalid,
    output             [1:0]                 O_lite_rresp
 );
    
 wire                S_start                   ;
 wire  [31:0]        S_weight_base_addr        ; 
 wire  [31:0]        S_f_iddr_addr             ; 
 wire  [31:0]        S_f_oddr_addr             ; 
 wire  [0 :0]        S_cnv_en                  ; 
 wire  [0 :0]        S_pooling_en              ; 
 wire  [15:0]        S_cur_layer_num           ; 
 wire  [0 :0]        S_layer_div_type          ; 
 wire  [10:0]        S_sub_layer_num           ; 
 wire  [10:0]        S_sub_layer_seq           ; 
 wire  [1 :0]        S_sub_layer_flag          ; 
 wire  [15:0]        S_weight_in_pos           ; 
 wire  [15:0]        S_bias_in_pos             ; 
 wire  [15:0]        S_scale_in_pos            ; 
 wire  [15:0]        S_mean_in_pos             ; 
 wire  [15:0]        S_variance_in_pos         ; 
 wire  [31:0]        S_weight_mem_addr_l       ; 
 wire  [7 :0]        S_weight_mem_addr_h       ; 
 wire  [31:0]        S_bias_mem_addr_l         ; 
 wire  [7 :0]        S_bias_mem_addr_h         ;  
 wire  [31:0]        S_mem_addr_scale_l        ; 
 wire  [7 :0]        S_mem_addr_scale_h        ; 
 wire  [31:0]        S_mem_addr_mean_l         ; 
 wire  [7 :0]        S_mem_addr_mean_h         ; 
 wire  [31:0]        S_mem_addr_variance_l     ; 
 wire  [7 :0]        S_mem_addr_variance_h     ; 
 wire  [18:0]        S_compress_size           ;
 wire  [15:0]        S_next_layer_num          ;
 wire  [0 :0]        S_next_div_type           ;
 wire  [10:0]        S_next_sub_layer_num      ;
 wire  [10:0]        S_next_sub_layer_seq      ;
 wire  [1 :0]        S_next_sub_layer_flag     ;
 wire  [15:0]        S_next_weight_in_pos      ;
 wire  [15:0]        S_next_bias_in_pos        ;
 wire  [15:0]        S_next_scale_in_pos       ;
 wire  [15:0]        S_next_mean_in_pos        ;
 wire  [15:0]        S_next_variance_in_pos    ;
 wire  [31:0]        S_next_weight_mem_addr_l  ;
 wire  [7 :0]        S_next_weight_mem_addr_h  ;
 wire  [31:0]        S_next_bias_mem_addr_l    ;
 wire  [7 :0]        S_next_bias_mem_addr_h    ;
 wire  [31:0]        S_next_mem_addr_scale_l   ;
 wire  [7 :0]        S_next_mem_addr_scale_h   ;
 wire  [31:0]        S_next_mem_addr_mean_l    ;
 wire  [7 :0]        S_next_mem_addr_mean_h    ;
 wire  [31:0]        S_next_mem_addr_variance_l;
 wire  [7 :0]        S_next_mem_addr_variance_h;  
 wire  [18:0]        S_next_compress_size      ;
 wire  [15:0]        S_ipara_batchsize         ;
 wire  [15:0]        S_ipara_width             ;
 wire  [15:0]        S_ipara_height            ;
 wire  [12:0]        S_ipara_ci                ;
 wire  [12:0]        S_ipara_ciAlign           ;
 wire  [12:0]        S_ipara_ciGroup           ;
 wire  [15:0]        S_img_in_pos              ;
 wire  [31:0]        S_mem_addr_img_in_l       ;
 wire  [7 :0]        S_mem_addr_img_in_h       ;
 wire  [15:0]        S_next_ipara_batchsize    ;
 wire  [15:0]        S_next_ipara_width        ;
 wire  [15:0]        S_next_ipara_height       ;
 wire  [12:0]        S_next_ipara_ci           ;
 wire  [12:0]        S_next_ipara_ciAlign      ;
 wire  [12:0]        S_next_ipara_ciGroup      ;
 wire  [15:0]        S_next_img_in_pos         ;
 wire  [31:0]        S_next_mem_addr_img_in_l  ;
 wire  [7 :0]        S_next_mem_addr_img_in_h  ;    
 wire  [15:0]        S_opara_batchsize        ;
 wire  [15:0]        S_opara_width            ;
 wire  [15:0]        S_opara_height           ;
 wire  [12:0]        S_opara_co               ;
 wire  [12:0]        S_opara_coAlign          ;
 wire  [12:0]        S_opara_coAlign16        ;
 wire  [15:0]        S_img_out_pos            ;
 wire  [31:0]        S_mem_addr_img_out_l     ;
 wire  [7 :0]        S_mem_addr_img_out_h     ;
 wire  [15:0]        S_next_opara_batchsize   ;
 wire  [15:0]        S_next_opara_width       ;
 wire  [15:0]        S_next_opara_height      ;
 wire  [12:0]        S_next_opara_co          ;
 wire  [12:0]        S_next_opara_coAlign     ;
 wire  [12:0]        S_next_opara_coAlign16   ;
 wire  [15:0]        S_next_img_out_pos       ;
 wire  [31:0]        S_next_mem_addr_img_out_l;
 wire  [7 :0]        S_next_mem_addr_img_out_h;
 wire  [0 :0]        S_relu_en                ;
 wire  [15:0]        S_dilation               ;
 wire  [4 :0]        S_cnv_pad_h              ;
 wire  [4 :0]        S_cnv_pad_w              ;
 wire  [4 :0]        S_cnv_kernel_h           ;
 wire  [4 :0]        S_cnv_kernel_w           ;
 wire  [4 :0]        S_cnv_stride_h           ;
 wire  [4 :0]        S_cnv_stride_w           ;
 wire  [0 :0]        S_next_relu_en           ;
 wire  [15:0]        S_next_dilation          ;
 wire  [4 :0]        S_next_cnv_pad_h         ;
 wire  [4 :0]        S_next_cnv_pad_w         ;
 wire  [4 :0]        S_next_cnv_kernel_h      ;
 wire  [4 :0]        S_next_cnv_kernel_w      ;
 wire  [4 :0]        S_next_cnv_stride_h      ;
 wire  [4 :0]        S_next_cnv_stride_w      ;
 wire  [4 :0]        S_pool_pad_h             ;
 wire  [4 :0]        S_pool_pad_w             ;
 wire  [4 :0]        S_pool_kernel_h          ;
 wire  [4 :0]        S_pool_kernel_w          ;
 wire  [4 :0]        S_pool_stride_h          ;
 wire  [4 :0]        S_pool_stride_w          ;
 wire  [0 :0]        S_pool_type              ;   
    
 wire  [31:0]        S_dram_feature_rd_addr   ;
 wire  [31:0]        S_wr_DDR_addr            ;
 wire  [31:0]        S_in_data_bytes_w        ;
 wire  [31:0]        S_in_data_bytes_b        ;
 wire  [31:0]        S_in_data_bytes_f        ;
 wire  [31:0]        S_out_data_bytes         ;
 wire  [15:0]        S_line_addr_num          ;
 
 wire  [C_AXIWIDTH-1:0]    S_mem_weight       ;
 wire                      S_mem_weight_valid ;
 wire  [C_AXIWIDTH-1:0]    S_mem_feature      ;
 wire                      S_mem_feature_valid;
 
 wire                S_ap_ready               ;
 wire                S_ap_done                ;
 
 wire  [C_AXIWIDTH-1:0]    S_cnv_data         ;
 wire                      S_cnv_dv           ;
 wire                      S_dram_feature_rd_flag;
 wire                      S_weight_ch        ;
 wire                      S_last_line        ;
 
 reg                       S_dram_feature_rd_flag_d1=0;
 reg                       S_dram_feature_rd_flag_d2=0;
 reg                       S_dram_feature_rd_flag_d3=0;
 
 always@ (posedge I_aclk)
 begin
     S_dram_feature_rd_flag_d1 <= S_dram_feature_rd_flag;
     S_dram_feature_rd_flag_d2 <= S_dram_feature_rd_flag_d1;
     S_dram_feature_rd_flag_d3 <= S_dram_feature_rd_flag_d2;
 end
 
 assign S_in_data_bytes_w = S_ipara_ciAlign * S_opara_coAlign * S_next_cnv_kernel_h * S_next_cnv_kernel_h;
 assign S_in_data_bytes_b = S_opara_coAlign;
 assign S_in_data_bytes_f = S_ipara_width<<4;
 assign S_out_data_bytes  = S_opara_width * S_opara_coAlign;
 assign S_line_addr_num   = S_opara_width * S_next_opara_coAlign[12:4];
          
     m_axi_mem_rweight#(
         .C_DATA_WIDTH      (C_AXIWIDTH),
         .C_ADDR_WIDTH      (C_ADDR_WIDTH)
     )m_axi_mem_rd_weight(
         .I_clk             (I_aclk),
         .I_rst             (~I_arst),
         .I_ap_start        (S_start),
         .I_ddr_rdw_addr    (S_next_weight_mem_addr_l),
         .I_ddr_rdb_addr    (S_next_bias_mem_addr_l),
         .I_ddr_wr_addr     (),
         .I_in_dataw_bytes  (S_in_data_bytes_w),
         .I_in_datab_bytes  (S_in_data_bytes_b),
         .I_out_data_bytes  (),
         //axi write
         .I_awready         (I_awready0    ),
         .I_bresp           (I_bresp0      ),
         .I_bvalid          (I_bvalid0     ),
         .I_wready          (I_wready0     ),
         .I_bid             (I_bid0        ),
         .O_awlock          (),
         .O_awid            (),
         .O_awburst         (),
         .O_awcache         (),
         .O_awprot          (),
         .O_awsize          (),
         .O_bready          (O_bready0     ),
         .O_wstrb           (),
         .O_awaddr          (),
         .O_awlen           (),
         .O_awvalid         (),
         .O_wdata           (),
         .O_wlast           (),
         .O_wvalid          (),
         .I_arready         (I_arready0    ),
         .I_rdata           (I_rdata0      ),
         .I_rvalid          (I_rvalid0     ),
         .I_rlast           (I_rlast0      ),
         .I_rresp           (I_rresp0      ),
         .I_rid             (I_rid0        ),
         .O_arburst         (O_arburst0    ),
         .O_arcache         (O_arcache0    ),
         .O_arprot          (O_arprot0     ),
         .O_arsize          (O_arsize0     ),
         .O_arid            (O_arid0       ),
         .O_arlock          (O_arlock0     ),
         .O_araddr          (O_araddr0     ),
         .O_arlen           (O_arlen0      ),
         .O_arvalid         (O_arvalid0    ),
         .O_rready          (O_rready0     ),
         //memory
         .O_mem_din         (S_mem_weight),//feature in,transport to next module
         .O_mem_din_valid   (S_mem_weight_valid),
         .O_weight_ch       (S_weight_ch),
         .I_mem_dout        (),//feature out,transport to ddr
         .I_mem_dout_valid  (),
         .O_ap_ready        (),
         .O_ap_done         ()
         );
                  
     m_axi_mem#(
         .C_DATA_WIDTH      (C_AXIWIDTH),
         .C_ADDR_WIDTH      (C_ADDR_WIDTH)
     )m_axi_mem_rd_feature(
         .I_clk             (I_aclk),
         .I_rst             (~I_arst),
         .I_ap_start        (S_start),
         .I_ddr_rdw_addr    (S_dram_feature_rd_addr),
         .I_ddr_rdb_addr    (),
         .I_ddr_wr_addr     (),
         .I_in_dataw_bytes  (S_in_data_bytes_f),
         .I_in_datab_bytes  (),
         .I_out_data_bytes  (),
         .I_ddr_raddr_change(/*S_dram_feature_rd_flag*/S_dram_feature_rd_flag_d3),
         //axi write
         .I_awready         (),
         .I_bresp           (I_bresp1),
         .I_bvalid          (I_bvalid1),
         .I_wready          (),
         .I_bid             (I_bid1),
         .O_awlock          (),
         .O_awid            (),
         .O_awburst         (),
         .O_awcache         (),
         .O_awprot          (),
         .O_awsize          (),
         .O_bready          (O_bready1),
         .O_wstrb           (),
         .O_awaddr          (),
         .O_awlen           (),
         .O_awvalid         (),
         .O_wdata           (),
         .O_wlast           (),
         .O_wvalid          (),
         .I_arready         (I_arready1),
         .I_rdata           (I_rdata1),
         .I_rvalid          (I_rvalid1),
         .I_rlast           (I_rlast1),
         .I_rresp           (I_rresp1),
         .I_rid             (I_rid1),
         .O_arburst         (O_arburst1),
         .O_arcache         (O_arcache1),
         .O_arprot          (O_arprot1),
         .O_arsize          (O_arsize1),
         .O_arid            (O_arid1),
         .O_arlock          (O_arlock1),
         .O_araddr          (O_araddr1),
         .O_arlen           (O_arlen1),
         .O_arvalid         (O_arvalid1),
         .O_rready          (O_rready1),
         //memory
         .O_mem_din         (S_mem_feature),
         .O_mem_din_valid   (S_mem_feature_valid),
         .I_mem_dout        (),
         .I_mem_dout_valid  (),
         .O_ap_ready        (),
         .O_ap_done         ()
         );
        
     m_axi_mem_wresult#(
         .C_DATA_WIDTH      (C_AXIWIDTH),
         .C_ADDR_WIDTH      (C_ADDR_WIDTH)
     )m_axi_mem_wr_result(        
         .I_clk             (I_aclk),
         .I_rst             (~I_arst),
         .I_ap_start        (S_start),
         .I_ddr_rdw_addr    (),
         .I_ddr_rdb_addr    (),
         .I_ddr_wr_addr     (S_wr_DDR_addr),
         .I_in_dataw_bytes  (),
         .I_in_datab_bytes  (),
         .I_out_data_bytes  (S_out_data_bytes),
         .I_line_addr_num   (S_line_addr_num),
         .I_last_line       (S_last_line),
         //axi write
         .I_awready         (I_awready2  ),
         .I_bresp           (I_bresp2    ),
         .I_bvalid          (I_bvalid2   ),
         .I_wready          (I_wready2   ),
         .I_bid             (I_bid2      ),
         .O_awlock          (O_awlock2   ),
         .O_awid            (O_awid2     ),
         .O_awburst         (O_awburst2  ),
         .O_awcache         (O_awcache2  ),
         .O_awprot          (O_awprot2   ),
         .O_awsize          (O_awsize2   ),
         .O_bready          (O_bready2   ),
         .O_wstrb           (O_wstrb2    ),
         .O_awaddr          (O_awaddr2   ),
         .O_awlen           (O_awlen2    ),
         .O_awvalid         (O_awvalid2  ),
         .O_wdata           (O_wdata2    ),
         .O_wlast           (O_wlast2    ),
         .O_wvalid          (O_wvalid2   ),
         .I_arready         (),
         .I_rdata           (),
         .I_rvalid          (),
         .I_rlast           (),
         .I_rresp           (),
         .I_rid             (),
         .O_arburst         (),
         .O_arcache         (),
         .O_arprot          (),
         .O_arsize          (),
         .O_arid            (),
         .O_arlock          (),
         .O_araddr          (),
         .O_arlen           (),
         .O_arvalid         (),
         .O_rready          (),
         //memory
         .O_mem_din         (),
         .O_mem_din_valid   (),
         .I_mem_dout        (S_cnv_data),
         .I_mem_dout_valid  (S_cnv_dv),
         .O_ap_ready        (S_ap_ready),
         .O_ap_done         (S_ap_done)
         );
        
         
       reg S_last = 0;
       always@ (posedge I_aclk)
       begin
           if (I_rlast0)
               S_last <= 1'b1;
       end

s_axilite2reg#(
    .C_ADDR_WIDTH    (C_ADDR_WIDTH),
    .C_DATA_WIDTH    (C_LITE_DWIDTH)
)s_axilite2reg_inst(
    .I_aclk                      (I_aclk),
    .I_arst                      (~I_arst),
    //axi
    .O_lite_awready              (O_lite_awready),
    .I_lite_awaddr               (I_lite_awaddr),         
    .I_lite_awvalid              (I_lite_awvalid),         
    .O_lite_wready               (O_lite_wready),
    .I_lite_wdata                (I_lite_wdata),         
    .I_lite_wvalid               (I_lite_wvalid),         
    .I_lite_wstrb                (I_lite_wstrb),         
    .I_lite_bready               (1'b1),         
    .O_lite_bresp                (O_lite_bresp),//okay
    .O_lite_bvalid               (O_lite_bvalid),
    .O_lite_arready              (O_lite_arready),
    .I_lite_araddr               (I_lite_araddr),         
    .I_lite_arvalid              (I_lite_arvalid),         
    .I_lite_rready               (I_lite_rready),         
    .O_lite_rdata                (O_lite_rdata),
    .O_lite_rvalid               (O_lite_rvalid),
    .O_lite_rresp                (O_lite_rresp),
    //register         
    .O_reg_addr                  (),
    .O_reg_data                  (),
    .I_ap_start_done             (S_last),
    
    .O_start                     (S_start),
    .O_weight_base_addr          (S_weight_base_addr   ),
    .O_f_iddr_addr               (S_f_iddr_addr        ),
    .O_f_oddr_addr               (S_f_oddr_addr        ),
    .O_cnv_en                    (S_cnv_en             ),
    .O_pooling_en                (S_pooling_en         ),
    .O_cur_layer_num             (S_cur_layer_num      ),
    .O_layer_div_type            (S_layer_div_type     ),
    .O_sub_layer_num             (S_sub_layer_num      ),
    .O_sub_layer_seq             (S_sub_layer_seq      ),
    .O_sub_layer_flag            (S_sub_layer_flag     ),
    .O_weight_in_pos             (S_weight_in_pos      ),
    .O_bias_in_pos               (S_bias_in_pos        ),
    .O_scale_in_pos              (S_scale_in_pos       ),
    .O_mean_in_pos               (S_mean_in_pos        ),
    .O_variance_in_pos           (S_variance_in_pos    ),
    .O_weight_mem_addr_l         (S_weight_mem_addr_l  ),
    .O_weight_mem_addr_h         (S_weight_mem_addr_h  ),
    .O_bias_mem_addr_l           (S_bias_mem_addr_l    ),
    .O_bias_mem_addr_h           (S_bias_mem_addr_h    ),
    .O_mem_addr_scale_l          (S_mem_addr_scale_l   ),
    .O_mem_addr_scale_h          (S_mem_addr_scale_h   ),
    .O_mem_addr_mean_l           (S_mem_addr_mean_l    ),
    .O_mem_addr_mean_h           (S_mem_addr_mean_h    ),
    .O_mem_addr_variance_l       (S_mem_addr_variance_l),
    .O_mem_addr_variance_h       (S_mem_addr_variance_h),
    .O_compress_size             (S_compress_size           ),
    .O_next_layer_num            (S_next_layer_num          ),
    .O_next_div_type             (S_next_div_type           ),
    .O_next_sub_layer_num        (S_next_sub_layer_num      ),
    .O_next_sub_layer_seq        (S_next_sub_layer_seq      ),
    .O_next_sub_layer_flag       (S_next_sub_layer_flag     ),
    .O_next_weight_in_pos        (S_next_weight_in_pos      ),
    .O_next_bias_in_pos          (S_next_bias_in_pos        ),
    .O_next_scale_in_pos         (S_next_scale_in_pos       ),
    .O_next_mean_in_pos          (S_next_mean_in_pos        ),
    .O_next_variance_in_pos      (S_next_variance_in_pos    ),
    .O_next_weight_mem_addr_l    (S_next_weight_mem_addr_l  ),
    .O_next_weight_mem_addr_h    (S_next_weight_mem_addr_h  ),
    .O_next_bias_mem_addr_l      (S_next_bias_mem_addr_l    ),
    .O_next_bias_mem_addr_h      (S_next_bias_mem_addr_h    ),
    .O_next_mem_addr_scale_l     (S_next_mem_addr_scale_l   ),
    .O_next_mem_addr_scale_h     (S_next_mem_addr_scale_h   ),
    .O_next_mem_addr_mean_l      (S_next_mem_addr_mean_l    ),
    .O_next_mem_addr_mean_h      (S_next_mem_addr_mean_h    ),
    .O_next_mem_addr_variance_l  (S_next_mem_addr_variance_l),
    .O_next_mem_addr_variance_h  (S_next_mem_addr_variance_h),
    .O_next_compress_size        (S_next_compress_size    ),
    .O_ipara_batchsize           (S_ipara_batchsize       ),
    .O_ipara_width               (S_ipara_width           ),
    .O_ipara_height              (S_ipara_height          ),
    .O_ipara_ci                  (S_ipara_ci              ),
    .O_ipara_ciAlign             (S_ipara_ciAlign         ),
    .O_ipara_ciGroup             (S_ipara_ciGroup         ),
    .O_img_in_pos                (S_img_in_pos            ),
    .O_mem_addr_img_in_l         (S_mem_addr_img_in_l     ),
    .O_mem_addr_img_in_h         (S_mem_addr_img_in_h     ),
    .O_next_ipara_batchsize      (S_next_ipara_batchsize  ),
    .O_next_ipara_width          (S_next_ipara_width      ),
    .O_next_ipara_height         (S_next_ipara_height     ),
    .O_next_ipara_ci             (S_next_ipara_ci         ),
    .O_next_ipara_ciAlign        (S_next_ipara_ciAlign    ),
    .O_next_ipara_ciGroup        (S_next_ipara_ciGroup    ),
    .O_next_img_in_pos           (S_next_img_in_pos       ),
    .O_next_mem_addr_img_in_l    (S_next_mem_addr_img_in_l),
    .O_next_mem_addr_img_in_h    (S_next_mem_addr_img_in_h),
    .O_opara_batchsize           (S_opara_batchsize        ),
    .O_opara_width               (S_opara_width            ),
    .O_opara_height              (S_opara_height           ),
    .O_opara_co                  (S_opara_co               ),
    .O_opara_coAlign             (S_opara_coAlign          ),
    .O_opara_coAlign16           (S_opara_coAlign16        ),
    .O_img_out_pos               (S_img_out_pos            ),
    .O_mem_addr_img_out_l        (S_mem_addr_img_out_l     ),
    .O_mem_addr_img_out_h        (S_mem_addr_img_out_h     ),
    .O_next_opara_batchsize      (S_next_opara_batchsize   ),
    .O_next_opara_width          (S_next_opara_width       ),
    .O_next_opara_height         (S_next_opara_height      ),
    .O_next_opara_co             (S_next_opara_co          ),
    .O_next_opara_coAlign        (S_next_opara_coAlign     ),
    .O_next_opara_coAlign16      (S_next_opara_coAlign16   ),
    .O_next_img_out_pos          (S_next_img_out_pos       ),
    .O_next_mem_addr_img_out_l   (S_next_mem_addr_img_out_l),
    .O_next_mem_addr_img_out_h   (S_next_mem_addr_img_out_h),
    .O_relu_en                   (S_relu_en          ),
    .O_dilation                  (S_dilation         ),
    .O_cnv_pad_h                 (S_cnv_pad_h        ),
    .O_cnv_pad_w                 (S_cnv_pad_w        ),
    .O_cnv_kernel_h              (S_cnv_kernel_h     ),
    .O_cnv_kernel_w              (S_cnv_kernel_w     ),
    .O_cnv_stride_h              (S_cnv_stride_h     ),
    .O_cnv_stride_w              (S_cnv_stride_w     ),
    .O_next_relu_en              (S_next_relu_en     ),
    .O_next_dilation             (S_next_dilation    ),
    .O_next_cnv_pad_h            (S_next_cnv_pad_h   ),
    .O_next_cnv_pad_w            (S_next_cnv_pad_w   ),
    .O_next_cnv_kernel_h         (S_next_cnv_kernel_h),
    .O_next_cnv_kernel_w         (S_next_cnv_kernel_w),
    .O_next_cnv_stride_h         (S_next_cnv_stride_h),
    .O_next_cnv_stride_w         (S_next_cnv_stride_w),
    .O_pool_pad_h                (S_pool_pad_h       ),
    .O_pool_pad_w                (S_pool_pad_w       ),
    .O_pool_kernel_h             (S_pool_kernel_h    ),
    .O_pool_kernel_w             (S_pool_kernel_w    ),
    .O_pool_stride_h             (S_pool_stride_h    ),
    .O_pool_stride_w             (S_pool_stride_w    ),
    .O_pool_type                 (S_pool_type        ),       
    
    .I_ap_ready                  (S_ap_ready),
    .I_ap_done                   (S_ap_done)
    );
         
top#(
         .AXIWIDTH                    (128),
         .LITEWIDTH                   (32),
         .CH_IN                       (16),
         .DWIDTH                      (8),
         .CH_OUT                      (32),
         .PIX                         (8),
         .ADD_WIDTH                   (19),
         .LAYERWIDTH                  (8),
         .KWIDTH                      (4),
         .COWIDTH                     (10),
         .DEPTHWIDTH                  (9),
         .W_WIDTH                     (10),
         .SWIDTH                      (2),
         .PWIDTH                      (2),
         .RDB_PIX                     (2),
         .IEMEM_1ADOT                 (16)
)top_inst(
         .I_clk                       (I_aclk),
         .I_rst                       (~I_arst),
         .I_feature                   (S_mem_feature),
         .I_feature_dv                (S_mem_feature_valid),  
         .I_layer_num                 (S_cur_layer_num),
         .I_feature_base_addr         (S_mem_addr_img_in_l),
         .I_ci_num                    ({20'd0,S_ipara_ciAlign}),
         .I_co_num                    ({20'd0,S_next_opara_co}),
         .I_kx_num                    ({27'd0,S_cnv_kernel_w}),
         .I_iheight                   ({16'd0,S_ipara_height}),
         .I_iwidth                    ({16'd0,S_ipara_width}),
         .I_oheight                   ({16'd0,S_opara_height}),
         .I_kernel_h                  ({27'd0,S_cnv_kernel_h}),
         .I_stride_h                  (S_cnv_stride_h),
         .I_stride_w                  (S_cnv_stride_w),
         .I_pad_w                     (S_cnv_pad_w),
         .I_pad_h                     (S_cnv_pad_h),
         .I_owidth_num                ({16'd0,S_opara_width}),
         .I_ap_start                  (S_start),
         .I_weight                    (S_mem_weight),
         .I_weight_dv                 (S_mem_weight_valid),
         .I_weight_ch                 (S_weight_ch),
         .I_relu_en                   (S_relu_en),
         .I_imgOutAddr                (S_mem_addr_img_out_l),
         .I_opara_coAlign16           (S_next_opara_coAlign16),
         .I_coAlign                   (S_opara_coAlign),
         .I_ciAlign                   (S_ipara_ciAlign),
         .I_ciGroup                   (S_ipara_ciGroup),
         .I_imgInPos                  (S_img_in_pos),
         .I_wghInPos                  (S_weight_in_pos),
         .I_biasInPos                 (S_bias_in_pos),
         .I_imgOutPos                 (S_img_out_pos),
         .O_result_0                  (),
         .O_result_1                  (),
         .O_data_dv                   (),
         .O_last_line                 (S_last_line),
         .O_dram_feature_rd_flag      (S_dram_feature_rd_flag),
         .O_dram_feature_rd_addr      (S_dram_feature_rd_addr),
         .O_cnv_data                  (S_cnv_data), 
         .O_cnv_dv                    (S_cnv_dv),
         .O_wr_DDRaddr                (S_wr_DDR_addr)
        );
  
         
endmodule
