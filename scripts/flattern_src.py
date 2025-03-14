import os
import shutil

# Define the paths
OPENLANE_DIR = "openlane"  # Directory for OpenLane
SRC_DIR = os.path.join(OPENLANE_DIR, "src")  # Directory to store the flattened files
RTL_FILE = "rtl.f"  # File containing the list of HDL files

# Remove the existing src directory if it exists
if os.path.exists(SRC_DIR):
    shutil.rmtree(SRC_DIR)

# Create the openlane/src directory
os.makedirs(SRC_DIR, exist_ok=True)

# Read rtl.f and copy the listed files to SRC_DIR
with open(RTL_FILE, "r") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):  # Skip comments and empty lines
            continue

        # Normalize the file path by removing the "../" prefix
        file_path = line.replace("./../", "")

        # Check if the file exists
        if not os.path.exists(file_path):
            print(f"File not found: {file_path}")
            continue

        # Copy the file to the src directory
        dest_path = os.path.join(SRC_DIR, os.path.basename(file_path))
        shutil.copy(file_path, dest_path)
        print(f"Copied: {file_path} -> {dest_path}")

print(f"Flattening complete. All HDL files are stored in {SRC_DIR}/")
