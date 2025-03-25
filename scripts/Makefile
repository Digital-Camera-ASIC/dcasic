# User-defined OpenLane design directory (modify as needed)
OPENLANE_DESIGN_DIR ?= ../../test_env/OpenLane/designs/dcasic
# OpenLane directories and script
SETUP_DIR := openlane
RTL_LIST := rtl.f
SRC_DIR := $(SETUP_DIR)/src
PYTHON_SCRIPT := openlane_script/openlane_gen.py
ASSEMBLER_SCRIPT := assembler_script/assembler.py
FIRMWARE_DIR := ../firmware

# Detect OS (Windows or Linux/macOS)
OS := $(shell uname 2>/dev/null || echo Windows)

.PHONY: openlane_gen clean openlane_push assemble

# Generate OpenLane source files
openlane_gen:
ifeq ($(OS), Windows)
	@if not exist "$(SRC_DIR)" mkdir "$(SRC_DIR)"
	@python3 $(PYTHON_SCRIPT) $(RTL_LIST) $(SRC_DIR)
	@echo "[INFO]: OpenLane source files generated in $(SRC_DIR)"
else
	@mkdir -p $(SRC_DIR)
	@python3 $(PYTHON_SCRIPT) $(RTL_LIST) $(SRC_DIR)
	@echo "[INFO]: OpenLane source files generated in $(SRC_DIR)"
endif

# Push OpenLane folder to the specified design directory
openlane_push:
ifeq ($(OS), Windows)
	@if exist "$(OPENLANE_DESIGN_DIR)" ( 
		echo "[INFO]: Pushing OpenLane files to $(OPENLANE_DESIGN_DIR)..." & 
		xcopy /E /I /Y "$(SETUP_DIR)" "$(OPENLANE_DESIGN_DIR)" & 
		echo "[INFO]: Push complete." 
	) else ( 
		echo "[ERROR]: OpenLane design folder does not exist: $(OPENLANE_DESIGN_DIR)" & 
		exit 1 
	)
else
	@if [ -d "$(OPENLANE_DESIGN_DIR)" ]; then \
		echo "[INFO]: Pushing OpenLane files to $(OPENLANE_DESIGN_DIR)..."; \
		rsync -av --delete $(SETUP_DIR)/ $(OPENLANE_DESIGN_DIR)/; \
		echo "[INFO]: Push complete."; \
	else \
		echo "[ERROR]: OpenLane design folder does not exist: $(OPENLANE_DESIGN_DIR)"; \
		exit 1; \
	fi
endif

# Clean OpenLane directory
openlane_clean:
ifeq ($(OS), Windows)
	@if exist "$(SETUP_DIR)" ( \
		del /s /q "$(SETUP_DIR)" && rmdir /s /q "$(SETUP_DIR)" \
	) else ( \
		echo "[INFO]: No OpenLane directory to clean." \
	)
else
	@rm -rf $(SETUP_DIR)
	@echo "[INFO]: Cleaned OpenLane directory"
endif

# Assemble firmware
assemble:
	@if [ -z "$(NAME)" ]; then \
		echo "[ERROR]: Please specify NAME=<firmware_name>"; \
		exit 1; \
	fi
ifeq ($(OS), Windows)
	@if exist "$(FIRMWARE_DIR)\$(NAME)" ( \
		if exist "$(FIRMWARE_DIR)\$(NAME)\$(NAME).s" ( \
			if exist "$(FIRMWARE_DIR)\$(NAME)\$(NAME).h" ( \
				echo "[INFO]: Assembling $(FIRMWARE_DIR)\$(NAME)\$(NAME).s with header $(FIRMWARE_DIR)\$(NAME)\$(NAME).h"; \
				python3 $(ASSEMBLER_SCRIPT) "$(FIRMWARE_DIR)\$(NAME)\$(NAME).s" "$(FIRMWARE_DIR)\$(NAME)\$(NAME).h"; \
				echo "[INFO]: Assembly complete." \
			) else ( \
				echo "[ERROR]: File $(FIRMWARE_DIR)\$(NAME)\$(NAME).h not found."; \
				exit 1 \
			) \
		) else ( \
			echo "[ERROR]: File $(FIRMWARE_DIR)\$(NAME)\$(NAME).s not found."; \
			exit 1 \
		) \
	) else ( \
		echo "[ERROR]: Firmware directory $(FIRMWARE_DIR)\$(NAME) not found."; \
		exit 1 \
	)
else
	@if [ -d "$(FIRMWARE_DIR)/$(NAME)" ]; then \
		S_FILE="$(FIRMWARE_DIR)/$(NAME)/$(NAME).s"; \
		H_FILE="$(FIRMWARE_DIR)/$(NAME)/$(NAME).hex"; \
		if [ -f "$$S_FILE" ] && [ -f "$$H_FILE" ]; then \
			echo "[INFO]: Assembling $$S_FILE with header $$H_FILE"; \
			python3 $(ASSEMBLER_SCRIPT) $$S_FILE $$H_FILE; \
			echo "[INFO]: Assembly complete."; \
		else \
			if [ ! -f "$$S_FILE" ]; then \
				echo "[ERROR]: File $$S_FILE not found."; \
			fi; \
			if [ ! -f "$$H_FILE" ]; then \
				echo "[ERROR]: File $$H_FILE not found."; \
			fi; \
			exit 1; \
		fi \
	else \
		echo "[ERROR]: Firmware directory $(FIRMWARE_DIR)/$(NAME) not found."; \
		exit 1; \
	fi
endif
