module full_adder(
    input a, b, cin,
    output reg s, cout
);

reg [2-1:0] _cout;
reg _s;

always @ (*) begin
    _s     = a ^ b;
    _cout[0] = a & b;
    s     = _s ^ cin;
    _cout[1] = _s & cin;
    cout  = _cout[0] | _cout[1];
end

endmodule

module fourbit_adder_subtractor(
    input [4-1:0] a, b,
    input M,
    output [4-1:0] s,
    output cout, v
);

wire [4-1:0] _xb;
wire [3-1:0] _cout;

xor (_xb[0], b[0], M);
xor (_xb[1], b[1], M);
xor (_xb[2], b[2], M);
xor (_xb[3], b[3], M);

full_adder fa0(a[0], _xb[0], M, s[0], _cout[0]);
full_adder fa1(a[1], _xb[1], _cout[0], s[1], _cout[1]);
full_adder fa2(a[2], _xb[2], _cout[1], s[2], _cout[2]);
full_adder fa3(a[3], _xb[3], _cout[2], s[3], cout);

xor (v, cout, _cout[2]);

endmodule

module fourbit_multiplier(
    input  [4-1:0] a, b,
    output [8-1:0] out
);
    // Generate ALL partial products (16 total)
    wire [16-1:0] pp;  // partial products
    
    // Row 0: a[0] * b[3:0]
    and (out[0], a[0], b[0]);           // LSB goes directly to output
    and (pp[0],  a[0], b[1]);
    and (pp[1],  a[0], b[2]);
    and (pp[2],  a[0], b[3]);
    
    // Row 1: a[1] * b[3:0] 
    and (pp[3],  a[1], b[0]);
    and (pp[4],  a[1], b[1]);
    and (pp[5],  a[1], b[2]);
    and (pp[6],  a[1], b[3]);
    
    // Row 2: a[2] * b[3:0]
    and (pp[7],  a[2], b[0]);
    and (pp[8],  a[2], b[1]);
    and (pp[9],  a[2], b[2]);
    and (pp[10], a[2], b[3]);
    
    // Row 3: a[3] * b[3:0]
    and (pp[11], a[3], b[0]);
    and (pp[12], a[3], b[1]);
    and (pp[13], a[3], b[2]);
    and (pp[14], a[3], b[3]);
    
    // Intermediate carry and sum wires
    wire [7:0] sum1, sum2;
    wire [2:0] carry_out;
    wire [2:0] overflow_dump;
    
    // Stage 1: Add Row 0 (shifted) + Row 1
    // Input: {pp[2], pp[1], pp[0], 1'b0} + {pp[6], pp[5], pp[4], pp[3]}
    fourbit_adder_subtractor stage1 (
        .a({1'b0, pp[2], pp[1], pp[0]}),    // Row 0 shifted left by 1
        .b({pp[6], pp[5], pp[4], pp[3]}),   // Row 1
        .M(1'b0),                           // Addition mode
        .s(sum1[3:0]),
        .cout(carry_out[0]),
        .v(overflow_dump[0])
    );
    
    assign out[1] = sum1[0];  // Second LSB
    
    // Stage 2: Add Stage 1 result + Row 2
    // Input: {carry_out[0], sum1[3:1]} + {pp[10], pp[9], pp[8], pp[7]}
    fourbit_adder_subtractor stage2 (
        .a({carry_out[0], sum1[3:1]}),      // Previous result shifted
        .b({pp[10], pp[9], pp[8], pp[7]}),  // Row 2
        .M(1'b0),                           // Addition mode
        .s(sum2[3:0]),
        .cout(carry_out[1]),
        .v(overflow_dump[1])
    );
    
    assign out[2] = sum2[0];  // Third LSB
    
    // Stage 3: Add Stage 2 result + Row 3  
    // Input: {carry_out[1], sum2[3:1]} + {pp[14], pp[13], pp[12], pp[11]}
    fourbit_adder_subtractor stage3 (
        .a({carry_out[1], sum2[3:1]}),      // Previous result shifted
        .b({pp[14], pp[13], pp[12], pp[11]}), // Row 3
        .M(1'b0),                           // Addition mode
        .s(out[6:3]),                       // Final high-order bits
        .cout(out[7]),                      // MSB
        .v(overflow_dump[2])
    );
    
endmodule

// Bitwise AND for 4-bit vectors
module fourbit_bitwise_and (
    input  [3:0] a,
    input  [3:0] b,
    output reg [3:0] out
);
    always @(*) begin
        out = a & b;
    end
endmodule

// Bitwise OR for 4-bit vectors
module fourbit_bitwise_or (
    input  [3:0] a,
    input  [3:0] b,
    output reg [3:0] out
);
    always @(*) begin
        out = a | b;
    end
endmodule

// Bitwise XOR for 4-bit vectors
module fourbit_bitwise_xor (
    input  [3:0] a,
    input  [3:0] b,
    output reg [3:0] out
);
    always @(*) begin
        out = a ^ b;
    end
endmodule

// Four-bit ALU: add, subtract, AND, OR, XOR, multiply low 4 bits
module TOP_fourbit_ALU (
    input  [3:0] a,
    input  [3:0] b,
    input  [2:0] opcode,      // 000=add, 001=sub, 010=and, 011=or, 100=xor, 101=mul
    output reg [3:0] out,
    output reg       cout,    // carry out for add/sub (borrow for sub)
    output reg       v        // overflow flag for add/sub
);

    // Internal wires for operations
    wire [3:0] sum_sub;
    wire       carry_int, ovf_int;
    wire [3:0] w_and, w_or, w_xor;
    wire [7:0] w_mul;

    // Adder/Subtractor (M = 1 for subtract)
    fourbit_adder_subtractor fas (
        .a(a),
        .b(b),
        .M(opcode == 3'b001),
        .s(sum_sub),
        .cout(carry_int),
        .v(ovf_int)
    );

    // Bitwise operations
    fourbit_bitwise_and and_u (.a(a), .b(b), .out(w_and));
    fourbit_bitwise_or  or_u  (.a(a), .b(b), .out(w_or));
    fourbit_bitwise_xor xor_u (.a(a), .b(b), .out(w_xor));

    // Multiplier (take full 8-bit result, low half used)
    fourbit_multiplier mul_u (.a(a), .b(b), .out(w_mul));

    // Output and flags selection
    always @(*) begin
        // Default flags
        cout = 1'b0;
        v    = 1'b0;
        case (opcode)
            3'b000: begin
                out  = sum_sub;       // add
                cout = carry_int;
                v    = ovf_int;
            end
            3'b001: begin
                out  = sum_sub;       // subtract
                // For subtraction, convert carry_out to borrow_out
                cout = carry_int;
                v    = ovf_int;
            end
            3'b010: begin
                out  = w_and;         // AND
            end
            3'b011: begin
                out  = w_or;          // OR
            end
            3'b100: begin
                out  = w_xor;         // XOR
            end
            3'b101: begin
                out  = w_mul[3:0];    // multiply low half
            end
            default: begin
                out  = 4'b0000;
            end
        endcase
    end

endmodule
