
## 🧠 总体目标：`feedback.v` 是干什么的？

`feedback.v` 是 **Tsetlin Machine 中的“反馈更新模块”**，用于在训练过程中，根据当前输入样本的结果，**更新每个 Tsetlin Automaton (TA) 的状态值以及每个 clause 的权重值**。

---

## 🧩 它处于哪一部分系统中？

在 Tsetlin Machine 系统中，大致流程如下：

```
输入样本 --> 各个 clause 匹配 --> 计算预测 --> 与 label 对比 --> 决定是否反馈 --> feedback.v --> 更新 TA 状态和权重
```

也就是说，`feedback.v` 是训练逻辑的一部分，**不参与推理，而只在学习/训练时使用**。


## ✅ 使用的仿真环境组成：

### 1. **iverilog**

* **作用：** 编译 Verilog 代码（包括模块和 testbench）
* **命令：** `iverilog -g2012 -o sim_feedback -s feedback_tb *.v`
* **说明：** 支持 Verilog-2005/2012，大多数 FPGA 项目都能在这里先验证逻辑正确性

---

### 2. **vvp**

* **作用：** 运行由 `iverilog` 编译出来的 `.out` 仿真文件（如 `sim_feedback`）
* **命令：** `vvp sim_feedback`
* **说明：** 会输出 `$display`、`$monitor` 的内容，并生成波形文件（若有 `$dumpfile`）

---

### 3. **GTKWave**（可选）

* **作用：** 查看 `.vcd` 波形文件
* **命令：** `gtkwave wave.vcd`
* **说明：** 可视化仿真信号变化，非常适合调试 TA 状态和 Clause 权重等时序行为

---

### 4. **Makefile**（你的工程中）

* **作用：** 自动调用上述命令，简化运行过程
* **支持命令：**

  * `make TOP=feedback run`（编译+运行）
  * `make wave`（打开波形）
  * `make clean`（清理中间文件）

---

### ✅ 总结：你正在使用的仿真环境是

> **Icarus Verilog + vvp + GTKWave + Makefile 自动化调度**

它是一个轻量、开源、适合学习与验证的 Verilog 仿真组合。如果你要移植到 ModelSim 或 Vivado 仿真环境，我也可以给出适配建议。是否需要？


## ✅ 如何使用这个 `Makefile`

### 1. 编译并运行测试文件

你只需要知道你模块的名字（比如模块叫 `feedback.v`，测试文件叫 `feedback_tb.v`），然后执行下面的命令：

```bash
make TOP=feedback run
```

> 它会自动帮你编译所有 `.v` 文件，然后运行 `feedback_tb` 测试模块。

---

### 2. 打开波形图（如果生成了 wave.vcd）

如果你在 testbench 中用了 `$dumpfile("wave.vcd");`，你可以运行：

```bash
make wave
```

> 它会打开 GTKWave 查看波形。

---

### 3. 清理编译后的临时文件

运行：

```bash
make clean
```

> 会删除所有 `sim_*` 和 `.vcd` 等临时文件，让工程目录干净。

---

### 4. 如果你有多个模块要测试

比如你有 `d_prob.v` 和 `d_prob_tb.v`：

```bash
make TOP=d_prob run
```

> 它会自动找 `d_prob_tb.v` 来运行测试。

