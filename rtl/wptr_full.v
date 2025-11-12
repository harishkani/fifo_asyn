//============================================================================
// wptr_full.v - Write Pointer and Full Flag Generation
//============================================================================
// Description:
//   Write clock domain logic for:
//   - Gray code Style #2 counter (binary + Gray code registers)
//   - Full flag generation
//   - Memory write address generation
//
// Full Condition:
//   FIFO is full when:
//   1. Write and read pointer MSBs are different (wrapped one more time)
//   2. Write and read pointer 2nd MSBs are different
//   3. All other bits are equal
//
// Based on: Cummings SNUG 2002
//============================================================================

module wptr_full #(
    parameter ADDRSIZE = 4
)(
    output reg                 wfull,       // FIFO full flag
    output     [ADDRSIZE-1:0]  waddr,       // Write address to memory
    output reg [ADDRSIZE:0]    wptr,        // Gray code write pointer
    input      [ADDRSIZE:0]    wq2_rptr,    // Synchronized read pointer
    input                      winc,        // Write increment
    input                      wclk,
    input                      wrst_n
);

    //------------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------------
    reg  [ADDRSIZE:0] wbin;                 // Binary write pointer
    wire [ADDRSIZE:0] wgraynext;            // Next Gray code value
    wire [ADDRSIZE:0] wbinnext;             // Next binary value
    wire              wfull_val;            // Full flag value

    //------------------------------------------------------------------------
    // GRAYSTYLE2 pointer - Binary and Gray code registers
    //------------------------------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            {wbin, wptr} <= 0;
        else
            {wbin, wptr} <= {wbinnext, wgraynext};
    end

    //------------------------------------------------------------------------
    // Memory write-address pointer (binary)
    //------------------------------------------------------------------------
    assign waddr = wbin[ADDRSIZE-1:0];

    //------------------------------------------------------------------------
    // Binary pointer increment (only when not full)
    //------------------------------------------------------------------------
    assign wbinnext = wbin + (winc & ~wfull);

    //------------------------------------------------------------------------
    // Binary to Gray code conversion
    //------------------------------------------------------------------------
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    //------------------------------------------------------------------------
    // FIFO full when:
    //   - MSBs are different (wptr has wrapped one more time)
    //   - 2nd MSBs are different
    //   - All other bits are equal
    //
    // Simplified: wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
    //                            wq2_rptr[ADDRSIZE-2:0]}
    //------------------------------------------------------------------------
    assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
                                       wq2_rptr[ADDRSIZE-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wfull <= 1'b0;
        else
            wfull <= wfull_val;
    end

endmodule
