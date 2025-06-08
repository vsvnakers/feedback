// d_prob_tb.v - 测试 d_prob 模块的功能与正确性（含 PASS/ERROR 检查输出）

module d_prob_tb;
    parameter T_WIDTH = 8;

    reg clk, rst_n;
    reg  [T_WIDTH:0] T, q;
    reg signed [T_WIDTH:0] v;
    wire [T_WIDTH-1:0] d;

    // 实例化模块
    d_prob #( .T_WIDTH(T_WIDTH) ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .T(T),
        .q(q),
        .v(v),
        .d(d)
    );

    // 时钟生成
    always #5 clk = ~clk;

    // 结果检查任务
    task check;
        input [7:0] test_id;
        input [T_WIDTH-1:0] expected;
        begin
            if (d === expected)
                $display("[PASS] Test %0d: d = %0d", test_id, d);
            else
                $display("[ERROR] Test %0d: d = %0d, expect = %0d", test_id, d, expected);
        end
    endtask

    initial begin
        $dumpfile("d_prob.vcd");
        $dumpvars(0, d_prob_tb);

        clk = 0;
        rst_n = 0;
        T = 36;
        #10 rst_n = 1;

        // === 测试用例：q 表目标类别，v 表预测得分 ===
        q = 0; v = 20;   #20 check(1, 28); // | -36 - 20 | = 56 >> 1 = 28
        q = 1; v = 0;    #20 check(2, 18); // | 36 - 0 | = 36 >> 1 = 18
        q = 1; v = 50;   #20 check(3, 0);  // clipped to 36 => d = 0
        q = 0; v = -60;  #20 check(4, 0);  // clipped to -36 => d = 0
        q = 0; v = -20;  #20 check(5, 8);  // | -36 - (-20) | = 16 >> 1 = 8

        #20 $finish;
    end
endmodule