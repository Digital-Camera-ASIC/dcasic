module drc_resizer #(
    parameter PXL_GRAYSCALE     = 0,              // Pixel Grayscale enable
    parameter FRM_DOWNSCALE     = 0,              // Frame Downscale enable
    parameter FRM_COL_NUM       = 640,            // Number of columns in 1 frame
    parameter FRM_ROW_NUM       = 480,            // Number of rows in 1 frame
    parameter DOWNSCALE_TYPE    = "AVR-POOLING",  // Downscale Type: "AVR-POOLING" || "MAX-POOLING"
    parameter RGB_PXL_W         = 16,             // RGB565 width
    parameter GS_PXL_W          = 8,              // Grayscale width
    parameter I_PXL_W           = RGB_PXL_W,      // Input pixel width
    parameter O_PXL_W           = PXL_GRAYSCALE ? GS_PXL_W : RGB_PXL_W  // Output pixel width
) (
    input                   clk,
    input                   rst_n,

    input   [I_PXL_W-1:0]   i_pxl_dat,
    input                   i_pxl_last, // Last pixel of the frame
    input                   i_pxl_vld,
    output                  i_pxl_rdy,
    
    output  [O_PXL_W-1:0]   o_pxl_dat,
    output                  o_pxl_last, // Last pixel of the frame
    output                  o_pxl_vld,
    input                   o_pxl_rdy
);
    // Internal signal
    wire    [O_PXL_W-1:0]   mid_pxl_dat;
    wire                    mid_pxl_last;
    wire                    mid_pxl_vld;
    wire                    mid_pxl_rdy;
    // Module instantiation
generate
if (PXL_GRAYSCALE == 1) begin : GRAYSCALE_GEN
    // -- Pixel Grayscaler
    drc_pxl_grayscaler  pg (
        .rgb_pxl_i      (i_pxl_dat),
        .rgb_pxl_last_i (i_pxl_last),
        .rgb_pxl_vld_i  (i_pxl_vld),
        .rgb_pxl_rdy_o  (i_pxl_rdy),
        .gs_pxl_o       (mid_pxl_dat),
        .gs_pxl_last_o  (mid_pxl_last),
        .gs_pxl_vld_o   (mid_pxl_vld),
        .gs_pxl_rdy_i   (mid_pxl_rdy)
    );
end
else begin : GRAYSCALE_BYPASS
    assign mid_pxl_dat  = i_pxl_dat;
    assign mid_pxl_last = i_pxl_last;
    assign mid_pxl_vld  = i_pxl_vld;
    assign i_pxl_rdy    = mid_pxl_rdy;
end
endgenerate
generate
if (FRM_DOWNSCALE == 1) begin : DOWNSCALE_GEN
    // -- Frame Downscaler
    drc_frm_downscaler #(
        .DOWNSCALE_TYPE (DOWNSCALE_TYPE),
        .I_PXL_W        (O_PXL_W),
        .COL_NUM        (FRM_COL_NUM),
        .ROW_NUM        (FRM_ROW_NUM)
    ) fd (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_pxl_data_i (mid_pxl_dat),
        .bwd_pxl_last_i (mid_pxl_last),
        .bwd_pxl_vld_i  (mid_pxl_vld),
        .bwd_pxl_rdy_o  (mid_pxl_rdy),
        .fwd_pxl_data_o (o_pxl_dat),
        .fwd_pxl_last_o (o_pxl_last),
        .fwd_pxl_vld_o  (o_pxl_vld),
        .fwd_pxl_rdy_i  (o_pxl_rdy)
    );
end
else begin : DOWNSCALE_BYPASS
    assign o_pxl_dat    = mid_pxl_dat;
    assign o_pxl_last   = mid_pxl_last;
    assign o_pxl_vld    = mid_pxl_vld;
    assign mid_pxl_rdy  = o_pxl_rdy;
end
endgenerate
    
endmodule