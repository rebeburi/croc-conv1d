module adder #(
    parameter int WIDTH = 32
)(
    input  logic signed [WIDTH-1:0] a,
    input  logic signed [WIDTH-1:0] b,
    output logic signed [WIDTH-1:0] s
);

    assign s = a + b;

endmodule