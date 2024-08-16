`timescale 1ms/1ps

module Controller_small (
    input  [7:0] ADC,
    input  Find_Setting,
    input  CLK,
    input  rst_n,

    output reg [3:0] LED_DRIVE,
    output reg [6:0] DC_Comp,
    output reg LED_IR,
    output reg LED_RED,
    output reg [3:0] PGA_Gain,
    output reg CLK_Filter,
    output reg [7:0] IR_ADC_Value,
    output reg [7:0] RED_ADC_Value

);
    
    reg [7:0] current_state;
    reg [7:0] next_state;

    reg [6:0] RED_DC_Comp;
    reg [6:0] IR_DC_Comp;

    reg [3:0] RED_PGA;
    reg [3:0] IR_PGA;

    reg [7:0] V_max;
    reg [7:0] V_min;
    reg [8:0] average;

    reg [10:0] i; 
    reg [3:0] timer;


    parameter INITIAL   = 8'b1000_0000; 
    parameter DC_RED    = 8'b0000_0001;//1
    parameter PGA_RED   = 8'b0000_0010;//2
    parameter DC_IR     = 8'b0000_0100;//4
    parameter PGA_IR    = 8'b0000_1000;//8
    parameter OPERATION = 8'b0001_0000;//16

    parameter ONE_ADC_PERIOD = 1000;
    parameter HALF_ADC_PERIOD = 500;//PAG Counter period
    parameter TWENTY_ADC_SAMPLE = 20;//DC Counter period

    //clk_filter
    always @(posedge CLK or negedge rst_n) begin
        if(~rst_n)
            CLK_Filter <= 1'd0;
        else
            CLK_Filter <= ~CLK_Filter;
    end    


    // FSM state transition at positive CLK 
    always @(posedge CLK or negedge rst_n) begin
        if (~rst_n) begin
            current_state = INITIAL;
        end
        else begin
            if (Find_Setting) begin 
                current_state = DC_RED;
            end
            else begin
                // current_state = next_state;
                case(current_state) 
                
                    INITIAL: begin              
                        //LED_DRIVE = 4'd10;  // fixed led drive
                        DC_Comp = 7'd127;	//highest dc_comp value
                        LED_IR = 1'b0;//turn off IR LED 
                        LED_RED = 1'b0; //turn off RED LED 
                        PGA_Gain = 4'd0;  

                        RED_DC_Comp = 7'b0;
                        IR_DC_Comp = 7'b0;
                        RED_PGA = 4'b0;
                        IR_PGA = 4'b0;

                        V_min = 255;
                        V_max = 0;
                        average = 0;
                        i = 0; //counter for dc and pga
                        timer = 0; //counter for LED_RED and LED_IR alternative

                        current_state = DC_RED; ////after initial, the controller starts to find LED_RED's DC_comp;
                    end

                    DC_RED: begin // DC comb for RED 
                        
                        LED_RED = 1'b1; //turn on LED_RED
                        LED_IR = 1'b0;

                        if (i<TWENTY_ADC_SAMPLE) begin
                            
                            V_max = (ADC > V_max)?  ADC:V_max; //find maximum voltage value
                            V_min = (ADC < V_min)?  ADC:V_min;   //find minimum voltage value
                            
                        end
                        else begin
                            i=0;
                            average = (V_max + V_min) >>1; 
                            if (average<116) begin 
                                DC_Comp = DC_Comp - 7'd4;

                                V_max = 0;
                                V_min = 255;
                            end
                                
                            else if (average>140) begin
                                DC_Comp = DC_Comp + 7'd3;

                                V_max = 0;
                                V_min = 255;
                            end
                                
                            else begin                             
                                RED_DC_Comp = DC_Comp;
                                V_max = 0;
                                V_min = 255;
                                average = 9'd0;
                                PGA_Gain = 4'd1;
                                current_state = PGA_RED;
                            end
                        end
                        i=i+1;
                    end 

                    PGA_RED: begin
                            if (i<HALF_ADC_PERIOD) begin
                                V_min = (ADC < V_min) ? ADC : V_min;
                                V_max = (ADC > V_max) ? ADC : V_max;
                                i=i+1;
                            end
                            else begin
                                i=0;
                                if (10<V_min && V_max<245) begin
                                    PGA_Gain = PGA_Gain + 4'd1;
                                    V_max = 0;
                                    V_min = 255;                                    
                                    // next_state = PGA_RED;                            
                                end
                                
                                if (V_min<10 || V_max>245 ) begin  
                                    V_max = 0;
                                    V_min = 255; 
                                    
                                    RED_PGA = PGA_Gain - 4'd1;
                                    
                                    PGA_Gain = 4'd0;
                                    DC_Comp =  7'd30;
                                    current_state = DC_IR;                     
                                end
                            end                              
                    end                         

                    DC_IR: begin // DC comb for IR 
                        LED_RED = 1'b0;
                        LED_IR = 1'b1;

                        if (i<TWENTY_ADC_SAMPLE) begin
                            V_max = (ADC > V_max)?  ADC:V_max;
                            V_min = (ADC < V_min)?  ADC:V_min;                   
                            
                        end
                        else begin
                            i=0;
                            average = (V_max + V_min) >>1; 
                            if (average<116) begin
                                DC_Comp = DC_Comp - 7'd4; 

                                V_max = 0;
                                V_min = 255;

                            end
                                
                            else if (average>140) begin
                                DC_Comp = DC_Comp + 7'd3; 

                                V_max = 0;
                                V_min = 255;

                            end
                        
                            else begin  
                                current_state = PGA_IR;
                                IR_DC_Comp = DC_Comp;
                                V_max = 0;
                                V_min = 255;
                                PGA_Gain = 4'd1;
                                average = 9'd0;
                            end
                        end
                        i=i+1;
                    end 

                    PGA_IR: begin
                            if (i<HALF_ADC_PERIOD) begin
                                V_min = (ADC < V_min) ? ADC : V_min;
                                V_max = (ADC > V_max) ? ADC : V_max;
                                i = i+1;
                            end
                            else begin
                                i=0;
                                if (10<V_min && V_max<245) begin
                                    V_max = 0;
                                    V_min = 255; 
                                    PGA_Gain = PGA_Gain + 4'b1;
                                    next_state = PGA_IR;                            
                                end
                                
                                if (V_min<10 || V_max>245 ) begin  
                                    V_max = 0;
                                    V_min = 255; 
                                    IR_PGA = PGA_Gain - 4'b1;                                    
                                    PGA_Gain = 4'b0;
                                    current_state = OPERATION;
                                       
                                end
                            end   
                    end
        
                    OPERATION: begin
 
                        if(timer == 9) begin //the LED of the finger-clip needs to start alternating between IR and RED with a frequency of 100 Hz. 100Hz -> 10ms
                            timer = 0;
                            LED_RED = ~LED_RED; 
                            LED_IR = ~LED_IR;	
                                if (LED_RED == 1 && LED_IR == 0) begin
                                    PGA_Gain = RED_PGA;
                                    DC_Comp = RED_DC_Comp;
                                end 
                                if (LED_RED == 0 && LED_IR == 1) begin
                                    PGA_Gain = IR_PGA;
                                    DC_Comp = IR_DC_Comp; 			
                                end 
                        end
                        else begin
                                       
                                if (LED_RED == 1 && LED_IR == 0) begin
                                    RED_ADC_Value = ADC;
                
                                end 

                                if (LED_RED == 0 && LED_IR == 1) begin
                                    IR_ADC_Value = ADC;
                            
                                end
                        end
                        timer = timer + 1;   
                    end
                         
        
                endcase

            end
        end
                   
        end
        
endmodule

 


 
