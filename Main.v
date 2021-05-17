`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:15:14 05/11/2021 
// Design Name: 
// Module Name:    Main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Main(n1,n2,oper,result,Overflow,Underflow,Exception);

input [31:0] n1,n2;
input[1:0] oper;
output Overflow,Underflow,Exception;
output [31:0] result;
wire [31:0] temp_result,result1,result2,result3,result4,result5,result6;
wire Overflow1,Underflow1,Exception1,Overflow2,Underflow2,Exception2,Overflow3,Underflow3,Exception3;

add_sub AS(.n1(n1),.n2(n2),.result(result1),.sub(|oper),.Overflow(Overflow1),.Underflow(Underflow1),.Exception(Exception1));
mul M(.n1(n1),.n2(n2),.result(result2),.Overflow(Overflow2),.Underflow(Underflow2),.Exception(Exception2));
div D(.n1(n1),.n2(n2),.result(result3),.Overflow(Overflow3),.Underflow(Underflow3),.Exception(Exception3));

Mux_32Bit M01(.in0(result1),.in1(result2),.sl(oper[1]),.out(temp_result));
Mux_32Bit M02(.in0(temp_result),.in1(result3),.sl(&oper),.out(result4));

Mux_1Bit M03(.in0(Overflow1),.in1(Overflow2),.sl(oper[1]),.out(temp1));
Mux_1Bit M04(.in0(temp1),.in1(Overflow3),.sl(&oper),.out(Overflow));

Mux_1Bit M05(.in0(Underflow1),.in1(Underflow2),.sl(oper[1]),.out(temp2));
Mux_1Bit M06(.in0(temp2),.in1(Underflow3),.sl(&oper),.out(Underflow));

Mux_1Bit M07(.in0(Exception1),.in1(Exception2),.sl(oper[1]),.out(temp3));
Mux_1Bit M08(.in0(temp3),.in1(Exception3),.sl(&oper),.out(Exception));

// if Exception is 1 ===> set the result to all 1s
Mux_32Bit M09(.in0(result4),.in1(32'b1_11111111_11111111111111111111111),.sl(Exception),.out(result5));

// if Underflow is 1 ===> set the result to all 0s and sign is the final_sign ( setting to 0 )
Mux_32Bit M010(.in0(result5),.in1({result4[31],31'b00000000_00000000000000000000000}),.sl(Underflow),.out(result6));

// if Overflow is 1 ===> set the E to all 1s and M to all 0s and sign is the final_sign ( setting to +inf or -inf)
Mux_32Bit M011(.in0(result6),.in1({result4[31],31'b11111111_00000000000000000000000}),.sl(Overflow),.out(result));


endmodule




