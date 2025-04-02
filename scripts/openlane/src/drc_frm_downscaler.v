module drc_frm_downscaler #(
    // Downscaler method configuration 
    parameter DOWNSCALE_TYPE    = "AVR-POOLING",    // Downscale Type: "AVR-POOLING" || "MAX-POOLING"
    // Pixel configuration
    parameter I_PXL_W           = 8,
    parameter COL_NUM           = 640,
    parameter ROW_NUM           = 480
)
(
    // Input declaration
    // -- Global
    input                   clk,
    input                   rst_n,
    // -- Backward pxiel
    input   [I_PXL_W-1:0]   bwd_pxl_data_i,
    input                   bwd_pxl_last_i, // Last pixel of the frame -> Always fourth pixel in a downscaler block
    input                   bwd_pxl_vld_i,
    output                  bwd_pxl_rdy_o,
    // -- Forward pixel
    output  [I_PXL_W-1:0]   fwd_pxl_data_o,
    output                  fwd_pxl_last_o, // Last pixel of the frame -> Always fourth pixel in a downscaler block
    output                  fwd_pxl_vld_o,
    input                   fwd_pxl_rdy_i
);
    // Local parameter 
    localparam COL_CTN_W = $clog2(COL_NUM);
    localparam ROW_CTN_W = $clog2(ROW_NUM);
    
    // Internal signal
    // -- wire
    wire                    bwd_pxl_hsk;    // DSM handshake
    wire                    col_last;
    wire    [COL_CTN_W-1:0] col_ctn_d;
    wire                    row_odd_d;
    wire    [I_PXL_W-1:0]   pf_data_o_map   [0:3];
    wire                    pf_wr_rdy_map   [0:3];
    wire                    pf_wr_vld_map   [0:3];
    wire                    pf_rd_rdy_map   [0:3];
    wire                    pf_rd_vld_map   [0:3];
    wire    [I_PXL_W+1:0]   sum_block_pxl;  // Sum of 4 neighboring pixels
    wire                    fwd_pxl_hsk;
    // -- reg
    reg     [COL_CTN_W-1:0] col_ctn_q;
    reg                     row_odd_q;
    
    // Internal module
    // -- Pixel FIFO for FIRST PIXEL in scaling block
    sync_fifo #(
        .FIFO_TYPE      (1),        // Non-registered output -> If VIOLATED timing path -> Set it to "2"
        .DATA_WIDTH     (I_PXL_W),
        .FIFO_DEPTH     (1<<$clog2(COL_NUM/2))
    ) frist_pixel_fifo (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_i         (bwd_pxl_data_i),
        .data_o         (pf_data_o_map[0]),
        .wr_valid_i     (pf_wr_vld_map[0]),
        .rd_valid_i     (fwd_pxl_hsk),
        .empty_o        (),
        .full_o         (),
        .wr_ready_o     (pf_wr_rdy_map[0]),
        .rd_ready_o     (pf_rd_rdy_map[0]),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        ()
    );
    // -- Pixel FIFO for SECOND PIXEL in scaling block
    sync_fifo #(
        .FIFO_TYPE      (1),        // Non-registered output -> If VIOLATED timing path -> Set it to "2"
        .DATA_WIDTH     (I_PXL_W),
        .FIFO_DEPTH     (1<<$clog2(COL_NUM/2))
    ) second_pixel_fifo (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_i         (bwd_pxl_data_i),
        .data_o         (pf_data_o_map[1]),
        .wr_valid_i     (pf_wr_vld_map[1]),
        .rd_valid_i     (fwd_pxl_hsk),
        .empty_o        (),
        .full_o         (),
        .wr_ready_o     (pf_wr_rdy_map[1]),
        .rd_ready_o     (pf_rd_rdy_map[1]),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        ()
    );
    // -- Pixel FIFO for THIRD PIXEL in scaling block
    sync_fifo #(
        .FIFO_TYPE      (1),        // Non-registered output -> If VIOLATED timing path -> Set it to "2"
        .DATA_WIDTH     (I_PXL_W),
        .FIFO_DEPTH     (2)
    ) third_pixel_fifo (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_i         (bwd_pxl_data_i),
        .data_o         (pf_data_o_map[2]),
        .wr_valid_i     (pf_wr_vld_map[2]),
        .rd_valid_i     (fwd_pxl_hsk),
        .empty_o        (),
        .full_o         (),
        .wr_ready_o     (pf_wr_rdy_map[2]),
        .rd_ready_o     (pf_rd_rdy_map[2]),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        ()
    );
    // -- Pixel FIFO for FOURTH PIXEL in scaling block
    sync_fifo #(
        .FIFO_TYPE      (1),        // Non-registered output -> If VIOLATED timing path -> Set it to "2"
        .DATA_WIDTH     (I_PXL_W + 1),  // Contain pixel + last pixel flag
        .FIFO_DEPTH     (2)
    ) fourth_pixel_fifo (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_i         ({bwd_pxl_last_i, bwd_pxl_data_i}),     // Last pixel of the frame
        .data_o         ({fwd_pxl_last_o, pf_data_o_map[3]}),
        .wr_valid_i     (pf_wr_vld_map[3]),
        .rd_valid_i     (fwd_pxl_hsk),
        .empty_o        (),
        .full_o         (),
        .wr_ready_o     (pf_wr_rdy_map[3]),
        .rd_ready_o     (pf_rd_rdy_map[3]),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        ()
    );
    // Combination logic
    assign bwd_pxl_rdy_o    = pf_wr_rdy_map[{row_odd_q, col_ctn_q[0]}];
    assign fwd_pxl_vld_o    = (pf_rd_rdy_map[0] & pf_rd_rdy_map[1] & pf_rd_rdy_map[2] & pf_rd_rdy_map[3]);
    assign fwd_pxl_hsk      = fwd_pxl_vld_o & fwd_pxl_rdy_i;
    assign bwd_pxl_hsk      = bwd_pxl_vld_i & bwd_pxl_rdy_o;
    assign col_last         = ~|(col_ctn_q^(COL_NUM - 1));
    assign col_ctn_d        = (col_last) ? {COL_CTN_W{1'b0}} : col_ctn_q + 1'b1;
    assign row_odd_d        = row_odd_q + col_last;
    assign pf_wr_vld_map[0] = bwd_pxl_vld_i & ((~col_ctn_q[0]) & (~row_odd_q));
    assign pf_wr_vld_map[1] = bwd_pxl_vld_i & (col_ctn_q[0]    & (~row_odd_q));
    assign pf_wr_vld_map[2] = bwd_pxl_vld_i & ((~col_ctn_q[0]) & row_odd_q);
    assign pf_wr_vld_map[3] = bwd_pxl_vld_i & (col_ctn_q[0]    & row_odd_q);
    generate
    if(DOWNSCALE_TYPE == "AVR-POOLING") begin : AVR_POOL
        assign sum_block_pxl  = pf_data_o_map[0] + pf_data_o_map[1] + pf_data_o_map[2] + pf_data_o_map[3];  
        assign fwd_pxl_data_o = sum_block_pxl >> 2;
    end
    else if(DOWNSCALE_TYPE == "MAX-POOLING") begin : MAX_POOL
        wire [I_PXL_W-1:0]  pxl_tournament_0;
        wire [I_PXL_W-1:0]  pxl_tournament_1;
        assign pxl_tournament_0 = (pf_data_o_map[0] > pf_data_o_map[1]) ? pf_data_o_map[0] : pf_data_o_map[1];
        assign pxl_tournament_1 = (pf_data_o_map[2] > pf_data_o_map[3]) ? pf_data_o_map[2] : pf_data_o_map[3];
        assign fwd_pxl_data_o   = (pxl_tournament_0 > pxl_tournament_1) ? pxl_tournament_0 : pxl_tournament_1;
    end
    endgenerate
    // Flip-flop
    // -- Column counter
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            col_ctn_q <= {COL_CTN_W{1'b0}};
        end
        else if(bwd_pxl_hsk) begin
            col_ctn_q <= col_ctn_d;
        end
    end
    // -- Odd row flag 
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            row_odd_q <= 1'b0;
        end
        else if(bwd_pxl_hsk) begin
            row_odd_q <= row_odd_d;
        end
    end
endmodule
