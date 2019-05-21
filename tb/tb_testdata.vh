

`timescale 1ns/1ps

module tb_dev_hash (/*AUTOARG*/ ) ;

integer TESTFILE;


// Global clock and reset
logic     clk;  
logic      reset_n; 

logic      start;
logic      done

logic      [31:0] reg1;
logic      [31:0] reg2;
logic      [31:0] reg3;
logic      [31:0] reg4;

logic 

/***********************************************
   System Clock: 50 MHz w/50% duty cycle
***********************************************/
initial begin
    clk = 1;
    forever
	  #10ns clk = ~clk;
end
/***********************************************
   System Reset: 
***********************************************/
initial begin
    reset_n     <=   1'b0;
	#50 reset_n <=   1'b1;
end

hash_dut DUT (
.CLK(clk),
.RESET_n(reset_n),
.START(start),      
.REG1(reg1),  
.REG2(reg2), 
.REG3(reg3),
.REG4(reg3),
.AG(),
.DONE()

);


endmodule



module hash_dut(
  input               CLK,
  input               RESET_n,
  input               START,      
  input      [31:0]   REG1,  
  input      [31:0]   REG2, 
  input      [31:0]   REG3,
  input      [31:0]   REG4,
  
  output     [4:0]    AG
  output              DONE
);











endmodule



















