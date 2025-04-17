module top_module ();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;
    `probe(clk);

    reg rst_n = 0;
    `probe(rst_n);

    localparam DATA_WIDTH = 32;
    localparam DEEPTH = 6;
    localparam ADDR_WDITH = $clog2(DEEPTH);

    reg wen = 0;
    reg ren = 0;
    reg [DATA_WIDTH-1:0] wdata = 0;
    wire [DATA_WIDTH-1:0] rdata;
    wire rempty, wfull;

    initial begin
        #5 rst_n <= 0;
        #10 rst_n <= 1; wen <= 1; wdata <= 'd0;
        #10 wen <= 1; wdata <= 'd1;
        #10 wen <= 1; wdata <= 'd2;
        #10 wen <= 1; wdata <= 'd3;
        #10 wen <= 1; wdata <= 'd4;
        #10 wen <= 0; ren <= 1;
        #10 wen <= 0; ren <= 1;
        #10 wen <= 0; ren <= 1;
        #10 wen <= 0; ren <= 1;
        #10 wen <= 1; wdata <= 'd5; ren <= 1;
        #10 wen <= 1; wdata <= 'd6; ren <= 1;
        #10 wen <= 1; wdata <= 'd7; ren <= 1;
        #10 wen <= 1; wdata <= 'd8; ren <= 1;
        #10 wen <= 0; ren <= 1; // rempty
        #10 wen <= 1; wdata <= 'd9; ren <= 0;
        #10 wen <= 1; wdata <= 'd0; ren <= 0;
        #10 wen <= 1; wdata <= 'd1; ren <= 0;
        #10 wen <= 1; wdata <= 'd2; ren <= 0;
        #10 wen <= 1; wdata <= 'd3; ren <= 0;
        #10 wen <= 1; wdata <= 'd4; ren <= 0;
        #50 $finish();
    end

    SynFifoWithDualPortRamUseCnt #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEEPTH(DEEPTH)
    ) u (
        .clk(clk),
        .rst_n(rst_n),
        .wen(wen),
        .wdata(wdata),
        .ren(ren),
        .rdata(rdata),
        .rempty(rempty),
        .wfull(wfull)
    );

    `probe(wen);
    `probe(wdata);
    `probe(wfull);
    `probe(ren);
    `probe(rdata);
    `probe(rempty);

endmodule

module DualPortRam #(
    parameter DATA_WIDTH = 8,
    parameter DEEPTH = 256
)(
    input clk,
    input wen,
    input [$clog2(DEEPTH)-1 : 0] waddr,
    input [DATA_WIDTH-1:0] wdata,
    input ren,
    input [$clog2(DEEPTH)-1 : 0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);

localparam ADDR_WIDTH = $clog2(DEEPTH);

reg [DATA_WIDTH-1:0] mem [DEEPTH-1:0];

always @(posedge clk) begin
    if(wen) begin
        mem[waddr] <= wdata;
    end
end

always @(posedge clk) begin
    if(ren) begin
        rdata <= mem[raddr];
    end
end

endmodule

module SynFifoWithDualPortRam #(
    parameter DATA_WIDTH = 8,
    parameter DEEPTH = 256
)(
    input clk,
    input rst_n,
    input wen,
    input [DATA_WIDTH-1:0] wdata,
    input ren,
    output [DATA_WIDTH-1:0] rdata,
    output wfull,
    output rempty
);

localparam ADDR_WIDTH = $clog2(DEEPTH);

reg [ADDR_WIDTH:0] wptr, rptr;

wire ram_wen = wen && !wfull;
wire ram_ren = ren && !rempty;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wptr <= {(ADDR_WIDTH+1){1'b0}};
        rptr <= {(ADDR_WIDTH+1){1'b0}};
    end
    else begin
        if(ram_wen && wptr[ADDR_WIDTH-1:0] + 1 != DEEPTH) begin
            wptr <= wptr + 1;
        end 
        else if(ram_wen && wptr[ADDR_WIDTH-1:0] + 1 == DEEPTH) begin
            wptr <= {~wptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        end
            
        if(ram_ren && rptr[ADDR_WIDTH-1:0] + 1 != DEEPTH) begin
            rptr <= rptr + 1;
        end 
        else if(ram_ren && rptr[ADDR_WIDTH-1:0] + 1 == DEEPTH) begin
            rptr <= {~rptr[ADDR_WIDTH], {ADDR_WIDTH{1'b0}}};
        end
    end
end


DualPortRam #(
    .DATA_WIDTH 	(DATA_WIDTH    ),
    .DEEPTH     	(DEEPTH  ))
u_DualPortRam(
    .clk      	(clk   ),
    .wen      	(ram_wen   ),
    .waddr    	(wptr[ADDR_WIDTH-1:0] ),
    .wdata    	(wdata ),
    .ren      	(ram_ren   ),
    .raddr    	(rptr[ADDR_WIDTH-1:0] ),
    .rdata    	(rdata )    
);

assign wfull = wptr == {~rptr[ADDR_WIDTH], rptr[ADDR_WIDTH-1 : 0]};
assign rempty = wptr == rptr;

endmodule

module SynFifoWithDualPortRamUseCnt #(
    parameter DATA_WIDTH = 8,
    parameter DEEPTH = 256
)(
    input clk,
    input rst_n,
    input wen,
    input [DATA_WIDTH-1:0] wdata,
    input ren,
    output [DATA_WIDTH-1:0] rdata,
    output wfull,
    output rempty
);

localparam ADDR_WIDTH = $clog2(DEEPTH);

reg [ADDR_WIDTH-1:0] fifo_cnt, wptr, rptr;

assign wfull = fifo_cnt == DEEPTH;
assign rempty = fifo_cnt == 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_cnt <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        case ({wen && !wfull, ren && !rempty})
            2'b01: fifo_cnt <= fifo_cnt - 1;
            2'b10: fifo_cnt <= fifo_cnt + 1;
            default: fifo_cnt <= fifo_cnt;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wptr <= {ADDR_WIDTH{1'b0}};
        rptr <= {ADDR_WIDTH{1'b0}};
    end
    else begin
        if (wen && !wfull) begin
            if (wptr + 1 == DEEPTH) begin 
                wptr <= {ADDR_WIDTH{1'b0}};
            end
            else begin
                wptr <= wptr + 1;
            end
        end

        if(ren && !rempty) begin
            if (rptr + 1 == DEEPTH) begin 
                rptr <= {ADDR_WIDTH{1'b0}};
            end
            else begin
                rptr <= rptr + 1;
            end
        end
    end
end

DualPortRam #(
    .DATA_WIDTH 	(DATA_WIDTH),
    .DEEPTH     	(DEEPTH))
u_DualPortRam (
    .clk      	(clk   ),
    .wen      	(wen && !wfull   ),
    .waddr    	(wptr  ),
    .wdata    	(wdata ),
    .ren      	(ren && !rempty  ),
    .raddr    	(rptr  ),
    .rdata    	(rdata )
);

endmodule
