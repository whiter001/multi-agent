# multi-agent

A multi-agent system implemented in V language, with Minimax-m2.5 as the main orchestrator and Qwen/Gemini as sub-agents.

## Features

- **Main Orchestrator**: Uses Minimax-m2.5 model to coordinate tasks
- **Sub-agents**:
  - **Qwen**: Good for logic and general tasks
  - **Gemini**: Good for creative writing and deep reasoning
- **Configurable**: Supports custom API key, model, temperature, and max tokens

## Requirements

- [V](https://vlang.io) compiler
- Minimax API key
- [Qwen CLI](https://github.com/QwenLM/Qwen) (optional, for Qwen sub-agent)
- [Gemini CLI](https://github.com/google/gemini-cli) (optional, for Gemini sub-agent)

## Quick Start

### Build

```bash
v -o multi_agent src/
```

### Configuration

Create config file at `~/.config/multi-agent/config`:

```ini
api_key=your_minimax_api_key
model=MiniMax-M2.5
api_url=https://api.minimaxi.com/v1/text/chatcompletion_v2
```

### Run

**CLI mode:**

```bash
./multi_agent "Your task description"
```

**Web interface mode:**

```bash
./multi_agent --web
# Then open http://localhost:18081
```

## Configuration Options

| Option        | Default                                              | Description                |
| ------------- | ---------------------------------------------------- | -------------------------- |
| `api_key`     | (required)                                           | Minimax API key            |
| `model`       | `MiniMax-M2.5`                                       | Model name                 |
| `api_url`     | `https://api.minimaxi.com/v1/text/chatcompletion_v2` | API endpoint               |
| `temperature` | `0.7`                                                | Sampling temperature       |
| `max_tokens`  | `4096`                                               | Maximum tokens to generate |

## Project Structure

```text
multi-agent/
├── src/
│   ├── main.v         # Entry point
│   ├── config.v       # Configuration loading
│   ├── client.v       # API client
│   ├── parser.v       # Response parser
│   └── subagents.v    # Sub-agent runners
├── tests/
│   └── subagents_test.v
├── README.md
├── README_zh.md       # Chinese documentation
├── TODO.md
└── v.mod
```

## License

MIT
