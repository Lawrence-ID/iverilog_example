module top_module ();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;
    `probe(clk);

    parameter N = 5;
    reg rst = 0;
    `probe(rst);

    reg din;
    `probe(din);

    initial begin
        #5 rst <= 0; din <= 0;
        #10 rst <= 1; din <= 0;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 0;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 0;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 0;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 0;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 0;
        #20 $finish;
    end

    wire dout;
    SeqenceTest #(.N(N)) seq (
        .clk(clk),
        .rst_n(rst),
        .din(din),
        .dout(dout)
    );

endmodule

module SeqenceTest #(
    parameter N = 5
)(
    input clk,
    input rst_n,
    input din,
    output reg dout
);
    reg [N-1 : 0] q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {N{1'b0}};
        end
        else begin
            q <= {q[N-2:0], din};
        end
    end

    wire check = {q[N-2:0], din} == 5'b10010;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 1'b0;
        end
        else begin
            dout <= check;
        end
    end

    `probe(q);
    `probe(dout);

endmodule