module sccb_master_controller #(
    // Memory Mapping
    parameter ATX_BASE_ADDR         = 32'h2000_0000,    // Base address of the IP in AXI Bus
    // FIFO
    parameter SCCB_TX_FIFO_DEPTH    = 4,                // SCCB TX FIFO depth (element's width = 8bit)
    parameter SCCB_RX_FIFO_DEPTH    = 4,                // SCCB RX FIFO depth (element's width = 8bit)
    // AXI4 Bus Configuration
    parameter ATX_DATA_W            = 8,
    parameter ATX_ADDR_W            = 32,
    parameter ATX_ID_W              = 5,
    parameter ATX_LEN_W             = 8,
    parameter ATX_SIZE_W            = 3,
    parameter ATX_RESP_W            = 2,
    // Timing configuration 
    parameter INTERNAL_CLK_FREQ     = 125_000_000,
    parameter MAX_SCCB_FREQ         = 100_000
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
    // -- SCCB Master Interface
    output                          sio_c,
    inout                           sio_d
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
    wire [ATX_DATA_W-2:0]       slv_dvc_addr;
    wire [ATX_DATA_W-1:0]       prescaler;
    wire [1:0]                  phase_amt;
    wire                        trans_type;
    wire                        ctrl_vld;
    wire                        ctrl_rdy;
    wire [ATX_DATA_W-1:0]       tx_data;
    wire                        tx_data_vld;
    wire                        tx_data_rdy;
    wire [ATX_DATA_W-1:0]       tx_sub_adr;
    wire                        tx_sub_adr_vld;
    wire                        tx_sub_adr_rdy;
    wire [ATX_DATA_W-1:0]       rx_data;
    wire                        rx_vld;
    wire                        rx_rdy;
    wire                        cntr_en;
    wire                        tick_en;
    wire                        sio_c_tgl_en;

    // Module instances
    smc_reg_map #(
        .ATX_BASE_ADDR      (ATX_BASE_ADDR),
        .ATX_DATA_W         (ATX_DATA_W),
        .ATX_ADDR_W         (ATX_ADDR_W),
        .ATX_ID_W           (ATX_ID_W),
        .ATX_LEN_W          (ATX_LEN_W),
        .ATX_SIZE_W         (ATX_SIZE_W),
        .ATX_RESP_W         (ATX_RESP_W),
        .SCCB_TX_FIFO_DEPTH (SCCB_TX_FIFO_DEPTH),
        .SCCB_RX_FIFO_DEPTH (SCCB_RX_FIFO_DEPTH)
    ) rm (
        .clk                (clk),
        .rst_n              (rst_n),
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
        .slv_dvc_addr       (slv_dvc_addr),
        .prescaler          (prescaler),
        .phase_amt          (phase_amt),
        .trans_type         (trans_type),
        .ctrl_vld           (ctrl_vld),
        .ctrl_rdy           (ctrl_rdy),
        .tx_data            (tx_data),
        .tx_data_vld        (tx_data_vld),
        .tx_data_rdy        (tx_data_rdy),
        .tx_sub_adr         (tx_sub_adr),
        .tx_sub_adr_vld     (tx_sub_adr_vld),
        .tx_sub_adr_rdy     (tx_sub_adr_rdy),
        .rx_data            (rx_data),
        .rx_vld             (rx_vld),
        .rx_rdy             (rx_rdy)
    );

    smc_timing_gen #(
        .INTERNAL_CLK_FREQ  (INTERNAL_CLK_FREQ),
        .MAX_SCCB_FREQ      (MAX_SCCB_FREQ)
    ) sccb_timing_gen (
        .clk                (clk),
        .rst_n              (rst_n),
        .cntr_en_i          (cntr_en),
        .prescaler_i        (prescaler),
        .tick_en_o          (tick_en),
        .sio_c_tgl_en_o     (sio_c_tgl_en)
    );

    smc_state_machine #(
        .DATA_W             (ATX_DATA_W)
    ) sccb_fsm (
        .clk                (clk),
        .rst_n              (rst_n),
        .slv_dvc_addr_i     (slv_dvc_addr),
        .trans_type_i       (trans_type),
        .phase_amt_i        (phase_amt),
        .ctrl_vld_i         (ctrl_vld),
        .tx_data_i          (tx_data),
        .tx_data_vld_i      (tx_data_vld),
        .tx_sub_adr_i       (tx_sub_adr),
        .tx_sub_adr_vld_i   (tx_sub_adr_vld),
        .rx_rdy_i           (rx_rdy),
        .tick_en_i          (tick_en),
        .sio_c_tgl_en_i     (sio_c_tgl_en),
        .ctrl_rdy_o         (ctrl_rdy),
        .tx_data_rdy_o      (tx_data_rdy),
        .tx_sub_adr_rdy_o   (tx_sub_adr_rdy),
        .rx_data_o          (rx_data),
        .rx_vld_o           (rx_vld),
        .cntr_en_o          (cntr_en),
        .sio_c              (sio_c),
        .sio_d              (sio_d)
    );
endmodule