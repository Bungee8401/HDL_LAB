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
// reg  [19:0] add_reg [10:0];

reg [7:0] i,j;
reg [7:0] k;
reg [2:0] en;

reg [19:0] add_temp1;
reg [19:0] add_temp2;

// en[2:0] shift
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		en[2:0] <= 3'b001;
		k <= 0;
	end else begin
		k <= k+1;
		if (k<=1) begin
			en[2:0] <= {en[1:0], 1'b0};
		end
		else begin
			k <= 0;
			en[2:0] <= 3'b001;
		end
	end
end

//22 shift_register, in_shift [21:0]
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0; i<=21; i=i+1) begin
			in_shift[i] <= 7'd0; 
		end
		//en[2:0] <= 3'b001;
	end 
	else if (en[0]) begin
		in_shift[0] <= IR_ADC_Value;
		for (i=0; i<=21; i=i+1) begin
			in_shift [i+1] <= in_shift[i];
			//$timeformat(-3, 0, "ns"); 
			//$display("in_shift %b",in_shift[i]);
		end
		// en[2:0] <= {en[1:0], 1'b0};
	end
end
				
//ADDER	
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (j=0; j<=10; j=j+1) begin
			mul_reg[j] <= 20'd0;
			//add_reg[j] <= 20'd0;
		end
	end 
	else if (en[1])begin
		for (j=0; j<=10; j=j+1) begin
			mul_reg[j] <= coeff[j] * (in_shift [j] + in_shift [21-j]); 
			
			
			// $display("mul_reg %b",mul_reg[j]);
			// $display("coeff %b",coeff[j]);
		end
		//en[2:0] <= {en[1:0], 1'b0};
	end
end


always @(posedge CLK_Filter or negedge rst_n) begin

	if(!rst_n)begin
		Out_IR_Filtered <= 20'd0;
	end 
	else if (en[2]) begin
		//$display ("enter!IR");
		//for (j=0; j<=10; j=j+1) begin
			//$display ("enter!RED forloop");
		add_temp1 <=  mul_reg[0] + mul_reg[1] + mul_reg[2] + mul_reg[3] + mul_reg[4] + mul_reg[5];
			//$display("Out_IR_Filtered %b",Out_IR_Filtered);
		add_temp2 <=  mul_reg[6] + mul_reg[7] + mul_reg[8] + mul_reg[9] + mul_reg[10];
		Out_IR_Filtered <= add_temp1 + add_temp2;
		//end
		//en[2:0] <= {en[1:0], 1'b1};
	end
end

endmodule
