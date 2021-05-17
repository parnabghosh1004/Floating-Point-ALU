`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:40:53 05/13/2021 
// Design Name: 
// Module Name:    mul 
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
module mul( 
				input [31:0] n1,
				input [31:0] n2,
				output [31:0] result,
				input Overflow,
				input Underflow,
				input Exception
			);

wire [8:0] sum_E,final_E;
wire [47:0] M_mul_result;
wire [23:0] normalized_M_mul_result;
wire [22:0] final_M;
wire final_sign,reduced_and_E1,reduced_and_E2,reduced_or_E1,reduced_or_E2,carry_E;
wire [31:0] result1,result2;

// Checking whether all the bits of E1, E2 are 1 ==> Then the number will be either infinity or NAN ( i.e. an Exception ) 
Reduction_and8bit RA01(.in(n1[30:23]),.out(reduced_and_E1));
Reduction_and8bit RA02(.in(n2[30:23]),.out(reduced_and_E2));

// If any of E1 or E2 has all btis 1 then we have an Exception( high ) 
or(Exception,reduced_and_E1,reduced_and_E2);

// final sign of the result
xor(final_sign,n1[31],n2[31]);

// if all the bits of E1 or E2 are 0  ===> Number is denormalized and the implied bit of the corresponding mantissa is to be set as 0.
Reduction_or8bit RO01(.in(n1[30:23]),.out(reduced_or_E1));
Reduction_or8bit RO02(.in(n1[30:23]),.out(reduced_or_E2));

// Multiplying M1 and M2( here we have firstly concatenated the implied bit with the corresponding mantissa )
Multiplier24bit MUL01(.a({reduced_or_E1,n1[22:0]}),.b({reduced_or_E2,n2[22:0]}),.mul(M_mul_result));

// MSB of the product is used as select line
// finding the rounding bit ( finally we will or with the LSB of the final product to include rounding )
// if M_mul_result[47] is 1 ===> product is normalized and we will round off the last 24 bits else last 23 bits
Reduction_or24bit RO03(.in({1'b0,M_mul_result[22:0]}),.out(mul_round1));
Reduction_or24bit RO04(.in(M_mul_result[23:0]),.out(mul_round2));
Mux_1Bit M01(.in0(mul_round1),.in1(mul_round2),.sl(M_mul_result[47]),.out(final_product_round));

// normalization
// if MSB of M_mul_result is 1 ===> product is already normalized and next 23 bits after MSB is taken
// if MSB of M_mul_result is 0 ===> The next bit is always 1, so starting from next to next bit, next 23 bits are taken
// here we do not require to shift any bit
Mux_24Bit M02(.in0({1'b0,M_mul_result[45:23]}),.in1({1'b0,M_mul_result[46:24]}),.sl(M_mul_result[47]),.out(normalized_M_mul_result));

Adder24bit ADD23(.a({1'b0,normalized_M_mul_result[22:0]}),.b({23'b0,final_product_round}),.cin(1'b0),.sum({temp,final_M}),.cout());

// Adding E1 and E2
Adder8bit ADD01(.a(n1[30:23]),.b(n2[30:23]),.cin(1'b0),.sum(sum_E[7:0]),.cout(sum_E[8]));

// Subtracting 127(BIAS) from sum_E = E1 + E2
// if M_mul_result[47] = 1 ===> product is of the form 11.(something) and we need to shift the decimal point to left to make the product normalized and therefore we add 1 to resultant E
// if M_mul_result[47] = 0 ===> product is of the form 01.(something) and the product is already normalized and nothing is added or subtracted to E
Adder9bit ADD02(.a(sum_E),.b(9'b110000001),.cin(M_mul_result[47]),.sum(final_E),.cout(carry_E));

// In 2's complement subtraction : 
// if carry_E = 0 ===> result is negative and it the case of Underflow
// if carry_E = 1 and MSB of sum(final_E) is 8 (that means sum is atleast 256 ) ===> it is the case of Overflow 
not(Underflow,carry_E);
and(Overflow,carry_E,final_E[8]);

// if Exception is 1 ===> set the result to all 1s
Mux_32Bit M04(.in0({final_sign,final_E[7:0],final_M}),.in1(32'b1_11111111_11111111111111111111111),.sl(Exception),.out(result1));

// if Underflow is 1 ===> set the result to all 0s and sign is the final_sign ( setting to 0 )
Mux_32Bit M05(.in0(result1),.in1({final_sign,31'b00000000_00000000000000000000000}),.sl(Underflow),.out(result2));

// if Overflow is 1 ===> set the E to all 1s and M to all 0s and sign is the final_sign ( setting to +inf or -inf)
Mux_32Bit M06(.in0(result2),.in1({final_sign,31'b11111111_00000000000000000000000}),.sl(Overflow),.out(result));

endmodule
