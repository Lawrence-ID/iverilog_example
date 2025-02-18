module top_module ();
	reg clk=0;
    reg [7:0] i_req;
    wire [7:0] o_grant, o_exit_higher_prio_reqs;
	always #5 clk = ~clk;  // Create clock with period=10
	initial `probe_start;   // Start the timing diagram

	`probe(clk);        // Probe signal "clk"

	// A testbench
	initial begin
		#10 i_req <= 8'd0;
		#10 i_req <= 8'd1;
		#20 i_req <= 8'd2;
		#20 i_req <= 8'd3;
		$display ("Hello world! The current time is (%0d ps)", $time);
		#50 $finish;            // Quit the simulation
	end

    SP_Arbiter #(
        .REQ_WIDTH(8)
    ) sp_arb (
        .i_req (i_req),
        .o_grant(o_grant),
        .o_exit_higher_prio_reqs(o_exit_higher_prio_reqs)
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

    `probe(i_req);	// Sub-modules can also have `probe()
    `probe(o_grant);
    `probe(o_exit_higher_prio_reqs);
endmodule

