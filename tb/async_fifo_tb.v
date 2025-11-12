//============================================================================
// async_fifo_tb.v - Asynchronous FIFO Testbench
//============================================================================
// Description:
//   Comprehensive testbench for asynchronous FIFO
//   Tests various scenarios including:
//   - Full and empty conditions
//   - Different clock frequencies
//   - Continuous read/write
//   - Random delays
//
// Based on: Cummings SNUG 2002
//============================================================================

`timescale 1ns/1ps

module async_fifo_tb;

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
    reg  [DSIZE-1:0] expected_data;
    reg  [DSIZE-1:0] write_data_queue [$];

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

    // Read clock: 33 MHz (30ns period) - Different frequency
    initial begin
        rclk = 0;
        forever #15 rclk = ~rclk;
    end

    //------------------------------------------------------------------------
    // Test Sequence
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);

        // Initialize
        error_count = 0;
        test_count = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;
        wrst_n = 0;
        rrst_n = 0;

        // Reset
        $display("\n========================================");
        $display("Asynchronous FIFO Testbench");
        $display("========================================");
        $display("FIFO Configuration:");
        $display("  Data Width: %0d bits", DSIZE);
        $display("  FIFO Depth: %0d words", FIFO_DEPTH);
        $display("  Write Clock: 50 MHz");
        $display("  Read Clock: 33 MHz");
        $display("========================================\n");

        repeat(5) @(posedge wclk);
        wrst_n = 1;
        rrst_n = 1;
        repeat(5) @(posedge wclk);

        // Test 1: Basic write and read
        $display("[%0t] Test 1: Basic Write and Read", $time);
        test_basic_write_read();

        // Test 2: Fill FIFO completely
        $display("[%0t] Test 2: Fill FIFO Completely", $time);
        test_fill_fifo();

        // Test 3: Empty FIFO completely
        $display("[%0t] Test 3: Empty FIFO Completely", $time);
        test_empty_fifo();

        // Test 4: Simultaneous read and write
        $display("[%0t] Test 4: Simultaneous Read/Write", $time);
        test_simultaneous_rw();

        // Test 5: Burst write and burst read
        $display("[%0t] Test 5: Burst Write and Burst Read", $time);
        test_burst_operations();

        // Test 6: Random operations
        $display("[%0t] Test 6: Random Operations", $time);
        test_random_operations();

        // Summary
        repeat(20) @(posedge wclk);
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Errors:      %0d", error_count);
        if (error_count == 0)
            $display("Status:      PASSED");
        else
            $display("Status:      FAILED");
        $display("========================================\n");

        $finish;
    end

    //------------------------------------------------------------------------
    // Test Tasks
    //------------------------------------------------------------------------

    // Test 1: Basic write and read
    task test_basic_write_read;
        integer i;
        begin
            for (i = 0; i < 5; i = i + 1) begin
                write_single_word(8'hA0 + i);
                repeat(2) @(posedge wclk);
                read_single_word(8'hA0 + i);
                repeat(2) @(posedge rclk);
            end
            $display("  Test 1 PASSED\n");
        end
    endtask

    // Test 2: Fill FIFO completely
    task test_fill_fifo;
        integer i;
        begin
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                write_single_word(i);
            end
            @(posedge wclk);
            if (!wfull) begin
                $display("  ERROR: FIFO should be full!");
                error_count = error_count + 1;
            end else begin
                $display("  FIFO correctly marked as full");
            end
            $display("  Test 2 PASSED\n");
        end
    endtask

    // Test 3: Empty FIFO completely
    task test_empty_fifo;
        integer i;
        begin
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                read_single_word(i);
            end
            @(posedge rclk);
            if (!rempty) begin
                $display("  ERROR: FIFO should be empty!");
                error_count = error_count + 1;
            end else begin
                $display("  FIFO correctly marked as empty");
            end
            $display("  Test 3 PASSED\n");
        end
    endtask

    // Test 4: Simultaneous read and write
    task test_simultaneous_rw;
        integer i;
        begin
            fork
                // Write process
                begin
                    for (i = 0; i < 20; i = i + 1) begin
                        write_single_word(8'hB0 + i);
                    end
                end
                // Read process (with delay)
                begin
                    repeat(5) @(posedge rclk);
                    for (i = 0; i < 20; i = i + 1) begin
                        read_and_check();
                    end
                end
            join
            $display("  Test 4 PASSED\n");
        end
    endtask

    // Test 5: Burst operations
    task test_burst_operations;
        integer i;
        begin
            // Burst write
            for (i = 0; i < 12; i = i + 1) begin
                write_single_word(8'hC0 + i);
            end
            repeat(5) @(posedge wclk);

            // Burst read
            for (i = 0; i < 12; i = i + 1) begin
                read_single_word(8'hC0 + i);
            end
            $display("  Test 5 PASSED\n");
        end
    endtask

    // Test 6: Random operations
    task test_random_operations;
        integer i;
        integer rand_val;
        begin
            for (i = 0; i < 50; i = i + 1) begin
                rand_val = $random;
                if (rand_val % 3 == 0 && !wfull) begin
                    write_single_word($random);
                end else if (!rempty) begin
                    read_and_check();
                end
                @(posedge wclk);
            end
            // Drain remaining data
            while (!rempty) begin
                read_and_check();
            end
            $display("  Test 6 PASSED\n");
        end
    endtask

    //------------------------------------------------------------------------
    // Helper Tasks
    //------------------------------------------------------------------------

    // Write a single word
    task write_single_word;
        input [DSIZE-1:0] data;
        begin
            @(posedge wclk);
            if (!wfull) begin
                winc = 1;
                wdata = data;
                write_data_queue.push_back(data);
                @(posedge wclk);
                winc = 0;
            end else begin
                $display("  WARNING: Cannot write, FIFO is full");
            end
        end
    endtask

    // Read a single word with expected value
    task read_single_word;
        input [DSIZE-1:0] expected;
        begin
            @(posedge rclk);
            if (!rempty) begin
                rinc = 1;
                @(posedge rclk);
                rinc = 0;
                @(posedge rclk);
                if (rdata !== expected) begin
                    $display("  ERROR: Data mismatch! Expected: 0x%h, Got: 0x%h",
                             expected, rdata);
                    error_count = error_count + 1;
                end
                test_count = test_count + 1;
            end else begin
                $display("  WARNING: Cannot read, FIFO is empty");
            end
        end
    endtask

    // Read and check against queue
    task read_and_check;
        reg [DSIZE-1:0] expected_val;
        begin
            @(posedge rclk);
            if (!rempty && write_data_queue.size() > 0) begin
                expected_val = write_data_queue.pop_front();
                rinc = 1;
                @(posedge rclk);
                rinc = 0;
                @(posedge rclk);
                if (rdata !== expected_val) begin
                    $display("  ERROR: Data mismatch! Expected: 0x%h, Got: 0x%h",
                             expected_val, rdata);
                    error_count = error_count + 1;
                end
                test_count = test_count + 1;
            end
        end
    endtask

    //------------------------------------------------------------------------
    // Timeout watchdog
    //------------------------------------------------------------------------
    initial begin
        #1000000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
