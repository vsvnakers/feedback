// d_prob.v - 用于计算 Type II 反馈概率 d（含修复后的完整实现）

module d_prob #(
    parameter T_WIDTH = 8                       // 超参数 T 的位宽
)(
    input clk,
    input rst_n,

    input [T_WIDTH:0] T,                        // 超参数 T，例如 36
    input [T_WIDTH:0] q,                        // 目标类别 q（1 表正样本，0 表负样本）
    input signed [T_WIDTH:0] v,                 // 当前类别得分（有符号数）

    output reg [T_WIDTH-1:0] d                  // 输出概率值 d（用于与 rand 比较）
);

    // ===================== 原理说明 =====================
    // Tsetlin 反馈中 Type II 的概率计算：
    //   d = | ±T - clip(v) | / 2
    // clip(v)：将 v 限制在 [-T, T] 范围
    // error = T-clip(v) 或 -T-clip(v)
    // d = abs(error) >> 1

    wire signed [T_WIDTH:0] clipped_v;         // 裁剪后的 v
    wire signed [T_WIDTH:0] error_val;         // 误差值
    reg [T_WIDTH-1:0] abs_error;               // 绝对值后再右移1位作为 d

    // clip(v, T)：将 v 限制在 [-T, T]
    assign clipped_v = (v > $signed(T)) ? $signed(T) :
                       (v < -$signed(T)) ? -$signed(T) : v;

    // error_val = (q==1) ? (T - clip(v)) : (-T - clip(v))
    assign error_val = q ? ($signed(T) - clipped_v) : (-$signed(T) - clipped_v);

    // 用时序逻辑先计算 abs(error)，再除以2，避免阻塞赋值冲突
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_error <= 0;
            d <= 0;
        end else begin
            abs_error <= (error_val < 0) ? -error_val[T_WIDTH-1:0] : error_val[T_WIDTH-1:0];
            d <= abs_error >> 1;  // 相当于 /2
        end
    end
endmodule
