//TODO ：
//完成预测阶段的投票，在一个周期内选出数值v_sum最高的种类
//需要注意路径长度
module y_vote #(
    parameter TYPE_NUM =10,
    parameter WEIGTH_WIDTH = 8
) (
    input         clk,          
    input         rst_n,
    input  [TYPE_NUM * WEIGTH -1 :0] v_sum,  //输入多种类的计算结果
    output [TYPE_NUM -1 : 0 ] y_out          //输出最终投票结果
);
    //在下方添加投票逻辑：
endmodule