module dtc_reg_map #(
    // DBI Interface
    parameter DBI_IF_D_W            = 8,
    // AXI4 Configuration 
    parameter ATX_ID_W              = 5,
    parameter ATX_ADDR_W            = 32,
    parameter ATX_DATA_W            = 32,
    parameter ATX_LEN_W             = 8,
    parameter ATX_SIZE_W            = 3,
    parameter ATX_RESP_W            = 2,
    // Mapping
    parameter ATX_BASE_ADDR         = 32'h1000_0000,
    // Image
    parameter FRM_DIM_W             = 16
) (
    input                           aclk,
    input                           aresetn,
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
    // DTC CSRs
    output  [1:0]                   dbi_ctrl_mode,
    output  [DBI_IF_D_W-1:0]        dbi_mem_com,
    output                          tx_type_rw,
    output                          tx_type_hrst,
    output  [2:0]                   tx_type_dat_amt,
    output                          tx_type_vld,
    input                           tx_type_rdy,
    output  [DBI_IF_D_W-1:0]        tx_com,
    output                          tx_com_vld,
    input                           tx_com_rdy,
    output  [DBI_IF_D_W-1:0]        tx_data,
    output                          tx_data_vld,
    input                           tx_data_rdy,
    output  [FRM_DIM_W-1:0]         frm_width,
    output  [FRM_DIM_W-1:0]         frm_height
);
    // Local parameters
    localparam RW_REG_ADDR      = ATX_BASE_ADDR + 32'h0000_0000;
    localparam RW1S_REG_ADDR    = ATX_BASE_ADDR + 32'h0000_0010;
    localparam RW_REG_NUM       = 1 + 1 + 1 + 1;    // DBI_CTRL_ST + DBI_MEM_COM + FRAME_WIDTH + FRAME_HEIGHT
    localparam RW1S_REG_NUM     = 1 + 1 + 1;// TX_TYPE + TX_COM + TX_DATA
    // Internal varibles
    genvar rw_reg_idx;
    genvar rw1s_reg_idx;
    // Internal signal
    wire    [ATX_DATA_W-1:0]    rw_reg      [0:RW_REG_NUM-1];
    wire    [ATX_DATA_W-1:0]    rw1s_dat    [0:RW1S_REG_NUM-1];
    wire    [RW1S_REG_NUM-1:0]  rw1s_vld;
    wire    [RW1S_REG_NUM-1:0]  rw1s_rdy;

    wire    [ATX_DATA_W*RW_REG_NUM-1:0]   rw_reg_flat;
    wire    [ATX_DATA_W*RW1S_REG_NUM-1:0] rw1s_dat_flat;

    // Module instances
    axi4_ctrl #(
        .AXI4_CTRL_CONF     (1),    // CONF_REG:    On
        .AXI4_CTRL_STAT     (0),    // STATUS_REG:  Off
        .AXI4_CTRL_MEM      (0),    // MEM:         Off
        .AXI4_CTRL_WR_ST    (1),    // TX_FIFO:     On
        .AXI4_CTRL_RD_ST    (0),    // RX_FIFO:     Off
        .CONF_BASE_ADDR     (RW_REG_ADDR),
        .CONF_OFFSET        (1),
        .CONF_DATA_W        (ATX_DATA_W),
        .CONF_REG_NUM       (RW_REG_NUM),
        .ST_WR_BASE_ADDR    (RW1S_REG_ADDR),
        .ST_WR_OFFSET       (1),
        .ST_WR_FIFO_NUM     (RW1S_REG_NUM),
        .ST_WR_FIFO_DEPTH   (16),
        .ST_RD_BASE_ADDR    (),
        .ST_RD_OFFSET       (),
        .ST_RD_FIFO_NUM     (),
        .ST_RD_FIFO_DEPTH   (),
        .DATA_W             (ATX_DATA_W),
        .ADDR_W             (ATX_ADDR_W),
        .MST_ID_W           (ATX_ID_W),
        .TRANS_DATA_LEN_W   (ATX_LEN_W),
        .TRANS_DATA_SIZE_W  (ATX_SIZE_W),
        .TRANS_RESP_W       (ATX_RESP_W)
    ) ac (
        .clk                (aclk),
        .rst_n              (aresetn),
        .m_awid_i           (s_awid_i),
        .m_awaddr_i         (s_awaddr_i),
        .m_awburst_i        (s_awburst_i),
        .m_awlen_i          (s_awlen_i),
        .m_awvalid_i        (s_awvalid_i),
        .m_wdata_i          (s_wdata_i),
        .m_wlast_i          (s_wlast_i),
        .m_wvalid_i         (s_wvalid_i),
        .m_bready_i         (s_bready_i),
        .m_arid_i           (s_arid_i),
        .m_araddr_i         (s_araddr_i),
        .m_arburst_i        (s_arburst_i),
        .m_arlen_i          (s_arlen_i),
        .m_arvalid_i        (s_arvalid_i),
        .m_rready_i         (s_rready_i),
        .stat_reg_i         (),
        .mem_wr_rdy_i       (),
        .mem_rd_data_i      (),
        .mem_rd_rdy_i       (),
        .wr_st_rd_vld_i     (rw1s_rdy),
        .rd_st_wr_data_i    (),
        .rd_st_wr_vld_i     (),
        .m_awready_o        (s_awready_o),
        .m_wready_o         (s_wready_o),
        .m_bid_o            (s_bid_o),
        .m_bresp_o          (s_bresp_o),
        .m_bvalid_o         (s_bvalid_o),
        .m_arready_o        (s_arready_o),
        .m_rid_o            (s_rid_o),
        .m_rdata_o          (s_rdata_o),
        .m_rresp_o          (s_rresp_o),
        .m_rlast_o          (s_rlast_o),
        .m_rvalid_o         (s_rvalid_o),
        .conf_reg_o         (rw_reg_flat),
        .mem_wr_data_o      (),
        .mem_wr_addr_o      (), 
        .mem_wr_vld_o       (),
        .mem_rd_addr_o      (),
        .mem_rd_vld_o       (),
        .wr_st_rd_data_o    (rw1s_dat_flat),
        .wr_st_rd_rdy_o     (rw1s_vld),
        .rd_st_wr_rdy_o     ()
    );
    
    
    // Memory mapping
    // -- BASE: 0x3000_0000 - OFFSET: 0x00 & 0x01
    assign dbi_ctrl_mode        = rw_reg    [8'd00][1:0];
    assign dbi_mem_com          = rw_reg    [8'd01][DBI_IF_D_W-1:0];
    assign frm_width            = rw_reg    [8'd02][FRM_DIM_W-1:0];
    assign frm_height           = rw_reg    [8'd03][FRM_DIM_W-1:0];
    // -- BASE: 0x3000_0010 - OFFSET: 0x00
    assign tx_type_rw           = rw1s_dat  [8'd00][0];
    assign tx_type_hrst         = rw1s_dat  [8'd00][1];
    assign tx_type_dat_amt      = rw1s_dat  [8'd00][4:2];
    assign tx_type_vld          = rw1s_vld  [8'd00];
    assign rw1s_rdy[8'd00]      = tx_type_rdy;
    // -- BASE: 0x3000_0010 - OFFSET: 0x01
    assign tx_com               = rw1s_dat  [8'd01][DBI_IF_D_W-1:0];
    assign tx_com_vld           = rw1s_vld  [8'd01];
    assign rw1s_rdy[8'd01]      = tx_com_rdy;
    // -- BASE: 0x3000_0010 - OFFSET: 0x02
    assign tx_data              = rw1s_dat  [8'd02][DBI_IF_D_W-1:0];
    assign tx_data_vld          = rw1s_vld  [8'd02];
    assign rw1s_rdy[8'd02]      = tx_data_rdy;
    // De-flatten
generate
    for(rw_reg_idx = 0; rw_reg_idx < RW_REG_NUM; rw_reg_idx = rw_reg_idx + 1) begin : DEFLAT_0
        assign rw_reg[rw_reg_idx] = rw_reg_flat[(rw_reg_idx+1)*ATX_DATA_W-1-:ATX_DATA_W];
    end
    for(rw1s_reg_idx = 0; rw1s_reg_idx < RW1S_REG_NUM; rw1s_reg_idx = rw1s_reg_idx + 1) begin : DEFLAT_1
        assign rw1s_dat[rw1s_reg_idx] = rw1s_dat_flat[(rw1s_reg_idx+1)*ATX_DATA_W-1-:ATX_DATA_W];
    end
endgenerate
endmodule