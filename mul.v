module Multiplier #(
    parameter N = 4
)(
    input clk,
    input rst_n,
    input [N-1 : 0] a,
    input [N-1 : 0] b,
    output reg [2*N-1 : 0] out
);

    reg [2*N-1 : 0] x1, x2, x3, x0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= {2*N-1{1'b0}};
            x1 <= {2*N-1{1'b0}};
            x2 <= {2*N-1{1'b0}};
            x3 <= {2*N-1{1'b0}};
        end
        else begin
            x0 <= b[0] == 1'b1 ? {N{1'b0}  , a        } : {2*N-1{1'b0}};
            x1 <= b[1] == 1'b1 ? {N-1{1'b0}, a, 1'b0  } : {2*N-1{1'b0}};
            x2 <= b[2] == 1'b1 ? {N-2{1'b0}, a, 2'b00 } : {2*N-1{1'b0}};
            x3 <= b[3] == 1'b1 ? {N-3{1'b0}, a, 3'b000} : {2*N-1{1'b0}}; 
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= {2*N-1{1'b0}};
        end
        else begin
            out <= x0 + x1 + x2 + x3;
        end
    end

endmodule