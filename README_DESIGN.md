# Asynchronous FIFO Design

## Overview

This is a clean, synthesizable asynchronous FIFO design based on Clifford Cummings' seminal SNUG 2002 paper: *"Simulation and Synthesis Techniques for Asynchronous FIFO Design"*.

The design safely passes data between two asynchronous clock domains using Gray code pointers to avoid metastability issues.

## Key Features

- **Parameterized Design**: Configurable data width and FIFO depth
- **Gray Code Synchronization**: Only one bit changes at a time during pointer updates
- **Dual Clock Domains**: Independent read and write clocks
- **Registered Outputs**: All outputs registered for clean timing
- **Synthesizable RTL**: Clean, modular design ready for synthesis
- **Full/Empty Detection**: Accurate flag generation with pessimistic removal
- **Style #2 Implementation**: Uses both binary and Gray code pointers for efficiency

## Architecture

### Block Diagram

```
                  ┌─────────────────────────────────────┐
    wdata[7:0] ──→│                                     │
    winc       ──→│         Write Clock Domain          │
    wclk       ──→│                                     │
    wrst_n     ──→│  ┌──────────────────────────────┐  │
                  │  │   wptr_full.v                │  │
                  │  │  - Write pointer (Gray code) │  │
    wfull      ←──│  │  - Full flag generation      │  │──→ waddr
                  │  └──────────────────────────────┘  │
                  │              │                      │
                  │              │ wptr (Gray)          │
                  │              ↓                      │
                  │  ┌──────────────────────────────┐  │
                  │  │   sync_w2r.v                 │  │
                  │  │  - 2-stage synchronizer      │  │
                  │  └──────────────────────────────┘  │
                  └──────────────┬──────────────────────┘
                                 │ rq2_wptr
                  ┌──────────────┴──────────────────────┐
                  │         fifomem.v                   │
                  │      (Dual-port RAM)                │
                  │   waddr ──→ [Memory] ──→ raddr      │
                  │   wdata ──→  Array   ──→ rdata      │
                  └──────────────┬──────────────────────┘
                                 │ wq2_rptr
                  ┌──────────────┴──────────────────────┐
                  │  ┌──────────────────────────────┐  │
                  │  │   sync_r2w.v                 │  │
                  │  │  - 2-stage synchronizer      │  │
                  │  └──────────────────────────────┘  │
                  │              ↑                      │
                  │              │ rptr (Gray)          │
    raddr     ←───│              │                      │
                  │  ┌──────────────────────────────┐  │
                  │  │   rptr_empty.v               │  │
    rempty    ←───│  │  - Read pointer (Gray code)  │  │
                  │  │  - Empty flag generation     │  │
    rdata[7:0]←───│  └──────────────────────────────┘  │
    rinc      ───→│                                     │
    rclk      ───→│         Read Clock Domain           │
    rrst_n    ───→│                                     │
                  └─────────────────────────────────────┘
```

## Module Descriptions

### 1. async_fifo.v (Top Level)
- **Purpose**: Top-level wrapper that instantiates all sub-modules
- **Clock Domains**: Both write and read
- **Function**: Connects all modules with proper signal routing

### 2. fifomem.v (Memory Buffer)
- **Purpose**: Dual-port synchronous RAM for FIFO storage
- **Clock Domain**: Write clock
- **Features**:
  - Asynchronous read
  - Synchronous write
  - Can be replaced with vendor RAM macro

### 3. sync_r2w.v (Read-to-Write Synchronizer)
- **Purpose**: Synchronize read pointer into write clock domain
- **Clock Domain**: Write clock
- **Implementation**: 2-stage flip-flop synchronizer
- **Input**: Gray code read pointer (rptr)
- **Output**: Synchronized read pointer (wq2_rptr)

### 4. sync_w2r.v (Write-to-Read Synchronizer)
- **Purpose**: Synchronize write pointer into read clock domain
- **Clock Domain**: Read clock
- **Implementation**: 2-stage flip-flop synchronizer
- **Input**: Gray code write pointer (wptr)
- **Output**: Synchronized write pointer (rq2_wptr)

### 5. wptr_full.v (Write Pointer & Full Logic)
- **Purpose**: Generate write pointer and detect full condition
- **Clock Domain**: Write clock
- **Features**:
  - Gray code Style #2 counter (binary + Gray registers)
  - Binary pointer for memory addressing
  - Full flag generation

**Full Condition:**
```
FIFO is full when:
1. wptr[MSB] != rptr[MSB]         (write wrapped one more time)
2. wptr[MSB-1] != rptr[MSB-1]     (2nd MSB differs)
3. wptr[MSB-2:0] == rptr[MSB-2:0] (all other bits equal)
```

