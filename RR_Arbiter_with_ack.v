module top_module();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;   // Start the timing diagram

    reg rst;

    parameter REQ_WIDTH = 8;
    
    reg [REQ_WIDTH-1:0] i_req;
    reg [REQ_WIDTH-1:0] i_ack;
    wire [REQ_WIDTH-1:0] o_grant;
    wire o_valid;

    `probe(clk);        // Probe signal "clk"
    `probe(rst);

    initial begin
        #5 rst <= 1;
        #10 rst <= 0; i_req <= 8'b10111; i_ack <= 0;
        #10 i_ack <= 0;
        #10 i_ack <= 1;
        #10 i_ack <= 0;
        #10 i_ack <= 0;
        #10 i_ack <= 0;
        #10 i_ack <= 2;
        #10 i_ack <= 0;
        #10 i_ack <= 4;
        #10 i_ack <= 16;
        #10 i_ack <= 0;
        #10 i_ack <= 0;
        #10 i_req <= 8'b011001;
        #10 i_ack <= 1;
        #10 i_ack <= 8'b001000;
        #10 i_ack <= 8'b010000;
        #10 i_ack <= 8'b000000;
        #10 i_req <= 8'b000000;
        #10 i_req <= 8'b01000000; i_ack <= 8'b01000000;
        $display ("Hello world! The current time is (%0d ps)", $time);
        #50 $finish;
    end
    
    always @(posedge clk) begin
        if (o_valid && o_grant == i_ack) begin
        	i_req <= i_req - o_grant;
        end
    end

    RR_Arbiter_with_ack #(
        .REQ_WIDTH(REQ_WIDTH)
    ) rr_arb (
        .clock(clk),
        .reset(rst),
        .i_req(i_req),
        .i_ack(i_ack),
        .o_grant(o_grant),
        .o_valid(o_valid)
    );

endmodule

module SP_Arbiter#(
    parameter REQ_WIDTH = 8
)(
    input [REQ_WIDTH - 1 : 0] i_req,
    output [REQ_WIDTH - 1 : 0] o_grant,
    output [REQ_WIDTH - 1 : 0] o_exit_higher_prio_reqs
);
    assign o_grant = i_req & (~i_req + {{REQ_WIDTH - 1{1'b0}}, 1'b1});
    assign o_exit_higher_prio_reqs = i_req ^ (~i_req + {{REQ_WIDTH - 1{1'b0}}, 1'b1});

    // `probe(i_req);	// Sub-modules can also have `probe()
    // `probe(o_grant);
    // `probe(o_exit_higher_prio_reqs);
endmodule

// Handshaking mechanism between N masters and 1 slave
// Each master must wait for ACK after asserting req before deasserting it
module RR_Arbiter_with_ack #(
    parameter REQ_WIDTH = 8
)(
    input                    clock,
    input                    reset,
    input  [REQ_WIDTH-1 : 0] i_req,
    input  [REQ_WIDTH-1 : 0] i_ack,
    output [REQ_WIDTH-1 : 0] o_grant,
    output                   o_valid
);
    reg  [REQ_WIDTH-1 : 0] mask;
    wire [REQ_WIDTH-1 : 0] req_masked = mask & i_req;
    
    wire [REQ_WIDTH-1 : 0] req_unmask_grant;
    wire [REQ_WIDTH-1 : 0] req_unmask_exit_higher_prio_reqs;

    wire [REQ_WIDTH-1 : 0] req_mask_grant;
    wire [REQ_WIDTH-1 : 0] req_mask_exit_higher_prio_reqs;

    SP_Arbiter #(
        .REQ_WIDTH(REQ_WIDTH)
    ) sp_arb_req_unmask (
        .i_req(i_req),
        .o_grant(req_unmask_grant),
        .o_exit_higher_prio_reqs(req_unmask_exit_higher_prio_reqs)
    );
    
    SP_Arbiter #(
        .REQ_WIDTH(REQ_WIDTH)
    ) sp_arb_req_mask (
        .i_req(req_masked),
        .o_grant(req_mask_grant),
        .o_exit_higher_prio_reqs(req_mask_exit_higher_prio_reqs)
    );

    always @(posedge clock) begin
        if (reset) begin
            mask <= {REQ_WIDTH{1'b0}};
        end
        else if (o_valid && (o_grant == i_ack)) begin
            mask <= (req_masked == {REQ_WIDTH{1'b0}}) ? req_unmask_exit_higher_prio_reqs : req_mask_exit_higher_prio_reqs;
        end
    end

    assign o_grant = (req_masked == {REQ_WIDTH{1'b0}}) ? req_unmask_grant : req_mask_grant;
    assign o_valid = |o_grant;

    `probe(i_req);
    `probe(mask);
    `probe(req_masked);
    `probe(req_unmask_grant);
    `probe(req_mask_grant);
    `probe(o_valid);
    `probe(o_grant);
    `probe(i_ack);

endmodule