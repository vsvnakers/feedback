// feedback_tb.v - 用于验证 feedback.v 模块的 Testbench（含中文注释 + 输出检查）

module feedback_tb;
    parameter CLAUSE_NUM = 4;          // 字句数量（简化为4，便于测试）
    parameter WEIGHT_WIDTH = 8;        // 权重位宽
    parameter STATE_WIDTH = 8;         // 状态位宽
    parameter LITERAL_NUM = 8;         // 字面数量（简化为8）

    reg clk, rst_n, en;                                 // 时钟、复位和使能信号
    reg [CLAUSE_NUM-1:0] conjunction_result;            // 合取结果输入
    reg [LITERAL_NUM-1:0] actions;                      // 每个字面当前的动作（1为include，0为exclude）
    reg [LITERAL_NUM-1:0] literals;                     // 输入样本的字面值

    reg  [CLAUSE_NUM*WEIGHT_WIDTH-1:0] weight_in;       // 初始权重输入
    wire [CLAUSE_NUM*WEIGHT_WIDTH-1:0] weight_out;      // 更新后的权重输出

    reg  [LITERAL_NUM*STATE_WIDTH-1:0] state_in;        // 初始状态输入
    wire [LITERAL_NUM*STATE_WIDTH-1:0] state_out;       // 更新后的状态输出

    // 添加 VCD 波形输出
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, feedback_tb);
    end

    // 实例化 feedback 模块
    feedback #(
        .CLAUSE_NUM(CLAUSE_NUM),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .STATE_WIDTH(STATE_WIDTH),
        .LITERAL_NUM(LITERAL_NUM),
        .LFSR_WIDTH(24)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .conjunction_result(conjunction_result),
        .actions(actions),
        .literals(literals),
        .en(en),
        .weight_in(weight_in),
        .weight_out(weight_out),
        .state_in(state_in),
        .state_out(state_out)
    );

    // 时钟生成逻辑
    always #5 clk = ~clk;

    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        en = 0;
        conjunction_result = 0;
        actions = 0;
        literals = 0;
        weight_in = 0;
        state_in = 0;

        #10 rst_n = 1;
        #10 en = 1;

        // 设置输入
        conjunction_result = 4'b1010;
        actions = 8'b11001100;
        literals = 8'b10101010;
        weight_in = 32'h01020304;
        state_in = 64'h0102030405060708;

        #20;

        // 输出显示
        $display("==== 状态输出 ====");
        $display("state_out = %h", state_out);
        $display("==== 权重输出 ====");
        $display("weight_out = %h", weight_out);

        // 正确的期望结果
        if (state_out != 64'h0202030306060707) begin
            $display("[ERROR] 状态更新不符合预期！");
        end else begin
            $display("[PASS] 状态更新正确。");
        end

        if (weight_out != 32'h02020404) begin
            $display("[ERROR] 权重更新不符合预期！");
        end else begin
            $display("[PASS] 权重更新正确。");
        end

        #10 $finish;
    end
endmodule