### 6. rptr_empty.v (Read Pointer & Empty Logic)
- **Purpose**: Generate read pointer and detect empty condition
- **Clock Domain**: Read clock
- **Features**:
  - Gray code Style #2 counter (binary + Gray registers)
  - Binary pointer for memory addressing
  - Empty flag generation

**Empty Condition:**
```
FIFO is empty when:
rptr[MSB:0] == wptr[MSB:0]  (all bits equal)
```

## Gray Code Technique

### Why Gray Code?

Gray code ensures only **one bit changes** at a time during pointer increments. This is crucial for clock domain crossing because:

1. **Avoids Metastability**: Multiple simultaneous bit changes can cause metastability in synchronizers
2. **Safe Synchronization**: Single bit changes are safely synchronized through 2-stage synchronizers
3. **No Handshaking Needed**: Unlike binary counters, Gray codes don't need ready/ack handshaking

### Gray Code Conversion

**Binary to Gray:**
```verilog
gray = (binary >> 1) ^ binary;
```

**Gray to Binary:**
```verilog
binary[n] = gray[n];
for (i = n-1; i >= 0; i--)
    binary[i] = binary[i+1] ^ gray[i];
```

### Style #2 Implementation

This design uses Gray code counter Style #2:
- **Binary register**: Used for easy incrementing and memory addressing
- **Gray register**: Used for clock domain crossing
- **Advantages**:
  - No need for Gray-to-binary conversion
  - Direct binary addressing of memory
  - Easy to calculate almost-full/empty (if needed)

## Full and Empty Generation

### Empty Detection (Read Clock Domain)

```
Empty = (rptr_gray == wptr_gray_synchronized)
```

- Detected when read pointer catches up to synchronized write pointer
- **Accurate assertion**: Happens immediately when FIFO becomes empty
- **Pessimistic removal**: Removed 2 rclk cycles after write occurs

### Full Detection (Write Clock Domain)

```
Full = (wptr_gray == {~rptr_gray_sync[MSB:MSB-1], rptr_gray_sync[MSB-2:0]})
```

- Detected when write pointer catches up to synchronized read pointer
- Need to invert top 2 MSBs to distinguish full from empty
- **Accurate assertion**: Happens immediately when FIFO becomes full
- **Pessimistic removal**: Removed 2 wclk cycles after read occurs

### Why Extra Pointer Bit?

An (n+1)-bit pointer is used for a 2^n depth FIFO:
- **n bits**: Address the memory locations (0 to 2^n-1)
- **1 extra bit (MSB)**: Distinguishes full from empty
  - When MSBs differ: write pointer has wrapped one more time than read (full condition)
  - When MSBs match: pointers have wrapped same number of times

## Design Considerations

### 1. Pointer Comparison

**Empty:** Easy - all bits equal
```
empty = (rptr == wptr_sync)
```

**Full:** Tricky - need to handle wrap-around
```
full = (wptr[MSB] != rptr[MSB]) &&
       (wptr[MSB-1] != rptr[MSB-1]) &&
       (wptr[MSB-2:0] == rptr[MSB-2:0])
```

### 2. Different Clock Speeds

The design works with any clock speed ratio:
- **Faster write clock**: Full detection is immediate, empty removal is pessimistic
- **Faster read clock**: Empty detection is immediate, full removal is pessimistic
- **No overflow/underflow**: Impossible due to synchronization technique

### 3. Metastability

Metastability is addressed through:
- **Gray code pointers**: Only one bit changes at a time
- **2-stage synchronizers**: MTBF (Mean Time Between Failures) is acceptably high
- **Registered outputs**: All status flags are registered

### 4. Reset Strategy

- **Separate resets**: Independent reset for each clock domain
- **Asynchronous assertion**: Reset asserts asynchronously
- **Synchronous deassertion**: Reset removes synchronously to clock
- **Initial states**:
  - Both pointers reset to 0
  - Empty flag set to 1
  - Full flag set to 0

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| DSIZE     | 8       | Data bus width in bits |
| ASIZE     | 4       | Address bus width (depth = 2^ASIZE) |

**Examples:**
- ASIZE=4 → 16-word FIFO
- ASIZE=8 → 256-word FIFO
- ASIZE=10 → 1024-word FIFO

## Ports

### Write Clock Domain

| Port    | Direction | Width      | Description |
|---------|-----------|------------|-------------|
| wdata   | Input     | DSIZE      | Write data |
| winc    | Input     | 1          | Write increment (enable) |
| wclk    | Input     | 1          | Write clock |
| wrst_n  | Input     | 1          | Write reset (active low) |
| wfull   | Output    | 1          | FIFO full flag |

