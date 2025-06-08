//TODO :
//使用流水线优化路径，在三个周期计算单个种类的和v_sum

module v_sum #(
   parameter TYPE_NUM =10,
   parameter CLAUSE_NUM =128,
   parameter WEIGTH_WIDTH = 8
) (
    input         clk,          
    input         rst_n,
    input [CLAUSE_NUM-1 : 0] conjunction_result,
    input [CLAUSE_NUM * WEIGTH_WIDTH - 1 : 0] weight,
    output [WEIGTH_WIDTH -1 : 0] sum_out
);
    //计算和流水线逻辑在下方添加：
endmodule