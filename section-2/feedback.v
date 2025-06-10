// feedback.v - Type I 和 Type II Feedback 实现（含中文注释 + Type III 占位）

module feedback #(
    parameter CLAUSE_NUM = 128,              // 字句数量
    parameter WEIGHT_WIDTH = 8,              // 权重位宽（有符号数）
    parameter LFSR_WIDTH = 24,               // 随机数生成器位宽（保留未用）
    parameter LITERAL_NUM = 272,             // 每个字句包含的字面数量
    parameter STATE_WIDTH = 8                // TA 状态位宽（最大状态值为 2^STATE_WIDTH - 1）
)(
    input clk,                               // 时钟信号
    input rst_n,                             // 异步复位，低有效

    input [CLAUSE_NUM-1:0] conjunction_result,   // 每个字句对输入样本的合取结果（是否匹配）
    input [LITERAL_NUM-1:0] actions,             // 每个TA当前的动作（1表示include，0表示exclude）
    input [LITERAL_NUM-1:0] literals,            // 输入样本中每个字面的取值（1或0）
    input en,                                    // 反馈更新使能
    input is_positive_sample,                    // 当前是否为正类样本（控制 Type I 或 Type II）

    input  [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_in,     // 输入的权重值
    output reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_out, // 更新后的权重值

    input  [LITERAL_NUM * STATE_WIDTH - 1:0] state_in,       // 输入的 TA 状态
    output reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_out   // 更新后的 TA 状态
);

    integer i;
    reg [STATE_WIDTH-1:0] curr_state;                          // 当前处理的 TA 状态
    reg signed [WEIGHT_WIDTH-1:0] curr_weight;                 // 当前处理的权重（有符号）

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_out <= 0;
            state_out <= 0;
        end else if (en) begin
            if (is_positive_sample) begin
                // ===================================================================
                // 类型 I 反馈（Type I Feedback）：用于正类样本训练
                // ===================================================================
                for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                    curr_state = state_in[i*STATE_WIDTH +: STATE_WIDTH];

                    if (actions[i]) begin
                        if (literals[i] && curr_state < ((1 << STATE_WIDTH) - 1)) begin
                            curr_state = curr_state + 1;
                        end
                    end else begin
                        if (!literals[i] && curr_state > 0) begin
                            curr_state = curr_state - 1;
                        end
                    end

                    state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;
                end

                for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
                    curr_weight = weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];

                    if (conjunction_result[i]) begin
                        if (curr_weight >= 0)
                            curr_weight = curr_weight + 1;
                        else
                            curr_weight = curr_weight - 1;
                    end

                    // Debug 打印
                    $display("[Type I] Clause %0d, in=%0d, out=%0d", i,
                             weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH],
                             curr_weight);

                    weight_out[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] <= curr_weight;
                end

            end else begin
                // ===================================================================
                // 类型 II 反馈（Type II Feedback）：用于负类样本训练
                // ===================================================================
                for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                    curr_state = state_in[i*STATE_WIDTH +: STATE_WIDTH];

                    if (actions[i]) begin
                        if (literals[i] && curr_state > 0) begin
                            curr_state = curr_state - 1;
                        end
                    end else begin
                        if (!literals[i] && curr_state < ((1 << STATE_WIDTH) - 1)) begin
                            curr_state = curr_state + 1;
                        end
                    end

                    state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;
                end

                for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
                    curr_weight = weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];

                    if (conjunction_result[i]) begin
                        if (curr_weight >= 0)
                            curr_weight = curr_weight - 1;
                        else
                            curr_weight = curr_weight + 1;
                    end

                    $display("[Type II] Clause %0d, in=%0d, out=%0d", i,
                             weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH],
                             curr_weight);

                    weight_out[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] <= curr_weight;
                end
            end

            // ===================================================================
            // TODO: Type III Feedback - 随机扰动机制（防止过拟合）
            // ===================================================================

        end
    end
endmodule
