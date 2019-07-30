`timescale 1ns / 1ps


module s_axilite2reg#(
parameter
    C_ADDR_WIDTH    = 32,
    C_DATA_WIDTH    = 32
)(
    input                                           I_aclk,
    input                                           I_arst,
    //axi
    output reg                                      O_lite_awready              = 0,
    input               [C_ADDR_WIDTH-1:0]          I_lite_awaddr,         
    input                                           I_lite_awvalid,         
    output reg                                      O_lite_wready               = 0,
    input               [C_DATA_WIDTH-1:0]          I_lite_wdata,         
    input                                           I_lite_wvalid,         
    input               [C_DATA_WIDTH/8-1:0]        I_lite_wstrb,         
    input                                           I_lite_bready,         
    output reg          [1:0]                       O_lite_bresp                = 0,//okay
    output reg                                      O_lite_bvalid               = 0,
    output reg                                      O_lite_arready              = 0,
    input               [C_ADDR_WIDTH-1:0]          I_lite_araddr,         
    input                                           I_lite_arvalid,         
    input                                           I_lite_rready,         
    output reg          [C_DATA_WIDTH-1:0]          O_lite_rdata                = 0,
    output reg                                      O_lite_rvalid               = 0,
    output reg          [1:0]                       O_lite_rresp                = 0,
    //register         
    output reg          [C_ADDR_WIDTH-1:0]          O_reg_addr                  = 0,
    output reg          [C_DATA_WIDTH-1:0]          O_reg_data                  = 0,
    input                                           I_ap_start_done,
    
    output reg                                      O_start                     = 0,
    output reg          [31:0]                      O_weight_base_addr          = 0,
    output reg          [31:0]                      O_f_iddr_addr               = 0,
    output reg          [31:0]                      O_f_oddr_addr               = 0,
    output reg          [0 :0]                      O_cnv_en                    = 0,
    output reg          [0 :0]                      O_pooling_en                = 0,
    output reg          [15:0]                      O_cur_layer_num             = 0,
    output reg          [0 :0]                      O_layer_div_type            = 0,
    output reg          [10:0]                      O_sub_layer_num             = 0,
    output reg          [10:0]                      O_sub_layer_seq             = 0,
    output reg          [1 :0]                      O_sub_layer_flag            = 0,
    output reg          [15:0]                      O_weight_in_pos             = 0,
    output reg          [15:0]                      O_bias_in_pos               = 0,
    output reg          [15:0]                      O_scale_in_pos              = 0,
    output reg          [15:0]                      O_mean_in_pos               = 0,
    output reg          [15:0]                      O_variance_in_pos           = 0,
    output reg          [31:0]                      O_weight_mem_addr_l         = 0,
    output reg          [7 :0]                      O_weight_mem_addr_h         = 0,
    output reg          [31:0]                      O_bias_mem_addr_l           = 0,
    output reg          [7 :0]                      O_bias_mem_addr_h           = 0,
    output reg          [31:0]                      O_mem_addr_scale_l          = 0,
    output reg          [7 :0]                      O_mem_addr_scale_h          = 0,
    output reg          [31:0]                      O_mem_addr_mean_l           = 0,
    output reg          [7 :0]                      O_mem_addr_mean_h           = 0,
    output reg          [31:0]                      O_mem_addr_variance_l       = 0,
    output reg          [7 :0]                      O_mem_addr_variance_h       = 0,
    output reg          [18:0]                      O_compress_size             = 0,
    output reg          [15:0]                      O_next_layer_num            = 0,
    output reg          [0 :0]                      O_next_div_type             = 0,
    output reg          [10:0]                      O_next_sub_layer_num        = 0,
    output reg          [10:0]                      O_next_sub_layer_seq        = 0,
    output reg          [1 :0]                      O_next_sub_layer_flag       = 0,
    output reg          [15:0]                      O_next_weight_in_pos        = 0,
    output reg          [15:0]                      O_next_bias_in_pos          = 0,
    output reg          [15:0]                      O_next_scale_in_pos         = 0,
    output reg          [15:0]                      O_next_mean_in_pos          = 0,
    output reg          [15:0]                      O_next_variance_in_pos      = 0,
    output reg          [31:0]                      O_next_weight_mem_addr_l    = 0,
    output reg          [7 :0]                      O_next_weight_mem_addr_h    = 0,
    output reg          [31:0]                      O_next_bias_mem_addr_l      = 0,
    output reg          [7 :0]                      O_next_bias_mem_addr_h      = 0,
    output reg          [31:0]                      O_next_mem_addr_scale_l     = 0,
    output reg          [7 :0]                      O_next_mem_addr_scale_h     = 0,
    output reg          [31:0]                      O_next_mem_addr_mean_l      = 0,
    output reg          [7 :0]                      O_next_mem_addr_mean_h      = 0,
    output reg          [31:0]                      O_next_mem_addr_variance_l  = 0,
    output reg          [7 :0]                      O_next_mem_addr_variance_h  = 0,
    output reg          [18:0]                      O_next_compress_size        = 0,
    output reg          [15:0]                      O_ipara_batchsize           = 0,
    output reg          [15:0]                      O_ipara_width               = 0,
    output reg          [15:0]                      O_ipara_height              = 0,
    output reg          [12:0]                      O_ipara_ci                  = 0,
    output reg          [12:0]                      O_ipara_ciAlign             = 0,
    output reg          [12:0]                      O_ipara_ciGroup             = 0,
    output reg          [15:0]                      O_img_in_pos                = 0,
    output reg          [31:0]                      O_mem_addr_img_in_l         = 0,
    output reg          [7 :0]                      O_mem_addr_img_in_h         = 0,
    output reg          [15:0]                      O_next_ipara_batchsize      = 0,
    output reg          [15:0]                      O_next_ipara_width          = 0,
    output reg          [15:0]                      O_next_ipara_height         = 0,
    output reg          [12:0]                      O_next_ipara_ci             = 0,
    output reg          [12:0]                      O_next_ipara_ciAlign        = 0,
    output reg          [12:0]                      O_next_ipara_ciGroup        = 0,
    output reg          [15:0]                      O_next_img_in_pos           = 0,
    output reg          [31:0]                      O_next_mem_addr_img_in_l    = 0,
    output reg          [7 :0]                      O_next_mem_addr_img_in_h    = 0,
    output reg          [15:0]                      O_opara_batchsize           = 0,
    output reg          [15:0]                      O_opara_width               = 0,
    output reg          [15:0]                      O_opara_height              = 0,
    output reg          [12:0]                      O_opara_co                  = 0,
    output reg          [12:0]                      O_opara_coAlign             = 0,
    output reg          [12:0]                      O_opara_coAlign16           = 0,
    output reg          [15:0]                      O_img_out_pos               = 0,
    output reg          [31:0]                      O_mem_addr_img_out_l        = 0,
    output reg          [7 :0]                      O_mem_addr_img_out_h        = 0,
    output reg          [15:0]                      O_next_opara_batchsize      = 0,
    output reg          [15:0]                      O_next_opara_width          = 0,
    output reg          [15:0]                      O_next_opara_height         = 0,
    output reg          [12:0]                      O_next_opara_co             = 0,
    output reg          [12:0]                      O_next_opara_coAlign        = 0,
    output reg          [12:0]                      O_next_opara_coAlign16      = 0,
    output reg          [15:0]                      O_next_img_out_pos          = 0,
    output reg          [31:0]                      O_next_mem_addr_img_out_l   = 0,
    output reg          [7 :0]                      O_next_mem_addr_img_out_h   = 0,
    output reg          [0 :0]                      O_relu_en                   = 0,
    output reg          [15:0]                      O_dilation                  = 0,
    output reg          [4 :0]                      O_cnv_pad_h                 = 0,
    output reg          [4 :0]                      O_cnv_pad_w                 = 0,
    output reg          [4 :0]                      O_cnv_kernel_h              = 0,
    output reg          [4 :0]                      O_cnv_kernel_w              = 0,
    output reg          [4 :0]                      O_cnv_stride_h              = 0,
    output reg          [4 :0]                      O_cnv_stride_w              = 0,
    output reg          [0 :0]                      O_next_relu_en              = 0,
    output reg          [15:0]                      O_next_dilation             = 0,
    output reg          [4 :0]                      O_next_cnv_pad_h            = 0,
    output reg          [4 :0]                      O_next_cnv_pad_w            = 0,
    output reg          [4 :0]                      O_next_cnv_kernel_h         = 0,
    output reg          [4 :0]                      O_next_cnv_kernel_w         = 0,
    output reg          [4 :0]                      O_next_cnv_stride_h         = 0,
    output reg          [4 :0]                      O_next_cnv_stride_w         = 0,
    output reg          [4 :0]                      O_pool_pad_h                = 0,
    output reg          [4 :0]                      O_pool_pad_w                = 0,
    output reg          [4 :0]                      O_pool_kernel_h             = 0,
    output reg          [4 :0]                      O_pool_kernel_w             = 0,
    output reg          [4 :0]                      O_pool_stride_h             = 0,
    output reg          [4 :0]                      O_pool_stride_w             = 0,
    output reg          [0 :0]                      O_pool_type                 = 0,       
    
    input                                           I_ap_ready,
    input                                           I_ap_done
    );
    
    localparam  ADDR_AP_CTRL                            = 32'ha000_1000;
    localparam  GLOBAL_INT_EN                           = 32'ha000_1004;
    localparam  IP_INT_EN                               = 32'ha000_1008;
    localparam  IP_INT_STAT                             = 32'ha000_100c;
                
    localparam  WDDR_BASE_ADDR                          = 32'ha000_1010;
    localparam  F_IDDR_ADDR                             = 32'ha000_1018;
    localparam  F_ODDR_ADDR                             = 32'ha000_1020;
    localparam  LAYER_EN_CNVEN                          = 32'ha000_1040;
    localparam  LAYER_EN_POOLEN                         = 32'ha000_1048;
    localparam  LAYER_NUM_CUR                           = 32'ha000_1050;
    localparam  LAYER_DIV_TYPE                          = 32'ha000_1058;
    localparam  SUB_LAYRT_NUM                           = 32'ha000_1060;
    localparam  SUB_LAYRT_SEQ                           = 32'ha000_1068;
    localparam  SUB_LAYER_FLAG                          = 32'ha000_1070;
    localparam  WEIGHT_IN_POS                           = 32'ha000_1078;
    localparam  BIAS_IN_POS                             = 32'ha000_1080;
    localparam  SCALE_IN_POS                            = 32'ha000_1088;
    localparam  MEAN_IN_POS                             = 32'ha000_1090;
    localparam  VARIANCE_IN_POS                         = 32'ha000_1098;
    localparam  MEM_ADDR_WEIGHTS_L                      = 32'ha000_10a0;
    localparam  MEM_ADDR_WEIGHTS_H                      = 32'ha000_10a4;
    localparam  MEM_ADDR_BIAS_L                         = 32'ha000_10ac;
    localparam  MEM_ADDR_BIAS_H                         = 32'ha000_10b0;
    localparam  MEM_ADDR_SCALE_L                        = 32'ha000_10b8;
    localparam  MEM_ADDR_SCALE_H                        = 32'ha000_10bc;
    localparam  MEM_ADDR_MEAN_L                         = 32'ha000_10c4;
    localparam  MEM_ADDR_MEAN_H                         = 32'ha000_10c8;
    localparam  MEM_ADDR_VARIANCE_L                     = 32'ha000_10d0;
    localparam  MEM_ADDR_VARIANCE_H                     = 32'ha000_10d4;
    localparam  COMPRESSION_SIZE                        = 32'ha000_10dc;
    localparam  NEXT_LAYER_NUM_CUR                      = 32'ha000_10e4;
    localparam  NEXT_LAYER_DIV_TYPE                     = 32'ha000_10ec;
    localparam  NEXT_SUB_LAYRT_NUM                      = 32'ha000_10f4;
    localparam  NEXT_SUB_LAYRT_SEQ                      = 32'ha000_10fc;
    localparam  NEXT_SUB_LAYER_FLAG                     = 32'ha000_1104;
    localparam  NEXT_WEIGHT_IN_POS                      = 32'ha000_110c;
    localparam  NEXT_BIAS_IN_POS                        = 32'ha000_1114;
    localparam  NEXT_SCALE_IN_POS                       = 32'ha000_111c;
    localparam  NEXT_MEAN_IN_POS                        = 32'ha000_1124;
    localparam  NEXT_VARIANCE_IN_POS                    = 32'ha000_112c;
    localparam  NEXT_MEM_ADDR_WEIGHTS_L                 = 32'ha000_1134;
    localparam  NEXT_MEM_ADDR_WEIGHTS_H                 = 32'ha000_1138;
    localparam  NEXT_MEM_ADDR_BIAS_L                    = 32'ha000_1140;
    localparam  NEXT_MEM_ADDR_BIAS_H                    = 32'ha000_1144;
    localparam  NEXT_MEM_ADDR_SCALE_L                   = 32'ha000_114c;
    localparam  NEXT_MEM_ADDR_SCALE_H                   = 32'ha000_1150;
    localparam  NEXT_MEM_ADDR_MEAN_L                    = 32'ha000_1158;
    localparam  NEXT_MEM_ADDR_MEAN_H                    = 32'ha000_115c;
    localparam  NEXT_MEM_ADDR_VARIANCE_L                = 32'ha000_1164;
    localparam  NEXT_MEM_ADDR_VARIANCE_H                = 32'ha000_1168;
    localparam  NEXT_COMPRESSION_SIZE                   = 32'ha000_1170;
    localparam  IPARA_BATCHSIZE                         = 32'ha000_1178;
    localparam  IPARA_WIDTH                             = 32'ha000_1180;
    localparam  IPARA_HEIGHT                            = 32'ha000_1188;
    localparam  IPARA_CI                                = 32'ha000_1190;
    localparam  IPARA_CIALIGN                           = 32'ha000_1198;
    localparam  IPARA_CIGROUP                           = 32'ha000_11a0;
    localparam  IPARA_IMGINPOS                          = 32'ha000_11a8;
    localparam  IPARA_MEM_ADDR_IMG_IN_L                 = 32'ha000_11b0;
    localparam  IPARA_MEM_ADDR_IMG_IN_H                 = 32'ha000_11b4;
    localparam  NEXT_IPARA_BATCHSIZE                    = 32'ha000_11bc;
    localparam  NEXT_IPARA_WIDTH                        = 32'ha000_11c4;
    localparam  NEXT_IPARA_HEIGHT                       = 32'ha000_11cc;
    localparam  NEXT_IPARA_CI                           = 32'ha000_11d4;
    localparam  NEXT_IPARA_CIALIGN                      = 32'ha000_11dc;
    localparam  NEXT_IPARA_CIGROUP                      = 32'ha000_11e4;
    localparam  NEXT_IPARA_IMGINPOS                     = 32'ha000_11ec;
    localparam  NEXT_IPARA_MEM_ADDR_IMG_IN_L            = 32'ha000_11f4;
    localparam  NEXT_IPARA_MEM_ADDR_IMG_IN_H            = 32'ha000_11f8;
    localparam  OPARA_BATCHSIZE                         = 32'ha000_1200;
    localparam  OPARA_WIDTH                             = 32'ha000_1208;
    localparam  OPARA_HEIGHT                            = 32'ha000_1210;
    localparam  OPARA_CO                                = 32'ha000_1218;
    localparam  OPARA_COALIGN                           = 32'ha000_1220;
    localparam  OPARA_COALIGN16                         = 32'ha000_1228;
    localparam  OPARA_IMGOUTPOS                         = 32'ha000_1230;
    localparam  OPARA_MEM_ADDR_IMG_OUT_L                = 32'ha000_1238;
    localparam  OPARA_MEM_ADDR_IMG_OUT_H                = 32'ha000_123c;
    localparam  NEXT_OPARA_BATCHSIZE                    = 32'ha000_1244;
    localparam  NEXT_OPARA_WIDTH                        = 32'ha000_124c;
    localparam  NEXT_OPARA_HEIGHT                       = 32'ha000_1254;
    localparam  NEXT_OPARA_CO                           = 32'ha000_125c;
    localparam  NEXT_OPARA_COALIGN                      = 32'ha000_1264;
    localparam  NEXT_OPARA_COALIGN16                    = 32'ha000_126c;
    localparam  NEXT_OPARA_IMGOUTPOS                    = 32'ha000_1274;
    localparam  NEXT_OPARA_MEM_ADDR_IMG_OUT_L           = 32'ha000_127c;
    localparam  NEXT_OPARA_MEM_ADDR_IMG_OUT_H           = 32'ha000_1280;
    localparam  LAYER_EN_RELUEN                         = 32'ha000_1288;
    localparam  PARA_DILATION                           = 32'ha000_1290;
    localparam  LAYER_PAD_H                             = 32'ha000_1298;
    localparam  LAYER_PAD_W                             = 32'ha000_12a0;
    localparam  LAYER_KERNEL_H                          = 32'ha000_12a8;
    localparam  LAYER_KERNEL_W                          = 32'ha000_12b0;
    localparam  LAYER_STRIDE_H                          = 32'ha000_12b8;
    localparam  LAYER_STRIDE_W                          = 32'ha000_12c0;
    localparam  NEXT_LAYER_EN_RELUEN                    = 32'ha000_12c8;
    localparam  NEXT_PARA_DILATION                      = 32'ha000_12d0;
    localparam  NEXT_LAYER_PAD_H                        = 32'ha000_12d8;
    localparam  NEXT_LAYER_PAD_W                        = 32'ha000_12e0;
    localparam  NEXT_LAYER_KERNEL_H                     = 32'ha000_12e8;
    localparam  NEXT_LAYER_KERNEL_W                     = 32'ha000_12f0;
    localparam  NEXT_LAYER_STRIDE_H                     = 32'ha000_12f8;
    localparam  NEXT_LAYER_STRIDE_W                     = 32'ha000_1300;
    localparam  PARA_POOL_PAD_H                         = 32'ha000_1308;
    localparam  PARA_POOL_PAD_W                         = 32'ha000_1310;
    localparam  PARA_POOL_KERNEL_H                      = 32'ha000_1318;
    localparam  PARA_POOL_KERNEL_W                      = 32'ha000_1320;
    localparam  PARA_POOL_STRIDE_H                      = 32'ha000_1328;
    localparam  PARA_POOL_STRIDE_W                      = 32'ha000_1330;
    localparam  PARA_POOL_TYPE                          = 32'ha000_1338;
    
    
    reg    aw_en = 1'b1;
    reg    ap_idle = 1'b1;
    reg    [1:0] ap_start;
    wire   bv_en = O_lite_awready & I_lite_awvalid & ~O_lite_bvalid & O_lite_wready & I_lite_wvalid;
    wire   rd_en = O_lite_arready & I_lite_arvalid;
    wire   wr_en = O_lite_wready & I_lite_wvalid;
    wire   [31:0] ap_ctrl = {28'd0,I_ap_ready,ap_idle,I_ap_done,O_start};
    reg    [8:0] S_stop_cnt=0;
    reg    S_cnt_en =0;
    
    always@ (posedge I_aclk)
    begin
        if (S_stop_cnt == 9'h1ff)
            S_cnt_en <= 1'b0;
        else if (O_start)
            S_cnt_en <= 1'b1;
        
        if (S_cnt_en)
            S_stop_cnt <= S_stop_cnt + 'd1;
    end
    
    always@ (posedge I_aclk)
    begin
        ap_start[1] = ap_start[0];
        ap_start[0] = O_start;
    
        if (/*~ap_start[1] & ap_start[0]*/O_start)
            ap_idle <= 1'b0;
        else if (I_ap_done)
            ap_idle <= 1'b1;

    end
    
    always@ (posedge I_aclk)
    begin
        if (I_arst) begin
            O_lite_awready <= 1'b0;
            aw_en <= 1'b1;
        end
        else begin
            if (~O_lite_awready & I_lite_awvalid & I_lite_wvalid & aw_en) begin
                O_lite_awready <= 1'b1;
                aw_en <= 1'b0;
            end
            else if (I_lite_bready & O_lite_bvalid) begin
                O_lite_awready <= 1'b0;
                aw_en <= 1'b1;
            end
            else begin
                O_lite_awready <= 1'b0;
            end
        end
    end
    
    always@ (posedge I_aclk)
    begin
        if (~O_lite_awready & I_lite_awvalid & I_lite_wvalid & aw_en) 
            O_reg_addr <= I_lite_awaddr;
        else;
    end
    
    always@ (posedge I_aclk)
    begin
        if (I_arst)
            O_lite_wready <= 1'b0;
        else if (~O_lite_wready & I_lite_awvalid & I_lite_wvalid & aw_en)
            O_lite_wready <= 1'b1;
        else
            O_lite_wready <= 1'b0;
    end
    
    always@ (posedge I_aclk)
    begin
        if (I_arst)
            O_lite_bvalid <= 1'b0;
        else if (/*O_awready & I_awvalid & (~O_bvalid) & O_wready & I_wvalid*/bv_en & (~O_lite_bvalid))
            O_lite_bvalid <= 1'b1;
        else if (O_lite_bvalid & I_lite_bready)
            O_lite_bvalid <= 1'b0;
    end
    
    always@ (posedge I_aclk)
    begin
        if (I_arst)
            O_lite_arready <= 1'b0;
        else if (~O_lite_arready & I_lite_arvalid)
            O_lite_arready <= 1'b1;
        else 
            O_lite_arready <= 1'b0;
    end

    
    always@ (posedge I_aclk)
    begin
        O_reg_data <= I_lite_wdata;
    end
    
    
    always@ (posedge I_aclk)
    begin
        if (I_arst)
            O_lite_rvalid <= 1'b0;
        else 
        if (rd_en) 
            O_lite_rvalid <= 1'b1;
        else if (O_lite_rvalid & I_lite_rready)
            O_lite_rvalid <= 1'b0;
    
//        if (rd_en) begin
//           if (I_lite_araddr == ADDR_AP_CTRL)
//               O_lite_rdata <= /*O_start*/ap_ctrl;
//           else if (I_lite_araddr[15:0] == DDR_RD_BASE_ADDR1[15:0])
//               O_lite_rdata <= O_ddr_rd_addr1;
//           else if (I_lite_araddr[15:0] == DDR_RD_BASE_ADDR2[15:0])
//               O_lite_rdata <= O_ddr_rd_addr2;   
           
//           else if (I_lite_araddr[15:0] == DDR_WR_BASE_ADDR[15:0])
//               O_lite_rdata <= O_ddr_wr_addr;
//           else if (I_lite_araddr[15:0] == IN_DATA_BYTES1[15:0])
//               O_lite_rdata <= O_in_data_bytes1;
//           else if (I_lite_araddr[15:0] == IN_DATA_BYTES2[15:0])
//               O_lite_rdata <= O_in_data_bytes2;
//           else if (I_lite_araddr[15:0] == OUT_DATA_BYTES[15:0])
//               O_lite_rdata <= O_out_data_bytes;
//        end
    end
    
    //----------------------------------------------
    //            read   back   part
    //----------------------------------------------
    
    always@ (posedge I_aclk)
    begin
        case(I_lite_araddr[11:0])
            ADDR_AP_CTRL[11:0]                    : O_lite_rdata <= ap_ctrl;
            WDDR_BASE_ADDR[11:0]                  : O_lite_rdata <= O_weight_base_addr;
            F_IDDR_ADDR[11:0]                     : O_lite_rdata <= O_f_iddr_addr;
            F_ODDR_ADDR[11:0]                     : O_lite_rdata <= O_f_oddr_addr;              
            LAYER_EN_CNVEN[11:0]                  : O_lite_rdata <= {31'd0,O_cnv_en};
            LAYER_EN_POOLEN[11:0]                 : O_lite_rdata <= {31'd0,O_pooling_en};
            LAYER_NUM_CUR[11:0]                   : O_lite_rdata <= {16'd0,O_cur_layer_num};
            LAYER_DIV_TYPE[11:0]                  : O_lite_rdata <= {31'd0,O_layer_div_type};
            SUB_LAYRT_NUM[11:0]                   : O_lite_rdata <= {21'd0,O_sub_layer_num};
            SUB_LAYRT_SEQ[11:0]                   : O_lite_rdata <= {21'd0,O_sub_layer_seq};
            SUB_LAYER_FLAG[11:0]                  : O_lite_rdata <= {30'd0,O_sub_layer_flag};
            WEIGHT_IN_POS[11:0]                   : O_lite_rdata <= {16'd0,O_weight_in_pos};
            BIAS_IN_POS[11:0]                     : O_lite_rdata <= {16'd0,O_bias_in_pos};
            SCALE_IN_POS[11:0]                    : O_lite_rdata <= {16'd0,O_scale_in_pos};
            MEAN_IN_POS[11:0]                     : O_lite_rdata <= {16'd0,O_mean_in_pos};
            VARIANCE_IN_POS[11:0]                 : O_lite_rdata <= {16'd0,O_variance_in_pos};
            MEM_ADDR_WEIGHTS_L[11:0]              : O_lite_rdata <= O_weight_mem_addr_l;
            MEM_ADDR_WEIGHTS_H[11:0]              : O_lite_rdata <= {24'd0,O_weight_mem_addr_h};
            MEM_ADDR_BIAS_L[11:0]                 : O_lite_rdata <= O_bias_mem_addr_l;  
            MEM_ADDR_BIAS_H[11:0]                 : O_lite_rdata <= {24'd0,O_bias_mem_addr_h};
            MEM_ADDR_SCALE_L[11:0]                : O_lite_rdata <= O_mem_addr_scale_l;
            MEM_ADDR_SCALE_H[11:0]                : O_lite_rdata <= {24'd0,O_mem_addr_scale_h};
            MEM_ADDR_MEAN_L[11:0]                 : O_lite_rdata <= O_mem_addr_mean_l;
            MEM_ADDR_MEAN_H[11:0]                 : O_lite_rdata <= {24'd0,O_mem_addr_mean_h};
            MEM_ADDR_VARIANCE_L[11:0]             : O_lite_rdata <= O_mem_addr_variance_l;
            MEM_ADDR_VARIANCE_H[11:0]             : O_lite_rdata <= {24'd0,O_mem_addr_variance_h};
            COMPRESSION_SIZE[11:0]                : O_lite_rdata <= {13'd0,O_compress_size};
            NEXT_LAYER_NUM_CUR[11:0]              : O_lite_rdata <= {16'd0,O_next_layer_num};
            NEXT_LAYER_DIV_TYPE[11:0]             : O_lite_rdata <= {31'd0,O_next_div_type};
            NEXT_SUB_LAYRT_NUM[11:0]              : O_lite_rdata <= {21'd0,O_next_sub_layer_num};
            NEXT_SUB_LAYRT_SEQ[11:0]              : O_lite_rdata <= {21'd0,O_next_sub_layer_seq};
            NEXT_SUB_LAYER_FLAG[11:0]             : O_lite_rdata <= {30'd0,O_next_sub_layer_flag};
            NEXT_WEIGHT_IN_POS[11:0]              : O_lite_rdata <= {16'd0,O_next_weight_in_pos};
            NEXT_BIAS_IN_POS[11:0]                : O_lite_rdata <= {16'd0,O_next_bias_in_pos};
            NEXT_SCALE_IN_POS[11:0]               : O_lite_rdata <= {16'd0,O_next_scale_in_pos};
            NEXT_MEAN_IN_POS[11:0]                : O_lite_rdata <= {16'd0,O_next_mean_in_pos};
            NEXT_VARIANCE_IN_POS[11:0]            : O_lite_rdata <= {16'd0,O_next_variance_in_pos};
            NEXT_MEM_ADDR_WEIGHTS_L[11:0]         : O_lite_rdata <= O_next_weight_mem_addr_l;
            NEXT_MEM_ADDR_WEIGHTS_H[11:0]         : O_lite_rdata <= {24'd0,O_next_weight_mem_addr_h};
            NEXT_MEM_ADDR_BIAS_L[11:0]            : O_lite_rdata <= O_next_bias_mem_addr_l;
            NEXT_MEM_ADDR_BIAS_H[11:0]            : O_lite_rdata <= {24'd0,O_next_bias_mem_addr_h};
            NEXT_MEM_ADDR_SCALE_L[11:0]           : O_lite_rdata <= O_next_mem_addr_scale_l;
            NEXT_MEM_ADDR_SCALE_H[11:0]           : O_lite_rdata <= {24'd0,O_next_mem_addr_scale_h};
            NEXT_MEM_ADDR_MEAN_L[11:0]            : O_lite_rdata <= O_next_mem_addr_mean_l;
            NEXT_MEM_ADDR_MEAN_H[11:0]            : O_lite_rdata <= {24'd0,O_next_mem_addr_mean_h};
            NEXT_MEM_ADDR_VARIANCE_L[11:0]        : O_lite_rdata <= O_next_mem_addr_variance_l;
            NEXT_MEM_ADDR_VARIANCE_H[11:0]        : O_lite_rdata <= {24'd0,O_next_mem_addr_variance_h};
            NEXT_COMPRESSION_SIZE[11:0]           : O_lite_rdata <= {13'd0,O_next_compress_size};
            IPARA_BATCHSIZE[11:0]                 : O_lite_rdata <= {16'd0,O_ipara_batchsize};
            IPARA_WIDTH[11:0]                     : O_lite_rdata <= {16'd0,O_ipara_width};
            IPARA_HEIGHT[11:0]                    : O_lite_rdata <= {16'd0,O_ipara_height};
            IPARA_CI[11:0]                        : O_lite_rdata <= {19'd0,O_ipara_ci};
            IPARA_CIALIGN[11:0]                   : O_lite_rdata <= {19'd0,O_ipara_ciAlign};
            IPARA_CIGROUP[11:0]                   : O_lite_rdata <= {19'd0,O_ipara_ciGroup};
            IPARA_IMGINPOS[11:0]                  : O_lite_rdata <= {16'd0,O_img_in_pos};
            IPARA_MEM_ADDR_IMG_IN_L[11:0]         : O_lite_rdata <= O_mem_addr_img_in_l;
            IPARA_MEM_ADDR_IMG_IN_H[11:0]         : O_lite_rdata <= {24'd0,O_mem_addr_img_in_h};
            NEXT_IPARA_BATCHSIZE[11:0]            : O_lite_rdata <= {16'd0,O_next_ipara_batchsize};
            NEXT_IPARA_WIDTH[11:0]                : O_lite_rdata <= {16'd0,O_next_ipara_width};
            NEXT_IPARA_HEIGHT[11:0]               : O_lite_rdata <= {16'd0,O_next_ipara_height};
            NEXT_IPARA_CI[11:0]                   : O_lite_rdata <= {19'd0,O_next_ipara_ci};
            NEXT_IPARA_CIALIGN[11:0]              : O_lite_rdata <= {19'd0,O_next_ipara_ciAlign};
            NEXT_IPARA_CIGROUP[11:0]              : O_lite_rdata <= {19'd0,O_next_ipara_ciGroup};
            NEXT_IPARA_IMGINPOS[11:0]             : O_lite_rdata <= {16'd0,O_next_img_in_pos};
            NEXT_IPARA_MEM_ADDR_IMG_IN_L[11:0]    : O_lite_rdata <= O_next_mem_addr_img_in_l;
            NEXT_IPARA_MEM_ADDR_IMG_IN_H[11:0]    : O_lite_rdata <= {24'd0,O_next_mem_addr_img_in_h};
            OPARA_BATCHSIZE[11:0]                 : O_lite_rdata <= {16'd0,O_opara_batchsize};
            OPARA_WIDTH[11:0]                     : O_lite_rdata <= {16'd0,O_opara_width};
            OPARA_HEIGHT[11:0]                    : O_lite_rdata <= {16'd0,O_opara_height};
            OPARA_CO[11:0]                        : O_lite_rdata <= {19'd0,O_opara_co};
            OPARA_COALIGN[11:0]                   : O_lite_rdata <= {19'd0,O_opara_coAlign};
            OPARA_COALIGN16[11:0]                 : O_lite_rdata <= {19'd0,O_opara_coAlign16};
            OPARA_IMGOUTPOS[11:0]                 : O_lite_rdata <= {16'd0,O_img_out_pos};
            OPARA_MEM_ADDR_IMG_OUT_L[11:0]        : O_lite_rdata <= O_mem_addr_img_out_l;
            OPARA_MEM_ADDR_IMG_OUT_H[11:0]        : O_lite_rdata <= {24'd0,O_mem_addr_img_out_h};
            NEXT_OPARA_BATCHSIZE[11:0]            : O_lite_rdata <= {16'd0,O_next_opara_batchsize};
            NEXT_OPARA_WIDTH[11:0]                : O_lite_rdata <= {16'd0,O_next_opara_width};
            NEXT_OPARA_HEIGHT[11:0]               : O_lite_rdata <= {16'd0,O_next_opara_height};
            NEXT_OPARA_CO[11:0]                   : O_lite_rdata <= {19'd0,O_next_opara_co};
            NEXT_OPARA_COALIGN[11:0]              : O_lite_rdata <= {19'd0,O_next_opara_coAlign};
            NEXT_OPARA_COALIGN16[11:0]            : O_lite_rdata <= {19'd0,O_next_opara_coAlign16};
            NEXT_OPARA_IMGOUTPOS[11:0]            : O_lite_rdata <= {16'd0,O_next_img_out_pos};
            NEXT_OPARA_MEM_ADDR_IMG_OUT_L[11:0]   : O_lite_rdata <= O_next_mem_addr_img_out_l;
            NEXT_OPARA_MEM_ADDR_IMG_OUT_H[11:0]   : O_lite_rdata <= {24'd0,O_next_mem_addr_img_out_h};
            LAYER_EN_RELUEN[11:0]                 : O_lite_rdata <= {31'd0,O_relu_en};
            PARA_DILATION[11:0]                   : O_lite_rdata <= {16'd0,O_dilation};
            LAYER_PAD_H[11:0]                     : O_lite_rdata <= {27'd0,O_cnv_pad_h};
            LAYER_PAD_W[11:0]                     : O_lite_rdata <= {27'd0,O_cnv_pad_w};
            LAYER_KERNEL_H[11:0]                  : O_lite_rdata <= {27'd0,O_cnv_kernel_h};
            LAYER_KERNEL_W[11:0]                  : O_lite_rdata <= {27'd0,O_cnv_kernel_w};
            LAYER_STRIDE_H[11:0]                  : O_lite_rdata <= {27'd0,O_cnv_stride_h};
            LAYER_STRIDE_W[11:0]                  : O_lite_rdata <= {27'd0,O_cnv_stride_w};
            NEXT_LAYER_EN_RELUEN[11:0]            : O_lite_rdata <= {31'd0,O_next_relu_en};
            NEXT_PARA_DILATION[11:0]              : O_lite_rdata <= {16'd0,O_next_dilation};
            NEXT_LAYER_PAD_H[11:0]                : O_lite_rdata <= {27'd0,O_next_cnv_pad_h};
            NEXT_LAYER_PAD_W[11:0]                : O_lite_rdata <= {27'd0,O_next_cnv_pad_w};
            NEXT_LAYER_KERNEL_H[11:0]             : O_lite_rdata <= {27'd0,O_next_cnv_kernel_h};
            NEXT_LAYER_KERNEL_W[11:0]             : O_lite_rdata <= {27'd0,O_next_cnv_kernel_w};
            NEXT_LAYER_STRIDE_H[11:0]             : O_lite_rdata <= {27'd0,O_next_cnv_stride_h};
            NEXT_LAYER_STRIDE_W[11:0]             : O_lite_rdata <= {27'd0,O_next_cnv_stride_w};
            PARA_POOL_PAD_H[11:0]                 : O_lite_rdata <= {27'd0,O_pool_pad_h};
            PARA_POOL_PAD_W[11:0]                 : O_lite_rdata <= {27'd0,O_pool_pad_w};
            PARA_POOL_KERNEL_H[11:0]              : O_lite_rdata <= {27'd0,O_pool_kernel_h};
            PARA_POOL_KERNEL_W[11:0]              : O_lite_rdata <= {27'd0,O_pool_kernel_w};
            PARA_POOL_STRIDE_H[11:0]              : O_lite_rdata <= {27'd0,O_pool_stride_h};
            PARA_POOL_STRIDE_W[11:0]              : O_lite_rdata <= {27'd0,O_pool_stride_w};
            PARA_POOL_TYPE[11:0]                  : O_lite_rdata <= {31'd0,O_pool_type};
            default : O_lite_rdata <= 'd0;
        endcase
    end
    
    
    always@ (posedge I_aclk)
    begin
        if (I_arst)
            O_start <= 1'b0;
        else if (I_lite_awaddr[11:0] == ADDR_AP_CTRL[11:0] & wr_en)
            O_start <= I_lite_wdata[0];
        else if (S_stop_cnt==9'h1fe)
            O_start <= 1'b0;
            
        if (I_lite_awaddr[11:0] == WDDR_BASE_ADDR[11:0] & wr_en)
            O_weight_base_addr <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == F_IDDR_ADDR[11:0] & wr_en)
            O_f_iddr_addr <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == F_ODDR_ADDR[11:0] & wr_en)
            O_f_oddr_addr <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == LAYER_EN_CNVEN[11:0] & wr_en)
            O_cnv_en <= I_lite_wdata[0];
        
        if (I_lite_awaddr[11:0] == LAYER_EN_POOLEN[11:0] & wr_en)
            O_pooling_en <= I_lite_wdata[0];
        
        if (I_lite_awaddr[11:0] == LAYER_NUM_CUR[11:0] & wr_en)
            O_cur_layer_num <= I_lite_wdata[15:0];

        if (I_lite_awaddr[11:0] == LAYER_DIV_TYPE[11:0] & wr_en)
            O_layer_div_type <= I_lite_wdata[0];
    
        if (I_lite_awaddr[11:0] == SUB_LAYRT_NUM[11:0] & wr_en)
            O_sub_layer_num <= I_lite_wdata[10:0];
        
        if (I_lite_awaddr[11:0] == SUB_LAYRT_SEQ[11:0] & wr_en)
            O_sub_layer_seq <= I_lite_wdata[10:0];
        
        if (I_lite_awaddr[11:0] == SUB_LAYER_FLAG[11:0] & wr_en)
            O_sub_layer_flag <= I_lite_wdata[1:0];
        
        if (I_lite_awaddr[11:0] == WEIGHT_IN_POS[11:0] & wr_en)
            O_weight_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == BIAS_IN_POS[11:0] & wr_en)
            O_bias_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == SCALE_IN_POS[11:0] & wr_en)
            O_scale_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == MEAN_IN_POS[11:0] & wr_en)
            O_mean_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == VARIANCE_IN_POS[11:0] & wr_en)
            O_variance_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_WEIGHTS_L[11:0] & wr_en)
            O_weight_mem_addr_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_WEIGHTS_H[11:0] & wr_en)
            O_weight_mem_addr_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_BIAS_L[11:0] & wr_en)
            O_bias_mem_addr_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_BIAS_H[11:0] & wr_en)
            O_bias_mem_addr_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_SCALE_L[11:0] & wr_en)
            O_mem_addr_scale_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_SCALE_H[11:0] & wr_en)
            O_mem_addr_scale_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_MEAN_L[11:0] & wr_en)
            O_mem_addr_mean_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_MEAN_H[11:0] & wr_en)
            O_mem_addr_mean_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_VARIANCE_L[11:0] & wr_en)
            O_mem_addr_variance_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == MEM_ADDR_VARIANCE_H[11:0] & wr_en)
            O_mem_addr_variance_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == COMPRESSION_SIZE[11:0] & wr_en)
            O_compress_size <= I_lite_wdata[18:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_NUM_CUR[11:0] & wr_en)
            O_next_layer_num <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_DIV_TYPE[11:0] & wr_en)
            O_next_div_type <= I_lite_wdata[0];
        
        if (I_lite_awaddr[11:0] == NEXT_SUB_LAYRT_NUM[11:0] & wr_en)
            O_next_sub_layer_num <= I_lite_wdata[10:0];
        
        if (I_lite_awaddr[11:0] == NEXT_SUB_LAYRT_SEQ[11:0] & wr_en)
            O_next_sub_layer_seq <= I_lite_wdata[10:0];
        
        if (I_lite_awaddr[11:0] == NEXT_SUB_LAYER_FLAG[11:0] & wr_en)
            O_next_sub_layer_flag <= I_lite_wdata[1:0];
        
        if (I_lite_awaddr[11:0] == NEXT_WEIGHT_IN_POS[11:0] & wr_en)
            O_next_weight_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_BIAS_IN_POS[11:0] & wr_en)
            O_next_bias_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_SCALE_IN_POS[11:0] & wr_en)
            O_next_scale_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEAN_IN_POS[11:0] & wr_en)
            O_next_mean_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_VARIANCE_IN_POS[11:0] & wr_en)
            O_next_variance_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_WEIGHTS_L[11:0] & wr_en)
            O_next_weight_mem_addr_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_WEIGHTS_H[11:0] & wr_en)
            O_next_weight_mem_addr_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_BIAS_L[11:0] & wr_en)
            O_next_bias_mem_addr_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_BIAS_H[11:0] & wr_en)
            O_next_bias_mem_addr_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_SCALE_L[11:0] & wr_en)
            O_next_mem_addr_scale_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_SCALE_H[11:0] & wr_en)
            O_next_mem_addr_scale_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_MEAN_L[11:0] & wr_en)
            O_next_mem_addr_mean_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_MEAN_H[11:0] & wr_en)
            O_next_mem_addr_mean_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_VARIANCE_L[11:0] & wr_en)
            O_next_mem_addr_variance_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_MEM_ADDR_VARIANCE_H[11:0] & wr_en)
            O_next_mem_addr_variance_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_COMPRESSION_SIZE[11:0] & wr_en)
            O_next_compress_size <= I_lite_wdata[18:0];
        
        if (I_lite_awaddr[11:0] == IPARA_BATCHSIZE[11:0] & wr_en)
            O_ipara_batchsize <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == IPARA_WIDTH[11:0] & wr_en)
            O_ipara_width <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == IPARA_HEIGHT[11:0] & wr_en)
            O_ipara_height <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == IPARA_CI[11:0] & wr_en)
            O_ipara_ci <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == IPARA_CIALIGN[11:0] & wr_en)
            O_ipara_ciAlign <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == IPARA_CIGROUP[11:0] & wr_en)
            O_ipara_ciGroup <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == IPARA_IMGINPOS[11:0] & wr_en)
            O_img_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == IPARA_MEM_ADDR_IMG_IN_L[11:0] & wr_en)
            O_mem_addr_img_in_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == IPARA_MEM_ADDR_IMG_IN_H[11:0] & wr_en)
            O_mem_addr_img_in_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_BATCHSIZE[11:0] & wr_en)
            O_next_ipara_batchsize <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_WIDTH[11:0] & wr_en)
            O_next_ipara_width <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_HEIGHT[11:0] & wr_en)
            O_next_ipara_height <= I_lite_wdata[15:0];
    
        if (I_lite_awaddr[11:0] == NEXT_IPARA_CI[11:0] & wr_en)
            O_next_ipara_ci <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_CIALIGN[11:0] & wr_en)
            O_next_ipara_ciAlign <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_CIGROUP[11:0] & wr_en)
            O_next_ipara_ciGroup <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_IMGINPOS[11:0] & wr_en)
            O_next_img_in_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_MEM_ADDR_IMG_IN_L[11:0] & wr_en)
            O_next_mem_addr_img_in_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_IPARA_MEM_ADDR_IMG_IN_H[11:0] & wr_en)
            O_next_mem_addr_img_in_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == OPARA_BATCHSIZE[11:0] & wr_en)
            O_opara_batchsize <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == OPARA_WIDTH[11:0] & wr_en)
            O_opara_width <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == OPARA_HEIGHT[11:0] & wr_en)
            O_opara_height <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == OPARA_CO[11:0] & wr_en)
            O_opara_co <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == OPARA_COALIGN[11:0] & wr_en)
            O_opara_coAlign <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == OPARA_COALIGN16[11:0] & wr_en)
            O_opara_coAlign16 <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == OPARA_IMGOUTPOS[11:0] & wr_en)
            O_img_out_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == OPARA_MEM_ADDR_IMG_OUT_L[11:0] & wr_en)
            O_mem_addr_img_out_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == OPARA_MEM_ADDR_IMG_OUT_H[11:0] & wr_en)
            O_mem_addr_img_out_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_BATCHSIZE[11:0] & wr_en)
            O_next_opara_batchsize <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_WIDTH[11:0] & wr_en)
            O_next_opara_width <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_HEIGHT[11:0] & wr_en)
            O_next_opara_height <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_CO[11:0] & wr_en)
            O_next_opara_co <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_COALIGN[11:0] & wr_en)
            O_next_opara_coAlign <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_COALIGN16[11:0] & wr_en)
            O_next_opara_coAlign16 <= I_lite_wdata[12:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_IMGOUTPOS[11:0] & wr_en)
            O_next_img_out_pos <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_MEM_ADDR_IMG_OUT_L[11:0] & wr_en)
            O_next_mem_addr_img_out_l <= I_lite_wdata;
        
        if (I_lite_awaddr[11:0] == NEXT_OPARA_MEM_ADDR_IMG_OUT_H[11:0] & wr_en)
            O_next_mem_addr_img_out_h <= I_lite_wdata[7:0];
        
        if (I_lite_awaddr[11:0] == LAYER_EN_RELUEN[11:0] & wr_en)
            O_relu_en <= I_lite_wdata[0];
        
        if (I_lite_awaddr[11:0] == PARA_DILATION[11:0] & wr_en)
            O_dilation <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == LAYER_PAD_H[11:0] & wr_en)
            O_cnv_pad_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == LAYER_PAD_W[11:0] & wr_en)
            O_cnv_pad_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == LAYER_KERNEL_H[11:0] & wr_en)
            O_cnv_kernel_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == LAYER_KERNEL_W[11:0] & wr_en)
            O_cnv_kernel_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == LAYER_STRIDE_H[11:0] & wr_en)
            O_cnv_stride_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == LAYER_STRIDE_W[11:0] & wr_en)
            O_cnv_stride_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_EN_RELUEN[11:0] & wr_en)
            O_next_relu_en <= I_lite_wdata[0];
        
        if (I_lite_awaddr[11:0] == NEXT_PARA_DILATION[11:0] & wr_en)
            O_next_dilation <= I_lite_wdata[15:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_PAD_H[11:0] & wr_en)
            O_next_cnv_pad_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_PAD_W[11:0] & wr_en)
            O_next_cnv_pad_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_KERNEL_H[11:0] & wr_en)
            O_next_cnv_kernel_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_KERNEL_W[11:0] & wr_en)
            O_next_cnv_kernel_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_STRIDE_H[11:0] & wr_en)
            O_next_cnv_stride_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == NEXT_LAYER_STRIDE_W[11:0] & wr_en)
            O_next_cnv_stride_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_PAD_H[11:0] & wr_en)
            O_pool_pad_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_PAD_W[11:0] & wr_en)
            O_pool_pad_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_KERNEL_H[11:0] & wr_en)
            O_pool_kernel_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_KERNEL_W[11:0] & wr_en)
            O_pool_kernel_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_STRIDE_H[11:0] & wr_en)
            O_pool_stride_h <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_STRIDE_W[11:0] & wr_en)
            O_pool_stride_w <= I_lite_wdata[4:0];
        
        if (I_lite_awaddr[11:0] == PARA_POOL_TYPE[11:0] & wr_en)
            O_pool_type <= I_lite_wdata[0];
    end
    
endmodule
