// feedback.v - Type I、II、III Feedback 实现（含中文注释 + 工作原理）

module feedback #(
    parameter CLAUSE_NUM = 128,              // 字句数量（每个Clause由多个TA组成）
    parameter WEIGHT_WIDTH = 8,              // Clause的权重位宽（通常为有符号数，用于表示分类贡献）
    parameter LFSR_WIDTH = 24,               // 随机数发生器位宽（未用，可扩展）
    parameter LITERAL_NUM = 272,             // 字面数量（每个样本输入的特征数量）
    parameter STATE_WIDTH = 8                // 每个TA的状态位宽（状态最大值为2^STATE_WIDTH - 1）
)(
    input clk,                               // 时钟信号
    input rst_n,                             // 异步复位，低有效

    input [CLAUSE_NUM-1:0] conjunction_result,   // 每个Clause对当前样本是否匹配（1=匹配成功）
    input [LITERAL_NUM-1:0] actions,             // 每个TA当前的动作（1=include，0=exclude）
    input [LITERAL_NUM-1:0] literals,            // 样本中的字面值（布尔输入）

    input en,                                    // 使能信号（高电平时触发反馈更新）
    input is_positive_sample,                    // 是否为正类样本（决定是Type I还是Type II反馈）
    input feedback_type_3_enable,                // 是否启用 Type III 随机扰动机制

    input  [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_in,      // Clause输入权重
    output reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_out, // Clause更新后的权重

    input  [LITERAL_NUM * STATE_WIDTH - 1:0] state_in,        // 所有TA的输入状态（打包格式）
    output reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_out    // 所有TA的更新状态（打包格式）
);

    integer i;
    reg [STATE_WIDTH-1:0] curr_state;                  // 临时变量：当前TA状态
    reg signed [WEIGHT_WIDTH-1:0] curr_weight;         // 临时变量：当前Clause权重

    // 工作原理：
    // Tsetlin Machine通过训练让每个TA学会如何include或exclude某些特征，从而让Clause整体在正类中为真、负类中为假。
    // Type I 用于增强正类匹配；Type II 用于抑制负类误匹配；Type III 为扰动机制，防止陷入局部最优。

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清空所有状态和权重
            weight_out <= 0;
            state_out <= 0;
        end else if (en) begin
            if (is_positive_sample) begin
                // ======================= Type I Feedback ========================
                // 用于正类样本训练：鼓励 Clause 为真
                // 奖励 include 且 literal=1 的 TA（增大状态）
                // 奖励 exclude 且 literal=0 的 TA（减小状态）
                for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                    curr_state = state_in[i*STATE_WIDTH +: STATE_WIDTH];

                    if (actions[i]) begin
                        if (literals[i] && curr_state < ((1 << STATE_WIDTH) - 1))
                            curr_state = curr_state + 1;
                    end else begin
                        if (!literals[i] && curr_state > 0)
                            curr_state = curr_state - 1;
                    end

                    state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;
                end

                // Clause匹配成功时：增加其正向权重（鼓励其参与决策）
                for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
                    curr_weight = weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];

                    if (conjunction_result[i]) begin
                        if (curr_weight >= 0)
                            curr_weight = curr_weight + 1;
                        else
                            curr_weight = curr_weight - 1;
                    end

                    $display("[Type I] Clause %0d, in=%0d, out=%0d", i,
                             weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH],
                             curr_weight);

                    weight_out[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] <= curr_weight;
                end

            end else begin
                // ======================= Type II Feedback ========================
                // 用于负类样本训练：抑制Clause对负类的错误匹配
                // 惩罚 include 且 literal=1 的 TA（减小状态）
                // 奖励 exclude 且 literal=0 的 TA（增大状态）
                for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                    curr_state = state_in[i*STATE_WIDTH +: STATE_WIDTH];

                    if (actions[i]) begin
                        if (literals[i] && curr_state > 0)
                            curr_state = curr_state - 1;
                    end else begin
                        if (!literals[i] && curr_state < ((1 << STATE_WIDTH) - 1))
                            curr_state = curr_state + 1;
                    end

                    state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;
                end

                // Clause匹配成功：说明误判负类 → 减少其权重
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

                // ======================= Type III Feedback ========================
                // 工作原理：
                // 为防止某些TA长时间保持高或低状态，Type III引入随机扰动
                // 每个TA有 25% 概率被扰动一次（状态增加或减少1）
                if (feedback_type_3_enable) begin
                    $display("[Type III] Random disturbance activated...");
                    for (i = 0; i < LITERAL_NUM; i = i + 1) begin
                        curr_state = state_out[i*STATE_WIDTH +: STATE_WIDTH];

                        if ($urandom % 4 == 0) begin  // 25%概率扰动
                            if ($urandom % 2 == 0 && curr_state > 0)
                                curr_state = curr_state - 1;
                            else if (curr_state < ((1 << STATE_WIDTH) - 1))
                                curr_state = curr_state + 1;

                            $display("[Type III] TA[%0d] disturbed to state = %0d", i, curr_state);
                        end

                        state_out[i*STATE_WIDTH +: STATE_WIDTH] <= curr_state;
                    end
                end
            end
        end
    end
endmodule
