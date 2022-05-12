module subservient_dbg_if
  #(parameter dbg_aw  = 0,
    parameter core_id = 0)
   (input wire 	       i_clk,
    input wire 	       i_rst,
    input wire 	       i_dbg_data,
    input wire 	       i_dbg_valid,
    output wire        o_dbg_data,
    output wire [31:0] o_wb_adr,
    output wire [31:0] o_wb_dat,
    output wire [3:0]  o_wb_sel,
    output wire        o_wb_we ,
    output wire        o_wb_stb,
    input wire [31:0]  i_wb_rdt,
    input wire 	       i_wb_ack);

   localparam sreg_len = dbg_aw+4+32+32;

   reg [sreg_len-1:0] sreg;
   reg [7:0] 	      cnt;
   wire 	      id;

   assign {id, o_wb_sel, o_wb_adr, o_wb_dat} = sreg;

   always @(posedge i_clk) begin
      if (i_dbg_valid) begin
	 sreg <= {sreg[sreg_len-2:0], i_dbg_data};
	 if (cnt == sreg_len-1)
	   cnt <= 0;
	 else
	   cnt <= cnt+1;

	 if (cnt == sreg_len-1)
	   o_wb_stb <= 1'b1;
	 else if (i_wb_ack)
	   o_wb_stb <= 1'b0;
      end
      if (i_rst) begin
	 cnt <= 0;
	 o_wb_stb <= 1'b0;
      end
   end

endmodule
