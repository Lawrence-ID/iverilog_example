module top_module();

    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;
    `probe(clk);

    parameter N = 5;

    reg rst = 0;
    `probe(rst);

    initial begin
        #5 rst <= 0;
        #10 rst <= 1;
        #100 $finish;
    end

    wire o_clk_divided;
    ClockOddDivider #(.N(N)) clk_odd_div (
        .clock(clk),
        .reset_n(rst),
        .o_clk_divided(o_clk_divided)
    );

endmodule

module ClockOddDivider #(
    parameter N = 3
)(
    input clock,
    input reset_n,
    output o_clk_divided
);
// assert(N % 2 == 1);

reg [$clog2(N) - 1 : 0] cnt;
always @(posedge clock or negedge reset_n) begin
    if(!reset_n) begin
        cnt <= 0;
    end
    else begin
        if (cnt == N - 1) begin
            cnt <= 0;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
end

reg clk_pos, clk_neg;

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        clk_pos <= 1'd0;
    end
    else begin
        if (|cnt == 1'b0) begin
            clk_pos <= 1'b1;
        end
        else if (cnt == (N-1) / 2) begin
            clk_pos <= 1'b0;
        end
    end
end

always @(negedge clock or negedge reset_n) begin
    if (!reset_n) begin
        clk_neg <= 1'd0;
    end
    else begin
        if (|cnt == 1'b0) begin
            clk_neg <= 1'b1;
        end
        else if (cnt == (N-1) / 2) begin
            clk_neg <= 1'b0;
        end
    end
end

assign o_clk_divided = clk_pos | clk_neg;

`probe(o_clk_divided);

endmodule