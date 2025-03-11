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
    reg [N-1:0] c_s, n_s;
    parameter IDLE    = 5'b00000;
    parameter S_1     = 5'b00001;
    parameter S_10    = 5'b00010;
    parameter S_100   = 5'b00100;
    parameter S_1001  = 5'b01000;
    parameter S_10010 = 5'b10000;

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
                    n_s = S_1;
                end
                else begin
                    n_s = IDLE;
                end
            end
            S_1: begin
                if (din == 1'b0) begin
                    n_s = S_10;
                end
                else begin
                    n_s = S_1;
                end
            end
            S_10: begin
                if (din == 1'b0) begin
                    n_s = S_100;
                end
                else begin
                    n_s = S_1;
                end
            end
            S_100: begin
                if (din == 1'b1) begin
                    n_s = S_1001;
                end
                else begin
                    n_s = IDLE;
                end
            end
            S_1001: begin
                if (din == 1'b0) begin
                    n_s = S_10010;
                end
                else begin
                    n_s = S_1;
                end
            end
            S_10010: begin
                if (din == 1'b0) begin
                    n_s = S_100;
                end
                else begin
                    n_s = S_1;
                end
            end
            default: n_s = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 1'b0;
        end
        else if (n_s == S_10010) begin
            dout <= 1'b1;
        end
        else begin
            dout <= 1'b0;
        end
    end
    
    `probe(c_s);
    `probe(n_s);
    `probe(dout);

endmodule