/**
This is an experimental approach to make the verilog model behave more like the physical Fingerclip.
Many thanks to Jonathan Strobl for providing the code for this revised fingerclip model.
**///(vw)

`timescale 1ms/1us

module Fingerclip_Model_v2(Vppg, DC_Comp, PGA_Gain, LED_RED, LED_IR);
	
	output wire [7:0] Vppg;
	input [6:0] DC_Comp;
	input [3:0] PGA_Gain;
	input LED_RED, LED_IR;

	localparam SINETABLE_SIZE = 20;
	localparam SHIFT_BETWEEN_LEDS = 8;

	reg clk;

	real DC_var, PGA_var;

	real Sin[19:0];
	reg [5:0] counter, advanced_counter;
	reg positiv, advanced_positiv;

	real Vppg_real;

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
		positiv = 0;
	end

	always #16 clk = !clk; //545

	always@(*) begin // LED input sanity check
		if(LED_RED & LED_IR) $display("Both LEDs are on!");
	end
	
	always@(posedge clk) begin // generates the sinus waveform counter

		if(counter < 19) counter = counter + 1;
		else begin
			counter = 0;
			positiv = !positiv;
		end
	end
	

	always @(*) begin // generate sinus signal
		PGA_var = $itor(PGA_Gain + 1) / 8.0;
		DC_var = (64.0 - $itor(DC_Comp)) / 16.0;

		advanced_counter = counter;
		advanced_positiv = positiv;
		if (LED_IR) begin
			advanced_counter = advanced_counter + SHIFT_BETWEEN_LEDS;
			if (advanced_counter >= SINETABLE_SIZE) begin
				advanced_counter = advanced_counter - SINETABLE_SIZE;
				advanced_positiv = !advanced_positiv;
			end
		end

		Vppg_real = Sin[advanced_counter] * (advanced_positiv ? 1.0 : -1.0);

		// Model LED characteristics (gain, offset)
		if (LED_RED) begin
			Vppg_real = Vppg_real * 0.7;
			Vppg_real = Vppg_real + 0.2;
		end

		// Apply DC comp and PGA gain as long as only one LED is on
		if (LED_IR != LED_RED) begin
			Vppg_real = Vppg_real + DC_var;
			Vppg_real = Vppg_real * PGA_var;
		end else begin
			// Both LEDs on, cut the output
			Vppg_real = 0;
		end

		// Go from [-1.0, +1.0] range to [0, 1.0]
		Vppg_real = (Vppg_real + 1.0) / 2;

		// Convert to int in range [0, 255] and clamp
		if (Vppg_real < 0.0)
			Vppg_intermediate = 0;
		else if (Vppg_real > 1.0)
			Vppg_intermediate = 255;
		else
			Vppg_intermediate = $rtoi(Vppg_real * 255);
	end

	assign #1 Vppg = Vppg_intermediate;
endmodule
