module mux_4to1_4bit(
    output reg [3:0] y,
    output reg       o_vld,
    input      [3:0] i0, i1, i2, i3,  // 4 separate 4-bit inputs
    input      [1:0] sel,
    input            i_vld,
    input            rst_n,
    input            clk
);

    localparam IDLE = 0, MUX = 1, DONE = 2;
    
    reg [1:0] cs, ns;
    reg [3:0] i0_r, i1_r, i2_r, i3_r;
    reg [1:0] sel_r;
    
    // State register
    always @(posedge clk, negedge rst_n)
        if (!rst_n) cs <= IDLE;
        else        cs <= ns;
    
    // Next state logic
    always @(*)
        case (cs)
            IDLE: ns = i_vld ? MUX : IDLE;
            MUX:  ns = DONE;
            DONE: ns = IDLE;
            default: ns = IDLE;
        endcase
    
    // Output logic
    always @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            y <= 0; o_vld <= 0;
            i0_r <= 0; i1_r <= 0; i2_r <= 0; i3_r <= 0; sel_r <= 0;
        end else case (cs)
            IDLE: begin
                o_vld <= 0;
                if (i_vld) begin
                    i0_r <= i0; i1_r <= i1; i2_r <= i2; i3_r <= i3;
                    sel_r <= sel;
                end
            end
            MUX: begin
                case (sel_r)
                    2'b00: y <= i0_r;
                    2'b01: y <= i1_r;
                    2'b10: y <= i2_r;
                    2'b11: y <= i3_r;
                endcase
            end
            DONE: o_vld <= 1;
        endcase

endmodule