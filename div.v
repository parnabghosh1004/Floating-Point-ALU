`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:22:49 05/15/2021 
// Design Name: 
// Module Name:    div 
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
module div(
			input [31:0] n1,
			input [31:0] n2,
			output [31:0] result,
			output Overflow,
			output Underflow,
			output Exception
         );

wire is_n2_zero,reduced_and_E1,reduced_and_E2,reduced_or_E1,reduced_or_E2,Overflow1,Underflow1,Overflow2,Underflow2;
wire [24:0] M_div_result;
wire [8:0] temp_E2,temp_E3;
wire [7:0] complemented_E2,complemented_shift_E1,sub_E,bias_added_E,temp_E1,final_E;
wire [4:0] shift_E1,shift_E2;
wire [22:0] normalized_M1,normalized_M2,final_M;

//if all the bits of E1 or E2 are 1 or if n2 is zero ===> Exception 
Reduction_and8bit RA01(.in(n1[30:23]),.out(reduced_and_E1));
Reduction_and8bit RA02(.in(n2[30:23]),.out(reduced_and_E2));
Reduction_nor31bit RN01(.in(n2[30:0]),.out(is_n2_zero));
or(Exception,reduced_and_E1,reduced_and_E2,is_n2_zero);

// final sign of the result
xor(final_sign,n1[31],n2[31]);

// if all the bits of E1 or E2 are 0  ===> Number is denormalized and the implied bit of the corresponding mantissa is to be set as 0.
Reduction_or8bit RO01(.in(n1[30:23]),.out(reduced_or_E1));
Reduction_or8bit RO02(.in(n1[30:23]),.out(reduced_or_E2));

// Subtracting E2 from E1 ===> 2's complement Subtraction
Complement8bit C01(.in(n2[30:23]),.out(complemented_E2));
Adder8bit ADD01(.a(n1[30:23]),.b(complemented_E2),.cin(1'b1),.sum(sub_E),.cout());

// Adding 127(BIAS) to sub_E
Adder8bit ADD02(.a(sub_E),.b(8'b01111111),.cin(1'b0),.sum(bias_added_E),.cout());

// Used to make all mantissae normalized if any of the them is firstly denormalized 
normalizeMandfindShift NM1(.M_result({reduced_or_E1,n1[22:0]}),.M_carry(1'b0),.real_oper(1'b0),.normalized_M(normalized_M1),.shift(shift_E1));
normalizeMandfindShift NM2(.M_result({reduced_or_E2,n2[22:0]}),.M_carry(1'b0),.real_oper(1'b0),.normalized_M(normalized_M2),.shift(shift_E2));

// dividing M1 by M2
Divider24bit DIV01(.a({1'b1,normalized_M1,24'b0}),.b({1'b1,normalized_M2}),.div(M_div_result));

// if M_div_result[24] = 0 ===> take ans from 22 pos to 0 pos, i.e, final_M = M_div_result[22:0]
// if M_div_result[24] = 1 ===> take ans from 23 pos to 1 pos, i.e, final_M = M_div_result[23:1]
Mux_24Bit M02(.in0({1'b0,M_div_result[22:0]}),.in1({1'b0,M_div_result[23:1]}),.sl(M_div_result[24]),.out({temp,final_M}));

// Subtracting shift_E1 from bias_added_E  ===> we get temp_E1
Complement8bit C02(.in({3'b000,shift_E1}),.out(complemented_shift_E1));
Adder8bit ADD03(.a(bias_added_E),.b(complemented_shift_E1),.cin(1'b1),.sum(temp_E1),.cout());

// Adding shift_E2 to temp_E1 ===> we get temp_E2
Adder8bit ADD04(.a(temp_E1),.b({3'b000,shift_E2}),.cin(1'b0),.sum(temp_E2[7:0]),.cout(temp_E2[8]));
and(Overflow1,temp_E1[8],temp_E2[8]);
nor(Underflow1,temp_E1[8],temp_E2[8]);

// Subtracting 1 from temp_E2[7:0] to get temp_E3
Adder8bit ADD05(.a(temp_E2[7:0]),.b(8'b11111111),.cin(1'b0),.sum(temp_E3[7:0]),.cout(temp_E3[8]));
and(Overflow2,temp_E2[8],temp_E3[8]);
nor(Underflow2,temp_E2[8],temp_E3[8]);

// Based on M_div_result[24] bit ===> we will select temp_E2 or temp_E3  
Mux_8Bit M03(.in0(temp_E3[7:0]),.in1(temp_E2[7:0]),.sl(M_div_result[24]),.out(final_E));
Mux_1Bit M04(.in0(Overflow2),.in1(Overflow1),.sl(M_div_result[24]),.out(Overflow));
Mux_1Bit M05(.in0(Underflow2),.in1(Underflow1),.sl(M_div_result[24]),.out(Underflow));

assign result = {final_sign,final_E[7:0],final_M};

endmodule



