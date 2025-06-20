

## ✅ `feedback.v` 模块工作原理详解

### 📌 模块功能简介：

本模块是 **Tsetlin Machine 中的 Feedback 控制逻辑**，用于根据输入样本的类型（正类或负类），对每个 TA（Tsetlin Automaton）的状态和 Clause 权重进行更新。

它通过 **三种反馈机制（Type I、II、III）** 来驱动学习过程：

| 反馈类型     | 使用时机        | 目的         | 涉及对象            |
| -------- | ----------- | ---------- | --------------- |
| Type I   | 正类样本输入      | 强化能识别正类的特征 | TA 状态、Clause 权重 |
| Type II  | 负类样本输入      | 抑制误判负类的规则  | TA 状态、Clause 权重 |
| Type III | 任意样本时（额外扰动） | 防止陷入局部最优状态 | TA 状态（随机扰动）     |

---

### 🧠 核心思想背景（Tsetlin Machine 原理）：

Tsetlin Machine 是一种使用简单二值规则和有限状态机（TA）组合构成逻辑判别器的学习架构。

* 每个 **TA** 学习判断某个字面是否应该被包含在规则中；
* 多个 TA 构成一个 **Clause**（类似布尔表达式：AND组合）；
* 多个 Clause 合作后，通过投票进行分类（类似神经网络的输出层）；
* Clause 的权重用于表示其在最终决策中的影响力（类似 softmax 权重）。

---

## 🔍 各反馈类型工作流程详解：



### 🟢 Type I Feedback（正样本反馈）

**使用时机：** `is_positive_sample = 1`

**目标：** 增强系统识别正样本的能力，让符合“正类特征”的 Clause 被激活，并给予奖励。

#### ➤ TA 状态更新逻辑：

| 条件                    | 动作               |
| --------------------- | ---------------- |
| include & literal = 1 | 状态上升（强化 include） |
| exclude & literal = 0 | 状态下降（强化 exclude） |

这些更新让 TA 更“坚决”地包含或排除某些字面，从而让 Clause 在遇到正样本时更可能为真。

#### ➤ Clause 权重更新逻辑：

* 如果 Clause 匹配成功（即为真）：

  * 权重加 1（如果是正权）
  * 权重减 1（如果是负权）

> 💡 **目的：** 增强这个 Clause 对分类结果的正面影响。

---

### 🔴 Type II Feedback（负样本反馈）

**使用时机：** `is_positive_sample = 0`

**目标：** 降低系统对负样本的误判率，削弱错误匹配的 Clause 的作用。

#### ➤ TA 状态更新逻辑：

| 条件                    | 动作               |
| --------------------- | ---------------- |
| include & literal = 1 | 状态下降（惩罚 include） |
| exclude & literal = 0 | 状态上升（奖励 exclude） |

这会使 TA 趋向于跳出“错误 include”状态，更倾向于排除负类特征。

#### ➤ Clause 权重更新逻辑：

* 如果 Clause 匹配成功（误匹配负样本）：

  * 权重减 1（如果是正权）
  * 权重加 1（如果是负权）

> 💡 **目的：** 抑制这个 Clause 对分类结果的错误引导。

---

### 🟡 Type III Feedback（扰动机制）

**使用时机：** `feedback_type_3_enable = 1`（通常配合 Type II 一起）

**目标：**
解决模型陷入“状态饱和”（所有 TA 状态趋于稳定）的风险，引入“随机性”鼓励探索。

#### ➤ 扰动逻辑：

* 对每个 TA，有 25% 概率被选中扰动；
* 如果选中：

  * 有 50% 概率状态减 1（前提：当前状态 > 0）
  * 否则状态加 1（前提：当前状态未达最大）

```text
扰动公式：
if ($urandom % 4 == 0) // 25% 概率
    if ($urandom % 2 == 0) 减1
    else 加1
```

> 💡 **目的：** 打破状态“僵局”，为系统注入搜索新模式的可能性，提高泛化能力。

```bash
# 执行
make TOP=feedback run 
```
