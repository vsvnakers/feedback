// feedback.v - Type I Feedback 实现（含详细中文注释 + Type II/III 占位标记）

module feedback #(
    parameter CLAUSE_NUM = 128,              // 字句数量
    parameter WEIGHT_WIDTH = 8,              // 权重位宽（通常为有符号数）
    parameter LFSR_WIDTH = 24,               // 随机数生成器位宽（保留未用）
    parameter LITERAL_NUM = 272,             // 每个字句包含的字面数量（即多少个TA）
    parameter STATE_WIDTH = 8                // TA 状态位宽（最大状态值为 2^STATE_WIDTH - 1）
)(
    input clk,                               // 时钟信号
    input rst_n,                             // 异步复位，低有效

    input [CLAUSE_NUM-1:0] conjunction_result, // 每个字句对输入样本的合取结果（是否匹配）
    input [LITERAL_NUM-1:0] actions,           // 每个TA当前的动作（1表示include，0表示exclude）
    input [LITERAL_NUM-1:0] literals,          // 输入样本中每个字面的取值（1或0）
    input en,                                  // 反馈更新使能

    input  [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_in,     // 输入的权重值
    output reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_out, // 更新后的权重值

    input  [LITERAL_NUM * STATE_WIDTH - 1:0] state_in,       // 输入的 TA 状态
    output reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_out   // 更新后的 TA 状态
);

    integer i;
    reg [STATE_WIDTH-1:0] curr_state;          // 当前处理的 TA 状态
    reg [WEIGHT_WIDTH-1:0] curr_weight;        // 当前处理的权重

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位时清零所有输出
            weight_out <= 0;
            state_out <= 0;
        end else if (en) begin
            // ===================================================================
            // 类型 I 反馈（Type I Feedback）：用于正类样本训练
            // 包括：
            // - TA 状态更新（include+literals=1时奖励）
            // - TA 状态更新（exclude+literals=0时奖励）
            // - Clause 权重：如果匹配成功，则调整权重值
            // ===================================================================

            // 1. TA 状态更新（针对所有字面）
            for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                curr_state = state_in[i*STATE_WIDTH +: STATE_WIDTH];

                if (actions[i]) begin
                    // 当前 TA 是 include 类型
                    if (literals[i] && curr_state < ((1 << STATE_WIDTH) - 1)) begin
                        curr_state = curr_state + 1;  // literal 为 1，增强 include
                    end
                end else begin
                    // 当前 TA 是 exclude 类型
                    if (!literals[i] && curr_state > 0) begin
                        curr_state = curr_state - 1;  // literal 为 0，增强 exclude
                    end
                end

                state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;  // 写回更新后状态
            end

            // 2. Clause 权重更新（仅对匹配的字句）
            for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
                curr_weight = weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];

                if (conjunction_result[i]) begin
                    // 匹配成功时调整权重：正值+1，负值-1
                    if (curr_weight[WEIGHT_WIDTH-1] == 1'b0)
                        curr_weight = curr_weight + 1;
                    else
                        curr_weight = curr_weight - 1;
                end

                weight_out[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] <= curr_weight;  // 写回更新后权重
            end

            // ===================================================================
            // TODO: Type II Feedback - 用于负类样本训练
            // - 惩罚匹配错误的 include 动作
            // - 奖励正确的 exclude 动作
            // - 权重朝负方向更新
            // ===================================================================

            // TODO: Type III Feedback - 随机扰动机制
            // - 防止过拟合，通过随机性鼓励探索
            // - 可选实现，通常用于 include/exclude 平衡
            // ===================================================================
        end
    end
endmodule