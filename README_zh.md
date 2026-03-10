# multi-agent

一个使用 V 语言实现的多代理系统，以 Minimax-m2.5 为主协调器，Qwen/Gemini 为子代理。

## 功能特性

- **主协调器**: 使用 Minimax-m2.5 模型来协调任务
- **子代理**: 
  - **Qwen**: 擅长逻辑和通用任务
  - **Gemini**: 擅长创意写作和深度推理
- **可配置**: 支持自定义 API 密钥、模型、温度和最大 token 数

## 环境要求

- [V](https://vlang.io) 编译器
- Minimax API 密钥
- [Qwen CLI](https://github.com/QwenLM/Qwen)（可选，用于 Qwen 子代理）
- [Gemini CLI](https://github.com/google/gemini-cli)（可选，用于 Gemini 子代理）

## 快速开始

### 构建

```bash
v -o multi_agent.exe src/main.v
```

### 配置

在 `~/.config/multi-agent/config` 创建配置文件：

```ini
api_key=你的minimax_api密钥
model=MiniMax-M2.5
```

### 运行

```bash
./multi_agent.exe "你的任务描述"
```

## 配置选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `api_key` | （必填） | Minimax API 密钥 |
| `model` | `MiniMax-M2.5` | 模型名称 |
| `temperature` | `0.7` | 采样温度 |
| `max_tokens` | `4096` | 生成的最大 token 数 |

## 项目结构

```
multi-agent/
├── src/
│   ├── main.v         # 入口文件
│   ├── config.v       # 配置加载
│   ├── client.v       # API 客户端
│   ├── parser.v       # 响应解析
│   └── subagents.v    # 子代理运行器
├── tests/
│   └── subagents_test.v
├── README.md          # 英文文档
├── README_zh.md       # 中文文档
├── TODO.md
└── v.mod
```

## 许可证

MIT
