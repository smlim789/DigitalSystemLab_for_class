module bin2BCD (
    input  [3:0] binary_input,
    output [3:0] tens,
    output [3:0] ones
);
    // tens = 1 if binary_input ≥ 10, else 0
    assign tens = (binary_input >= 4'd10) ? 4'd1 : 4'd0;
    // ones = binary_input - tens*10 (10 = 8 + 2)
    assign ones = binary_input - (tens << 3) - (tens << 1);
endmodule

module BCD2seven (
    input  [3:0] BCD_input,
    output reg [7:0] seven_segment
);
    always @(*) begin
        case (BCD_input)
            4'd0: seven_segment = 8'b1111_1100; // 0
            4'd1: seven_segment = 8'b0110_0000; // 1
            4'd2: seven_segment = 8'b1101_1010; // 2
            4'd3: seven_segment = 8'b1111_0010; // 3
            4'd4: seven_segment = 8'b0110_0110; // 4
            4'd5: seven_segment = 8'b1011_0110; // 5
            4'd6: seven_segment = 8'b1011_1110; // 6
            4'd7: seven_segment = 8'b1110_0000; // 7
            4'd8: seven_segment = 8'b1111_1110; // 8
            4'd9: seven_segment = 8'b1111_0110; // 9
            default: seven_segment = 8'b1111_1111; // blank
        endcase
    end
endmodule

module controller(
    input clk,
    input reset,
    input [7:0] seg0, seg1, seg2, seg3, seg4, seg5, seg6, seg7,
    output reg [7:0] seg_COM,   // active-LOW digit select
    output reg [7:0] seg_DATA   // active-LOW segment data
);
    reg [2:0] counter = 3'd0;

    always @(posedge clk) begin
        if (reset) begin
            // active-LOW 보드: 0이면 선택, 1이면 해제
            seg_COM  <= 8'b1111_1111; // 모든 digit 해제(보드 설계상 '소등')
            seg_DATA <= 8'b0000_0000; // 모든 segment OFF
            counter  <= 3'd0;
        end else begin
            counter <= (counter == 3'd7) ? 3'd0 : counter + 3'd1;

            case (counter)
                3'd0: begin seg_COM <= 8'b0111_1111; seg_DATA <= seg0; end
                3'd1: begin seg_COM <= 8'b1011_1111; seg_DATA <= seg1; end
                3'd2: begin seg_COM <= 8'b1101_1111; seg_DATA <= seg2; end
                3'd3: begin seg_COM <= 8'b1110_1111; seg_DATA <= seg3; end
                3'd4: begin seg_COM <= 8'b1111_0111; seg_DATA <= seg4; end
                3'd5: begin seg_COM <= 8'b1111_1011; seg_DATA <= seg5; end
                3'd6: begin seg_COM <= 8'b1111_1101; seg_DATA <= seg6; end
                3'd7: begin seg_COM <= 8'b1111_1110; seg_DATA <= seg7; end
                default: begin
                    seg_COM  <= 8'b0000_0000; // 안전하게 소등
                    seg_DATA <= 8'b1111_1111;
                end
            endcase
        end
    end
endmodule

module TOP_bin2seven (
    input clk,
    input reset,
    input  [3:0] binary,
    output [7:0] seg_COM,
    output [7:0] seg_DATA
);
    // 내부 배선
    wire [3:0] tens, ones;
    wire [7:0] seg_tens, seg_ones;

    // 공란(OFF): active-HIGH이므로 1로 채움
    localparam [7:0] SEG_BLANK = 8'b0000_0000;

    // 1) Binary -> BCD
    bin2BCD u_bin2BCD (
        .binary_input(binary),
        .tens(tens),
        .ones(ones)
    );

    // 2) BCD -> 7-segment
    BCD2seven u_BCD2seven_tens (.BCD_input(tens), .seven_segment(seg_tens));
    BCD2seven u_BCD2seven_ones (.BCD_input(ones), .seven_segment(seg_ones));

    // 3) 7-segment 주사 구동
    controller u_controller (
        .clk(clk),
        .reset(reset),
        .seg0(seg_tens),      // 가장 왼쪽
        .seg1(seg_ones),
        .seg2(SEG_BLANK),
        .seg3(SEG_BLANK),
        .seg4(SEG_BLANK),
        .seg5(SEG_BLANK),
        .seg6(SEG_BLANK),
        .seg7(SEG_BLANK),
        .seg_COM(seg_COM),
        .seg_DATA(seg_DATA)
    );
endmodule
