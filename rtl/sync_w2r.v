`timescale 1ns/1ps

//============================================================================
// sync_w2r.v - Write-to-Read Clock Domain Synchronizer
//============================================================================
// Description:
//   Two-stage synchronizer to pass write pointer from write clock domain
//   to read clock domain. Uses Gray code to ensure only one bit changes
//   at a time, avoiding metastability issues.
//
// Based on: Cummings SNUG 2002
//============================================================================

module sync_w2r #(
    parameter ADDRSIZE = 4
)(
    output reg [ADDRSIZE:0] rq2_wptr,    // Synchronized write pointer
    input      [ADDRSIZE:0] wptr,        // Write pointer from write domain
    input                   rclk,
    input                   rrst_n
);

    reg [ADDRSIZE:0] rq1_wptr;

    //------------------------------------------------------------------------
    // Two-stage synchronizer
    //------------------------------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            {rq2_wptr, rq1_wptr} <= 0;
        else
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end

endmodule
