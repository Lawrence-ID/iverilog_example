module AsyncResetGen #(
)(
    input clock,
    input rst_async_n,      // 异步低电平复位信号
    output reg rst_sync_n   // 同步释放后的复位信号, 可接入系统的寄存器
);
    // 第一级同步寄存器（消除亚稳态）
    reg rst_sync1_n;

    always  @(posedge clock or negedge rst_async_n) begin
        if (!rst_async_n) begin
            rst_sync_n <= 1'b0;
            rst_sync1_n <= 1'b0;
        end
        else begin
            rst_sync1_n <= 1'b1;         // 同步阶段1
            rst_sync_n <= rst_sync1_n;   // 同步阶段2
        end
    end


endmodule


module AsyncResetGenWithStage #(
    parameter SYNC_STAGE = 2
)(
    input clock,
    input rst_async_n,      // 异步低电平复位信号
    output rst_sync_n   // 同步释放后的复位信号, 接入系统的寄存器rst_n端
);
    reg [SYNC_STAGE-1 : 0] sync_chain;

    always  @(posedge clock or negedge rst_async_n) begin
        if (!rst_async_n) begin
            sync_chain <= {SYNC_STAGE{1'b0}};
        end
        else begin
            sync_chain <= {sync_chain[SYNC_STAGE-2 : 0], 1'b1}
        end
    end

    assign rst_sync_n = sync_chain[SYNC_STAGE-1];

endmodule


module AsyncResetGenWithStageAndPulse #(
    parameter SYNC_STAGES = 2,    // 同步级数（默认2级）
    parameter PULSE_WIDTH = 4     // 最小复位脉冲宽度（时钟周期数）
)(
    input  clk,
    input  rst_async_n,
    output rst_sync_n
);

reg [SYNC_STAGES-1:0] sync_chain;
reg [PULSE_WIDTH-1:0] pulse_counter;

// 同步链
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        sync_chain <= {SYNC_STAGES{1'b0}};
    end else begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], 1'b1};
    end
end

// 复位脉冲展宽
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        pulse_counter <= {PULSE_WIDTH{1'b0}};
    end else begin
        pulse_counter <= {pulse_counter[PULSE_WIDTH-2:0], 1'b1};
    end
end

assign rst_sync_n = &pulse_counter && sync_chain[SYNC_STAGES-1];

endmodule

// Xilinx Vivado示例约束
// set_false_path -to [get_pins sync_chain_reg*/D]
// set_max_delay -from [get_ports rst_async_n] -to [get_pins sync_chain_reg*/D] 0.5