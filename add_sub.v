`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:39:06 05/11/2021 
// Design Name: 
// Module Name:    add_sub 
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
module add_sub(
    input [31:0] n1,
    input [31:0] n2,
    output [31:0] result,
    input sub,
    input Overflow,
    input Underflow,
    input Exception
    );
	 
wire real_oper,real_sign,M_carry;
wire isElLessThanE2,reduced_and_E1 ,reduced_and_E2;
wire [7:0] temp_exp_diff,One_Added_E,new_E,complemented_temp_exp_diff,exp_diff,E,complemented_E2,complemented_shift_E;
wire [8:0] final_E;
wire [23:0] M1,M2,complemented_M2,complemented_M_result,M_result,M_result2,new_M2;
wire w1,w2,w3,final_sign;
wire [22:0] final_M;
wire[4:0] shift_E;
wire[31:0] result1;

// initially setting overflow and underflow to 0
not(Overflow,1'b1);
not(Underflow,1'b1);

// Checking whether all the bits of E1, E2 are 1 ==> Then the number will be either infinity or NAN ( i.e. an Exception ) 
Reduction_and8bit RA01(.in(n1[30:23]),.out(reduced_and_E1));
Reduction_and8bit RA02(.in(n2[30:23]),.out(reduced_and_E2));

// If any of E1 or E2 has all btis 1 then we have an Exception( high ) 
or(Exception,reduced_and_E1,reduced_and_E2);

// Taking the difference of E1 and E2
// before subtraction let's complement E2 then we add E1 and Complemented E2 along with cin = 1 ( for 2's complement )
Complement8bit C01(.in(n2[30:23]),.out(complemented_E2));
Adder8bit ADD01(.a(n1[30:23]),.b(complemented_E2),.cin(1'b1),.sum(temp_exp_diff),.cout(isE1GreaterThanE2));

Complement8bit_2s C023(.in(temp_exp_diff),.out(complemented_temp_exp_diff));
Mux_8Bit M011(.in0(complemented_temp_exp_diff),.in1(temp_exp_diff),.sl(isE1GreaterThanE2),.out(exp_diff));

// swap the mantissae and store them in M1 and M2 ==> This is done only to know which mantissa is to be shifted by exp_diff
// for expo
// Selecting the larger exponent
Mux_8Bit M03(.in0(n2[30:23]),.in1(n1[30:23]),.sl(isE1GreaterThanE2),.out(E));

// Now apply shift right operation on M2 by exp_diff
assign M1 = isE1GreaterThanE2? {1'b1,n1[22:0]}:{1'b1,n1[22:0]} >> exp_diff;
assign M2 = isE1GreaterThanE2?{1'b1,n2[22:0]} >> exp_diff:{1'b1,n2[22:0]};

// S1,S2 and sub may have different sign and also
xor(real_oper,sub,n1[31],n2[31]);
buf(real_sign,n1[31]);

Complement24bit C02(.in(M2),.out(complemented_M2));
Mux_24Bit M04(.in0(M2),.in1(complemented_M2),.sl(real_oper),.out(new_M2));

Adder24bit ADD02(.a(M1),.b(new_M2),.cin(real_oper),.sum(M_result),.cout(M_carry));

and(w1,~real_sign,real_oper,~M_carry);
and(w2,~real_oper,real_sign);
and(w3,M_carry,real_sign);
or(final_sign,w1,w2,w3);

Adder8bit ADD0212(.a(E),.b(8'd1),.cin(1'b0),.sum(One_Added_E),.cout());
Mux_8Bit M031(.in0(E),.in1(One_Added_E),.sl(M_carry&!real_oper),.out(new_E));

Complement24bit_2s C03(.in(M_result),.out(complemented_M_result));
Mux_24Bit M05(.in0(M_result),.in1(complemented_M_result),.sl(real_oper&!M_carry),.out(M_result2));

normalizeMandfindShift NM(.M_result(M_result2),.M_carry(M_carry),.real_oper(real_oper),.normalized_M(final_M),.shift(shift_E));
Complement8bit C04(.in({3'b000,shift_E}),.out(complemented_shift_E));
Adder8bit ADD03(.a(new_E),.b(complemented_shift_E),.cin(1'b1),.sum(final_E[7:0]),.cout(final_E[8]));

not(Underflow,final_E[8]);

// if Exception is 1 ===> set the result to all 1s
Mux_32Bit M06(.in0({final_sign,final_E[7:0],final_M}),.in1(32'b1_11111111_11111111111111111111111),.sl(Exception),.out(result1));

// if Underflow is 1 ===> set the result to all 0s and sign is the final_sign ( setting to 0 )
Mux_32Bit M07(.in0(result1),.in1({final_sign,31'b00000000_00000000000000000000000}),.sl(Underflow),.out(result));

endmodule


