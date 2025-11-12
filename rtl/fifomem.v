//============================================================================
// fifomem.v - FIFO Memory Buffer Module
//============================================================================
// Description:
//   Dual-port synchronous RAM for FIFO storage
//   Can be replaced with vendor-specific memory macro for larger FIFOs
//
// Based on: Cummings SNUG 2002 - "Simulation and Synthesis Techniques
//           for Asynchronous FIFO Design"
//============================================================================

module fifomem #(
    parameter DATASIZE = 8,     // Memory data word width
    parameter ADDRSIZE = 4      // Number of memory address bits
)(
    output [DATASIZE-1:0] rdata,
    input  [DATASIZE-1:0] wdata,
    input  [ADDRSIZE-1:0] waddr,
    input  [ADDRSIZE-1:0] raddr,
    input                 wclken,
    input                 wfull,
    input                 wclk
);

    //------------------------------------------------------------------------
    // RTL Verilog memory model
    //------------------------------------------------------------------------
    localparam DEPTH = 1 << ADDRSIZE;

    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    // Asynchronous read
    assign rdata = mem[raddr];

    // Synchronous write
    always @(posedge wclk) begin
        if (wclken && !wfull) begin
            mem[waddr] <= wdata;
        end
    end

endmodule
