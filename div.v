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
wire [8:0] sub_E,bias_added_E,temp_E1,temp_E2,temp_E3;
wire [7:0] complemented_E2,complemented_shift_E1,final_E;
wire [4:0] shift_E1,shift_E2;
wire [22:0] normalized_M1,normalized_M2,final_M;
wire [31:0] result1,result2;

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
Adder8bit ADD01(.a(n1[30:23]),.b(complemented_E2),.cin(1'b1),.sum(sub_E[7:0]),.cout(sub_E[8]));

// Adding 127(BIAS) to sub_E
Adder8bit ADD02(.a(sub_E[7:0]),.b(8'b01111111),.cin(1'b0),.sum(bias_added_E[7:0]),.cout(bias_added_E[8]));

// sub_E[8] = 1 ===> sub_E[7:0] is +ve
// final_E[8] = 1 ===> final_E is atleast 256 ( Overflow condition )   
// and(Overflow,sub_E[8],final_E[8]);

// sub_E[8] = 0 ===> sub_E[7:0] is -ve
// final_E[8] = 0 ===> final_E is -ve ( Underflow condition )
// nor(Underflow,sub_E[8],final_E[8]);


// Used to make all mantissae normalized if any of the them is firstly denormalized 
normalizeMandfindShift NM1(.M_result({reduced_or_E1,n1[22:0]}),.M_carry(1'b0),.real_oper(1'b0),.normalized_M(normalized_M1),.shift(shift_E1));
normalizeMandfindShift NM2(.M_result({reduced_or_E2,n2[22:0]}),.M_carry(1'b0),.real_oper(1'b0),.normalized_M(normalized_M2),.shift(shift_E2));

// dividing M1 by M2
Divider24bit DIV01(.a({1'b1,normalized_M1,24'b0}),.b({1'b1,normalized_M2}),.div(M_div_result));

Mux_24Bit M02(.in0({1'b0,M_div_result[22:0]}),.in1({1'b0,M_div_result[23:1]}),.sl(M_div_result[24]),.out({temp,final_M}));

Complement8bit C02(.in({3'b000,shift_E1}),.out(complemented_shift_E1));
Adder8bit ADD03(.a(bias_added_E[7:0]),.b(complemented_shift_E1),.cin(1'b1),.sum(temp_E1[7:0]),.cout(temp_E1[8]));

Adder8bit ADD04(.a(temp_E1[7:0]),.b({3'b000,shift_E2}),.cin(1'b0),.sum(temp_E2[7:0]),.cout(temp_E2[8]));
and(Overflow1,temp_E1[8],temp_E2[8]);
nor(Underflow1,temp_E1[8],temp_E2[8]);

Adder8bit ADD05(.a(temp_E2[7:0]),.b(8'b11111111),.cin(1'b0),.sum(temp_E3[7:0]),.cout(temp_E3[8]));
and(Overflow2,temp_E2[8],temp_E3[8]);
nor(Underflow2,temp_E2[8],temp_E3[8]);

Mux_8Bit M03(.in0(temp_E3[7:0]),.in1(temp_E2[7:0]),.sl(M_div_result[24]),.out(final_E));
Mux_1Bit M04(.in0(Overflow2),.in1(Overflow1),.sl(M_div_result[24]),.out(Overflow));
Mux_1Bit M05(.in0(Underflow2),.in1(Underflow1),.sl(M_div_result[24]),.out(Underflow));

// if Exception is 1 ===> set the result to all 1s
Mux_32Bit M06(.in0({final_sign,final_E[7:0],final_M}),.in1(32'b1_11111111_11111111111111111111111),.sl(Exception),.out(result1));

// if Underflow is 1 ===> set the result to all 0s and sign is the final_sign ( setting to 0 )
Mux_32Bit M07(.in0(result1),.in1({final_sign,31'b00000000_00000000000000000000000}),.sl(Underflow),.out(result2));

// if Overflow is 1 ===> set the E to all 1s and M to all 0s and sign is the final_sign ( setting to +inf or -inf)
Mux_32Bit M08(.in0(result2),.in1({final_sign,31'b11111111_00000000000000000000000}),.sl(Overflow),.out(result));

endmodule



