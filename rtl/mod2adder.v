///////////////////////////////////////////////////////////////////////////////////
//=================================================================================
//  Copyright(c) SecureRF Inc., 2019
//  ALL RIGHTS RESERVED
//===========================================================================
//
// File name:  : mod2adder.v
// Author      : Mike Delphia
// Contact     : mdelphia@securerf.com
// Description : mod 2^32 - 1 adder for SHA-256 
//
// Subtraction is performed using ones complement arithmetic . One's complement 
// works by inverting the subtrahend (take-away value) and adding it to the minuend. 
// If the addition causes an overflow, the overflow bit is dropped and 1 is added to
// sum. Logic has been implemented here to work around this extra operation.
//
// Schmema for subtraction
//  1)  Invert subtrahend - This will be 0x8000_0000
//  2)  Replace the LSB of the inverted subtrahend with the MSB of the minuend. 
//      The overflow is handled here instead of after the addition
//  3)  Perform addition.
//================================================================================ 
///////////////////////////////////////////////////////////////////////////////////

module adder_mmm  (
        input                      aclr,          //   IN
        input                      add_sub,       //   IN (add = 1, subtract=0)
        input                      clock,         //   IN
        input          [31:0]      dataa,         //   IN [31:0]
        input          [31:0]      datab,         //   IN [31:0]
        output     reg             overflow,      //  OUT
        output     reg [31:0]      result         //  OUT [31:0]
			   );              
		  
wire [32:0] dataA_int;
wire [32:0] dataB_int;
wire [32:0] sum;
wire [32:0] CRY_CO;

// Lengthen vectors for intermediate operation
// Minuend
assign dataA_int = {1'b0, dataa};      

// Subtrahend                
assign dataB_int = (add_sub) ? {1'b0, datab} : {(~({1'b0, datab[31:1]})) , dataa[31]};


// 32 bit adder
generate
genvar i; //
  for (i = 0; i < 33; i = i + 1)
     begin : ADDGen
	  fulladder  FA1( 
	       .a(dataA_int[i]),                     // Addend/Minuend
	       .b(dataB_int[i]),                     // Augend/Subtrahend
	       .cin((i==0) ? 1'b0 : CRY_CO[i-1]) ,   // In-carry
           .sum(sum[i]),                         // Sum
           .carry(CRY_CO[i]));                   // Out Carry
     end
endgenerate


// Register out sum. Note active high reset
always @(posedge clock or posedge aclr) begin
  if (aclr) begin
     result    <=    32'h0000_0000;
	 overflow  <=     1'b0;
	 end
  else begin
     result    <=    sum[31:0];
     overflow  <=    sum[32];
	 end
  end

  

  
  

endmodule