#============================================================================
# Makefile for Asynchronous FIFO Design
#============================================================================

# Simulator
SIM = iverilog
SIMFLAGS = -g2012 -Wall
VIEWER = gtkwave

# Directories
RTL_DIR = rtl
TB_DIR = tb
BUILD_DIR = build

# Source files
RTL_SOURCES = \
	$(RTL_DIR)/fifomem.v \
	$(RTL_DIR)/sync_r2w.v \
	$(RTL_DIR)/sync_w2r.v \
	$(RTL_DIR)/rptr_empty.v \
	$(RTL_DIR)/wptr_full.v \
	$(RTL_DIR)/async_fifo.v

TB_SOURCES = \
	$(TB_DIR)/async_fifo_tb.v

# Output files
VVP_FILE = $(BUILD_DIR)/async_fifo_tb.vvp
VCD_FILE = $(BUILD_DIR)/async_fifo_tb.vcd

# Targets
.PHONY: all clean sim view help

all: sim

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Compile
compile: $(BUILD_DIR) $(RTL_SOURCES) $(TB_SOURCES)
	@echo "==================================="
	@echo "Compiling Asynchronous FIFO..."
	@echo "==================================="
	$(SIM) $(SIMFLAGS) -o $(VVP_FILE) \
		-s async_fifo_tb \
		$(RTL_SOURCES) $(TB_SOURCES)
	@echo "Compilation successful!"
	@echo ""

# Simulate
sim: compile
	@echo "==================================="
	@echo "Running Simulation..."
	@echo "==================================="
	cd $(BUILD_DIR) && vvp async_fifo_tb.vvp
	@echo ""
	@echo "Simulation complete!"
	@echo "Waveform saved to: $(VCD_FILE)"
	@echo ""

# View waveforms
view: $(VCD_FILE)
	@echo "Opening waveform viewer..."
	$(VIEWER) $(VCD_FILE) &

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# Help
help:
	@echo "Asynchronous FIFO Makefile"
	@echo "=========================="
	@echo ""
	@echo "Targets:"
	@echo "  make          - Compile and run simulation (default)"
	@echo "  make compile  - Compile only"
	@echo "  make sim      - Compile and simulate"
	@echo "  make view     - View waveforms (requires GTKWave)"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Files:"
	@echo "  RTL:       $(RTL_DIR)/"
	@echo "  Testbench: $(TB_DIR)/"
	@echo "  Build:     $(BUILD_DIR)/"
	@echo ""
