`timescale 1ns / 1ps

module rom_sync(
    input clk,            // 100 MHz Basys 3 clock
    input rst,            // Reset button (active high)
    input load,           // Load button (T17) - press to display ROM value
    input [3:0] address,  // Binary input switches (SW3-SW0)
    output [7:0] seg,     // 7-segment signals
    output [3:0] anode    // Anode signals for displays
);
    
    reg [7:0] data;       // Display data - holds value until load pressed again
    wire [3:0] bcd;
    wire en_1khz;         // 1 kHz enable for multiplexing
    
    // Clock divider for display multiplexing
    clock_divider clk_div (
        .clk(clk),
        .rst(rst),
        .en_1khz(en_1khz)
    );
    
    // Display multiplexer
    display_mux mux (
        .clk(clk),
        .rst(rst),
        .en_1khz(en_1khz),
        .data(data),
        .anode(anode),
        .bcd(bcd)
    );
    
    // BCD to 7-segment decoder
    bcd_to_7seg decoder (
        .bcd(bcd),
        .seg(seg)
    );
    
    // ROM read logic - ONLY updates when load button pressed
    always @(posedge clk) begin 
        if (rst) begin
            data <= 8'b0000_0000;  // Reset: display shows "00"
        end else if (load) begin   // ONLY read ROM when load button is HIGH
            case(address)     
                4'h0: data <= 8'b1001_0000;  // 90
                4'h1: data <= 8'b0000_0010;  // 02
                4'h2: data <= 8'b0000_0100;  // 04
                4'h3: data <= 8'b0000_0001;  // 01
                4'h4: data <= 8'b1000_0000;  // 80
                4'h5: data <= 8'b0100_0110;  // 46
                4'h6: data <= 8'b0000_0111;  // 07
                4'h7: data <= 8'b0001_0100;  // 14
                4'h8: data <= 8'b0010_0000;  // 20
                4'h9: data <= 8'b0010_1001;  // 2A
                4'hA: data <= 8'b1000_0011;  // 83
                4'hB: data <= 8'b0011_0110;  // 36
                4'hC: data <= 8'b0100_0010;  // 42
                4'hD: data <= 8'b0010_0110;  // 26
                4'hE: data <= 8'b1000_1000;  // 88
                4'hF: data <= 8'b0110_0011;  // 63
                default: data <= 8'b0000_0000;
            endcase 
        end
        // If load = 0, do nothing - data register holds its value
    end
    
endmodule

module clock_divider (
    input clk,           // 100 MHz input clock
    input rst,           // Reset
    output reg en_1khz   // 1 kHz enable pulse
);
    reg [16:0] cnt_1khz; // Counter for 1kHz generation
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1khz <= 0;
            en_1khz <= 0;
        end else begin
            if (cnt_1khz == 100_000 - 1) begin
                cnt_1khz <= 0;
                en_1khz <= 1;
            end else begin
                cnt_1khz <= cnt_1khz + 1;
                en_1khz <= 0;
            end
        end
    end
    
endmodule

module display_mux (
    input clk,          // 100 MHz main clock
    input rst,          // Reset
    input en_1khz,      // 1 kHz enable pulse
    input [7:0] data,   // 8-bit data (2 BCD digits)
    output reg [3:0] anode,
    output reg [3:0] bcd
);
    reg disp_sel;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            disp_sel <= 0;
        else if (en_1khz)
            disp_sel <= ~disp_sel; 
    end
    
    always @(*) begin
        case (disp_sel)
            1'd0: begin
                anode = 4'b1101; // Activate AN2 (tens digit)
                bcd = data[7:4];
            end
            1'd1: begin
                anode = 4'b1110; // Activate AN3 (units digit)
                bcd = data[3:0];
            end
            default: begin
                anode = 4'b1111;
                bcd = 4'b0000;
            end
        endcase
    end
endmodule

module bcd_to_7seg (
    input [3:0] bcd,
    output reg [7:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0: seg = 8'b11000000;  // 0
            4'd1: seg = 8'b11111001;  // 1
            4'd2: seg = 8'b10100100;  // 2
            4'd3: seg = 8'b10110000;  // 3
            4'd4: seg = 8'b10011001;  // 4
            4'd5: seg = 8'b10010010;  // 5
            4'd6: seg = 8'b10000010;  // 6
            4'd7: seg = 8'b11111000;  // 7
            4'd8: seg = 8'b10000000;  // 8
            4'd9: seg = 8'b10010000;  // 9
            default: seg = 8'b11111111;
        endcase
    end
endmodule