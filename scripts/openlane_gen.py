import os
import shutil
import json
from collections import OrderedDict

# Define paths
OPENLANE_DIR = "openlane"
SRC_DIR = os.path.join(OPENLANE_DIR, "src")
RTL_FILE = "rtl.f"
SDC_SOURCE = "../rtl/dcasic.sdc"
SDC_DEST = os.path.join(SRC_DIR, "dcasic.sdc")
CONFIG_TEMPLATE = "openlane_config.json"
CONFIG_OUTPUT = os.path.join(OPENLANE_DIR, "config.json")

# Remove the existing src directory if it exists
if os.path.exists(SRC_DIR):
    shutil.rmtree(SRC_DIR)

# Create the src directory
os.makedirs(SRC_DIR, exist_ok=True)

# Read rtl.f and copy the listed files to SRC_DIR
verilog_files = []
with open(RTL_FILE, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):  # Skip comments and empty lines
            continue

        file_path = line
        if not os.path.exists(file_path):
            print(f"[WARN]: File not found: {file_path}")
            continue

        dest_path = os.path.join(SRC_DIR, os.path.basename(file_path))
        shutil.copy(file_path, dest_path)
        verilog_files.append(f"dir::src/{os.path.basename(file_path)}")
        print(f"[INFO]: Copied: {file_path} -> {dest_path}")

# Copy the SDC file
if os.path.exists(SDC_SOURCE):
    shutil.copy(SDC_SOURCE, SDC_DEST)
    print(f"[INFO]: Copied SDC: {SDC_SOURCE} -> {SDC_DEST}")
else:
    print(f"[WARN]: SDC file not found: {SDC_SOURCE}")

# Load the config template
with open(CONFIG_TEMPLATE, "r") as f:
    config_template = json.load(f)

# Define primary keys
primary_config = OrderedDict({
    "DESIGN_NAME": "dcasic",
    "VERILOG_FILES": verilog_files,
    "CLOCK_PORT": "sys_clk",
    "CLOCK_NET": "sys_clk",
    "BASE_SDC_FILE": f"dir::src/dcasic.sdc" if os.path.exists(SDC_DEST) else ""
})

# Merge with template (primary keys first)
final_config = OrderedDict(primary_config)
final_config.update(config_template)

# Save the new config.json
with open(CONFIG_OUTPUT, "w") as f:
    json.dump(final_config, f, indent=4)

print(f"[INFO]: Config generated at {CONFIG_OUTPUT}")
