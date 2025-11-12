//============================================================================
// rptr_empty.v - Read Pointer and Empty Flag Generation
//============================================================================
// Description:
//   Read clock domain logic for:
//   - Gray code Style #2 counter (binary + Gray code registers)
//   - Empty flag generation
//   - Memory read address generation
//
// Empty Condition:
//   FIFO is empty when next read pointer equals synchronized write pointer
//
// Based on: Cummings SNUG 2002
//============================================================================

module rptr_empty #(
    parameter ADDRSIZE = 4
)(
    output reg                 rempty,      // FIFO empty flag
    output     [ADDRSIZE-1:0]  raddr,       // Read address to memory
    output reg [ADDRSIZE:0]    rptr,        // Gray code read pointer
    input      [ADDRSIZE:0]    rq2_wptr,    // Synchronized write pointer
    input                      rinc,        // Read increment
    input                      rclk,
    input                      rrst_n
);

    //------------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------------
    reg  [ADDRSIZE:0] rbin;                 // Binary read pointer
    wire [ADDRSIZE:0] rgraynext;            // Next Gray code value
    wire [ADDRSIZE:0] rbinnext;             // Next binary value
    wire              rempty_val;           // Empty flag value

    //------------------------------------------------------------------------
    // GRAYSTYLE2 pointer - Binary and Gray code registers
    //------------------------------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            {rbin, rptr} <= 0;
        else
            {rbin, rptr} <= {rbinnext, rgraynext};
    end

    //------------------------------------------------------------------------
    // Memory read-address pointer (binary)
    //------------------------------------------------------------------------
    assign raddr = rbin[ADDRSIZE-1:0];

    //------------------------------------------------------------------------
    // Binary pointer increment (only when not empty)
    //------------------------------------------------------------------------
    assign rbinnext = rbin + (rinc & ~rempty);

    //------------------------------------------------------------------------
    // Binary to Gray code conversion
    //------------------------------------------------------------------------
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    //------------------------------------------------------------------------
    // FIFO empty when next rptr == synchronized wptr
    //------------------------------------------------------------------------
    assign rempty_val = (rgraynext == rq2_wptr);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty <= 1'b1;
        else
            rempty <= rempty_val;
    end

endmodule
