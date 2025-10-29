`timescale 1ns / 1ps

// Top-level module for displaying minutes and seconds (MM:SS) on Basys 3 7-segment display
module time_display (
    input clk,          // 100 MHz Basys 3 clock
    input rst,          // Reset button (active high)
    output [7:0] seg,   // 7-segment signals (CA, CB, CC, CD, CE, CF, CG, DP)
    output [3:0] anode  // Anode signals for four displays (AN0-AN3)
);
    // Internal signals
    wire en_1khz;       // 1 kHz enable pulse for multiplexing
    wire en_1hz;        // 1 Hz enable pulse for timekeeping
    wire [3:0] sec_units, sec_tens, min_units, min_tens; // BCD digits
    wire [3:0] bcd;     // Current BCD digit to display
    
    // Clock divider module for 1 kHz and 1 Hz enable pulses
    clock_divider clk_div (
        .clk(clk),
        .rst(rst),
        .en_1khz(en_1khz),
        .en_1hz(en_1hz)
    );
    
    // BCD counter for seconds and minutes
    bcd_counter counter (
        .clk(clk),
        .rst(rst),
        .en_1hz(en_1hz),
        .sec_units(sec_units),
        .sec_tens(sec_tens),
        .min_units(min_units),
        .min_tens(min_tens)
    );
    
    // Multiplexer for 7-segment displays
    display_mux mux (
        .clk(clk),
        .rst(rst),
        .en_1khz(en_1khz),
        .sec_units(sec_units),
        .sec_tens(sec_tens),
        .min_units(min_units),
        .min_tens(min_tens),
        .anode(anode),
        .bcd(bcd)
    );
    
    // BCD to 7-segment decoder
    bcd_to_7seg decoder (
        .bcd(bcd),
        .seg(seg)
    );
endmodule

// Clock divider module to generate 1 kHz and 1 Hz enable pulses from 100 MHz
module clock_divider (
    input clk,          // 100 MHz input clock
    input rst,          // Reset
    output reg en_1khz, // 1 kHz enable pulse (1 cycle every 1ms)
    output reg en_1hz   // 1 Hz enable pulse (1 cycle every 1s)
);
    // For 1 kHz enable: 100 MHz / 100,000 = 1 kHz (pulse every 1 ms)
    // For 1 Hz enable: 100 MHz / 100,000,000 = 1 Hz (pulse every 1 s)
    
    reg [16:0] cnt_1khz; // 17-bit counter for 100,000
    reg [26:0] cnt_1hz;  // 27-bit counter for 100,000,000
    
    // 1 kHz enable generation (pulse every 100,000 clock cycles = 1ms)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1khz <= 0;
            en_1khz <= 0;
        end else begin
            if (cnt_1khz == 100_000 - 1) begin
                cnt_1khz <= 0;
                en_1khz <= 1;  // Pulse high for one clock cycle
            end else begin
                cnt_1khz <= cnt_1khz + 1;
                en_1khz <= 0;  // Stay low while counting
            end
        end
    end
    
    // 1 Hz enable generation (pulse every 100,000,000 clock cycles = 1s)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1hz <= 0;
            en_1hz <= 0;
        end else begin
            if (cnt_1hz == 100_000_000 - 1) begin
                cnt_1hz <= 0;
                en_1hz <= 1;  // Pulse high for one clock cycle
            end else begin
                cnt_1hz <= cnt_1hz + 1;
                en_1hz <= 0;  // Stay low while counting
            end
        end
    end
endmodule

// BCD counter for seconds and minutes (00:00 to 59:59)
module bcd_counter (
    input clk,          // 100 MHz main clock
    input rst,          // Reset
    input en_1hz,       // 1 Hz enable pulse (high for 1 clock cycle every second)
    output reg [3:0] sec_units, // Seconds units (0-9)
    output reg [3:0] sec_tens,  // Seconds tens (0-5)
    output reg [3:0] min_units, // Minutes units (0-9)
    output reg [3:0] min_tens   // Minutes tens (0-5)
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sec_units <= 0;
            sec_tens <= 0;
            min_units <= 0;
            min_tens <= 0;
        end else if (en_1hz) begin  // Only update when 1Hz enable pulse arrives
            // Increment seconds units
            if (sec_units == 9) begin
                sec_units <= 0;
                // Increment seconds tens
                if (sec_tens == 5) begin
                    sec_tens <= 0;
                    // Increment minutes units
                    if (min_units == 9) begin
                        min_units <= 0;
                        // Increment minutes tens
                        if (min_tens == 5) begin
                            min_tens <= 0; // Reset at 59:59
                        end else begin
                            min_tens <= min_tens + 1;
                        end
                    end else begin
                        min_units <= min_units + 1;
                    end
                end else begin
                    sec_tens <= sec_tens + 1;
                end
            end else begin
                sec_units <= sec_units + 1;
            end
        end
    end
endmodule

// Multiplexer to cycle through four 7-segment displays
module display_mux (
    input clk,          // 100 MHz main clock
    input rst,          // Reset
    input en_1khz,      // 1 kHz enable pulse (high for 1 clock cycle every 1ms)
    input [3:0] sec_units, sec_tens, min_units, min_tens, // BCD digits
    output reg [3:0] anode, // Anode signals (active low for common anode)
    output reg [3:0] bcd    // BCD digit to display
);
    reg [1:0] disp_sel; // 2-bit counter to select display (0-3)
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            disp_sel <= 0;
        else if (en_1khz)  // Only update when 1kHz enable pulse arrives
            disp_sel <= disp_sel + 1; // Cycle through 0-3
    end
    
    always @(*) begin
        case (disp_sel)
            2'd0: begin
                anode = 4'b0111; // Activate AN0 (minutes tens)
                bcd = min_tens;
            end
            2'd1: begin
                anode = 4'b1011; // Activate AN1 (minutes units)
                bcd = min_units;
            end
            2'd2: begin
                anode = 4'b1101; // Activate AN2 (seconds tens)
                bcd = sec_tens;
            end
            2'd3: begin
                anode = 4'b1110; // Activate AN3 (seconds units)
                bcd = sec_units;
            end
            default: begin
                anode = 4'b1111; // All displays off
                bcd = 4'b0000;
            end
        endcase
    end
endmodule

// BCD to 7-segment decoder for common anode display
module bcd_to_7seg (
    input [3:0] bcd,    // BCD input (0-9)
    output reg [7:0] seg // 7-segment output (CA, CB, CC, CD, CE, CF, CG, DP)
);
    // Note: For common anode, 0 = segment on, 1 = segment off
    always @(*) begin
        case (bcd)
            4'd0: seg = 8'b01000000;  // 0
            4'd1: seg = 8'b01111001;  // 1
            4'd2: seg = 8'b00100100;  // 2
            4'd3: seg = 8'b00110000;  // 3
            4'd4: seg = 8'b00011001;  // 4
            4'd5: seg = 8'b00010010;  // 5
            4'd6: seg = 8'b00000010;  // 6
            4'd7: seg = 8'b01111000;  // 7
            4'd8: seg = 8'b00000000;  // 8
            4'd9: seg = 8'b00010000;  // 9
            default: seg = 8'b11111111; // All off
        endcase
    end
endmodule