`timescale 1ms/1ps
`include "Controller.v"

module Controller_TB ();
    
    reg [7:0] ADC;
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
    
    Controller controller_ins1 (
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

    initial begin
        CLK = 1'b0;
        forever #0.5 CLK = ~CLK;    //1000Hz 

        rst_n = 1'b1;
        ADC = 

    end





















endmodule