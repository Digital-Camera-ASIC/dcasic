import re
import sys

# Define instruction formats and their encoding information
INSTRUCTION_SET = {
    # R type
    "add":      {"type": "R", "opcode": 0b0110011, "funct3": 0b000, "funct7": 0b0000000},
    "sub":      {"type": "R", "opcode": 0b0110011, "funct3": 0b000, "funct7": 0b0100000},
    "sll":      {"type": "R", "opcode": 0b0110011, "funct3": 0b001, "funct7": 0b0000000},
    "slt":      {"type": "R", "opcode": 0b0110011, "funct3": 0b010, "funct7": 0b0000000},
    "sltu":     {"type": "R", "opcode": 0b0110011, "funct3": 0b011, "funct7": 0b0000000},
    "xor":      {"type": "R", "opcode": 0b0110011, "funct3": 0b100, "funct7": 0b0000000},
    "srl":      {"type": "R", "opcode": 0b0110011, "funct3": 0b101, "funct7": 0b0000000},
    "sra":      {"type": "R", "opcode": 0b0110011, "funct3": 0b101, "funct7": 0b0100000},
    "or":       {"type": "R", "opcode": 0b0110011, "funct3": 0b110, "funct7": 0b0000000},
    "and":      {"type": "R", "opcode": 0b0110011, "funct3": 0b111, "funct7": 0b0000000},
    # I type
    "addi":     {"type": "I", "opcode": 0b0010011, "funct3": 0b000},
    "slti":     {"type": "I", "opcode": 0b0010011, "funct3": 0b010},
    "sltiu":    {"type": "I", "opcode": 0b0010011, "funct3": 0b011},
    "xori":     {"type": "I", "opcode": 0b0010011, "funct3": 0b100},
    "ori":      {"type": "I", "opcode": 0b0010011, "funct3": 0b110},
    "andi":     {"type": "I", "opcode": 0b0010011, "funct3": 0b111},
    "slli":     {"type": "I", "opcode": 0b0010011, "funct3": 0b001},
    "srli":     {"type": "I", "opcode": 0b0010011, "funct3": 0b101},

    "lb":       {"type": "I", "opcode": 0b0000011, "funct3": 0b000},
    "lw":       {"type": "I", "opcode": 0b0000011, "funct3": 0b010},
    # S type
    "sb":       {"type": "S", "opcode": 0b0100011, "funct3": 0b000},
    "sw":       {"type": "S", "opcode": 0b0100011, "funct3": 0b010},
    # B type
    "beq":      {"type": "B", "opcode": 0b1100011, "funct3": 0b000},
    "bne":      {"type": "B", "opcode": 0b1100011, "funct3": 0b001},
    # J type
    "jal":      {"type": "J", "opcode": 0b1101111},
    # U type
    "lui":      {"type": "U", "opcode": 0b0110111},
    # C type (custom type for PicoRV32 Interrupt)
    "getq":     {"type": "C", "opcode": 0b0001011, "funct3": 0b100, "funct7": 0b0000000},
    "setq":     {"type": "C", "opcode": 0b0001011, "funct3": 0b010, "funct7": 0b0000001},
    "retirq":   {"type": "C", "opcode": 0b0001011, "funct3": 0b000, "funct7": 0b0000010},
    "maskirq":  {"type": "C", "opcode": 0b0001011, "funct3": 0b110, "funct7": 0b0000011},
    "waitirq":  {"type": "C", "opcode": 0b0001011, "funct3": 0b100, "funct7": 0b0000100},
    "timer":    {"type": "C", "opcode": 0b0001011, "funct3": 0b110, "funct7": 0b0000101},
}

# Function to parse register and immediate values
def parse_operands(operands, is_custom=False):
    parsed = []
    for op in operands:
        # print(op)
        if op.startswith("x"):
            parsed.append(int(op[1:]))  # Register number
        elif re.match(r"^-?0x[0-9a-fA-F]+$", op): # Hexadecimal immediate
            parsed.append(int(op, 16))
        elif re.match(r"^-?0b[01]+$", op): # Binary immediate
            parsed.append(int(op, 2))
        elif re.match(r"^-?\d+$", op): # Decimal immediate
            parsed.append(int(op))
        elif "(" in op and ")" in op:
            imm, reg = re.match(r"(-?\d+|0x[0-9a-fA-F]+|0b[01]+)\(x(\d+)\)", op).groups()
            if imm.startswith("0x"):
                imm = int(imm, 16)
            elif imm.startswith("0b"):
                imm = int(imm, 2)
            else:
                imm = int(imm)
            parsed.extend([int(reg), imm])
        elif op.startswith("q"): # Interrupt register
            parsed.append(int(op[1:]))  # Register number
        elif is_custom: 
            parsed.append(op)  # Keep custom operands as is
        else:
            raise ValueError(f"Invalid operand: {op}")
    return parsed

