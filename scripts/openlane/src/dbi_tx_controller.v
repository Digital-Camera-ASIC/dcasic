module dbi_tx_controller 
#(
    parameter INTERNAL_CLK          = 125000000,
    // DBI Interface
    parameter DBI_IF_D_W            = 8,
    // AXI-Stream Configuration
    parameter TID_W                 = 2,
    parameter TDEST_W               = 2,
    parameter TDATA_W               = 256,
    parameter TKEEP_W               = TDATA_W/8,
    parameter TSTRB_W               = TDATA_W/8,
    parameter AXIS_FIFO_D           = 2,    // AXI-Stream FIFO depth (width: 256)
    // AXI4 Configuration 
    parameter ATX_ID_W              = 5,
    parameter ATX_ADDR_W            = 32,
    parameter ATX_DATA_W            = 32,
    parameter ATX_LEN_W             = 8,
    parameter ATX_SIZE_W            = 3,
    parameter ATX_RESP_W            = 2,
    // Mapping
    parameter ATX_BASE_ADDR         = 32'h1000_0000,    // AXI4 Address map
    parameter TDEST_MASK            = 2'b00,            // AXIS Destination map
    // Image format
    parameter IN_PXL_TYPE           = "GRAY",   // "GRAY": Gray pixel || "RGB": RGB565 pixel
    parameter OUT_PXL_TYPE          = "RGB",    // Always "RGB" - RGB565 pixel
    parameter FRM_COL_NUM           = 640,      // Maximum number of columns in 1 frame
    parameter FRM_ROW_NUM           = 480       // Maximum number of rows in 1 frame
) (
    input                           clk,
    input                           rst_n,
    // AXI-Stream interface
    input   [TID_W-1:0]             s_tid_i,    
    input   [TDEST_W-1:0]           s_tdest_i,
    input   [TDATA_W-1:0]           s_tdata_i,
    input   [TKEEP_W-1:0]           s_tkeep_i,
    input   [TSTRB_W-1:0]           s_tstrb_i,
    input                           s_tlast_i,
    input                           s_tvalid_i,
    output                          s_tready_o,
    // AXI4 Master configuration line
    // -- AW channel
    input   [ATX_ID_W-1:0]          s_awid_i,
    input   [ATX_ADDR_W-1:0]        s_awaddr_i,
    input   [1:0]                   s_awburst_i,        
    input   [ATX_LEN_W-1:0]         s_awlen_i,
    input                           s_awvalid_i,
    output                          s_awready_o,
    // -- W channel
    input   [ATX_DATA_W-1:0]        s_wdata_i,
    input                           s_wlast_i,
    input                           s_wvalid_i,
    output                          s_wready_o,
    // -- B channel
    output  [ATX_ID_W-1:0]          s_bid_o,
    output  [ATX_RESP_W-1:0]        s_bresp_o,
    output                          s_bvalid_o,
    input                           s_bready_i,
    // -- AR channel
    input   [ATX_ID_W-1:0]          s_arid_i,
    input   [ATX_ADDR_W-1:0]        s_araddr_i,
    input   [1:0]                   s_arburst_i,
    input   [ATX_LEN_W-1:0]         s_arlen_i,
    input                           s_arvalid_i,
    output                          s_arready_o,
    // -- R channel
    output  [ATX_ID_W-1:0]          s_rid_o,
    output  [ATX_DATA_W-1:0]        s_rdata_o,
    output  [ATX_RESP_W-1:0]        s_rresp_o,
    output                          s_rlast_o,
    output                          s_rvalid_o,
    input                           s_rready_i,
    // DBI TX interface
    output                          dbi_dcx_o,
    output                          dbi_csx_o,
    output                          dbi_resx_o,
    output                          dbi_rdx_o,
    output                          dbi_wrx_o,
    inout   [DBI_IF_D_W-1:0]        dbi_d_o 
);
    // Local parameters 
    localparam GRAY_PXL_W   = 8;
    localparam RGB_PXL_W    = 16;   // RGB565
    localparam IN_PXL_W     = (IN_PXL_TYPE == "GRAY") ? GRAY_PXL_W : RGB_PXL_W;
    localparam OUT_PXL_W    = RGB_PXL_W; // Always RGB565
    localparam FRM_DIM_MAX  = (FRM_COL_NUM > FRM_ROW_NUM) ? FRM_COL_NUM : FRM_ROW_NUM;
    localparam FRM_DIM_W    = $clog2(FRM_DIM_MAX);  // Each dimension width
    // Registers Map
    wire    [1:0]               dbi_ctrl_mode;
    wire    [DBI_IF_D_W-1:0]    dbi_mem_com;
    wire                        tx_type_rw;
    wire                        tx_type_hrst;
    wire    [2:0]               tx_type_dat_amt;
    wire                        tx_type_vld;
    wire                        tx_type_rdy;
    wire    [DBI_IF_D_W-1:0]    tx_com;
    wire                        tx_com_vld;
    wire                        tx_com_rdy;
    wire    [DBI_IF_D_W-1:0]    tx_data;
    wire                        tx_data_vld;
    wire                        tx_data_rdy;
    wire    [FRM_DIM_W-1:0]     frm_width;
    wire    [FRM_DIM_W-1:0]     frm_height;
    // Input Pixel data
    wire    [IN_PXL_W-1:0]      in_pxl_dat;
    wire                        in_pxl_vld;
    wire                        in_pxl_rdy;
    // Adapted Pixel
    wire    [OUT_PXL_W-1:0]     adp_pxl_dat;
    wire                        adp_pxl_vld;
    wire                        adp_pxl_rdy;
    // Adapted Pixel
    wire    [DBI_IF_D_W-1:0]    dbi_pxl_dat;
    wire                        dbi_pxl_vld;
    wire                        dbi_pxl_rdy;
    // State Machine to PHY Controller
    wire                        dtp_dbi_hrst;
    wire    [DBI_IF_D_W-1:0]    dtp_tx_cmd_typ;
    wire    [DBI_IF_D_W-1:0]    dtp_tx_cmd_dat;
    wire                        dtp_tx_no_dat;
    wire                        dtp_tx_last;
    wire                        dtp_tx_vld;
    wire                        dtp_tx_rdy;
    // Module instances
    // -- Registers Map
    dtc_reg_map #(
        .DBI_IF_D_W         (DBI_IF_D_W),
        .ATX_ID_W           (ATX_ID_W),
        .ATX_ADDR_W         (ATX_ADDR_W),
        .ATX_DATA_W         (ATX_DATA_W),
        .ATX_LEN_W          (ATX_LEN_W),
        .ATX_SIZE_W         (ATX_SIZE_W),
        .ATX_RESP_W         (ATX_RESP_W),
        .ATX_BASE_ADDR      (ATX_BASE_ADDR),
        .FRM_DIM_W          (FRM_DIM_W)
    ) rm (
        .aclk               (clk),
        .aresetn            (rst_n),
        .s_awid_i           (s_awid_i),
        .s_awaddr_i         (s_awaddr_i),
        .s_awburst_i        (s_awburst_i),
        .s_awlen_i          (s_awlen_i),
        .s_awvalid_i        (s_awvalid_i),
        .s_awready_o        (s_awready_o),
        .s_wdata_i          (s_wdata_i),
        .s_wlast_i          (s_wlast_i),
        .s_wvalid_i         (s_wvalid_i),
        .s_wready_o         (s_wready_o),
        .s_bid_o            (s_bid_o),
        .s_bresp_o          (s_bresp_o),
        .s_bvalid_o         (s_bvalid_o),
        .s_bready_i         (s_bready_i),
        .s_arid_i           (s_arid_i),
        .s_araddr_i         (s_araddr_i),
        .s_arburst_i        (s_arburst_i),
        .s_arlen_i          (s_arlen_i),
        .s_arvalid_i        (s_arvalid_i),
        .s_arready_o        (s_arready_o),
        .s_rid_o            (s_rid_o),
        .s_rdata_o          (s_rdata_o),
        .s_rresp_o          (s_rresp_o),
        .s_rlast_o          (s_rlast_o),
        .s_rvalid_o         (s_rvalid_o),
        .s_rready_i         (s_rready_i),
        .dbi_ctrl_mode      (dbi_ctrl_mode),
        .dbi_mem_com        (dbi_mem_com),
        .tx_type_rw         (tx_type_rw),
        .tx_type_hrst       (tx_type_hrst),
        .tx_type_dat_amt    (tx_type_dat_amt),
        .tx_type_vld        (tx_type_vld),
        .tx_type_rdy        (tx_type_rdy),
        .tx_com             (tx_com),
        .tx_com_vld         (tx_com_vld),
        .tx_com_rdy         (tx_com_rdy),
        .tx_data            (tx_data),
        .tx_data_vld        (tx_data_vld),
        .tx_data_rdy        (tx_data_rdy),
        .frm_width          (frm_width),
        .frm_height         (frm_height)
    );
    // -- AXI-Stream to Pixel
    dtc_axis_pxl #(
        .TID_W              (TID_W),
        .TDEST_W            (TDEST_W),
        .TDATA_W            (TDATA_W),
        .TKEEP_W            (TKEEP_W),
        .TSTRB_W            (TSTRB_W),
        .TDEST_MASK         (TDEST_MASK),
        .AXIS_FIFO_D        (AXIS_FIFO_D),
        .IN_PXL_TYPE        (IN_PXL_TYPE),
        .GRAY_PXL_W         (GRAY_PXL_W),
        .RGB_PXL_W          (RGB_PXL_W),
        .IN_PXL_W           (IN_PXL_W)
    ) ap (
        .clk                (clk),
        .rst_n              (rst_n),
        .s_tid_i            (s_tid_i),
        .s_tdest_i          (s_tdest_i),
        .s_tdata_i          (s_tdata_i),
        .s_tkeep_i          (s_tkeep_i),
        .s_tstrb_i          (s_tstrb_i),
        .s_tlast_i          (s_tlast_i),
        .s_tvalid_i         (s_tvalid_i),
        .s_tready_o         (s_tready_o),
        .pxl_dat_o          (in_pxl_dat),
        .pxl_vld_o          (in_pxl_vld),
        .pxl_rdy_i          (in_pxl_rdy)
    );
    // -- Pixel Adapter
    dtc_pxl_adapter #(
        .IN_PXL_TYPE        (IN_PXL_TYPE),
        .GRAY_PXL_W         (GRAY_PXL_W),
        .RGB_PXL_W          (RGB_PXL_W),
        .IN_PXL_W           (IN_PXL_W)
    ) pa (
        .clk                (clk),
        .rst_n              (rst_n),
        .in_pxl_dat         (in_pxl_dat),
        .in_pxl_vld         (in_pxl_vld),
        .in_pxl_rdy         (in_pxl_rdy),
        .out_pxl_dat        (adp_pxl_dat),
        .out_pxl_vld        (adp_pxl_vld),
        .out_pxl_rdy        (adp_pxl_rdy)
    );
    // -- DBI Data Aligner
    dtc_dbi_aligner #(
        .PROC_PXL_W         (OUT_PXL_W),
        .DBI_IF_D_W         (DBI_IF_D_W)
    ) da (
        .clk                (clk),
        .rst_n              (rst_n),
        .proc_pxl_dat       (adp_pxl_dat),
        .proc_pxl_vld       (adp_pxl_vld),
        .proc_pxl_rdy       (adp_pxl_rdy),
        .dbi_pxl_dat        (dbi_pxl_dat),
        .dbi_pxl_vld        (dbi_pxl_vld),
        .dbi_pxl_rdy        (dbi_pxl_rdy)
    );
    // -- State Machine 
    dtc_state_machine #(
        .INTERNAL_CLK       (INTERNAL_CLK),
        .DBI_IF_D_W         (DBI_IF_D_W),
        .FRM_DIM_W          (FRM_DIM_W)
    ) sm (
        .clk                (clk),
        .rst_n              (rst_n),
        .dbi_ctrl_mode_i    (dbi_ctrl_mode),
        .dbi_mem_com_i      (dbi_mem_com),
        .tx_type_rw_i       (tx_type_rw),
        .tx_type_hrst_i     (tx_type_hrst),
        .tx_type_dat_amt_i  (tx_type_dat_amt),
        .tx_type_vld_i      (tx_type_vld),
        .tx_com_i           (tx_com),
        .tx_com_vld_i       (tx_com_vld),
        .tx_data_i          (tx_data),
        .tx_data_vld_i      (tx_data_vld),
        .pxl_d_i            (dbi_pxl_dat),
        .pxl_vld_i          (dbi_pxl_vld),
        .dtp_tx_rdy_i       (dtp_tx_rdy),
        .tx_type_rdy_o      (tx_type_rdy),
        .tx_com_rdy_o       (tx_com_rdy),
        .tx_data_rdy_o      (tx_data_rdy),
        .pxl_rdy_o          (dbi_pxl_rdy),
        .dtp_dbi_hrst_o     (dtp_dbi_hrst),
        .dtp_tx_cmd_typ_o   (dtp_tx_cmd_typ),
        .dtp_tx_cmd_dat_o   (dtp_tx_cmd_dat),
        .dtp_tx_last_o      (dtp_tx_last),
        .dtp_tx_no_dat_o    (dtp_tx_no_dat),
        .dtp_tx_vld_o       (dtp_tx_vld),
        .frm_width          (frm_width),
        .frm_height         (frm_height)
    );
    // -- PHY Controller
    dtc_phy_ctrl #(
        .INTERNAL_CLK       (INTERNAL_CLK),
        .DBI_IF_D_W         (DBI_IF_D_W)
    ) pc (
        .clk                (clk),
        .rst_n              (rst_n),
        .dtf_dbi_hrst_i     (dtp_dbi_hrst),
        .dtf_tx_cmd_typ_i   (dtp_tx_cmd_typ),
        .dtf_tx_cmd_dat_i   (dtp_tx_cmd_dat),
        .dtf_tx_no_dat_i    (dtp_tx_no_dat),
        .dtf_tx_last_i      (dtp_tx_last),
        .dtf_tx_vld_i       (dtp_tx_vld),
        .dtf_tx_rdy_o       (dtp_tx_rdy),
        .dbi_d_o            (dbi_d_o),
        .dbi_csx_o          (dbi_csx_o),
        .dbi_dcx_o          (dbi_dcx_o),
        .dbi_resx_o         (dbi_resx_o),
        .dbi_rdx_o          (dbi_rdx_o),
        .dbi_wrx_o          (dbi_wrx_o)
    );


endmodule