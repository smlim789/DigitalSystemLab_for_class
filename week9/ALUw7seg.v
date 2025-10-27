module TOP_Finw7 (
    input         clk,
    input         reset,
    input  [3:0]  operandA,
    input  [3:0]  operandB,
    input  [2:0]  opcode,
    output [7:0]  seg_COM,
    output [7:0]  seg_DATA
);

    // ALU result wires
    wire [3:0] alu_out;
    wire       alu_cout;
    wire       alu_v;

    // Instantiate the 4-bit ALU
    TOP_fourbit_ALU u_alu (
        .a     (operandA),
        .b     (operandB),
        .opcode(opcode),
        .out   (alu_out),
        .cout  (alu_cout),
        .v     (alu_v)
    );

    // Instantiate the 7-segment driver (binary→BCD→7-segment + controller)
    TOP_bin2seven u_display (
        .clk     (clk),
        .reset   (reset),
        .binary  (alu_out),
        .seg_COM (seg_COM),
        .seg_DATA(seg_DATA)
    );

endmodule
