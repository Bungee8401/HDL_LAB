`timescale 1ms/1us
module Fingerclip_Model_TB ();

	
	
	reg [0:6] DC_Comp;
	reg [0:3] PGA_Gain;
	wire [0:7] Vppg;
	reg clk, LED_RED, LED_IR;
	
	Fingerclip_Model dut(.Vppg(Vppg), .DC_Comp(DC_Comp), .PGA_Gain(PGA_Gain), .LED_RED(LED_RED), .LED_IR(LED_IR));

	initial begin
		DC_Comp = 0;
		PGA_Gain = 0;
		clk = 0;
		LED_RED = 0;
		LED_IR = 1;
		#2 LED_RED = 1;
		#2 LED_RED = 0;
		#100000 $stop;
	end

	always #500 clk = !clk;
	
	always begin
		LED_RED = !LED_RED;
		#5 LED_IR = !LED_IR;
	end


	always@(posedge clk) begin
		if (DC_Comp < 40) DC_Comp = DC_Comp +1;
		else PGA_Gain = PGA_Gain + 1;

		

	end


endmodule
