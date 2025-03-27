ISR_PROG:
#   x9:  store interrupt source
#   x10: temporary value
#   x11: temporary value
# Get the source of the interrupt signal
    getq x9, q1
# Check if interrupt source is FRAME_CAPTURED interrupt
FRAME_CAPTURED_FLAG:
    addi x10, x0, 0b0001 # Mask of the FRAME_CAPTURED
    and x11, x9, x10
    beq x11, x0, FRAME_STORED_FLAG
    add x10, x10, x0 # TODO: Handle FRAME_CAPTURED interrupt
# Check if interrupt source is FRAME_STORED interrupt
FRAME_STORED_FLAG:
    addi x10, x0, 0b0010 # Mask of the FRAME_STORED
    and x11, x9, x10
    beq x11, x0, TXN_DSP_COMPLETE_FLAG
    # Start DMA to move image to display ############################################
    #   x10: store DMA base address
    #   x12: store DMA's channel 0 base address 
    #   x13: store DMA's channel 1 base address 
    #   x14: store TRANSFER_SUBMIT[0] register offset
    #   x15: store TRANSFER_SUBMIT[1] register offset
    lui x10, 0x80000
    addi x12, x0, 0x00  # For channel 0
    slli x12, x12, 4    # Convert to channel offset (chn_idx << 4)
    add x12, x12, x10   # CHN0_base_address = DMA_base_address + CHN0_offset
    addi x13, x0, 0x01  # For channel 1
    slli x13, x13, 4    # Convert to channel offset (chn_idx << 4)
    add x13, x13, x10   # CHN1_base_address = DMA_base_address + CHN0_offset
    lui x14, 0x00001    # RW1S offset: 0x1000
    add x15, x14, x13   # TRANSFER_SUBMIT[1] base address = CHN1_base_address + RW1S_offset
    add x14, x14, x12   # TRANSFER_SUBMIT[0] base address = CHN0_base_address + RW1S_offset  
    addi x14, x14, 0x00 # register_address = RW1S_base_address + register_offset 
    addi x4, x0, 0x01    
    sw x4, 0(x14)       # Submit to Channel 0
    sw x4, 0(x15)       # Submit to Channel 1
    #################################################################################
# Check if interrupt source is TXN_DSP_COMPLETE interrupt
TXN_DSP_COMPLETE_FLAG:
    addi x10, x0, 0b0100 # Mask of the TXN_DSP_COMPLETE
    and x11, x9, x10
    beq x11, x0, TXN_IP_COMPLETE_FLAG
    add x10, x10, x0 # TODO: Handle TXN_DSP_COMPLETE interrupt
# Check if interrupt source is TXN_IP_COMPLETE interrupt
TXN_IP_COMPLETE_FLAG:
    addi x10, x0, 0b1000 # Mask of the TXN_IP_COMPLETE
    and x11, x9, x10
    beq x11, x0, RETIRQ_FLAG
    add x10, x10, x0 # TODO: Handle TXN_IP_COMPLETE interrupt
RETIRQ_FLAG:
    retirq