`timescale 1ms/1ps
//`include "Controller.v"

module Controller_TB ();
    
    wire [7:0] ADC;
    reg Find_setting;
    reg CLK;
    reg rst_n;

    wire [3:0] LED_DRIVE;
    wire [6:0] DC_Comp;
    wire LED_IR;
    wire LED_RED;
    wire [3:0] PGA_Gain;
    wire CLK_Filter;
    wire [7:0] IR_ADC_Value;
    wire [7:0] RED_ADC_Value;
    
    Controller ctl_dut (
        .ADC                    (ADC),
        .Find_setting           (Find_setting),
        .CLK                    (CLK),
        .rst_n                  (rst_n),
        .LED_DRIVE              (LED_DRIVE),
        .DC_Comp                (DC_Comp),
        .LED_IR                 (LED_IR),
        .LED_RED                (LED_RED),
        .PGA_Gain               (PGA_Gain),
        .CLK_Filter             (CLK_Filter),
        .IR_ADC_Value           (IR_ADC_Value),
        .RED_ADC_Value          (RED_ADC_Value)
    ); 
	
	Fingerclip_Model_v2 front_dut (
	.DC_Comp	(DC_Comp),
	.PGA_Gain	(PGA_Gain),
	.LED_RED	(LED_RED),
	.LED_IR		(LED_IR),
	.Vppg		(ADC)
);
	

initial begin
	CLK = 1'b0;
        forever #0.5 CLK = ~CLK;    //1000Hz 

end


  initial begin
        
        rst_n = 1'b0;
        Find_setting = 1'b0;
        #2  
	rst_n = 1'b1;     
	Find_setting = 1'b1;
	#1
	Find_setting = 1'b0;
            

	
 	#50000
	$stop;
	

    end

endmodule
