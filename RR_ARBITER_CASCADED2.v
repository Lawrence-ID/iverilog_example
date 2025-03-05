// 实现一个4请求的round robin arbiter，并基于它实现16请求的round robin arbiter;arbiter4的输入输出给出如下:
// ·o_find用来指示仲裁完成，
// .o_find_one_hot为4bit独热码;
// ·o_index表示被授予总线的位置:

// 希望级联后的RR-Arbiter能够按照优先级从高到低的顺序来轮询，但实际上仍然无法完成，因为rr_top的轮询顺序固定
// 考虑req = 7f3f
// req  rr_top(o_find_one_hot) afterReq
// 7f3f        1, 2, 4, 8       7f30
// 7f30        1, 2             7f00
// 7f00        4, 8, 1, 2       7000
// 7000        4, 8, 1          0000
module top_module();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;   // Start the timing diagram

    reg rst_n;

    parameter REQ_WIDTH = 16;
    reg [REQ_WIDTH-1:0] i_req;
    wire [REQ_WIDTH-1:0] o_grant;
    wire o_find;

    `probe(clk);        // Probe signal "clk"
    `probe(rst_n);

    initial begin
        #5 rst_n <= 0;
        #10 rst_n <= 1;
        $display ("Hello world! The current time is (%0d ps)", $time);
        #500 $finish;
    end

    reg i_change_pt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        	i_change_pt <= 1'b0;
        end
        else begin
        	i_change_pt <= ~i_change_pt; // 间隔一拍确认
        end
    end
    
    reg [REQ_WIDTH-1 : 0] req_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        	req_r <= 16'h7f3f;
        end
        else begin
            if (o_find && i_change_pt) begin
                req_r <= req_r - o_grant; // 握手后需要将req拉低
            end
        end
    end
    
    RR_ARBITER_CASCADED #(
        .N(REQ_WIDTH)
    ) rr_arb (
        .clk(clk),
        .rst_n(rst_n),
        .i_index(req_r),
        .i_change_pt(i_change_pt),
        .o_find_one_hot(o_grant),
        .o_find(o_find),
        .o_index()
    );
    
    `probe(req_r);
    `probe(o_grant);
    `probe(o_find);
    `probe(i_change_pt);

endmodule

module SP_ARBITER #(
    parameter N = 4
)(
    input [N-1 : 0] i_req,
    output [N-1 : 0] o_grant,
    output [N-1 : 0] o_exit_higher_prio_reqs
);

    assign o_grant = i_req & (~i_req + 1);
    assign o_exit_higher_prio_reqs = i_req ^ (~i_req + 1);

endmodule

module RR_ARBITER #(
    parameter N = 4,
    parameter AW= $clog2(N)
)(
    //ICB
    input clk,
    input rst_n,
    //InData
    input [N-1:0] i_index,
    input i_change_pt,

    //OutData
    output [N-1:0] o_find_one_hot,
    output o_find,
    output [AW-1 : 0] o_index
);

reg [N-1 : 0] mask;

wire [N-1 : 0] req_masked = i_index & mask;

// output declaration of module SP_ARBITER1
wire [N-1:0] o_grant;
wire [N-1:0] o_exit_higher_prio_reqs;

SP_ARBITER #(
    .N 	(N  ))
u_SP_ARBITER1(
    .i_req                   	(i_index                  ),
    .o_grant                 	(o_grant                  ),
    .o_exit_higher_prio_reqs 	(o_exit_higher_prio_reqs  )
);

// output declaration of module SP_ARBITER2
wire [N-1:0] o_grant_mask;
wire [N-1:0] o_exit_higher_prio_reqs_mask;

SP_ARBITER #(
    .N 	(N  ))
u_SP_ARBITER2(
    .i_req                   	(req_masked                    ),
    .o_grant                 	(o_grant_mask                  ),
    .o_exit_higher_prio_reqs 	(o_exit_higher_prio_reqs_mask  )
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mask <= 'd0;
    end
    else begin
        if (o_find && i_change_pt) begin
            mask <= (|req_masked == 'd0) ? o_exit_higher_prio_reqs : o_exit_higher_prio_reqs_mask;
        end
    end
end

assign o_find_one_hot = (|req_masked == 'd0) ? o_grant : o_grant_mask;
assign o_find = |o_find_one_hot;
    
    `probe(i_index);
    // `probe(mask);
    // `probe(req_masked);
    // `probe(o_grant_mask);
    `probe(o_find_one_hot);
    `probe(o_find);


endmodule

module RR_ARBITER_CASCADED #(
    parameter N = 16,
    parameter AW = $clog2(N)
) (
    //ICB
    input clk,
    input rst_n,
    //InData
    input [N-1:0] i_index,
    input i_change_pt,

    //OutData
    output [N-1:0] o_find_one_hot,
    output o_find,
    output [AW-1 : 0] o_index
);

wire [N/4-1 : 0] find_one_hot_0;
wire [N/4-1 : 0] find_one_hot_1;
wire [N/4-1 : 0] find_one_hot_2;
wire [N/4-1 : 0] find_one_hot_3;

wire o_find_0, o_find_1, o_find_2, o_find_3, o_find_top;

wire change_pt_rr0, change_pt_rr1, change_pt_rr2, change_pt_rr3;

RR_ARBITER #(.N(N/4)) rr0 (
    .clk           (clk),
    .rst_n         (rst_n),
    .i_index       ({i_index[12], i_index[8], i_index[4], i_index[0]}),
    .i_change_pt   (change_pt_rr0),
    .o_find_one_hot(find_one_hot_0),
    .o_find        (o_find_0),
    .o_index       ()
);

RR_ARBITER #(.N(N/4)) rr1 (
    .clk           (clk),
    .rst_n         (rst_n),
    .i_index       ({i_index[12+1], i_index[8+1], i_index[4+1], i_index[0+1]}),
    .i_change_pt   (change_pt_rr1),
    .o_find_one_hot(find_one_hot_1),
    .o_find        (o_find_1),
    .o_index       ()
);

