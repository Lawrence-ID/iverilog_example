module top_module();
    reg clk = 0;
    always #5 clk = ~clk;
    initial `probe_start;   // Start the timing diagram

    reg rst;

    parameter REQ_WIDTH = 8;
    reg [REQ_WIDTH-1:0] i_req;
    wire [REQ_WIDTH-1:0] o_grant;

    `probe(clk);        // Probe signal "clk"
    `probe(rst);

    initial begin
        #5 rst <= 1;
        #10 rst <= 0; i_req <= 8'd1;
        #10 i_req <= 8'd3;
        #10 i_req <= 8'd7;
        #10 i_req <= 8'd2;
        #10 i_req <= 8'd6;
        #10 i_req <= 8'd0;
        #10 i_req <= 8'd3;
        #10 i_req <= 8'd7;
        #10 i_req <= 8'd2;
        #10 i_req <= 8'd6;
        #20 i_req <= 8'd7;
        $display ("Hello world! The current time is (%0d ps)", $time);
        #50 $finish;
    end

    RR_Arbiter #(
        .REQ_WIDTH(REQ_WIDTH)
    ) rr_arb (
        .clock(clk),
        .reset(rst),
        .i_req(i_req),
        .o_grant(o_grant)
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

// No handshaking mechanism between master and slave
// By default, each cycle processes a request (req) and acknowledgement (ack)
module RR_Arbiter #(
    parameter REQ_WIDTH = 8
)(
    input                    clock,
    input                    reset,
    input  [REQ_WIDTH-1 : 0] i_req,
    output [REQ_WIDTH-1 : 0] o_grant
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
        else begin
            mask <= (req_masked == {REQ_WIDTH{1'b0}}) ? req_unmask_exit_higher_prio_reqs : req_mask_exit_higher_prio_reqs;
        end
    end

    assign o_grant = (req_masked == {REQ_WIDTH{1'b0}}) ? req_unmask_grant : req_mask_grant;

    `probe(i_req);
    `probe(mask);
    `probe(req_masked);
    `probe(req_unmask_grant);
    `probe(req_mask_grant);
    `probe(o_grant);

endmodule