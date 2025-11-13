`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.11.2025 19:33:35
// Design Name: 
// Module Name: LED_Peripheral
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module LED_Peripheral(
    input clk,reset_n,write_enable,
    input [7:0] write_address,write_data,
    output reg [15:0]led
    );
    
    reg [7:0] LED_control, LED_data_01, LED_data_02, store_control_data;
    reg [1:0] cs,ns;
    
    parameter RESET         = 3'b000;
    parameter read_data     = 3'b001;
    parameter display_led   = 3'b011;
    
     always @(posedge clk)
    begin
        if (reset_n) cs <= RESET; // assign cs to ns
        else        cs <= ns;
    end
    
    always @(*) // state logic which is always sequential
        begin
        case (cs)
            RESET: ns = reset_n ? RESET : read_data;                        //0
            read_data : ns = write_enable ? display_led : read_data;        //1
            display_led : ns = reset_n ? RESET : read_data;                 //3
            default: ns = RESET;
        endcase
        end
    
    always @(posedge clk)
    begin
     
        case(cs)
        RESET:
            begin
                led <= 0;
                LED_control <= 0;
                LED_data_01 <= 0;
                LED_data_02 <= 0;
            end
        
        read_data :
             begin
                case(write_address)
                8'h01 :
                    LED_control <= write_data;
                8'h02 :
                    LED_data_01 <= write_data;
                8'h03 :
                    LED_data_02 <= write_data;
                default : begin
                    LED_data_01 <= 0; 
                    LED_data_02 <= 0; 
                    end 
                endcase
             end  
     
        display_led :
            begin
                   if(LED_control[0])
                begin
                    led <= {LED_data_01,LED_data_02};
                end
                   else
                led <= 0;
            end
        endcase
        end
endmodule

