/***********************************************************
>> FIR_IR : f_s?500hz,(2ms) f_cutoff?10Hz, order? 21
>> mul : 11, FIR_coefficoefficients are symmetry
>> adder : 21
>> shift_reg : 21+1 = 22

>>the LED of the finger-clip needs to start alternating between 
infrared and red with a frequency of 100 Hz. 10ms
************************************************************/

`timescale 1ms/1ms
module FIR_IR ( 
	input CLK_Filter,
	input rst_n,
	input  [7:0] IR_ADC_Value,
	output reg [19:0] Out_IR_Filtered
	);

//define coefficients 
//22 coeficienrs --> 22'b -->21z^-1 21 steps
wire [7:0] coeff[10:0];
assign coeff[0]= 8'd2; 
assign coeff[1]=8'd10; 
assign coeff[2]=8'd16;
assign coeff[3]=8'd28; 
assign coeff[4]=8'd43;
assign coeff[5]=8'd60; 
assign coeff[6]=8'd78;
assign coeff[7]=8'd95;
assign coeff[8]=8'd111;
assign coeff[9]=8'd122;
assign coeff[10]=8'd128;

// define input shift register
reg [7:0] in_shift [21:0]; 
reg [19:0] shift_buf [10:0];

//define multipler
reg [19:0] mul_reg [10:0]; 

//define sum register
reg [19:0] add_temp1; 
reg [19:0] add_temp2;


//22 shift_register, in_shift [21:0]
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		in_shift[0] <= 8'd0;
		in_shift[1] <= 8'd0;
		in_shift[2] <= 8'd0;
		in_shift[3] <= 8'd0;
		in_shift[4] <= 8'd0;
		in_shift[5] <= 8'd0;
		in_shift[6] <= 8'd0;
		in_shift[7] <= 8'd0;
		in_shift[8] <= 8'd0;
		in_shift[9] <= 8'd0;
		in_shift[10] <= 8'd0;
		in_shift[11] <= 8'd0;
		in_shift[12] <= 8'd0;
		in_shift[13] <= 8'd0;
		in_shift[14] <= 8'd0;
		in_shift[15] <= 8'd0;
		in_shift[16] <= 8'd0;
		in_shift[17] <= 8'd0;
		in_shift[18] <= 8'd0;
		in_shift[19] <= 8'd0;
		in_shift[20] <= 8'd0;
		in_shift[21] <= 8'd0; 
		shift_buf [0] <= 20'd0;
		shift_buf [1] <= 20'd0;
		shift_buf [2] <= 20'd0;
		shift_buf [3] <= 20'd0;
		shift_buf [4] <= 20'd0;
		shift_buf [5] <= 20'd0;
		shift_buf [6] <= 20'd0;
		shift_buf [7] <= 20'd0;
		shift_buf [8] <= 20'd0;
		shift_buf [9] <= 20'd0;
		shift_buf [10] <= 20'd0;

	end 

	else begin
		in_shift[0] <= IR_ADC_Value;
		in_shift[1] <= in_shift[0];
		in_shift[2] <= in_shift[1];
		in_shift[3] <= in_shift[2];
		in_shift[4] <= in_shift[3];
		in_shift[5] <= in_shift[4];
		in_shift[6] <= in_shift[5];
		in_shift[7] <= in_shift[6];
		in_shift[8] <= in_shift[7];
		in_shift[9] <= in_shift[8];
		in_shift[10] <= in_shift[9];
		in_shift[11] <= in_shift[10];
		in_shift[12] <= in_shift[11];
		in_shift[13] <= in_shift[12];
		in_shift[14] <= in_shift[13];
		in_shift[15] <= in_shift[14];
		in_shift[16] <= in_shift[15];
		in_shift[17] <= in_shift[16];
		in_shift[18] <= in_shift[17];
		in_shift[19] <= in_shift[18];
		in_shift[20] <= in_shift[19];
		in_shift[21] <= in_shift[20];

		shift_buf [0] <= in_shift [0] + in_shift [21];
		shift_buf [1] <= in_shift [1] + in_shift [20];
		shift_buf [2] <= in_shift [2] + in_shift [19];
		shift_buf [3] <= in_shift [3] + in_shift [18];
		shift_buf [4] <= in_shift [4] + in_shift [17];
		shift_buf [5] <= in_shift [5] + in_shift [16];
		shift_buf [6] <= in_shift [6] + in_shift [15];
		shift_buf [7] <= in_shift [7] + in_shift [14];
		shift_buf [8] <= in_shift [8] + in_shift [13];
		shift_buf [9] <= in_shift [9] + in_shift [12];
		shift_buf [10] <= in_shift [10] + in_shift[11];
		
	end
end
				
//ADDER	
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin		
			mul_reg[0] <= 20'd0;
			mul_reg[1] <= 20'd0;
			mul_reg[2] <= 20'd0;
			mul_reg[3] <= 20'd0;
			mul_reg[4] <= 20'd0;
			mul_reg[5] <= 20'd0;
			mul_reg[6] <= 20'd0;
			mul_reg[7] <= 20'd0;
			mul_reg[8] <= 20'd0;
			mul_reg[9] <= 20'd0;
			mul_reg[10] <= 20'd0;
			
	end 
	else begin		
			mul_reg[0] <= coeff[0] * shift_buf [0]; 
			mul_reg[1] <= coeff[1] * shift_buf [1];
			mul_reg[2] <= coeff[2] * shift_buf [2];
			mul_reg[3] <= coeff[3] * shift_buf [3]; 
			mul_reg[4] <= coeff[4] * shift_buf [4]; 
			mul_reg[5] <= coeff[5] * shift_buf [5]; 
			mul_reg[6] <= coeff[6] * shift_buf [6]; 
			mul_reg[7] <= coeff[7] * shift_buf [7]; 
			mul_reg[8] <= coeff[8] * shift_buf [8]; 
			mul_reg[9] <= coeff[9] * shift_buf [9]; 
			mul_reg[10] <= coeff[10] * shift_buf [10]; 			
	end
end

always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		Out_IR_Filtered <= 20'd0;
		add_temp1 <= 20'd0;
		add_temp2 <= 20'd0;
	end 
	else begin
		add_temp1 <=  mul_reg[0] + mul_reg[1] + mul_reg[2] + mul_reg[3] + mul_reg[4] + mul_reg[5];
		add_temp2 <=  mul_reg[6] + mul_reg[7] + mul_reg[8] + mul_reg[9] + mul_reg[10];
		Out_IR_Filtered <= add_temp1 + add_temp2;
	end
end

endmodule
