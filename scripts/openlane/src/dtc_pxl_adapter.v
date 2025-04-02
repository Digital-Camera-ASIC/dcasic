// Any Pixel format -> RGB565 Pixel format
module dtc_pxl_adapter #(
    parameter IN_PXL_TYPE   = "GRAY",   // "GRAY": Gray pixel || "RGB": RGB565 pixel
    parameter GRAY_PXL_W    = 8,
    parameter RGB_PXL_W     = 16,
    parameter IN_PXL_W      = (IN_PXL_TYPE == "GRAY") ? GRAY_PXL_W : RGB_PXL_W,
    parameter OUT_PXL_W     = RGB_PXL_W
) (
    input                   clk,
    input                   rst_n,
    // Input Pixel 
    input   [IN_PXL_W-1:0]  in_pxl_dat,
    input                   in_pxl_vld,
    output                  in_pxl_rdy,
    // Output Pixel
    output  [OUT_PXL_W-1:0] out_pxl_dat,
    output                  out_pxl_vld,
    input                   out_pxl_rdy
);
generate
if(IN_PXL_TYPE == "GRAY") begin : ADAPT_GEN 
    // Internal signal
    // -- -- RGB565
    wire    [4:0]               pxl_r_dat;
    wire    [5:0]               pxl_g_dat;
    wire    [4:0]               pxl_b_dat;
    wire    [RGB_PXL_W-1:0]     rgb_pxl_dat;

    // Combination logic
    assign out_pxl_dat  = rgb_pxl_dat;
    assign out_pxl_vld  = in_pxl_vld;
    assign in_pxl_rdy   = out_pxl_rdy;
    assign rgb_pxl_dat  = {pxl_r_dat, pxl_g_dat, pxl_b_dat};
    assign pxl_r_dat    = in_pxl_dat[7-:5];
    assign pxl_g_dat    = in_pxl_dat[7-:6];
    assign pxl_b_dat    = in_pxl_dat[7-:5];
end
else begin : BYPASS
    assign out_pxl_dat  = in_pxl_dat;
    assign out_pxl_vld  = in_pxl_vld;
    assign in_pxl_rdy   = out_pxl_rdy;
end
endgenerate
endmodule