# Top
./../rtl/dcasic.v
# Processor (RV32I)
./../rtl/processor/picorv32.v
# Camera IF (DVP TX Controller)
./../ip/camera_if/dvp_rx_controller/rtl/dvp_rx_controller.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_cs_state_machine.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_ctrl_state.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_dvp_data_fifo.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_frm_downscaler.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_mem_aligner.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_pclk_sync.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_pxl_grayscaler.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_regmap.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_resizer.v
./../ip/camera_if/dvp_rx_controller/rtl/drc_xclk_gen.v
# Display IF (DBI TX Controller)
./../ip/display_if/dbi_tx_controller/rtl/dbi_tx_controller.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_axis_pxl.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_dbi_aligner.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_phy_ctrl.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_pxl_adapter.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_reg_map.v
./../ip/display_if/dbi_tx_controller/rtl/dtc_state_machine.v
# AXI DMA
./../ip/dma/axi_dma/axi_dma/rtl/axi_dma.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_as_atx_arb.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_as_atx_fetch.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_as_atx_req.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_as_tx_stat.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_atx_sched.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_chn_man.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_cm_chn_unit.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_cm_tf_split.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_cm_tx_fetch.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_cm_xfer_stat.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_data_mover.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_desc_queue.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_axi_ax.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_axi_b.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_axi_r.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_axi_w.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_data_buf.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_dst_axis.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_rd_host.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_src_axis.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_dm_wr_host.v
./../ip/dma/axi_dma/axi_dma/rtl/adma_reg_map.v
# AXI Interconnect
./../ip/interconnect/axi_interconnect/rtl/axi_interconnect.v
./../ip/interconnect/axi_interconnect/rtl/ai_dispatcher.v
./../ip/interconnect/axi_interconnect/rtl/ai_slave_arbitration.v
./../ip/interconnect/axi_interconnect/rtl/dsp_Ax_channel.v
./../ip/interconnect/axi_interconnect/rtl/dsp_B_channel.v
./../ip/interconnect/axi_interconnect/rtl/dsp_R_channel.v
./../ip/interconnect/axi_interconnect/rtl/dsp_read_channel.v
./../ip/interconnect/axi_interconnect/rtl/dsp_W_channel.v
./../ip/interconnect/axi_interconnect/rtl/dsp_write_channel.v
./../ip/interconnect/axi_interconnect/rtl/sa_Ax_channel.v
./../ip/interconnect/axi_interconnect/rtl/sa_B_channel.v
./../ip/interconnect/axi_interconnect/rtl/sa_R_channel.v
./../ip/interconnect/axi_interconnect/rtl/sa_W_channel.v
./../ip/interconnect/axi_interconnect/rtl/splitting_4kb_masker.v
# AXI Memory
./../ip/memory/axi_mem/rtl/axi4_mem.v
./../ip/memory/axi_mem/rtl/amem_dispath.v
./../ip/memory/axi_mem/rtl/amem_dsp_read.v
./../ip/memory/axi_mem/rtl/amem_dsp_write.v
# Camera Controller (SCCB Master Controller)
./../ip/peripherals/sccb_master_controller/rtl/sccb_master_controller.v
./../ip/peripherals/sccb_master_controller/rtl/smc_reg_map.v
./../ip/peripherals/sccb_master_controller/rtl/smc_state_machine.v
./../ip/peripherals/sccb_master_controller/rtl/smc_timing_gen.v
# Common
./../rtl/common/adapter/axi/axi4_ctrl.v
./../rtl/common/arbiter/iwrr/arb_prior_granter.v
./../rtl/common/arbiter/iwrr/arb_round_comp_detector.v
./../rtl/common/arbiter/iwrr/arbiter_iwrr_1cycle.v
./../rtl/common/converter/bin2gray_converter.v
./../rtl/common/converter/gray2bin_converter.v
./../rtl/common/decoder/onehot_decoder/onehot_decoder.v
./../rtl/common/encoder/onehot_encoder/onehot_encoder.v 
./../rtl/common/encoder/priority_encoder/priority_encoder.v 
./../rtl/common/edgedet/edgedet.v 
./../rtl/common/fifo/async_fifo/asyn_fifo.v 
./../rtl/common/fifo/sync_fifo/sync_fifo.v 
./../rtl/common/fifo/sync_fifo/fifo.v
./../rtl/common/memory/mem.v 
./../rtl/common/reorder_buffer/reorder_buffer.v
./../rtl/common/skid_buffer/skid_buffer.v
./../rtl/common/skid_buffer/sb_fifo.v
./../rtl/common/splitter/splitter.v