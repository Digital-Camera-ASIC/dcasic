BOOTLOADER_PROG:
    #   x4:     store address of the UART_RX register
    #   x5:     store rx data
    #   x6:     store rx counter
    #   x7:     store word data (contain 4 rx data)
    #   x8:     store word type (0: address, 1: data)
    #   x9:     store address of the current instruction
    #   x10:    store data of the current instruction
    #   x11:    store the address of main program
    #   x12:    store temporary value
    #   x13:    store temporary value
    lui x4, 0xA0000     # Base address of the UART
    addi x4, x4, 0x20    # Address of the UART_RX register (0xA000_0020)
    lui x11, 0x00010    # Address of main program (0x0001_0000)
    addi x6, x0, 0      # rx_cnt = 0
    addi x7, x0, 0      # word_data = 0
    addi x8, x0, 0      # word_type = 0 (0: Address, 1: Data)

LOOP:
    # Receive RX data (Wait until rx data is received)
    lb x5, 0(x4)

    # rx_buffer |= (rx_data << rx_cnt)
    sll x5, x5, x6      # Shift rx_data left by rx_cnt
    or x7, x7, x5       # OR with rx_buffer
    # Clear RX data buffer
    addi x5, x0, 0      # rx_data = 0

    # Check if received 1 word data (32bit) completely
    addi x12, x0, 3
    bne x6, x12, WORD_REMAIN
    # Clear rx data counter when 1 word data is received
    addi x6, x0, 0

    # Store the current word data to the corresponding data
    # Check if the current type is address
    bne x8, x0, BUFFER_DATA
    add x9, x7, x0  # addr_instr = rx_buffer
    jal x13, TOGGLE_WORD_TYPE

BUFFER_DATA:
    add x10, x7, x0 # data_instr = rx_buffer

    # Check if the current instruction is End-of-Programming (addr: 0xffff_ffff & data: 0xffff_ffff) 
    sub x12, x0, 1  # Generate mask: 0xffff_ffff
    and x13, x9, x10
    bne x13, x12, STORE_MEM

    # Jump to Main program & finish the bootloader mode
    jalr x13, x11, 0

STORE_MEM:
    # Store the data of instruction to the address of instruction
    sw x10, 0(x9)

TOGGLE_WORD_TYPE:
    # word_type = !word_type
    xori x8, x8, 1
    jal x13, LOOP

WORD_REMAIN:
    # Increase the rx data counter (byte counter) 
    addi x6, x6, 1
    jal x13, LOOP

