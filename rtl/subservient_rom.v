module wb_bootrom
  #(parameter DEPTH = 0,             // Memory size in bytes
    parameter WB_AW = $clog2(DEPTH), // Wishbone address width
    parameter MEMFILE = "")          // Initialization file
  (input 	     wb_clk_i,
   input 	     wb_rst_i,
   input [31:0]      wb_adr_i,
   input 	     wb_stb_i,
   output reg [31:0] wb_dat_o,
   output reg 	     wb_ack_o);

   reg [31:0] 	 mem[0:DEPTH/4-1];
   
   wire [WB_AW-1:0] adr = wb_adr_i[WB_AW-1:2];
   
   always @(posedge wb_clk_i) begin
      wb_ack_o <= wb_stb_i & !wb_ack_o;
      wb_dat_o <= mem[adr];
   end
		     
   initial
     if(MEMFILE == "")
       $display("%m : Warning! Memory is not initialized");
     else begin
	$display("Preloading boot ROM from %s", MEMFILE);
	$readmemh(MEMFILE, mem);
     end

endmodule
