module smc_reg_map#(
    // Memory Mapping
    parameter ATX_BASE_ADDR         = 32'h2000_0000,    // Base address of the IP in AXI Bus
    // Capac
    parameter SCCB_TX_FIFO_DEPTH    = 4,                // SCCB TX FIFO depth (element's width = 8bit)
    parameter SCCB_RX_FIFO_DEPTH    = 4,                // SCCB RX FIFO depth (element's width = 8bit)
    // AXI4 Bus Configuration
    parameter ATX_DATA_W            = 8,
    parameter ATX_ADDR_W            = 32,
    parameter ATX_ID_W              = 5,
    parameter ATX_LEN_W             = 8,
    parameter ATX_SIZE_W            = 3,
    parameter ATX_RESP_W            = 2
) (
    // -- Global 
    input                           clk,
    input                           rst_n,
    // -- AXI4 Interface            
    // -- -- AW channel         
    input   [ATX_ID_W-1:0]          s_awid_i,
    input   [ATX_ADDR_W-1:0]        s_awaddr_i,
    input   [1:0]                   s_awburst_i,
    input   [ATX_LEN_W-1:0]         s_awlen_i,
    input                           s_awvalid_i,
    output                          s_awready_o,
    // -- -- W channel          
    input   [ATX_DATA_W-1:0]        s_wdata_i,
    input                           s_wlast_i,
    input                           s_wvalid_i,
    output                          s_wready_o,
    // -- -- B channel          
    output  [ATX_ID_W-1:0]          s_bid_o,
    output  [ATX_RESP_W-1:0]        s_bresp_o,
    output                          s_bvalid_o,
    input                           s_bready_i,
    // -- -- AR channel         
    input   [ATX_ID_W-1:0]          s_arid_i,
    input   [ATX_ADDR_W-1:0]        s_araddr_i,
    input   [1:0]                   s_arburst_i,
    input   [ATX_LEN_W-1:0]         s_arlen_i,
    input                           s_arvalid_i,
    output                          s_arready_o,
    // -- -- R channel          
    output  [ATX_ID_W-1:0]          s_rid_o,
    output  [ATX_DATA_W-1:0]        s_rdata_o,
    output  [ATX_RESP_W-1:0]        s_rresp_o,
    output                          s_rlast_o,
    output                          s_rvalid_o,
    input                           s_rready_i,
    // CSRs
    output  [ATX_DATA_W-2:0]        slv_dvc_addr,
    output  [ATX_DATA_W-1:0]        prescaler,
    output  [1:0]                   phase_amt,
    output                          trans_type,
    output                          ctrl_vld,
    input                           ctrl_rdy,
    output  [ATX_DATA_W-1:0]        tx_data,
    output                          tx_data_vld,
    input                           tx_data_rdy,
    output  [ATX_DATA_W-1:0]        tx_sub_adr,
    output                          tx_sub_adr_vld,
    input                           tx_sub_adr_rdy,
    input   [ATX_DATA_W-1:0]        rx_data,
    input                           rx_vld,
    output                          rx_rdy

);
    // Local parameters declaration
    localparam CONF_BASE_ADDR   = ATX_BASE_ADDR + 32'h0000_0000;
    localparam TX_BASE_ADDR     = ATX_BASE_ADDR + 32'h0000_0010;
    localparam RX_BASE_ADDR     = ATX_BASE_ADDR + 32'h0000_0020;
    localparam CONFIG_REG_NUM   = 2; // SLV_DVC_ADDR + PRESCALER 
    localparam SCCB_TX_FIFO_NUM = 3; // CONTROL_SIGNAL + SUB_ADDR + TX_DATA
    localparam SCCB_RX_FIFO_NUM = 1; // RX_DATA

    // Internal variable
    genvar tx_fifo_idx;
    genvar conf_reg_idx;
    // Internal signal
    // -- wire
    wire [ATX_DATA_W-1:0]       conf_reg        [0:CONFIG_REG_NUM-1];
    wire [ATX_DATA_W-1:0]       tx_fifo_dat     [0:SCCB_TX_FIFO_NUM-1];
    wire [SCCB_TX_FIFO_NUM-1:0] tx_fifo_vld;
    wire [SCCB_TX_FIFO_NUM-1:0] tx_fifo_rdy;
    wire [ATX_DATA_W*CONFIG_REG_NUM-1:0]    conf_reg_flat;
    wire [ATX_DATA_W*SCCB_TX_FIFO_NUM-1:0]  tx_fifo_flat;

    // MEMORY MAPPING
    // -- BASE: 0x2000_0000 - OFFSET: 0-1
    assign slv_dvc_addr         = conf_reg   [8'd00];
    assign prescaler            = conf_reg   [8'd01];
    // -- BASE: 0x2100_0000 - OFFSET: 0
    assign phase_amt            = tx_fifo_dat[8'd00][1:0];
    assign trans_type           = tx_fifo_dat[8'd00][2];
    assign ctrl_vld             = tx_fifo_vld[8'd00];
    assign tx_fifo_rdy[8'd00]   = ctrl_rdy;
    // -- BASE: 0x2100_0000 - OFFSET: 1
    assign tx_sub_adr           = tx_fifo_dat[8'd01];
    assign tx_sub_adr_vld       = tx_fifo_vld[8'd01];
    assign tx_fifo_rdy[8'd01]   = tx_sub_adr_rdy;
    // -- BASE: 0x2100_0000 - OFFSET: 2
    assign tx_data              = tx_fifo_dat[8'd02];
    assign tx_data_vld          = tx_fifo_vld[8'd02];
    assign tx_fifo_rdy[8'd02]   = tx_data_rdy;

    // De-flattern
generate
    for(tx_fifo_idx = 0; tx_fifo_idx < SCCB_TX_FIFO_NUM; tx_fifo_idx = tx_fifo_idx + 1) begin : TX_LOGIC_GEN
        assign tx_fifo_dat[tx_fifo_idx] = tx_fifo_flat[(tx_fifo_idx+1)*ATX_DATA_W-1-:ATX_DATA_W];
    end
    for(conf_reg_idx = 0; conf_reg_idx < CONFIG_REG_NUM; conf_reg_idx = conf_reg_idx + 1) begin : CONF_LOGIC_GEN
        assign conf_reg[conf_reg_idx] = conf_reg_flat[(conf_reg_idx+1)*ATX_DATA_W-1-:ATX_DATA_W];
    end
endgenerate

    // Module instances
    axi4_ctrl #(
        .AXI4_CTRL_CONF     (1),    // CONF_REG: On
        .AXI4_CTRL_STAT     (0),    // STAT_REG: Off
        .AXI4_CTRL_MEM      (0),    // MEM:     Off
        .AXI4_CTRL_WR_ST    (1),    // TX_FIFO: On
        .AXI4_CTRL_RD_ST    (1),    // RX_FIFO: On
        .CONF_BASE_ADDR     (CONF_BASE_ADDR),
        .CONF_OFFSET        (32'h01),
        .CONF_REG_NUM       (CONFIG_REG_NUM),
        .ST_WR_BASE_ADDR    (TX_BASE_ADDR),
        .ST_WR_OFFSET       (32'h01),
        .ST_WR_FIFO_NUM     (SCCB_TX_FIFO_NUM),
        .ST_WR_FIFO_DEPTH   (SCCB_TX_FIFO_DEPTH),
        .ST_RD_BASE_ADDR    (RX_BASE_ADDR),
        .ST_RD_OFFSET       (32'h01),
        .ST_RD_FIFO_NUM     (SCCB_RX_FIFO_NUM),
        .ST_RD_FIFO_DEPTH   (SCCB_RX_FIFO_DEPTH),
        .DATA_W             (ATX_DATA_W),
        .ADDR_W             (ATX_ADDR_W),
        .MST_ID_W           (ATX_ID_W),
        .TRANS_DATA_LEN_W   (ATX_LEN_W),
        .TRANS_DATA_SIZE_W  (ATX_SIZE_W),
        .TRANS_RESP_W       (ATX_RESP_W)
    ) axi4_ctrl (
        .clk                (clk),
        .rst_n              (rst_n),
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
        .wr_st_rd_vld_i     (tx_fifo_rdy),
        .rd_st_wr_data_i    (rx_data),
        .rd_st_wr_vld_i     (rx_vld),
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
        .conf_reg_o         (conf_reg_flat),
        .mem_wr_data_o      (),
        .mem_wr_addr_o      (), 
        .mem_wr_vld_o       (),
        .mem_rd_addr_o      (),
        .mem_rd_vld_o       (),
        .wr_st_rd_data_o    (tx_fifo_flat),
        .wr_st_rd_rdy_o     (tx_fifo_vld),
        .rd_st_wr_rdy_o     (rx_rdy)
    );
    
endmodule