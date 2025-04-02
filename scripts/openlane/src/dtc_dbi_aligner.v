module dtc_dbi_aligner #(
    parameter PROC_PXL_W    = 16,
    parameter DBI_IF_D_W    = 8
) (
    input                       clk,
    input                       rst_n,
    // Processed Pixel
    input   [PROC_PXL_W-1:0]    proc_pxl_dat,
    input                       proc_pxl_vld,
    output                      proc_pxl_rdy,
    // DBI Pixel
    output  [DBI_IF_D_W-1:0]    dbi_pxl_dat,
    output                      dbi_pxl_vld,
    input                       dbi_pxl_rdy
);
generate
if(PROC_PXL_W > DBI_IF_D_W) begin : ALIGN_GEN
    // Module instantiation
    sync_fifo #(
        .FIFO_TYPE      (4),     // Deconcat (Downsizer)  
        .DATA_WIDTH     (),      // Don't care
        .IN_DATA_WIDTH  (PROC_PXL_W),
        .OUT_DATA_WIDTH (DBI_IF_D_W),
        .DECONCAT_ORDER ("MSB"), // First half of a RGB565 pixel is the upper 8-bit (MSB) -> According to MIPI DBI spec 
        .FIFO_DEPTH     ()       // Don't care
    ) downsizer (   
        .clk            (clk),
        .data_i         (proc_pxl_dat),
        .wr_valid_i     (proc_pxl_vld),
        .wr_ready_o     (proc_pxl_rdy),
        .data_o         (dbi_pxl_dat),
        .rd_ready_o     (dbi_pxl_vld),
        .rd_valid_i     (dbi_pxl_rdy),
        .empty_o        (),
        .full_o         (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        (),
        .rst_n          (rst_n)
    );
end
else begin : BYPASS
    assign dbi_pxl_dat  = proc_pxl_dat;
    assign dbi_pxl_vld  = proc_pxl_vld;
    assign proc_pxl_rdy = dbi_pxl_rdy;
end
endgenerate
endmodule