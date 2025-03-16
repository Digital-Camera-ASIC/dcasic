# User-defined OpenLane design directory (modify as needed)
OPENLANE_DESIGN_DIR ?= ../../test_env/OpenLane/designs/dcasic
# OpenLane directories and script
SETUP_DIR := openlane
RTL_LIST := rtl.f
SRC_DIR := $(SETUP_DIR)/src
PYTHON_SCRIPT := openlane_gen.py


.PHONY: openlane_gen clean openlane_push

# Generate OpenLane source files
openlane_gen:
	@mkdir -p $(SRC_DIR)
	@python3 $(PYTHON_SCRIPT) $(RTL_LIST) $(SRC_DIR)
	@echo "[INFO]: OpenLane source files generated in $(SRC_DIR)"

# Push OpenLane folder to the specified design directory
openlane_push:
	@if [ -d "$(OPENLANE_DESIGN_DIR)" ]; then \
		echo "[INFO]: Pushing OpenLane files to $(OPENLANE_DESIGN_DIR)..."; \
		rsync -av --delete $(SETUP_DIR)/ $(OPENLANE_DESIGN_DIR)/; \
		echo "[INFO]: Push complete."; \
	else \
		echo "[ERROR]: OpenLane design folder does not exist: $(OPENLANE_DESIGN_DIR)"; \
		exit 1; \
	fi

# Clean OpenLane directory
clean:
	@rm -rf $(SETUP_DIR)
	@echo "[INFO]: Cleaned OpenLane directory"
