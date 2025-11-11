`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2025 13:47:36
// Design Name: 
// Module Name: Traffic_Light
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


module Traffic_Light(
    input clk,rst,
    output reg [3:0]LG,
    output reg [3:0]SG,
    output reg [3:0]RG,
    output reg [3:0]R
    );
    
    wire en_30sec;        // 1 Hz enable pulse for timekeeping
    reg [6:0] counter;
    reg [2:0] cs,ns;
    
    parameter RESET = 3'b000;
    parameter T1    = 3'b001;
    parameter T2    = 3'b010;
    parameter T3    = 3'b011;
    parameter T4    = 3'b100;
    
   pulse_generator pulse_gen (
        .clk(clk),
        .rst(rst),
        .en_30sec(en_30sec)
    );
    
    always @(posedge clk)
    begin
        if (rst) cs <= RESET; // assign cs to ns
        else        cs <= ns;
    end
    
    
    always @(*) // state logic which is always sequential
        begin
        case (cs)
            RESET: ns = !rst ? T1 : RESET;
            T1 : ns = en_30sec ? T2 : T1;
            T2 : ns = en_30sec ? T3 : T2;
            T3 : ns = en_30sec ? T4 : T3;
            T4 : ns = en_30sec ? T1 : T4;
            default: ns = RESET;
        endcase
        end
        
    always @(posedge clk or posedge rst) // sequential output logic
    begin
    if(rst)
        begin
            LG <= 0;
            SG <= 0;
            RG <= 0;
            R <= 0;
        end
      
     else
        begin
            case(cs)
                RESET : 
                    begin
                        LG <= 0;
                        SG <= 0;
                        RG <= 0;
                        R <= 0;
                    end
                 
                 T1 :
                    begin
                        LG[3:0] <= 4'b 0001;
                        SG[3:0] <= 4'b 0001;
                        RG[3:0] <= 4'b 0000;
                        R[3:0]  <= 4'b 1110;
                    end
                 T2 :
                    begin
                        LG[3:0] <= 4'b 0010;
                        SG[3:0] <= 4'b 0010;
                        RG[3:0] <= 4'b 0010;
                        R[3:0]  <= 4'b 1101;
                    end
                 
                 T3 :
                    begin
                        LG[3:0] <= 4'b 0100;
                        SG[3:0] <= 4'b 0100;
                        RG[3:0] <= 4'b 0100;
                        R[3:0]  <= 4'b 1011;
                    end
                             
                 T4 :
                    begin
                        LG[3:0] <= 4'b 1000;
                        SG[3:0] <= 4'b 1000;
                        RG[3:0] <= 4'b 1000;
                        R[3:0]  <= 4'b 0111;
                    end
                 
            endcase
            
        end         
    end

endmodule

module pulse_generator (
    input clk,         
    input rst,        
    output reg en_30sec 
);
    reg [31:0] cnt_30sec;  // counter for 3,000,000,000
    
    // 30 sec enable generation (pulse every 3,000,000,000 clock cycles = 30s)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_30sec <= 0;
            en_30sec <= 0;
        end else begin
            if (cnt_30sec == 30_000_000_000 - 1) begin
                cnt_30sec <= 0;
                en_30sec <= 1;  // Pulse high for one clock cycle
            end else begin
                cnt_30sec <= cnt_30sec + 1;
                en_30sec <= 0;  // Stay low while counting
            end
        end
    end
endmodule
