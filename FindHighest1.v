module top_module();

reg clk;
always #5 clk = ~clk;
initial `probe_start;
`probe(clk);

reg rst_n;
`probe(rst_n);

reg [15:0] din;

initial begin
    #5 rst_n <= 0;
    #10 rst_n <= 1;
    #10 din <= 16'h11;
    #10 din <= 16'h12;
    #10 din <= 16'h04;
    #10 din <= 16'h18;
    #10 din <= 16'h00;
    #10 din <= 16'h10;
    #10 din <= 16'h20;
    #10 din <= 16'h40;
    #10 din <= 16'h80;
    #10 din <= 16'h00;
    #10 din <= 16'h0100;
    #10 din <= 16'h02f1;
    #10 din <= 16'h0431;
    #10 din <= 16'h08ac;
    #10 din <= 16'h00;
    #10 din <= 16'h1020;
    #10 din <= 16'h2040;
    #10 din <= 16'h4100;
    #10 din <= 16'h8030;
    #20 $finish;
end

wire o_valid;
wire [3:0] o_pos;

FindHighest1 test_module (
    .x(din),
    .o_valid(o_valid),
    .o_pos(o_pos)
);

    `probe(din);
`probe(o_valid);
`probe(o_pos);

endmodule

module FindHighest1 #(
    parameter N = 16
)(
    input [N - 1 : 0] x,
    output o_valid,
    output [$clog2(N) : 0] o_pos
);

reg [1:0] A0, A1, A2, A3;
wire A0_valid, A1_valid, A2_valid, A3_valid;

always @(*) begin
    casez (x[3:0])
        4'b0001: A0 = 2'b00;
        4'b001?: A0 = 2'b01;
        4'b01??: A0 = 2'b10;
        4'b1???: A0 = 2'b11;
        default: A0 = 2'b00;
    endcase
end

always @(*) begin
    casez (x[7:4])
        4'b0001: A1 = 2'b00;
        4'b001?: A1 = 2'b01;
        4'b01??: A1 = 2'b10;
        4'b1???: A1 = 2'b11;
        default: A1 = 2'b00;
    endcase
end

always @(*) begin
    casez (x[11:8])
        4'b0001: A2 = 2'b00;
        4'b001?: A2 = 2'b01;
        4'b01??: A2 = 2'b10;
        4'b1???: A2 = 2'b11;
        default: A2 = 2'b00;
    endcase
end

always @(*) begin
    casez (x[15:12])
        4'b0001: A3 = 2'b00;
        4'b001?: A3 = 2'b01;
        4'b01??: A3 = 2'b10;
        4'b1???: A3 = 2'b11;
        default: A3 = 2'b00;
    endcase
end

assign A0_valid = |x[3:0];
assign A1_valid = |x[7:4];
assign A2_valid = |x[11:8];
assign A3_valid = |x[15:12];

wire [2:0] B0 = A1_valid ? {1'b1, A1} : {1'b0, A0};
wire B0_valid = A0_valid | A1_valid;

wire [2:0] B1 = A3_valid ? {1'b1, A3} : {1'b0, A2};
wire B1_valid = A2_valid | A3_valid;

wire [3:0]  C = B1_valid ? {1'b1, B1} : {1'b0, B0};
wire C_valid = B0_valid | B1_valid;

assign o_valid = C_valid;
assign o_pos = C;

endmodule