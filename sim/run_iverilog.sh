#!/bin/bash
#============================================================================
# run_iverilog.sh - Script to compile and simulate async FIFO with iverilog
#============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================="
echo "Async FIFO Simulation with Iverlog"
echo "========================================="

# Check if iverilog is installed
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}ERROR: iverilog is not installed${NC}"
    echo ""
    echo "To install iverilog:"
    echo "  Ubuntu/Debian: sudo apt-get install iverilog"
    echo "  MacOS: brew install icarus-verilog"
    echo "  From source: http://iverilog.icarus.com/"
    exit 1
fi

echo -e "${GREEN}Found iverilog: $(iverilog -v 2>&1 | head -1)${NC}"
echo ""

# Create sim directory if it doesn't exist
cd "$(dirname "$0")"/..
mkdir -p sim
cd sim

# Clean previous build
rm -f async_fifo_tb.vvp async_fifo_tb.vcd

echo "Compiling design files..."
iverilog -g2012 -o async_fifo_tb.vvp \
    ../rtl/fifomem.v \
    ../rtl/sync_r2w.v \
    ../rtl/sync_w2r.v \
    ../rtl/rptr_empty.v \
    ../rtl/wptr_full.v \
    ../rtl/async_fifo.v \
    ../tb/async_fifo_tb.v

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Compilation successful${NC}"
    echo ""
    echo "Running simulation..."
    vvp async_fifo_tb.vvp

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}Simulation completed${NC}"
        if [ -f async_fifo_tb.vcd ]; then
            echo "Waveform saved to: sim/async_fifo_tb.vcd"
            echo "View with: gtkwave sim/async_fifo_tb.vcd"
        fi
    else
        echo -e "${RED}Simulation failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}Compilation failed${NC}"
    exit 1
fi

echo "========================================="
echo "Done!"
echo "========================================="
