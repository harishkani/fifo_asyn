`timescale 1ns/1ps

//============================================================================
// sync_r2w.v - Read-to-Write Clock Domain Synchronizer
//============================================================================
// Description:
//   Two-stage synchronizer to pass read pointer from read clock domain
//   to write clock domain. Uses Gray code to ensure only one bit changes
//   at a time, avoiding metastability issues.
//
// Based on: Cummings SNUG 2002
//============================================================================

module sync_r2w #(
    parameter ADDRSIZE = 4
)(
    output reg [ADDRSIZE:0] wq2_rptr,    // Synchronized read pointer
    input      [ADDRSIZE:0] rptr,        // Read pointer from read domain
    input                   wclk,
    input                   wrst_n
);

    reg [ADDRSIZE:0] wq1_rptr;

    //------------------------------------------------------------------------
    // Two-stage synchronizer
    //------------------------------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            {wq2_rptr, wq1_rptr} <= 0;
        else
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end

endmodule
