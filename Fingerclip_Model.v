`timescale 1ms/1us
/**
This is a non-synthesizable mockup of a fingerclip device used for blood preassure meassurement.
**/
module Fingerclip_Model(Vppg, DC_Comp, PGA_Gain, LED_RED, LED_IR);
	
	output [7:0] Vppg;
	input [6:0] DC_Comp;
	input [3:0] PGA_Gain;
	input LED_RED, LED_IR;	

	reg clk;
	reg [19:0] Vppg_var, DC_var, PGA_var;

	real Sin[19:0];
	reg [4:0] counter;
	reg positiv;
	reg [7:0] Vppg_intermediate;

	initial begin
		Sin[0] = 0.0; // sine table
		Sin[1] = 0.15643446504023087;
		Sin[2] = 0.3090169943749474;
		Sin[3] = 0.45399049973954675;
		Sin[4] = 0.5877852522924731;
		Sin[5] = 0.7071067811865476;
		Sin[6] = 0.8090169943749475;
		Sin[7] = 0.8910065241883678;
		Sin[8] = 0.9510565162951535;
		Sin[9] = 0.9876883405951378;
		Sin[10] = 1.0;
		Sin[11] = 0.9876883405951378;
		Sin[12] = 0.9510565162951536;
		Sin[13] = 0.8910065241883679;
		Sin[14] = 0.8090169943749475;
		Sin[15] = 0.7071067811865476;
		Sin[16] = 0.5877852522924732;
		Sin[17] = 0.45399049973954686;
		Sin[18] = 0.3090169943749475;
		Sin[19] = 0.15643446504023098;	
		clk = 0;
		Vppg_intermediate = 0;
		Vppg_var = 0;
		positiv = 0;
	end

	always #16 clk = !clk; //545

	always@( LED_RED or LED_IR) begin // LED input sanity check
		
		if(LED_RED & LED_IR) $display("Both LEDs are on!");

	end
	
	always@(posedge clk) begin // generates the sinus waveform counter

		if(counter < 19) counter = counter + 1;
		else begin
			counter = 0;
			positiv = !positiv;
		end
	end
	
	always@* begin // adjust DC_Comp and PGA Variables dependent on LED
		
		if(!LED_RED & !LED_IR) begin
			DC_var = 0;
			PGA_var = 0;
		end else
		if (LED_RED) begin
			DC_var = DC_Comp << 1;
			PGA_var = PGA_Gain << 4;

		end else begin
			DC_var = (DC_Comp << 1) + 10;
			if(DC_var > 255) DC_var = 255;
			if(PGA_Gain > 0) PGA_var = (PGA_Gain << 5) - 1;
			else PGA_var = 0;
		end
	


	end


	always@* begin // generate sinus signal
		
		if(positiv == 1) begin
			Vppg_var  = (255-DC_var) + (PGA_var+1)*Sin[counter];
			if(Vppg_var > 255) Vppg_intermediate = 255;
			else Vppg_intermediate = Vppg_var;
		end else 
			if(((PGA_var+1)*Sin[counter] + DC_var) > 255) Vppg_intermediate  = 0;
			else Vppg_intermediate = ((255-DC_var) - (PGA_var+1)*Sin[counter]);

	end
	assign #1 Vppg  = Vppg_intermediate;

endmodule