/*
 * subservient_tb.v : Verilog testbench for the subservient SoC
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module subservient_tb;

   parameter memfile = "";
   parameter memsize = 8192;
   parameter with_csr = 0;
   parameter aw    = $clog2(memsize);

   reg clk = 1'b0;
   reg rst = 1'b1;

   wire [aw-1:0] sram_waddr;
   wire [7:0] 	 sram_wdata;
   wire 	 sram_wen;
   wire [aw-1:0] sram_raddr;
   wire [7:0] 	 sram_rdata;
   wire 	 sram_ren;

   wire q;

   always  #5 clk <= !clk;
   initial #62 rst <= 1'b0;

   vlog_tb_utils vtu();

   integer baudrate = 0;
   initial begin
      if ($value$plusargs("uart_baudrate=%d", baudrate))
	$display("UART decoder using baud rate %0d", baudrate);
      else
	forever
	  @(q) $display("%0t output o_gpio is %s", $time, q ? "ON" : "OFF");

   end

   reg [1023:0] firmware_file;

   initial begin
      if ($value$plusargs("firmware=%s", firmware_file)) begin
	 $display("Writing %0s to SRAM", firmware_file);
	 $readmemh(firmware_file, memory.mem);
      end else
	$display("No application to load. SRAM will be empty");

      repeat (10) @(posedge clk);
   end

   uart_decoder uart_decoder (baudrate, q);

   subservient_generic_ram
     #(.depth (memsize))
   memory
     (.i_clk   (clk),
      .i_rst   (rst),
      .i_waddr (sram_waddr),
      .i_wdata (sram_wdata),
      .i_wen   (sram_wen),
      .i_raddr (sram_raddr),
      .o_rdata (sram_rdata),
      .i_ren   (sram_ren));

   //Note: This should probably be a proper assert instead
   always @(posedge clk)
     if (sram_ren & sram_wen)
       $display("$0t Error: Simultaneous SRAM read and write", $time);

   subservient
     #(.memsize  (memsize),
       .WITH_CSR (with_csr))
   dut
     (// Clock & reset
      .i_clk (clk),
      .i_rst (rst),

      //SRAM interface
      .o_sram_waddr (sram_waddr),
      .o_sram_wdata (sram_wdata),
      .o_sram_wen   (sram_wen),
      .o_sram_raddr (sram_raddr),
      .i_sram_rdata (sram_rdata),
      .o_sram_ren   (sram_ren),

      // External I/O
      .o_gpio (q));

endmodule
