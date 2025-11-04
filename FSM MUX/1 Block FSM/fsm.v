`timescale 1ns / 1ps

module fsm(
    output reg [3:0]Y,
    output reg output_enable,
    input [3:0] I0,
    input [3:0] I1,
    input [3:0] I2,
    input [3:0] I3,    
    input [1:0]S,
    input input_enable,
    input rst,
    input clk
    );
    
    localparam [1:0]
    IDLE  = 0,
    CHECK_SELECT_LINE = 1,
    VALID_OUTPUT = 2;
    
    reg [1:0] current;
    reg [3:0] I0_reg;
    reg [3:0] I1_reg;
    reg [3:0] I2_reg;
    reg [3:0] I3_reg;
    reg [1:0] S_reg;

    
    always @ (posedge clk) begin
        if (rst) begin 
            Y <= 4'b0;
            output_enable <= 0;
            current <= IDLE;
        end
        else begin 
            case(current)
                IDLE:
                    if(input_enable) begin
                        I0_reg <= I0;
                        I1_reg <= I1;
                        I2_reg <= I2;
                        I3_reg <= I3;
                        S_reg <= S;
                        current <= CHECK_SELECT_LINE;
                        output_enable <= 0;
                    end
                CHECK_SELECT_LINE:
                    begin
                        case(S_reg)
                            2'b00 : Y <= I0_reg;  
                            2'b01 : Y <= I1_reg;  
                            2'b10 : Y <= I2_reg;  
                            2'b11 : Y <= I3_reg; 
                            default: Y <= 0;
                        endcase
                        current <= VALID_OUTPUT;
                        output_enable <= 0;
                   end
                VALID_OUTPUT:
                    begin 
                        output_enable <= 1;
                        current <= IDLE;           
                    end
             endcase       
        end  
    end    
   
endmodule
