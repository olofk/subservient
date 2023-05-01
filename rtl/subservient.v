/*
 * subservient.v : Toplevel for the subservient SoC
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module subservient
  #(//Memory parameters
    parameter memsize  = 512,
    parameter aw       = $clog2(memsize),
    //Enable CSR + interrupts
    parameter WITH_CSR = 0)
  (
   input wire 		i_clk,
   input wire 		i_rst,

   //SRAM interface
   output wire [aw-1:0] o_sram_waddr,
   output wire [7:0] 	o_sram_wdata,
   output wire 		o_sram_wen,
   output wire [aw-1:0] o_sram_raddr,
   input wire [7:0] 	i_sram_rdata,
   output wire 		o_sram_ren,

   //Debug interface
   input wire 		i_debug_mode,
   input wire [31:0] 	i_wb_dbg_adr,
   input wire [31:0] 	i_wb_dbg_dat,
   input wire [3:0] 	i_wb_dbg_sel,
   input wire 		i_wb_dbg_we ,
   input wire 		i_wb_dbg_stb,
   output wire [31:0] 	o_wb_dbg_rdt,
   output wire 		o_wb_dbg_ack,

   //External I/O
   output wire		o_sclk,
   output wire		o_cs_n,
   output wire		o_mosi,
   input wire		i_miso,
   output wire 		o_gpio);

   wire [31:0] 	wb_core_adr;
   wire [31:0] 	wb_core_dat;
   wire [3:0] 	wb_core_sel;
   wire 	wb_core_we;
   wire 	wb_core_stb;
   wire [31:0] 	wb_core_rdt;
   wire		wb_spi_ack;
   wire		wb_gpio_ack;
   wire 	wb_core_ack = wb_spi_ack | wb_gpio_ack;

   wire 	wb_gpio_rdt;
   wire [7:0]	wb_spi_rdt;
   
   assign wb_core_rdt = {24'd0, wb_core_adr[31] ? wb_spi_rdt : {7'd0,wb_gpio_rdt}};
   wire		wb_gpio_stb = wb_core_stb & !wb_core_adr[31];
   wire		wb_spi_stb  = wb_core_stb &  wb_core_adr[31];
   

   subservient_gpio gpio
     (.i_wb_clk (i_clk),
      .i_wb_rst (i_rst),
      .i_wb_dat (wb_core_dat[0]),
      .i_wb_we  (wb_core_we),
      .i_wb_stb (wb_gpio_stb),
      .o_wb_rdt (wb_gpio_rdt),
      .o_wb_ack (wb_gpio_ack),
      .o_gpio   (o_gpio));

   simple_spi spi
     (// Wishbone slave interface
      .clk_i  (i_clk),
      .rst_i  (i_rst),
      .adr_i  (wb_core_adr[4:2]),
      .dat_i  (wb_core_dat[7:0]),
      .we_i   (wb_core_we),
      .cyc_i  (1'b1),
      .stb_i  (wb_spi_stb),
      .dat_o  (wb_spi_rdt),
      .ack_o  (wb_spi_ack),
      .inta_o (),
      // SPI interface
      .sck_o  (o_sclk),
      .ss_o   (o_cs_n),
      .mosi_o (o_mosi),
      .miso_i (i_miso));
   
   subservient_core
     #(.memsize (memsize),
       .WITH_CSR (WITH_CSR))
   core
     (.i_clk       (i_clk),
      .i_rst       (i_rst),
      .i_timer_irq (1'b0),

      //SRAM interface
      .o_sram_waddr (o_sram_waddr),
      .o_sram_wdata (o_sram_wdata),
      .o_sram_wen   (o_sram_wen),
      .o_sram_raddr (o_sram_raddr),
      .i_sram_rdata (i_sram_rdata),
      .o_sram_ren   (o_sram_ren),

      //Debug interface
      .i_debug_mode (i_debug_mode),
      .i_wb_dbg_adr (i_wb_dbg_adr),
      .i_wb_dbg_dat (i_wb_dbg_dat),
      .i_wb_dbg_sel (i_wb_dbg_sel),
      .i_wb_dbg_we  (i_wb_dbg_we ),
      .i_wb_dbg_stb (i_wb_dbg_stb),
      .o_wb_dbg_rdt (o_wb_dbg_rdt),
      .o_wb_dbg_ack (o_wb_dbg_ack),

      //Peripheral interface
      .o_wb_adr (wb_core_adr),
      .o_wb_dat (wb_core_dat),
      .o_wb_sel (wb_core_sel),
      .o_wb_we  (wb_core_we) ,
      .o_wb_stb (wb_core_stb),
      .i_wb_rdt (wb_core_rdt),
      .i_wb_ack (wb_core_ack));

endmodule