RR_ARBITER #(.N(N/4)) rr2 (
    .clk           (clk),
    .rst_n         (rst_n),
    .i_index       ({i_index[12+1+1], i_index[8+1+1], i_index[4+1+1], i_index[0+1+1]}),
    .i_change_pt   (change_pt_rr2),
    .o_find_one_hot(find_one_hot_2),
    .o_find        (o_find_2),
    .o_index       ()
);

RR_ARBITER #(.N(N/4)) rr3 (
    .clk           (clk),
    .rst_n         (rst_n),
    .i_index       ({i_index[12+3], i_index[8+3], i_index[4+3], i_index[0+3]}),
    .i_change_pt   (change_pt_rr3),
    .o_find_one_hot(find_one_hot_3),
    .o_find        (o_find_3),
    .o_index       ()
);

wire [N/4-1 : 0] o_find_rr_one_hot;

RR_ARBITER #(.N(N/4)) rr_top (
    .clk           (clk),
    .rst_n         (rst_n),
    .i_index       ({o_find_3, o_find_2, o_find_1, o_find_0}),
    .i_change_pt   (i_change_pt),
    .o_find_one_hot(o_find_rr_one_hot),
    .o_find        (o_find_top),
    .o_index       ()
);

assign change_pt_rr0 = o_find_rr_one_hot[0] && i_change_pt;
assign change_pt_rr1 = o_find_rr_one_hot[1] && i_change_pt;
assign change_pt_rr2 = o_find_rr_one_hot[2] && i_change_pt;
assign change_pt_rr3 = o_find_rr_one_hot[3] && i_change_pt;

assign o_find = o_find_top;

assign o_find_one_hot[0] = o_find_rr_one_hot == 4'b0001 ? find_one_hot_0[0] : 1'b0;
assign o_find_one_hot[1] = o_find_rr_one_hot == 4'b0010 ? find_one_hot_1[0] : 1'b0;
assign o_find_one_hot[2] = o_find_rr_one_hot == 4'b0100 ? find_one_hot_2[0] : 1'b0;
assign o_find_one_hot[3] = o_find_rr_one_hot == 4'b1000 ? find_one_hot_3[0] : 1'b0;

assign o_find_one_hot[0+4] = o_find_rr_one_hot == 4'b0001 ? find_one_hot_0[1] : 1'b0;
assign o_find_one_hot[1+4] = o_find_rr_one_hot == 4'b0010 ? find_one_hot_1[1] : 1'b0;
assign o_find_one_hot[2+4] = o_find_rr_one_hot == 4'b0100 ? find_one_hot_2[1] : 1'b0;
assign o_find_one_hot[3+4] = o_find_rr_one_hot == 4'b1000 ? find_one_hot_3[1] : 1'b0;

assign o_find_one_hot[0+8] = o_find_rr_one_hot == 4'b0001 ? find_one_hot_0[2] : 1'b0;
assign o_find_one_hot[1+8] = o_find_rr_one_hot == 4'b0010 ? find_one_hot_1[2] : 1'b0;
assign o_find_one_hot[2+8] = o_find_rr_one_hot == 4'b0100 ? find_one_hot_2[2] : 1'b0;
assign o_find_one_hot[3+8] = o_find_rr_one_hot == 4'b1000 ? find_one_hot_3[2] : 1'b0;

assign o_find_one_hot[0+12] = o_find_rr_one_hot == 4'b0001 ? find_one_hot_0[3] : 1'b0;
assign o_find_one_hot[1+12] = o_find_rr_one_hot == 4'b0010 ? find_one_hot_1[3] : 1'b0;
assign o_find_one_hot[2+12] = o_find_rr_one_hot == 4'b0100 ? find_one_hot_2[3] : 1'b0;
assign o_find_one_hot[3+12] = o_find_rr_one_hot == 4'b1000 ? find_one_hot_3[3] : 1'b0;
    
    `probe(o_find_rr_one_hot);
    
endmodule