`timescale 1ms/1ms

module FIR_TB ();

    reg CLK_Filter;
    reg [7:0] ADC_Value;
    reg rst_n;

    wire [19:0] Out_Filtered;

    FIR_IR ins1 (
        .CLK_Filter     (CLK_Filter),
        .IR_ADC_Value   (ADC_Value),
        .rst_n          (rst_n),

        .Out_IR_Filtered    (Out_Filtered)
    );

    
    initial forever #1 CLK_Filter = ~CLK_Filter; 

	initial begin
        //$dumpfile("test.vcd"); $dumpvars;

        CLK_Filter = 0;
        rst_n = 1;
        IR_ADC_Value = 0;   

        #1 
        rst_n = 0;
        #4
        rst_n = 1;
        #2
        IR_ADC_Value = 200;
        #6
        rst_n = 0;
        #2
        rst_n = 1;
        #2
        IR_ADC_Value = 100;

        #6

	    $stop;
        $finish;



    end






endmodule
