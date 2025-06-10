`timescale 1ns/1ps

module feedback_tb;

// ======================= 参数定义 ==========================
    parameter CLAUSE_NUM = 4;               // 字句数量
    parameter WEIGHT_WIDTH = 8;             // 每个字句权重的位宽（有符号数）
    parameter LITERAL_NUM = 8;              // 字面数量（等价于 TA 数量）
    parameter STATE_WIDTH = 4;              // TA 状态位宽（例如最大状态为 2^4 - 1 = 15）

// ======================= 输入输出信号定义 ==================
    reg clk, rst_n, en;                     // 时钟、复位、更新使能信号
    reg is_positive_sample;                 // 是否是正样本，决定是 Type I 还是 Type II 反馈
    reg feedback_type_3_enable;             // 是否启用 Type III 随机扰动反馈

    reg [CLAUSE_NUM-1:0] conjunction_result;    // 每个字句的匹配结果（1表示该字句为真）
    reg [LITERAL_NUM-1:0] actions;              // 每个 TA 的动作（1=include，0=exclude）
    reg [LITERAL_NUM-1:0] literals;             // 输入样本中每个字面的布尔值（1/0）

    reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_in;   // 所有字句的输入权重（打包形式）
    wire [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_out; // 所有字句的更新后权重

    reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_in;     // 所有 TA 的输入状态（打包形式）
    wire [LITERAL_NUM * STATE_WIDTH - 1:0] state_out;   // 所有 TA 的更新后状态

// ======================= 中间变量 ==========================
    reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_before; // 保存扰动前的状态值
    reg changed;                                        // 标记是否发生了扰动
    integer i;                                          // 通用循环计数器

// ======================= 实例化被测试模块 ==================
    feedback #(
        .CLAUSE_NUM(CLAUSE_NUM),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .LITERAL_NUM(LITERAL_NUM),
        .STATE_WIDTH(STATE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .is_positive_sample(is_positive_sample),
        .feedback_type_3_enable(feedback_type_3_enable),
        .conjunction_result(conjunction_result),
        .actions(actions),
        .literals(literals),
        .weight_in(weight_in),
        .weight_out(weight_out),
        .state_in(state_in),
        .state_out(state_out)
    );

// ======================= 时钟生成 ==========================
    always #5 clk = ~clk;   // 10ns周期时钟

// ======================= 测试过程 ==========================
    initial begin
        // 初始复位状态
        clk = 0;
        rst_n = 0;
        en = 0;
        is_positive_sample = 0;
        feedback_type_3_enable = 0;
        changed = 0;

        // 设置样本输入（动作、样本内容、字句匹配）
        actions = 8'b10101010;               // 奇偶位置交替设为 include/exclude
        literals = 8'b11001100;              // 输入样本内容，测试不同组合
        conjunction_result = 4'b1100;        // 前两个字句匹配，后两个不匹配

        // 初始化 TA 状态为 5
        for (i = 0; i < LITERAL_NUM; i = i + 1)
            state_in[i*STATE_WIDTH +: STATE_WIDTH] = 4'd5;

        // 初始化所有字句权重为 0
        for (i = 0; i < CLAUSE_NUM; i = i + 1)
            weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'sd0;

        // 复位释放
        #10 rst_n = 1;
        #10;

        // ========= Type I Feedback（正样本训练） =========
        $display("\n=== Type I Feedback ===");
        en = 1;
        is_positive_sample = 1;              // 设置为正样本
        feedback_type_3_enable = 0;          // 不启用扰动
        #10 en = 0;                          // 更新一次

        $write("State: ");
        for (i = 0; i < LITERAL_NUM; i = i + 1)
            $write("%0d ", state_out[i*STATE_WIDTH +: STATE_WIDTH]);
        $write("\n");

        // ========= Type II Feedback（负样本训练） =========
        $display("\n=== Type II Feedback ===");
        state_in = state_out;
        weight_in = weight_out;
        en = 1;
        is_positive_sample = 0;              // 设置为负样本
        feedback_type_3_enable = 0;          // 不启用扰动
        conjunction_result = 4'b1010;        // 更换匹配模式
        #10 en = 0;

        $write("State: ");
        for (i = 0; i < LITERAL_NUM; i = i + 1)
            $write("%0d ", state_out[i*STATE_WIDTH +: STATE_WIDTH]);
        $write("\n");

        // ========= Type III Feedback（随机扰动） =========
        $display("\n=== Type III Feedback ===");
        state_before = state_out;            // 记录扰动前状态
        state_in = state_out;
        weight_in = weight_out;
        en = 1;
        is_positive_sample = 0;              // 可设任意，扰动不依赖它
        feedback_type_3_enable = 1;          // 启用扰动
        conjunction_result = 4'b0000;        // 避免 Type II 生效
        $display("扰动前:");
        for (i = 0; i < LITERAL_NUM; i = i + 1)
            $write("%0d ", state_out[i*STATE_WIDTH +: STATE_WIDTH]);
        $write("\n");

        #10 en = 0;

        $display("扰动后:");
        for (i = 0; i < LITERAL_NUM; i = i + 1)
            $write("%0d ", state_out[i*STATE_WIDTH +: STATE_WIDTH]);
        $write("\n");

        // 检查是否发生扰动（任意一个 TA 状态发生变化即可）
        changed = 0;
        for (i = 0; i < LITERAL_NUM; i = i + 1) begin
            if (state_out[i*STATE_WIDTH +: STATE_WIDTH] !== state_before[i*STATE_WIDTH +: STATE_WIDTH])
                changed = 1;
        end

        if (changed == 1) begin
            $display("[PASS] Type III: at least one TA state changed");
        end else begin
            $display("[ERROR] Type III: no TA state changed");
        end

        $finish;
    end

endmodule
