import argparse
import sys

class Bitstream:
    def __init__(self):
        # Dynamic array to store bitstream elements (address, data)
        self.elements = []
        # Length of the bitstream
        self.length = 0

    def append(self, machine_code_file, base_address, offset):
        """
        Reads the machine_code_file and appends elements to the bitstream.
        :param machine_code_file: Path to the file containing machine code.
        :param base_address: Base address for the bitstream.
        :param offset: Address increment between consecutive data entries.
        """
        try:
            with open(machine_code_file, 'r') as file:
                for index, line in enumerate(file):
                    # Remove newline and whitespace characters
                    data = line.strip()
                    if not data:
                        continue  # Skip empty lines

                    # Calculate the address
                    address = base_address + offset * index

                    # Append the element to the bitstream
                    self.elements.append({'address': hex(address), 'data': hex(int(data, 16))})
                    self.length += 1
        except FileNotFoundError:
            print(f"Error: File '{machine_code_file}' not found.")
        except ValueError:
            print(f"Error: Invalid data format in file '{machine_code_file}'.")

    def write_to_file(self, output_file):
        """
        Writes the bitstream to a file in the specified format.
        Each element is split into bytes in the order: Address → Data.
        The order of bits in a word is LSB → MSB, and each byte is written as a separate line.
        :param output_file: Path to the output file.
        """
        try:
            with open(output_file, 'w') as file:
                for element in self.elements:
                    # Convert address and data to integers
                    address = int(element['address'], 16)
                    data = int(element['data'], 16)

                    # Split address into bytes (LSB → MSB)
                    address_bytes = address.to_bytes(4, byteorder='little')
                    for byte in address_bytes:
                        file.write(f"{byte:02X}\n")

                    # Split data into bytes (LSB → MSB)
                    data_bytes = data.to_bytes(4, byteorder='little')
                    for byte in data_bytes:
                        file.write(f"{byte:02X}\n")
        except IOError:
            print(f"Error: Unable to write to file '{output_file}'.")

    def finish(self):
        """
        Appends a finish element to the bitstream with address=0xFFFF_FFFF and data=0xFFFF_FFFF
        """
        self.elements.append({'address': '0xFFFFFFFF', 'data': '0xFFFFFFFF'})
        self.length += 1

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("[ERROR]: You should pass the paths for the main program, ISR program, and output bitstream file.\n"
            "Usage: python3 build.py <MAIN_PROGRAM_PATH> <ISR_PROGRAM_PATH> <BITSTREAM_PATH>")
        sys.exit(1)
    
    BITSTREAM_PATH = sys.argv[1]
    MAIN_PROGRAM_PATH = sys.argv[2]
    ISR_PROGRAM_PATH = sys.argv[3]

    bitstream = Bitstream()
    
    # Link all programs to the bitstream
    bitstream.append(MAIN_PROGRAM_PATH, base_address=0x0001_0000, offset=4)
    bitstream.append(ISR_PROGRAM_PATH, base_address=0x0002_0000, offset=4)
    # TODO: Use-define here 

    # Append a finish text to bitstream
    bitstream.finish()

    # Generate bitstream file
    bitstream.write_to_file(BITSTREAM_PATH)

    # Debug
    # print("Bitstream Elements:", bitstream.elements)
    # print("Bitstream Length:", bitstream.length)