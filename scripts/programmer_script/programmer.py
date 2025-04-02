import serial 
import time
import sys

def load_bitstream(file_path, serial_port, baudrate=9600):
    try:
        # Read the bitstream file and convert each line into a byte
        with open(file_path, "r") as file:
            data = [int(line.strip(), 16) for line in file if line.strip()]
        
        total_bytes = len(data)
        if total_bytes == 0:
            print("[ERROR]: Bitstream file is empty.")
            return
        
        # Open the serial connection with specified settings
        with serial.Serial(serial_port, baudrate, timeout=1) as ser:
            last_print_time = time.time()  # Track time for 1s interval
            
            # Send each byte over UART with progress tracking
            for index, byte in enumerate(data, start=1):
                ser.write(bytes([byte]))
                time.sleep(0.01)  # Small delay to ensure correct transmission
                
                # Monitor progress every 1s
                if time.time() - last_print_time >= 1:
                    progress = (index / total_bytes) * 100
                    print(f"[INFO]: Programming ... ({progress:.2f}% complete)")
                    last_print_time = time.time()  # Reset timer
            
            print("[INFO]: Bitstream uploaded completely")
    except Exception as e:
        print(f"[ERROR]: {e}")  # Print error message if an issue occurs

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)
    
    com_number = sys.argv[1].strip()
    serial_port = f"COM{com_number}"  # Construct the full COM port name
    file_path = "output/programmer/bitstream.hex"  # Path to the bitstream file
    
    load_bitstream(file_path, serial_port)