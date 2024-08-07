`timescale 1ms/1ms

module Controller (
    input [7:0] ADC,
    input Find_setting,
    input CLK,
    input rst_n,

    output reg [3:0] LED_DRIVE,
    output reg [6:0] DC_Comp,
    output reg LED_IR,
    output reg LED_RED,
    output reg [3:0] PGA_Gain,
    output reg CLK_Filter,
    output reg [7:0] IR_ADC_Value,
    output reg [7:0] RED_ADC_Value
);
    
    always @(posedge CLK) begin
        CLK_Filter <= ~CLK_Filter;
    end

    reg [7:0] current_state;
    reg [7:0] next_state;
    reg [6:0] RED_DC_Comp;
    reg [6:0] IR_DC_Comp;
    reg [3:0] RED_PGA;
    reg [3:0] IR_PGA;
    reg Find_setting_Complete;

    parameter INITIAL   = 8'b1000_0000;
    parameter DC_RED    = 8'b0000_0001;
    parameter PGA_RED   = 8'b0000_0010;
    parameter DC_IR     = 8'b0000_0100;
    parameter PGA_IR    = 8'b0000_1000;
    parameter OPERATION = 8'b0001_0000;
    
    // FSM state transition 
    always @(posedge CLK or negedge rst_n) begin
        if (~rst_n) begin
            current_state <= INITIAL;
        end
        else if (Find_setting) begin 
            current_state <= next_state;
        end
    end

    // FSM state def ---- INITIAL -> DC_RED -> PGA_RED -> DC_IR -> PGA_IR, no OPERATION here! 
    // TODO: LED_DRIVE is fixed here. shouldnt be this case in cadence.   
    always @(*) begin 
        if(Find_setting && !Find_setting_Complete) begin
            case(current_state) 

                DC_RED: begin // DC comb for RED 
                    LED_RED = 1'b1;
                    LED_IR = 1'b0;
                    if (ADC<110) begin
                        DC_Comp = DC_Comp - 7'b1;
                        next_state = DC_RED;
                    end
                        
                    else if (ADC>140) begin
                        DC_Comp = DC_Comp + 7'b1;
                        next_state = DC_RED;
                    end
                        
                    else begin    
                        next_state = PGA_RED;
                        RED_DC_Comp = DC_Comp;
                    end
                        
                end
                
                PGA_RED: begin  // PGA Gain for RED 
                    if( 5<ADC<250 ) begin
                        PGA_Gain = PGA_Gain + 4'b1;
                        next_state = PGA_RED;
                    end
                        
                    else if (ADC<5 | ADC>250 | PGA_Gain==4'd15 ) begin  //cutoff happend, max_pga_gain
                        next_state = DC_IR;
                        RED_PGA = PGA_Gain; 
                        PGA_Gain = 4'd7; //initial pgagain
                    end
                end

                DC_IR: begin // DC comb for IR 
                    LED_RED = 1'b0;
                    LED_IR = 1'b1;

                    if (ADC<120) begin
                        DC_Comp = DC_Comp -7'b1;
                        next_state = DC_IR;
                    end
                        
                    else if (ADC>140) begin
                        DC_Comp = DC_Comp +7'b1;
                        next_state = DC_IR;
                    end
                        
                    else begin
                        next_state = PGA_IR;
                        IR_DC_Comp = DC_Comp;
                    end

                end 

                PGA_IR: begin
                     if( 5<ADC<250 ) begin
                        PGA_Gain = PGA_Gain + 4'b1;
                        next_state = PGA_RED;
                    end
                        
                    else if (ADC<5 | ADC>250 | PGA_Gain==4'd15 ) begin
                        next_state = DC_IR;
                        IR_PGA = PGA_Gain;
                        PGA_Gain = 4'd7;
                        Find_setting_Complete  = 1'b1;      // flag signal for LED switching block
                    end
                end

                INITIAL: begin              
                    CLK_Filter = 1'b0;
                    LED_DRIVE = 4'd10;  // begin in the middle
                    DC_Comp = 7'd64;
                    LED_IR = 1'b0;
                    LED_RED = 1'b0;
                    PGA_Gain = 4'd0;    // begin in the middle

                    RED_DC_Comp = 7'b0;
                    IR_DC_Comp = 7'b0;
                    RED_PGA = 4'b0;
                    RED_PGA = 4'b0;

                    Find_setting_Complete = 1'b0;
                end
                
                default:    next_state = INITIAL ;
                
            endcase
        end
    end

    //OPERATION ---- LED switching
    always @(posedge CLK) begin  
        if(Find_setting_Complete) begin // setting found, switch faster -> 100Hz, 10ms
            forever begin
                #10 LED_RED = ~LED_RED;
                #10 LED_IR = ~LED_IR;
            end
             
        end
        
        // else begin  // before found,switch slower
            
        // end
    end
    //hi! see if you can see this on github!
endmodule
