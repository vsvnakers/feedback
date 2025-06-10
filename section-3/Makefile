# Makefile - 支持以模块名为基础自动编译运行（不要求 _tb 后缀）

# 指定 testbench 名（不带 .v 后缀）
TOP ?= feedback

# 自动补全 testbench 文件名（添加 _tb 后缀）
TB_FILE := $(TOP)_tb

# 编译输出文件名
OUT := sim_$(TOP)

# 所有源码文件
SRCS := $(wildcard *.v)

# 默认目标：编译 + 运行
all: run

# 编译规则
$(OUT): $(SRCS)
	@echo "[Compiling testbench $(TB_FILE)]"
	iverilog -g2012 -o $(OUT) -s $(TB_FILE) $(SRCS)

# 仿真执行
run: $(OUT)
	@echo "[Running $(TB_FILE)]"
	vvp $(OUT)

# 打开波形图（若有）
wave:
	gtkwave wave.vcd &

# 清理中间文件
clean:
	rm -f sim_* *.vcd

# 帮助信息
help:
	@echo "Usage: make TOP=<name> run | wave | clean"
	@echo "Examples:"
	@echo "  make TOP=feedback run     # 自动寻找 feedback_tb.v"
	@echo "  make TOP=d_prob run       # 自动寻找 d_prob_tb.v"
	@echo "  make wave                 # 打开波形图"
	@echo "  make clean                # 清理中间文件"
