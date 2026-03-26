module multiplier #(
    parameter int WIDTH = 8
)(
    input  logic signed [WIDTH-1:0]     a,
    input  logic signed [WIDTH-1:0]     b,
    output logic signed [(2*WIDTH)-1:0] p
);

    assign p = a * b;

endmodule