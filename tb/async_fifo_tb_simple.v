//============================================================================
// async_fifo_tb_simple.v - Simplified Asynchronous FIFO Testbench
//============================================================================
// Description:
//   Clean testbench with better data tracking
//============================================================================

`timescale 1ns/1ps

module async_fifo_tb_simple;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter DSIZE = 8;
    parameter ASIZE = 4;
    parameter FIFO_DEPTH = 1 << ASIZE;

    //------------------------------------------------------------------------
    // Testbench signals
    //------------------------------------------------------------------------
    reg  [DSIZE-1:0] wdata;
    reg              winc;
    reg              wclk;
    reg              wrst_n;
    wire             wfull;

    wire [DSIZE-1:0] rdata;
    reg              rinc;
    reg              rclk;
    reg              rrst_n;
    wire             rempty;

    // Test control
    integer          error_count;
    integer          test_count;
    integer          i;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE)
    ) dut (
        .wdata   (wdata),
        .winc    (winc),
        .wclk    (wclk),
        .wrst_n  (wrst_n),
        .wfull   (wfull),
        .rdata   (rdata),
        .rinc    (rinc),
        .rclk    (rclk),
        .rrst_n  (rrst_n),
        .rempty  (rempty)
    );

    //------------------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------------------
    // Write clock: 50 MHz (20ns period)
    initial begin
        wclk = 0;
        forever #10 wclk = ~wclk;
    end

    // Read clock: 33 MHz (30ns period)
    initial begin
        rclk = 0;
        forever #15 rclk = ~rclk;
    end

    //------------------------------------------------------------------------
    // Test Sequence
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("async_fifo_tb_simple.vcd");
        $dumpvars(0, async_fifo_tb_simple);

        // Initialize
        error_count = 0;
        test_count = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;
        wrst_n = 0;
        rrst_n = 0;

        $display("\n========================================");
        $display("Asynchronous FIFO Testbench (Simple)");
        $display("========================================");
        $display("FIFO Configuration:");
        $display("  Data Width: %0d bits", DSIZE);
        $display("  FIFO Depth: %0d words", FIFO_DEPTH);
        $display("========================================\n");

        // Reset
        repeat(5) @(posedge wclk);
        wrst_n = 1;
        rrst_n = 1;
        repeat(5) @(posedge wclk);

        // Test 1: Write and read single word
        $display("[%0t] Test 1: Write and Read Single Word", $time);
        test_single_word();

        // Test 2: Write multiple, read multiple
        $display("[%0t] Test 2: Write 5 Words, Read 5 Words", $time);
        test_multiple_words();

        // Test 3: Fill FIFO
        $display("[%0t] Test 3: Fill FIFO to Capacity", $time);
        test_fill_fifo();

        // Test 4: Empty FIFO
        $display("[%0t] Test 4: Empty FIFO Completely", $time);
        test_empty_fifo();

        // Test 5: Concurrent read/write
        $display("[%0t] Test 5: Concurrent Operations", $time);
        test_concurrent();

        // Summary
        repeat(20) @(posedge wclk);
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Errors:      %0d", error_count);
        if (error_count == 0)
            $display("Status:      PASSED ✓");
        else
            $display("Status:      FAILED ✗");
        $display("========================================\n");

        $finish;
    end

    //------------------------------------------------------------------------
    // Test Tasks
    //------------------------------------------------------------------------

    // Test 1: Single word
    task test_single_word;
        reg [DSIZE-1:0] test_data;
        begin
            test_data = 8'hAA;

            // Write
            @(posedge wclk);
            winc = 1;
            wdata = test_data;
            @(posedge wclk);
            winc = 0;

            // Wait for synchronization
            repeat(5) @(posedge rclk);

            // Read - sample data BEFORE incrementing pointer
            @(posedge rclk);
            @(posedge rclk);  // Wait for data to be available

            // Check data while pointer is stable
            test_count = test_count + 1;
            if (rdata !== test_data) begin
                $display("  ERROR: Expected 0x%h, Got 0x%h", test_data, rdata);
                error_count = error_count + 1;
            end else begin
                $display("  PASS: Data matches (0x%h)", rdata);
            end

            // Now increment pointer
            rinc = 1;
            @(posedge rclk);
            rinc = 0;
            $display("");
        end
    endtask

    // Test 2: Multiple words
    task test_multiple_words;
        integer j;
        reg [DSIZE-1:0] expected;
        begin
            // Write 5 words
            for (j = 0; j < 5; j = j + 1) begin
                @(posedge wclk);
                winc = 1;
                wdata = 8'h10 + j;
                @(posedge wclk);
                winc = 0;
            end

            // Wait for synchronization
            repeat(5) @(posedge rclk);

            // Read and verify 5 words
            for (j = 0; j < 5; j = j + 1) begin
                expected = 8'h10 + j;
                @(posedge rclk);

                // Sample data before incrementing
                test_count = test_count + 1;
                if (rdata !== expected) begin
                    $display("  ERROR: Word %0d - Expected 0x%h, Got 0x%h", j, expected, rdata);
                    error_count = error_count + 1;
                end

                // Increment pointer
                rinc = 1;
                @(posedge rclk);
                rinc = 0;
            end
            $display("  Verified 5 words");
            $display("");
        end
    endtask

    // Test 3: Fill FIFO
    task test_fill_fifo;
        integer j;
        begin
            // Fill FIFO
            for (j = 0; j < FIFO_DEPTH; j = j + 1) begin
                @(posedge wclk);
                if (!wfull) begin
                    winc = 1;
                    wdata = 8'h20 + j;
                    @(posedge wclk);
                    winc = 0;
                end
            end

            // Check full flag
            repeat(5) @(posedge wclk);
            test_count = test_count + 1;
            if (!wfull) begin
                $display("  ERROR: FIFO should be full");
                error_count = error_count + 1;
            end else begin
                $display("  PASS: FIFO is full");
            end

            // Try to write when full
            @(posedge wclk);
            winc = 1;
            wdata = 8'hFF;
            @(posedge wclk);
            winc = 0;

            $display("");
        end
    endtask

    // Test 4: Empty FIFO
    task test_empty_fifo;
        integer j;
        reg [DSIZE-1:0] expected;
        begin
            // Read all words
            repeat(5) @(posedge rclk);
            for (j = 0; j < FIFO_DEPTH; j = j + 1) begin
                expected = 8'h20 + j;
                if (!rempty) begin
                    @(posedge rclk);

                    // Sample data before incrementing
                    test_count = test_count + 1;
                    if (rdata !== expected) begin
                        $display("  ERROR: Word %0d - Expected 0x%h, Got 0x%h", j, expected, rdata);
                        error_count = error_count + 1;
                    end

                    // Increment pointer
                    rinc = 1;
                    @(posedge rclk);
                    rinc = 0;
                end
            end

            // Check empty flag
            repeat(5) @(posedge rclk);
            test_count = test_count + 1;
            if (!rempty) begin
                $display("  ERROR: FIFO should be empty");
                error_count = error_count + 1;
            end else begin
                $display("  PASS: FIFO is empty");
            end

            $display("");
        end
    endtask

    // Test 5: Concurrent operations
    task test_concurrent;
        integer write_count, read_count;
        reg [DSIZE-1:0] expected_val;
        begin
            write_count = 0;
            read_count = 0;

            fork
                // Write process
                begin
                    for (write_count = 0; write_count < 8; write_count = write_count + 1) begin
                        @(posedge wclk);
                        if (!wfull) begin
                            winc = 1;
                            wdata = 8'h30 + write_count;
                        end else begin
                            winc = 0;
                        end
                        @(posedge wclk);
                        winc = 0;
                    end
                end

                // Read process (start after some delay)
                begin
                    repeat(10) @(posedge rclk);
                    for (read_count = 0; read_count < 8; read_count = read_count + 1) begin
                        expected_val = 8'h30 + read_count;
                        wait (!rempty);  // Wait for data
                        @(posedge rclk);

                        // Sample data before incrementing
                        test_count = test_count + 1;
                        if (rdata !== expected_val) begin
                            $display("  ERROR: Word %0d - Expected 0x%h, Got 0x%h",
                                     read_count, expected_val, rdata);
                            error_count = error_count + 1;
                        end

                        // Increment pointer
                        rinc = 1;
                        @(posedge rclk);
                        rinc = 0;
                    end
                end
            join

            $display("  Concurrent test completed");
            $display("");
        end
    endtask

    //------------------------------------------------------------------------
    // Timeout watchdog
    //------------------------------------------------------------------------
    initial begin
        #500000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
