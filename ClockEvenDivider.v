module top_module();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;
    `probe(clk);

    reg rst = 0;
    `probe(rst);

    wire o_clk2, o_clk4, o_clk8;
    initial begin
        #5 rst <= 0;
        #10 rst <= 1;
        #100 $finish;
    end

    ClockEvenDivider clk_out (
        .clock(clk),
        .reset_n(rst),
        .o_clk2(o_clk2),
        .o_clk4(o_clk4),
        .o_clk8(o_clk8)
    );


endmodule

module ClockEvenDivider (
    input clock,
    input reset_n,
    output reg o_clk2,
    output reg o_clk4,
    output reg o_clk8
);

always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        o_clk2 <= 1'b0;
    end
    else begin
        o_clk2 <= ~o_clk2;
    end
end

reg [1:0] cnt1;
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        cnt1 <= 2'd0;
        o_clk4 <= 1'b0;
    end
    else begin
        cnt1 <= cnt1 + 1'd1;
        if (cnt1 < 2) begin
            o_clk4 <= 1'b1;
        end
        else begin
            o_clk4 <= 1'b0;
        end
    end
end

reg [2:0] cnt2;
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        cnt2 <= 3'd0;
        o_clk8 <= 1'b0;
    end
    else begin
        cnt2 <= cnt2 + 1'd1;
        if (cnt2 < 4) begin
            o_clk8 <= 1'b1;
        end
        else begin
            o_clk8 <= 1'b0;
        end
    end
end

`probe(o_clk2);
`probe(o_clk4);
`probe(o_clk8);

endmodule