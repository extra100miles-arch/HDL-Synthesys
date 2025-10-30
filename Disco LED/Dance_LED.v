`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:19:40
// Design Name: 
// Module Name: Dance_LED
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


module Dance_LED(
    output [15:0]led,     // 16 Display LEDs for dance
    input [1:0]speed,     // 2 Switches - speed[0], speed[1] = Speed control  sw[2] = Direction Control
    input direction,      // direction = Direction Control
    input rst,            // Reset all LEDs
    input clk             // 100MHz clock
    );
    
    wire enable_pulse;

    // Determines clk speed as per switches selected
    clock_select clk_sel(
        .enable_pulse(enable_pulse),
        .speed(speed),
        .clk(clk),
        .rst(rst)
    );
    
    // Returns the LED output pattern (Direction and Speed)
    led_pattern pattern(
        .led(led),
        .enable_pulse(enable_pulse),
        .direction(direction),
        .rst(rst),
        .clk(clk)
    );  
    
endmodule



module clock_select (
    output reg enable_pulse,      // Selected clock Frequency
    input [1:0]speed,             //Selected Switches
    input clk,                    // 100 MHz input clock
    input rst                     // Reset   
);
    reg [26:0] cnt;              // Counter (large enough for 100M)
    reg [26:0] threshold;        // Compare value for selected frequency
    
    // Calculate threshold based on speed selection
    always @(*) begin
        case(speed)
            2'b00:   threshold = 27'd100_000_000; // 1 Hz  
            2'b01:   threshold = 27'd50_000_000;  // 2 Hz  
            2'b10:   threshold = 27'd33_333_333;  // 3 Hz  
            2'b11:   threshold = 27'd25_000_000;  // 4 Hz  
            default: threshold = 27'd100_000_000; // Default 1 Hz
        endcase
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            enable_pulse <= 0;
        end else begin
            enable_pulse <= 0;  // Default: pulse is LOW
            
            if (cnt >= threshold - 1) begin
                cnt <= 0;
                enable_pulse <= 1;  // Pulse HIGH for 1 cycle
            end else begin
                cnt <= cnt + 1;
            end
        end
    end  
endmodule

module led_pattern(
    output reg [15:0]led,
    input enable_pulse,
    input direction,
    input rst,
    input clk
);

    always @(posedge clk or posedge rst ) begin
        if(rst) begin
            led <= 16'h0001; 
        end
        else begin
            if(enable_pulse) begin 
                if(direction) led <= {led[0], led[15:1]};      // Rotate Left
                else led <= {led[14:0], led[15]};              // Rotate right  
            end
        end
    end

endmodule