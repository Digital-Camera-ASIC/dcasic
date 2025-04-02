module image_processor #(
    // Image Processor
    parameter IP_AMT            = 1,    // Image processor amount  
    parameter IP_ADDR_W         = $clog2(IP_AMT),
    parameter IP_DATA_W         = 256,
    // AXI-Stream configuration
    parameter AXIS_TDEST_MSK    = 1'b1,
    parameter AXIS_TID_W        = 2,
    parameter AXIS_TDEST_W      = (IP_ADDR_W > 1) ? IP_ADDR_W : 1,
    parameter AXIS_TDATA_W      = IP_DATA_W,
    parameter AXIS_TKEEP_W      = AXIS_TDATA_W/8,
    parameter AXIS_TSTRB_W      = AXIS_TDATA_W/8,
    // Image processor configuaration
    parameter   PG_WIDTH            = 256,
    parameter   CELL_WIDTH          = 768,
    parameter   CELL_NUM            = 1200,
    parameter   FRAME_ROW_CNUM      = 30,               // 30 cells
    parameter   FRAME_COL_CNUM      = 40,               // 40 cells
    parameter   CELL_ROW_PNUM       = 8,                // 8 pixels
    parameter   CELL_COL_PNUM       = 8,                // 8 pixels

    // hog_svm parameter
    parameter   PIX_W               = 8, // pixel width
    parameter   MAG_F               = 4,// fraction part of magnitude
    parameter   TAN_I               = 4, // tan width
    parameter   TAN_F               = 16, // tan width
    parameter   BIN_I               = 16, // integer part of bin
    parameter   FEA_I               = 4, // integer part of hog feature
    parameter   FEA_F               = 16, // fractional part of hog feature
    parameter   SW_W                = 11, // slide window width
    parameter   CELL_S              = 10 // Size of cell, default 8x8 pixel and border
)(
    input                           s_aclk,
    input                           s_aresetn,
    // -- AXI-Stream interface
    input   [AXIS_TID_W-1:0]        s_tid_i,    
    input   [AXIS_TDEST_W-1:0]      s_tdest_i, 
    input   [AXIS_TDATA_W-1:0]      s_tdata_i,
    input   [AXIS_TKEEP_W-1:0]      s_tkeep_i,
    input   [AXIS_TSTRB_W-1:0]      s_tstrb_i,
    input                           s_tlast_i,
    input                           s_tvalid_i,
    output                          s_tready_o,
    // -- HOG_SVM
    output                          o_valid,
    output                          is_person,
    output  [SW_W - 1   : 0]        sw_id,
    output                          led
);
    
    wire [CELL_WIDTH - 1 : 0] cell_data;
    wire cell_valid;
    wire cell_ready; 
    axi_frame_fetch #(
        // Features configuration
        .IP_AMT             (IP_AMT),
        .IP_ADDR_W          (IP_ADDR_W),
        .IP_DATA_W          (IP_DATA_W),
        .AXIS_TDEST_MSK     (AXIS_TDEST_MSK),
        .AXIS_TID_W         (AXIS_TID_W),
        .AXIS_TDEST_W       (AXIS_TDEST_W),
        .AXIS_TDATA_W       (AXIS_TDATA_W),
        .AXIS_TKEEP_W       (AXIS_TKEEP_W),
        .AXIS_TSTRB_W       (AXIS_TSTRB_W),
        // Image processor configuaration
        .PG_WIDTH           (PG_WIDTH),
        .CELL_WIDTH         (CELL_WIDTH),
        .CELL_NUM           (CELL_NUM),
        .FRAME_ROW_CNUM     (FRAME_ROW_CNUM),
        // 30 cells
        .FRAME_COL_CNUM     (FRAME_COL_CNUM),
        // 40 cells
        .CELL_ROW_PNUM      (CELL_ROW_PNUM),
        // 8 pixels
        .CELL_COL_PNUM      (CELL_COL_PNUM),
        // 8 pixels
        .FRAME_COL_BNUM     (FRAME_COL_CNUM/2),
        // 20 blocks
        .FRAME_COL_PGNUM    (FRAME_COL_CNUM/4)
        // 10 pixel groups
    ) aff (
        // Input declaration
        // -- Global signals
        .s_aclk             (s_aclk),
        .s_aresetn          (s_aresetn),
        // AXI-Stream
        .s_tid_i            (s_tid_i),
        .s_tdest_i          (s_tdest_i),
        .s_tdata_i          (s_tdata_i),
        .s_tkeep_i          (s_tkeep_i),
        .s_tstrb_i          (s_tstrb_i),
        .s_tlast_i          (s_tlast_i),
        .s_tvalid_i         (s_tvalid_i),
        .s_tready_o         (s_tready_o),
        // -- To HOG
        .cell_data_o        (cell_data),
        .cell_valid_o       (cell_valid),
        .cell_ready_i       (cell_ready)
    );
    hog_svm #(
        .PIX_W           (PIX_W),
        // pixel width
        .MAG_F           (MAG_F),
        // fraction part of magnitude
        .TAN_I           (TAN_I),
        // tan width
        .TAN_F           (TAN_F),
        // tan width
        .BIN_I           (BIN_I),
        // integer part of bin
        .FEA_I           (FEA_I),
        // integer part of hog feature
        .FEA_F           (FEA_F),
        // fractional part of hog feature
        .SW_W            (SW_W),
        // slide window width
        .CELL_S          (CELL_S)
    ) hs (
        //// hog if
        .clk             (s_aclk),
        .rst             (s_aresetn),
        .ready           (cell_valid),
        .request         (cell_ready),
        .i_data_fetch    (cell_data),
        //// svm if
        // ram interface
        .addr_a          (6'h00),
        .write_en        (1'b0),
        .i_data_a        (2100'd0),
        .o_data_a        (),
        // bias
        .bias            (20'h0),
        .b_load          (1'b0),
        // svm if
        .o_valid         (o_valid),
        .is_person       (is_person),
        .sw_id           (sw_id),
        // led
        .led             (led)
    );
endmodule