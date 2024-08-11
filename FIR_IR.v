`timescale 1ms/1ms;

    // always @(posedge CLK) begin  
    //     if(Find_setting_Complete) begin // setting found, switch faster -> 100Hz, 10ms       
    //         if(timer == 9) begin
    //             timer <= 0;
    //             LED_RED <= ~LED_RED;
    //             LED_IR <= ~LED_IR;
    //         end else begin
    //             timer <= timer + 1;       
    //             if (LED_RED == 1 && LED_IR == 0) begin
    //                 RED_ADC_Value <= ADC;
    //                 PGA_Gain <= RED_PGA;
    //                 DC_Comp <= RED_DC_Comp;
    //             end 

    //             if (LED_RED == 0 && LED_IR == 1) begin
    //                 IR_ADC_Value <= ADC;
    //                 PGA_Gain <= IR_PGA;
    //                 DC_Comp <= IR_DC_Comp;           
    //             end
    //         end
    //     end
        
    // end


module FIR_IR ( 
	input CLK_Filter,
	input rst_n,
	input  [7:0] IR_ADC_Value,
	output reg [19:0] Out_IR_Filtered
	);

//define coefficients
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

reg  [7:0] in_shift [20:0]; //21steps
reg  [19:0] mul_reg [10:0]; //22mul, but only 11 multipliers needed as FIR_coefficoefficients are symmetry
//reg  [19:0] add_reg ;

integer i,j;

always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0; i<=20; i=i+1) begin
			in_shift[i] <= 7'd0; 
		end
	end 
	else begin
		in_shift[0] = IR_ADC_Value;
		for (i=0; i<=20; i=i+1) begin
			in_shift [i+1] = in_shift[i];
			//$timeformat(-3, 0, "ns"); 
			$display("in_shift %b",in_shift[i]);
		end
	end
end
				
		
always @(posedge CLK_Filter or negedge rst_n) begin
	if(!rst_n)begin
		for (j=0; j<=10; j=j+1) begin
			mul_reg[j] <= 20'd0;
		end

	end 
	else begin
		for (j=0; j<=10; j=j+1) begin
			mul_reg[j] <= coeff[j] * (in_shift [j] + in_shift [20-j]);
			$display("mul_reg %b",mul_reg[j]);
			$display("coeff %b",coeff[j]);
		end
	end
end



always @(posedge CLK_Filter or negedge rst_n) begin

	if(!rst_n)begin
			Out_IR_Filtered <= 20'd0;
	end 
	else begin
		for (j=0; j<=10; j=j+1) begin
			Out_IR_Filtered = Out_IR_Filtered + mul_reg[j];
			$display("Out_IR_Filtered %b",Out_IR_Filtered);
		end
	end
end

endmodule