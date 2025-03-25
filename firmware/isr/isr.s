ISR_PROG:
    #   x10: temporary value
    #   x11: store interrupt source
    # Get the source of the interrupt signal
        getq x11, q1
    # Check if interrupt source is FRAME_CAPTURED interrupt
    FRAME_CAPTURED_FLAG:
        addi x10, x0, 0b0001 # Mask of the FRAME_CAPTURED
        and x11, x11, x10
        beq x11, x0, FRAME_STORED_FLAG
        add x10, x10, x0 # TODO: Handle FRAME_CAPTURED interrupt
    # Check if interrupt source is FRAME_STORED interrupt
    FRAME_STORED_FLAG:
        addi x10, x0, 0b0010 # Mask of the FRAME_STORED
        and x11, x11, x10
        beq x11, x0, TXN_DSP_COMPLETE_FLAG
        add x10, x10, x0 # TODO: Handle FRAME_STORED interrupt
    # Check if interrupt source is TXN_DSP_COMPLETE interrupt
    TXN_DSP_COMPLETE_FLAG:
        addi x10, x0, 0b0100 # Mask of the TXN_DSP_COMPLETE
        and x11, x11, x10
        beq x11, x0, TXN_IP_COMPLETE_FLAG
        add x10, x10, x0 # TODO: Handle TXN_DSP_COMPLETE interrupt
    # Check if interrupt source is TXN_IP_COMPLETE interrupt
    TXN_IP_COMPLETE_FLAG:
        addi x10, x0, 0b1000 # Mask of the TXN_IP_COMPLETE
        and x11, x11, x10
        beq x11, x0, RETIRQ_FLAG
        add x10, x10, x0 # TODO: Handle TXN_IP_COMPLETE interrupt
    RETIRQ_FLAG:
        retirq