`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:40:05 05/17/2021
// Design Name:   Main
// Module Name:   F:/Documents/floatingPointALU/Main_tb.v
// Project Name:  floatingPointALU
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Main_tb;

	// Inputs
	reg [31:0] n1;
	reg [31:0] n2;
	reg [1:0] oper;

	// Outputs
	wire [31:0] result;
	wire Overflow;
	wire Underflow;
	wire Exception;

	// Instantiate the Unit Under Test (UUT)
	Main uut (
		.n1(n1), 
		.n2(n2), 
		.oper(oper), 
		.result(result), 
		.Overflow(Overflow), 
		.Underflow(Underflow), 
		.Exception(Exception)
	);

	initial begin
		// Initialize Inputs
		n1 = 32'b01000011000011111000111101011100;    // 143.56
		n2 = 32'b11000010101011101101111110111110;    // -87.437


		oper = 2'd0; #50;

		$display("Addtion result : %b",result);
		$display("Overflow : %b , Underflow : %b , Exception : %b",Overflow,Underflow,Exception);		
		
		oper = 2'd1; #50;

		$display("Subtraction result : %b",result);
		$display("Overflow : %b , Underflow : %b , Exception : %b",Overflow,Underflow,Exception);		
		
		oper = 2'd2; #50;

		$display("Multiplication result : %b",result);
		$display("Overflow : %b , Underflow : %b , Exception : %b",Overflow,Underflow,Exception);		
		
		oper = 2'd3; #50;

		$display("Division result : %b",result);
		$display("Overflow : %b , Underflow : %b , Exception : %b",Overflow,Underflow,Exception);



	end
      
endmodule

