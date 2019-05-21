/**********************************************************************
 32 bit x 63 location RAM for synthesis inference
 Dual-Port RAM maps directly to Altera TriMatrix memory.
 
 Refer to Intel® Quartus® Prime Standard Edition Handbook Volume 1
 Section 18.10.3.2 - Inferring RAM
**********************************************************************/
`timescale 1ns / 1ps

module ram_infer_sha
(
  input   [31:0]   data,
  input    [5:0]   read_addr,
  input    [5:0]   write_addr,
  input            we,
  input            clk,
  output   reg [31:0]   q
);

// RAM register set
 reg [31:0] mem [63:0];
 
always @ (posedge clk) begin
 // Write
   if (we)  
      mem[write_addr] <= data;

   q  <= mem[read_addr];	  

 end
 
  

 
endmodule




