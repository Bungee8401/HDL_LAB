`timescale 1ms/1ps

module Controller (
    input  [7:0] ADC,
    input  Find_setting,
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
    reg Find_setting_Complete = 1'b0;

    reg [6:0] RED_DC_Comp;
    reg [6:0] IR_DC_Comp;

    reg [3:0] RED_PGA;
    reg [3:0] IR_PGA;


    reg [7:0] V_max;
    reg [7:0] V_min;
    reg [8:0] average;

    reg [7:0] i;
    //reg [7:0] j;
    reg [3:0] timer;
    reg [12:0] adc_sum;

    parameter INITIAL   = 8'b1000_0000;
    parameter DC_RED    = 8'b0000_0001;
    parameter PGA_RED   = 8'b0000_0010;
    parameter DC_IR     = 8'b0000_0100;
    parameter PGA_IR    = 8'b0000_1000;
    parameter OPERATION = 8'b0001_0000;

    parameter PGA_DC_IN = 8'b0001_0001;
    parameter PGA_DC_OUT = 8'b0001_0011;
    parameter PGA_RED_IN = 8'b0001_0100;
    parameter PGA_RED_OUT = 8'b0001_0101;

    //clk_filter
    always @(posedge CLK) begin
        CLK_Filter <= ~CLK_Filter;
    end    


    // FSM state ffs    
    always @(posedge CLK or negedge rst_n) begin
        if (~rst_n) begin
            current_state <= INITIAL;
        end
        else if (Find_setting) begin 
            current_state <= DC_RED;
        end
        else begin
            current_state <= next_state;
        end
    end

     task calculate_min_max;
        input [7:0] ADC;
        output [7:0] V_max;
        output [7:0] V_min;
        integer k;
         begin
            V_max = 0;
            V_min = 255;
            for (k = 0; k < 10; k = k + 1) begin
                if (ADC < V_min) begin
                    V_min = ADC;
                else if(ADC > V_max) begin
                    V_max = ADC;
                end
                end
            end       
        end
     endtask
        
    // FSM state transition  TODO: LED_DRIVE is fixed here. shouldnt be this case in cadence.   
    always @(*) begin 
            case(current_state) 
                
                INITIAL: begin              
                    @(negedge CLK)
                    CLK_Filter = 1'b0;
                    LED_DRIVE = 4'd10;  // fixed now, TODO later
                    DC_Comp = 7'd44;	// start somewhere
                    LED_IR = 1'b0;
                    LED_RED = 1'b0;
                    PGA_Gain = 4'd0;
                    adc_sum = 13'b0;    

                    RED_DC_Comp = 7'b0;
                    IR_DC_Comp = 7'b0;
                    RED_PGA = 4'b0;
                    IR_PGA = 4'b0;

                    Find_setting_Complete = 1'b0;

                    V_min = 255;
                    V_max = 0;
                    average = 0;
                    i = 0;
                    timer = 0;

                    next_state = DC_RED; //next_state = DC_RED;
                end

                DC_RED: begin // DC comb for RED 

                    LED_RED = 1'b1;
                    LED_IR = 1'b0;

                    if (i<26) begin
                        adc_sum = adc_sum + ADC;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        average = adc_sum / 27;
                        adc_sum = 13'b0;
                        if (average<120) begin
                            // DC_Comp = DC_Comp - 7'b1;
                            DC_Comp = DC_Comp - DC_Comp/2;
                            // DC_Comp = DC_Comp - ((120-average)>>1);
                        end
                            
                        else if (average>135) begin
                            // DC_Comp = DC_Comp + 7'b1;
                            DC_Comp = DC_Comp + DC_Comp/2;
                            // DC_Comp = DC_Comp + ((135-average)>>1);
                        end
                            
                        else begin
                            next_state = PGA_RED;
                            @ (negedge CLK);    
                            i=0;
                            RED_DC_Comp = DC_Comp;
                            V_max = 0;
                            V_min = 255;
                            //DC_Comp = 0;
                            //PGA_Gain = 4'd0;
                            PGA_Gain = 4'd7;
                        end
                    end
                    // if ( ADC < V_min) begin
                    //     V_min = ADC;
                        
                    // //   next_state = DC_RED;
                    // end
                    // else if (ADC > V_max) begin
                    //     V_max = ADC;
                        
                    // //   next_state = DC_RED;
                    // end
                    
                    // average = (V_max + V_min) >> 1;     
                    
                    
                  end                           
                


                PGA_RED: begin

                    if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            V_max = 0;
                            V_min = 255; 
                            PGA_Gain = PGA_Gain + 4'b1;
                            next_state = PGA_RED_IN;
                            
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            V_max = 0;
                            V_min = 255; 
                            PGA_Gain = PGA_Gain - 4'b1;
                            next_state = PGA_RED_OUT;
                                                
                        end
                    end   
                end

                PGA_RED_IN: begin
                        if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            PGA_Gain = PGA_Gain + 4'b1;
                            V_max = 0;
                            V_min = 255;
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            @ (negedge CLK);
                            next_state = DC_IR;
                            RED_PGA = PGA_Gain - 4'b1;
                            PGA_Gain = 0;
                            V_max = 0;
                            V_min = 255;
                        end
                end
                end

                
                PGA_RED_OUT: begin
                        if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            next_state = DC_IR;
                            @ (negedge CLK);
                            RED_PGA = PGA_Gain + 4'b1;
                            PGA_Gain = 0;
                            V_max = 0;
                            V_min = 255;                       
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            IR_PGA = PGA_Gain - 4'b1;
                            V_max = 0;
                            V_min = 255; 
                        end
                end
                end

                // PGA_RED: begin  // PGA Gain for RED 
                
                //     if (i<26) begin
                //         V_min = (ADC < V_min) ? ADC : V_min;
                //         V_max = (ADC > V_max) ? ADC : V_max;
                //         i=i+1;
                //     end
                //     else begin
                //         i=0;
                //         if (10<V_min && V_max<245) begin
                //             PGA_Gain = PGA_Gain + 4'd2;
                //             // next_state = PGA_RED;
                //         end
                        
                //         if (V_min<10 || V_max>245 || PGA_Gain == 4'd15 ) begin  //cutoff happend, max_pga_gain 
                //             next_state = DC_IR;
                //             @ (negedge CLK);
                //             RED_PGA = PGA_Gain-2; 
                //             PGA_Gain = 4'd0; //initial pgagain
                //             V_max = 0;
                //             V_min = 255;
			    
                //         end
                //     end   
                // end

                DC_IR: begin // DC comb for IR 
                    LED_RED = 1'b0;
                    LED_IR = 1'b1;

                    if (i<26) begin
                        adc_sum = adc_sum + ADC;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        average = adc_sum / 27;
                        adc_sum = 13'b0;
                    
                        if (average<120) begin
                            // DC_Comp = DC_Comp - 7'b1; 
                            DC_Comp = DC_Comp - DC_Comp/2;
                            // DC_Comp = DC_Comp - ((120-average)>>1); 
                        end
                            
                        else if (average>135) begin
                            // DC_Comp = DC_Comp + 7'b1; 
                            DC_Comp = DC_Comp + DC_Comp/2; 
                            // DC_Comp = DC_Comp + ((135-average)>>1);  
                        end
                    
                        else begin  
                            next_state = PGA_IR;
                            @ (negedge CLK);
                            IR_DC_Comp = DC_Comp;
                            V_max = 0;
                            V_min = 255;
                            // DC_Comp = 0;
                            // PGA_Gain = 4'd0;
                            PGA_Gain = 4'd7;
                        end
                    end
                end 
                
                PGA_IR: begin

                    if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            V_max = 0;
                            V_min = 255; 
                            PGA_Gain = PGA_Gain + 4'b1;
                            next_state = PGA_IR_IN;
                            
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            V_max = 0;
                            V_min = 255; 
                            PGA_Gain = PGA_Gain - 4'b1;
                            next_state = PGA_IR_OUT;
                                                
                        end
                    end   
                end

                PGA_IR_IN: begin
                        if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            PGA_Gain = PGA_Gain + 4'b1;
                            V_max = 0;
                            V_min = 255;
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            IR_PGA = PGA_Gain - 4'b1;
                            PGA_Gain = 0;
                            V_max = 0;
                            V_min = 255; 
                            next_state = OPERATION;
                        end
                end
                end

                
                PGA_IR_OUT: begin
                        if (i<26) begin
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;
                        i=i+1;
                    end
                    else begin
                        i=0;
                        if (10<V_min && V_max<245) begin
                            IR_PGA = PGA_Gain + 4'b1;
                            PGA_Gain = 0;
                            V_max = 0;
                            V_min = 255; 
                            next_state = OPERATION;
                        end
                        
                        if (V_min<10 || V_max>245 ) begin  
                            IR_PGA = PGA_Gain - 4'b1;
                            V_max = 0;
                            V_min = 255; 
                        end
                end
                end




                // PGA_IR: begin

                //     if (i<26) begin
                //         V_min = (ADC < V_min) ? ADC : V_min;
                //         V_max = (ADC > V_max) ? ADC : V_max;
                //         i=i+1;
                //     end
                //     else begin
                //         i=0;
                //         if (10<V_min && V_max<245) begin
                //             PGA_Gain = PGA_Gain + 4'd2;
                //             // next_state = PGA_RED;
                //         end
                        
                //         if (V_min<10 || V_max>245 || PGA_Gain == 4'd15 ) begin   
                //             next_state = OPERATION;
                //             @ (negedge CLK);
                //             V_max = 0;
                //             V_min = 255;

                //             IR_PGA = PGA_Gain-2; 
                //             PGA_Gain = 4'd0; //initial pgagain
                            
                //         end
                //     end   
                // end
		

		        OPERATION: begin
		            Find_setting_Complete  = 1'b1;      // flag signal for LED switching block
		        end

                default:    current_state = INITIAL ;
                
            endcase
        end
    //end

    always @(posedge CLK) begin  
        if(Find_setting_Complete) begin // setting found, switch faster -> 100Hz, 10ms       
            if(timer == 9) begin
                timer <= 0;
                LED_RED <= ~LED_RED;
                LED_IR <= ~LED_IR;
            end else begin
                timer <= timer + 1;       
                if (LED_RED == 1 && LED_IR == 0) begin
                    RED_ADC_Value <= ADC;
                    PGA_Gain <= RED_PGA;
                    DC_Comp <= RED_DC_Comp;
                end 

                if (LED_RED == 0 && LED_IR == 1) begin
                    IR_ADC_Value <= ADC;
                    PGA_Gain <= IR_PGA;
                    DC_Comp <= IR_DC_Comp;           
                end
            end
        end
        
    end
endmodule



            
