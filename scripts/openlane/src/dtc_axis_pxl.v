module dtc_axis_pxl #(
    // AXI-Stream Configuration
    parameter TID_W                 = 2,
    parameter TDEST_W               = 2,
    parameter TDATA_W               = 256,
    parameter TKEEP_W               = TDATA_W/8,
    parameter TSTRB_W               = TDATA_W/8,
    parameter TDEST_MASK            = 2'b00,
    parameter AXIS_FIFO_D           = 4,        // AXI-Stream FIFO depth (width: 256)
    // Image format
    parameter IN_PXL_TYPE           = "GRAY",   // "GRAY": Gray pixel || "RGB": RGB565 pixel
    parameter GRAY_PXL_W            = 8,
    parameter RGB_PXL_W             = 16,       // RGB565
    parameter IN_PXL_W              = (IN_PXL_TYPE == "GRAY") ? GRAY_PXL_W : RGB_PXL_W
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
    // Pixel
    output  [IN_PXL_W-1:0]          pxl_dat_o,
    output                          pxl_vld_o,
    input                           pxl_rdy_i
);
    // Local parameters
    localparam AXIS_INFO_W  = TDATA_W;
    // Internal signal
    wire                    axis_map_vld;
    wire                    s_tvalid_flt;
    wire                    s_tready_ff;
    wire    [TDATA_W-1:0]   s_tdata;
    wire                    s_tvalid;
    wire                    s_tready;

    // Module instantiation
    // -- AXI-Stream FIFO 
    sync_fifo #(
        .FIFO_TYPE      (1),            // Normal FIFO  
        .DATA_WIDTH     (AXIS_INFO_W),  // TDATA
        .FIFO_DEPTH     (AXIS_FIFO_D)
    ) af (
        .clk            (clk),
        .data_i         ({s_tdata_i}),
        .wr_valid_i     (s_tvalid_flt),
        .wr_ready_o     (s_tready_ff),
        .data_o         ({s_tdata}),
        .rd_ready_o     (s_tvalid),
        .rd_valid_i     (s_tready),
        .empty_o        (),
        .full_o         (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        (),
        .rst_n          (rst_n)
    );
    // -- Pixel aligner
    sync_fifo #(
        .FIFO_TYPE      (4),     // Deconcater 
        .DATA_WIDTH     (),      // Don't care
        .IN_DATA_WIDTH  (TDATA_W),
        .OUT_DATA_WIDTH (IN_PXL_W),
        .FIFO_DEPTH     ()       // Don't care
    ) pa (   
        .clk            (clk),
        .data_i         (s_tdata),
        .wr_valid_i     (s_tvalid),
        .wr_ready_o     (s_tready),
        .data_o         (pxl_dat_o),
        .rd_ready_o     (pxl_vld_o),
        .rd_valid_i     (pxl_rdy_i),
        .empty_o        (),
        .full_o         (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        (),
        .rst_n          (rst_n)
    );
    // Combinational logic
    assign axis_map_vld = ~|(s_tdest_i ^ TDEST_MASK);   // s_tdest_i == TDEST_MASK
    assign s_tvalid_flt = s_tvalid_i & axis_map_vld;
    assign s_tready_o   = s_tready_ff & axis_map_vld; // Only assert when (AXIS FIFO is ready) & (TVALID is mapping)
endmodule