module top_module();

    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;   // Start the timing diagram
    `probe(clk);

    reg rst = 0;
    `probe(rst);

    parameter ONE_HOT_WIDTH = 8;
    reg [ONE_HOT_WIDTH - 1 : 0] one_hot;
    wire [$clog2(ONE_HOT_WIDTH) - 1 : 0] o_bin;

    initial begin
        #5 rst <= 1; one_hot <= 8'd1;
        #10 rst <= 0; 
        #100 $finish;
    end

    always @(posedge clk) begin
        if (rst) begin
            one_hot <= 8'd1;
        end
        else begin
            one_hot <= one_hot << 1;
        end
    end

    OH2Binary #(
        .ONE_HOT_WIDTH(ONE_HOT_WIDTH)
    ) oh2bin (
        .i_oh(one_hot),
        .o_bin(o_bin)
    );

endmodule

module OH2Binary #(
    parameter ONE_HOT_WIDTH = 8
)(
    input [ONE_HOT_WIDTH - 1 : 0] i_oh,
    output [$clog2(ONE_HOT_WIDTH) - 1 : 0] o_bin
);

    wire [$clog2(ONE_HOT_WIDTH) - 1 : 0] temp1 [ONE_HOT_WIDTH - 1 : 0];
    wire [ONE_HOT_WIDTH - 1 : 0] temp2 [$clog2(ONE_HOT_WIDTH) - 1 : 0];

    genvar i, j;
    generate
        for (i = 0; i < ONE_HOT_WIDTH; i = i + 1) begin
            assign temp1[i] = i_oh[i] ? i : 'd0;
        end
    endgenerate

    generate
        for (i = 0; i < ONE_HOT_WIDTH; i = i + 1) begin
            for (j = 0; j < $clog2(ONE_HOT_WIDTH); j = j + 1) begin
                assign temp2[j][i] = temp1[i][j];
            end
        end
    endgenerate

    generate
        for(i = 0; i < $clog2(ONE_HOT_WIDTH); i = i + 1) begin
            assign o_bin[i] = |temp2[i];
        end
    endgenerate

    `probe(i_oh);
    `probe(o_bin);

endmodule