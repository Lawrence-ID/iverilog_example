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
        #10 din <= 1;
        #10 din <= 1;
        #10 din <= 1;
        #10 din <= 0;
        #10 din <= 1;
        #10 din <= 1;
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
    parameter N = 4
)(
    input clk,
    input rst_n,
    input din,
    output dout
);
    reg [N-1:0] c_s, n_s;
    parameter IDLE = 4'b0000, A = 4'b0001, B = 4'b0010, C = 4'b0100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_s <= IDLE;
        end
        else begin
            c_s <= n_s;
        end
    end

    always @(*) begin
        case (c_s)
            IDLE: begin
                if (din == 1'b1) begin
                    n_s = A;
                end
                else begin
                    n_s = IDLE;
                end
            end
            A: begin
                if (din == 1'b0) begin
                    n_s = B;
                end
                else begin
                    n_s = A;
                end
            end
            B: begin
                if (din == 1'b1) begin
                    n_s = C;
                end
                else begin
                    n_s = B;
                end
            end
            C: begin
                if (din == 1'b1) begin
                    n_s = IDLE;
                end
                else begin
                    n_s = C;
                end
            end
            default: n_s = IDLE;
        endcase
    end

    assign dout = c_s == C && din == 1'b1;
    
    `probe(c_s);
    `probe(n_s);
    `probe(dout);

endmodule