# Encoding functions
def encode_r_type(opcode, funct3, funct7, rd, rs1, rs2):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i_type(opcode, funct3, rd, rs1, imm):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s_type(opcode, funct3, rs1, rs2, imm):
    return (((imm >> 5) & 0x7F) << 25) | (rs1 << 20) | (rs2 << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | opcode

def encode_b_type(opcode, funct3, rs1, rs2, imm):
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | opcode

def encode_u_type(opcode, rd, imm):
    return ((imm << 12) & 0xFFFFF000) | (rd << 7) | opcode

def encode_j_type(opcode, rd, imm):
    return (((imm >> 20) & 1) << 31) | (((imm >> 12) & 0xFF) << 12) | (((imm >> 11) & 1) << 20) | (((imm >> 1) & 0x3FF) << 21) | (rd << 7) | opcode

def encode_c_type(opcode, funct3, funct7, xd=0, xs=0): # xd is Xd register || xs is Xs register (X = r || q)
    return (funct7 << 25) | (0x0 << 20) | (xs << 15) | (funct3 << 12) | (xd << 7) | opcode

# Instruction encoding
def encode_instruction(instr, operands, info):
    if info["type"] == "R":
        return encode_r_type(info["opcode"], info["funct3"], info["funct7"], *operands)
    elif info["type"] == "I":
        return encode_i_type(info["opcode"], info["funct3"], *operands)
    elif info["type"] == "S":
        return encode_s_type(info["opcode"], info["funct3"], *operands)
    elif info["type"] == "B":
        return encode_b_type(info["opcode"], info["funct3"], *operands)
    elif info["type"] == "U":
        return encode_u_type(info["opcode"], *operands)
    elif info["type"] == "J":
        return encode_j_type(info["opcode"], *operands)
    elif info["type"] == "C":
        return encode_c_type(info["opcode"], info["funct3"], info["funct7"], *operands)
    else:
        raise ValueError(f"Unknown instruction type: {info['type']}")

# Parse and assemble assembly code
def parse_assembly(assembly_code):
    machine_code = []
    labels = {}
    instructions = []

    # First pass: collect labels and their addresses
    address = 0
    for line in assembly_code.strip().split("\n"):
        line = line.split("#")[0].strip()  # Remove comments
        if not line:
            continue
        if ":" in line:  # Label definition
            label = line.replace(":", "").strip()
            labels[label] = str(address)
        else:
            instructions.append(line)
            address += 4  # Each instruction is 4 bytes
    # Second pass: process instructions
    for line in instructions:
        tokens = line.replace(",", "").split()
        instr = tokens[0]
        info = INSTRUCTION_SET.get(instr, {"custom": True})
        
        # print(tokens)
        pc = len(machine_code) * 4  # Calculate the current program counter (PC)
        # print(f"[INFO]: Processing instruction with PC {pc}\t(Instr order {int(pc/4)})\t{line}")

        operands = parse_operands(
            [
            str(int(labels[op]) - pc) if op in labels else op
            for op in tokens[1:]
            ],  # Replace labels with relative offsets
            info.get("custom", False)
        )
        # print(operands)

        binary_instr = encode_instruction(instr, operands, info)
        machine_code.append(f"{binary_instr:032b}")

    return machine_code

# Main function to run the assembler
def run_assembler(asm_prog_path, mc_prog_path):
    with open(asm_prog_path, "r") as file:
        assembly_code = file.read()
    
    machine_code = parse_assembly(assembly_code)

    with open(mc_prog_path, "w") as file:
        for instr in machine_code:
            file.write(f"{int(instr, 2):08X}\n")

if __name__ == "__main__":
    # Pass the path of source assembly and destination machine code
    if len(sys.argv) != 3:
        print("[ERROR]: You should pass the path of the program \n python3 assembler.py <SRC_PROG_PATH> <DST_PROG_PATH>")
        sys.exit(1)

    SRC_PROG_PATH = sys.argv[1]
    DST_PROG_PATH = sys.argv[2]

    run_assembler(SRC_PROG_PATH, DST_PROG_PATH)
