OPENLANE_DIR := openlane
RTL_LIST := rtl.f
SRC_DIR := $(OPENLANE_DIR)/src
PYTHON_SCRIPT := openlane_gen.py

.PHONY: openlane_gen clean

openlane_gen:
	@mkdir -p $(SRC_DIR)
	@python3 $(PYTHON_SCRIPT) $(RTL_LIST) $(SRC_DIR)
	@echo "[INFO]: OpenLane source files generated in $(SRC_DIR)"

clean:
	@rm -rf $(OPENLANE_DIR)
	@echo "[INFO]: Cleaned OpenLane directory"
