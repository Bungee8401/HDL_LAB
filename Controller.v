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
    reg [3:0] timer;

    parameter INITIAL   = 8'b1000_0000;
    parameter DC_RED    = 8'b0000_0001;
    parameter PGA_RED   = 8'b0000_0010;
    parameter DC_IR     = 8'b0000_0100;
    parameter PGA_IR    = 8'b0000_1000;
    parameter OPERATION = 8'b0001_0000;


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
            current_state <= next_state;
        end
    end



    // FSM state transition  TODO: LED_DRIVE is fixed here. shouldnt be this case in cadence.   
    always @(*) begin 
        if (!Find_setting) 
            //$display ("both 1!");
	    next_state = OPERATION;
        if (Find_setting) begin
            case(current_state) 
                
                INITIAL: begin              
                    
                    CLK_Filter = 1'b0;
                    LED_DRIVE = 4'd10;  // fixed now, TODO later
                    DC_Comp = 7'd64;
                    LED_IR = 1'b0;
                    LED_RED = 1'b0;
                    PGA_Gain = 4'd0;    

                    RED_DC_Comp = 7'b0;
                    IR_DC_Comp = 7'b1;
                    RED_PGA = 4'b0;
                    IR_PGA = 4'b0;

                    Find_setting_Complete = 1'b0;

                    V_min = 255;
                    V_max = 0;
                    average = 0;
                    i = 0;
                    timer = 0;

                    next_state = DC_RED;
                end

                DC_RED: begin // DC comb for RED 

                    LED_RED = 1'b1;
                    LED_IR = 1'b0;

                    if (i<10) begin //10ms
                        i = i + 1;
                        if ( ADC < V_min) begin
                          V_min = ADC;
                        //   next_state = DC_RED;
                        end
                        else if (ADC > V_max) begin
                          V_max = ADC;
                        //   next_state = DC_RED;
                        end
                    end  
                    else begin
                        average = (V_max + V_min) >> 1;
                        i = 0;
                        V_max = 0;
                        V_min = 255;

                    if (average<110) begin
                        DC_Comp = DC_Comp - 7'b1;
                        // next_state = DC_RED;
                    end
                        
                    else if (average>140) begin
                        DC_Comp = DC_Comp + 7'b1;
                        // next_state = DC_RED;
                    end
                        
                    else begin    
                        next_state = PGA_RED;
                        RED_DC_Comp = DC_Comp;
                    end
                  end                           
                end

                PGA_RED: begin  // PGA Gain for RED 
                    if (i<50) begin
                        i = i+1;
                        V_min = (ADC < V_min) ? ADC : V_min;
                        V_max = (ADC > V_max) ? ADC : V_max;

                        // if (ADC >= V_max) begin
                        //     V_max = ADC;
                        // end
                        // else if (ADC < V_min) begin
                        //     V_min = ADC;
                        // end
                    end
                    else begin
			            i=0;
                        if( 5<V_min && V_max<250 ) begin
                        PGA_Gain = PGA_Gain + 4'b1;
                        // next_state = PGA_RED;
                        end
                        
                        else if (V_min<5 || V_max>250 || PGA_Gain==4'd15 ) begin  //cutoff happend, max_pga_gain
		                    V_min = 255;
			                V_max = 0;
                            next_state = DC_IR;
                            RED_PGA = PGA_Gain; 
                            PGA_Gain = 4'd0; //initial pgagain
                        end
                    end           
                end

                DC_IR: begin // DC comb for IR 
                    LED_RED = 1'b0;
                    LED_IR = 1'b1;
            
                    if (i<10) begin //10ms
                            i = i + 1;
                            if ( ADC < V_min) begin
                            V_min = ADC;
                            end
                            else if (ADC > V_max) begin
                            V_max = ADC;
                            end
                    end  
                    else begin
                        average = (V_max + V_min) >> 1;
                        i = 0;
                        V_max = 0;
                        V_min = 255;

                        if (average<120) begin
                            DC_Comp = DC_Comp -7'b1;
                            // next_state = DC_IR;
                        end     
                        else if (average>135) begin
                            DC_Comp = DC_Comp +7'b1;
                            // next_state = DC_IR;
                        end                  
                        else begin
                            next_state = PGA_IR;
                            IR_DC_Comp = DC_Comp;
                        end
                    end 
                end

                PGA_IR: begin
                    if (i<50) begin
                        i = i+1;
                        if (ADC > V_max) begin
                            V_max = ADC;
                        end
                        else if (ADC < V_min) begin
                            V_min = ADC;
                        end
                    end
                    else begin
                        i=0;
                        if( 5<V_min && V_max<250 ) begin
                            PGA_Gain = PGA_Gain + 4'b1;
                            // next_state = PGA_RED;
                        end
                        
                        else if (V_min<5 || V_max>250 || PGA_Gain==4'd15 ) begin  //cutoff happend, max_pga_gain
                            
                            V_max = 0;
                            V_min = 255;
                            next_state = OPERATION;
                            IR_PGA = PGA_Gain; 
                            PGA_Gain = 4'd0; //initial pgagain
                            
                        end

                        
                    end 
                end
		

		        OPERATION:begin
		            Find_setting_Complete  = 1'b1;      // flag signal for LED switching block
		        end

                default:    next_state = INITIAL ;
                
            endcase
        end
    end

    always @(posedge CLK) begin  
     if(Find_setting_Complete) begin // setting found, switch faster -> 100Hz, 10ms       
        if(timer == 9) begin
            timer = 0;
            LED_RED = ~LED_RED;
            LED_IR = ~LED_IR;
        end else begin
            timer = timer + 1;       
            if (LED_RED == 1 && LED_IR == 0) begin
                RED_ADC_Value = ADC;
                PGA_Gain = RED_PGA;
                DC_Comp = RED_DC_Comp;
            end 

                if (LED_RED == 0 && LED_IR == 1) begin
                    IR_ADC_Value = ADC;
                    PGA_Gain = IR_PGA;
                    DC_Comp = IR_DC_Comp;           
                end
            end
        end
        
    end
endmodule

  /*  task find_average (input ADC, input CLK,
            output average);
            always @(posedge CLK) begin
                wait (!dcReady);
                while (i<10) begin  //10ms
                    i = i + 1;
                   if (ADC < V_min) begin
                    V_min = ADC;
                    else if(ADC > V_max) begin
                        V_max = ADC;
                        end
                    end
                    average = (V_max + V_min) >> 1;
                end
                if (i > 10) begin
                    averageReady = 1;
                end
            end */

            