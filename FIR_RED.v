/***********************************************************
>> FIR_RED : f_s：500hz, f_cutoff：10Hz, order： 21
>> f_s:500Hz ---> T:2ms
>> mul : 22, but only 11 multipliers needed as FIR_coefficoefficients are symmetry
>> adder : 21
>> shift_reg : 21+1 = 22
************************************************************/

`timescale 1ms/1ms;
module FIR_RED ( 
	input CLK_Filter,
	input rst_n,
	input  [7:0] RED_ADC_Value,
	
	output reg [19:0] Out_RED_Filtered
	);

//define coefficients 
//22 coeficienrs --> 22'b -->21z^-1 21 steps
wire [7:0] coeff[10:0];
assign coeff[0]= 8'd2; 
assign coeff[1]=8'd10; 
assign coeff[2]='d16;
assign coeff[3]=8'd28; 
assign coeff[4]=8'd43;
assign coeff[5]=8'd60; 
assign coeff[6]=8'd78;
assign coeff[7]=8'd95;
assign coeff[8]=8'd111;
assign coeff[9]=8'd122;
assign coeff[10]=8'd128;

reg  [7:0] in_shift [21:0]; 
reg  [19:0] mul_reg [10:0]; 
reg  [19:0] add_reg [11:0];

integer i,j;

//22 shift_register, in_shift [21:0]
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0; i<21; i=i+1) begin
			in_shift[i] <= 7'd0; 
		end
	end 
	else begin
		in_shift[0] <= IR_ADC_Value;
		for (i=0; i<21; i=i+1) begin
			in_shift [i+1] <= in_shift[i];
			//$timeformat(-3, 0, "ns"); 
			$display("in_shift %b",in_shift[i]);
		end
	end
end
				
//11 mul, mul_reg [10:0]	
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (j=0; j<11; j=j+1) begin
			mul_reg[j] <= 20'd0;
		end
	end 
	else begin
		for (j=0; j<11; j=j+1) begin
			add_reg[j] <= in_shift [j] + in_shift [21-j];
			//这里应该再延一个时间周期？
			mul_reg[j] <= coeff[j] * add_reg[j];
			$display("mul_reg %b",mul_reg[j]);
			$display("coeff %b",coeff[j]);
		end
	end
end



always @(posedge CLK_Filter or negedge rst_n) begin

	if(!rst_n)begin
			Out_RED_Filtered <= 20'd0;
	end 
	else begin
		for (j=0; j<=10; j=j+1) begin
			Out_RED_Filtered <= Out_RED_Filtered + mul_reg[j];
			$display("Out_IR_Filtered %b",Out_RED_Filtered);
		end
	end
end

endmodule