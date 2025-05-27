`timescale 1ns/1ps
module tb_PISO;

  parameter SIZE_DATA_IN = 16;
  parameter SIZE_DATA_OUT = 2;

  logic i_clk, i_rst_n, i_start;
  logic [SIZE_DATA_IN-1:0] i_data;
  logic [SIZE_DATA_OUT-1:0] o_data;
  logic o_valid, o_done;

  // Clock generation
  always #10 i_clk = ~i_clk;

  // Instantiate the PISO module
  PISO #(
      .SIZE_DATA_IN (SIZE_DATA_IN),
      .SIZE_DATA_OUT(SIZE_DATA_OUT)
  ) uut (
      .i_clk      (i_clk),
      .i_rst_n    (i_rst_n),
      .i_start    (i_start),
      .i_data     (i_data),
      .o_data     (o_data),
      .o_valid    (o_valid),
      .o_done     (o_done)
  );

  // VCD dump for waveform analysis
  initial begin
      $dumpfile("tb_PISO.vcd");
      $dumpvars(0, tb_PISO);
  end

  // Task to display signals
  task display_signals;
      $display("Time = %t \t| i_start = %b \t| i_data = %b \t| o_data = %b \t| o_valid = %b \t| o_done = %b",
               $time, i_start, i_data, o_data, o_valid, o_done);
  endtask

  // Task to run a test case with given inputs
  task run_test_case(input string test_name, logic rst_n, logic start, logic [SIZE_DATA_IN-1:0] data, integer cycles);
      $display("========== %s =========", test_name);
      i_rst_n = rst_n;
      i_start = start;
      i_data = data;
      #20; // Wait for signal stabilization
      if (!rst_n) begin
          #20;
          i_rst_n = 1'b1; // Release reset if needed
      end
      repeat (cycles) begin
          @(posedge i_clk);
          display_signals();
          if (o_done) begin
              $display("Done processing data.");
              @(posedge i_clk);
              break; // Exit loop when done
          end
      end
  endtask

  // Main test sequence
  initial begin
      // Initialize signals
      i_clk = 1'b0;
      i_rst_n = 1'b0;
      i_start = 1'b0;
      i_data = 16'h0000;

      // Test Case 1: Reset and Start
      run_test_case("Test Case 1: Reset and Start", 1'b0, 1'b0, 16'h1234, 10);

      #100; // Inter-test delay

      // Test Case 2: Test Output After Reset
      run_test_case("Test Case 2: Test Output After Reset", 1'b0, 1'b1, 16'h1234, 10);

      #100; // Inter-test delay

      // Test Case 3: Change Data When Start is High
      run_test_case("Test Case 3: Change Data When Start is High - Data = 0x1234", 1'b0, 1'b1, 16'h1234, 2);
      run_test_case("Test Case 3: Change Data When Start is High - Data = 0x5678", 1'b1, 1'b1, 16'h5678, 8);
      
      #100; // Inter-test delay

      // Test Case 4: Change Start Signal While Data is Being Processed
      $display("========== Test Case 4: Change Start Signal While Data is Being Processed =========");
      i_start = 1'b0;
      #20;
      i_start = 1'b1;
      i_data = 16'h5678;
      repeat (5) begin
          @(posedge i_clk);
          display_signals();
          if (o_done) begin
              $display("Done processing new data.");
              @(posedge i_clk);
              break;
          end
      end
      i_start = 1'b0;
      repeat (5) begin
          @(posedge i_clk);
          display_signals();
          if (o_done) begin
              $display("Done processing new data.");
              @(posedge i_clk);
              break;
          end
      end
      
      #100;

      // Finish simulation
      $display("Simulation completed.");
      $finish;
  end

endmodule