### Read Clock Domain

| Port    | Direction | Width      | Description |
|---------|-----------|------------|-------------|
| rdata   | Output    | DSIZE      | Read data |
| rinc    | Input     | 1          | Read increment (enable) |
| rclk    | Input     | 1          | Read clock |
| rrst_n  | Input     | 1          | Read reset (active low) |
| rempty  | Output    | 1          | FIFO empty flag |

## Usage Example

```verilog
// Instantiate a 32-bit wide, 256-deep FIFO
async_fifo #(
    .DSIZE(32),    // 32-bit data
    .ASIZE(8)      // 256-word depth
) my_fifo (
    // Write interface
    .wdata  (write_data),
    .winc   (write_enable),
    .wclk   (write_clock),
    .wrst_n (write_reset_n),
    .wfull  (fifo_full),

    // Read interface
    .rdata  (read_data),
    .rinc   (read_enable),
    .rclk   (read_clock),
    .rrst_n (read_reset_n),
    .rempty (fifo_empty)
);
```

## Simulation

A comprehensive testbench is provided in `tb/async_fifo_tb.v` that tests:

1. **Basic operations**: Simple write and read
2. **Full condition**: Fill FIFO to capacity
3. **Empty condition**: Drain FIFO completely
4. **Simultaneous R/W**: Concurrent operations
5. **Burst operations**: Rapid writes followed by rapid reads
6. **Random operations**: Stress test with random patterns

### Running the Testbench

```bash
# Using Icarus Verilog
iverilog -o async_fifo_tb.vvp -s async_fifo_tb \
    rtl/async_fifo.v \
    rtl/fifomem.v \
    rtl/sync_r2w.v \
    rtl/sync_w2r.v \
    rtl/rptr_empty.v \
    rtl/wptr_full.v \
    tb/async_fifo_tb.v

vvp async_fifo_tb.vvp

# View waveforms
gtkwave async_fifo_tb.vcd
```

## Synthesis Notes

### For ASIC

1. **Memory**: Replace `fifomem.v` with vendor memory compiler macro
2. **Clock domains**: Use separate synthesis scripts for each domain
3. **False paths**: Set false paths on cross-domain signals:
   ```tcl
   set_false_path -from [get_pins sync_r2w/*wq1_rptr*/Q]
   set_false_path -from [get_pins sync_w2r/*rq1_wptr*/Q]
   ```

### For FPGA

1. **Memory**: Can use inferred RAM or instantiate block RAM
2. **Synchronizers**: Some tools require specific synchronizer attributes:
   ```verilog
   (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] wq1_rptr;
   (* ASYNC_REG = "TRUE" *) reg [ASIZE:0] wq2_rptr;
   ```

## Timing Analysis

### Critical Paths

1. **Write domain**:
   - Binary increment → Gray conversion → Register
   - Full flag comparison → Register

2. **Read domain**:
   - Binary increment → Gray conversion → Register
   - Empty flag comparison → Register

### Clock Domain Crossing

All CDC paths are through 2-stage synchronizers:
- **Write domain**: `rptr` → `wq1_rptr` → `wq2_rptr`
- **Read domain**: `wptr` → `rq1_wptr` → `rq2_wptr`

Set these as false paths in STA (Static Timing Analysis).

## Advantages Over Binary Pointer Approach

| Aspect | Gray Code | Binary + Handshake |
|--------|-----------|-------------------|
| Latency | 2 clock cycles | 4+ clock cycles |
| Hardware | n pointers + sync | n pointers + sync + handshake logic |
| Flexibility | Power-of-2 depths | Any depth |
| Complexity | Medium | Higher |

## Known Limitations

1. **FIFO Depth**: Must be power of 2 (2^ASIZE)
2. **Almost Full/Empty**: Not implemented (can be added)
3. **Flags**: Only full and empty (no count/level indicators)
4. **Memory**: Simple inference (vendor RAM may be better for large FIFOs)

## Future Enhancements

Possible improvements:
- Add almost-full and almost-empty flags
- Add programmable threshold flags
- Add FIFO count output
- Add first-word fall-through mode
- Add overflow/underflow error flags

## References

1. Clifford E. Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design," SNUG 2002
2. Clifford E. Cummings and Peter Alfke, "Simulation and Synthesis Techniques for Asynchronous FIFO Design with Asynchronous Pointer Comparisons," SNUG 2002
3. Frank Gray, "Pulse Code Communication," U.S. Patent 2,632,058, March 17, 1953

## License

This design is based on publicly available research papers and is provided for educational purposes.

## Author

Design based on Clifford Cummings' SNUG 2002 paper.
Implementation: 2025
