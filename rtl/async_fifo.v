`timescale 1ns/1ps

//============================================================================
// async_fifo.v - Asynchronous FIFO Top Module
//============================================================================
// Description:
//   Top-level wrapper for asynchronous FIFO design
//   Safely passes data between two asynchronous clock domains using
//   Gray code pointers for synchronization
//
// Features:
//   - Parameterized data width and depth
//   - Gray code pointer synchronization
//   - Registered full and empty flags
//   - Synthesizable RTL design
//   - Separate reset signals for each clock domain
//
// Design Methodology:
//   Based on Clifford Cummings SNUG 2002 paper:
//   "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
//
// Parameters:
//   DSIZE - Data width (default: 8 bits)
//   ASIZE - Address width (default: 4 bits = 16 word FIFO)
//
// Author: Based on Cummings SNUG 2002
// Date: 2025
//============================================================================

module async_fifo #(
    parameter DSIZE = 8,        // Data bus width
    parameter ASIZE = 4         // Address bus width (FIFO depth = 2^ASIZE)
)(
    // Write clock domain
    input  [DSIZE-1:0] wdata,   // Write data
    input              winc,    // Write increment (write enable)
    input              wclk,    // Write clock
    input              wrst_n,  // Write reset (active low)
    output             wfull,   // FIFO full flag

    // Read clock domain
    output [DSIZE-1:0] rdata,   // Read data
    input              rinc,    // Read increment (read enable)
    input              rclk,    // Read clock
    input              rrst_n,  // Read reset (active low)
    output             rempty   // FIFO empty flag
);

    //------------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------------
    wire [ASIZE-1:0] waddr;         // Write address to memory
    wire [ASIZE-1:0] raddr;         // Read address from memory
    wire [ASIZE:0]   wptr;          // Write pointer (Gray code)
    wire [ASIZE:0]   rptr;          // Read pointer (Gray code)
    wire [ASIZE:0]   wq2_rptr;      // Synchronized read pointer (in write domain)
    wire [ASIZE:0]   rq2_wptr;      // Synchronized write pointer (in read domain)

    //------------------------------------------------------------------------
    // Module Instantiations
    //------------------------------------------------------------------------

    // Synchronize read pointer to write clock domain
    sync_r2w #(ASIZE) sync_r2w_inst (
        .wq2_rptr   (wq2_rptr),
        .rptr       (rptr),
        .wclk       (wclk),
        .wrst_n     (wrst_n)
    );

    // Synchronize write pointer to read clock domain
    sync_w2r #(ASIZE) sync_w2r_inst (
        .rq2_wptr   (rq2_wptr),
        .wptr       (wptr),
        .rclk       (rclk),
        .rrst_n     (rrst_n)
    );

    // FIFO memory buffer
    fifomem #(DSIZE, ASIZE) fifomem_inst (
        .rdata      (rdata),
        .wdata      (wdata),
        .waddr      (waddr),
        .raddr      (raddr),
        .wclken     (winc),
        .wfull      (wfull),
        .wclk       (wclk)
    );

    // Read pointer and empty flag generation
    rptr_empty #(ASIZE) rptr_empty_inst (
        .rempty     (rempty),
        .raddr      (raddr),
        .rptr       (rptr),
        .rq2_wptr   (rq2_wptr),
        .rinc       (rinc),
        .rclk       (rclk),
        .rrst_n     (rrst_n)
    );

    // Write pointer and full flag generation
    wptr_full #(ASIZE) wptr_full_inst (
        .wfull      (wfull),
        .waddr      (waddr),
        .wptr       (wptr),
        .wq2_rptr   (wq2_rptr),
        .winc       (winc),
        .wclk       (wclk),
        .wrst_n     (wrst_n)
    );

endmodule
