module main

import os

struct Config {
pub mut:
	api_key       string
	model         string
	api_url       string = 'https://api.minimax.chat/v1/text/chatcompletion_v2'
	temperature   f64    = 0.7
	max_tokens    int    = 4096
	system_prompt string = '你是主 Agent（Main Agent），负责全局统筹与调度。
你的职责包括：
1. 接收用户的最终目标。
2. 将复杂任务拆解为可执行的子任务。
3. 根据任务类型选择合适的子 Agent。
   - Qwen (model: coder-model): 擅长逻辑推理、代码编写、结构化任务。
   - Gemini (model: gemini-3-flash-preview): 擅长创意写作、深度分析、发散性思维。
4. 向子 Agent 下达指令并收集结果。
5. 整合所有子 Agent 的输出，生成最终答案。
6. 处理异常、冲突、失败重试（如子 Agent 返回错误，应调整策略重新尝试）。
7. 管理上下文、状态与资源，确保任务高效完成。

请利用 call_qwen 和 call_gemini 工具来调度子任务。在任务完成后，给用户提供一个完整、专业且经过整合的最终答复。'
}

fn load_config() !Config {
	home := os.home_dir()
	config_path := os.join_path(home, '.config', 'multi-agent', 'config')
	
	if !os.exists(config_path) {
		return error('Config file not found at ${config_path}. Please create it or copy from minimax config.')
	}

	lines := os.read_lines(config_path) or { return error('Failed to read config file') }
	mut cfg := Config{}

	for line in lines {
		if line.contains('=') {
			parts := line.split('=')
			key := parts[0].trim_space()
			val := parts[1].trim_space()
			match key {
				'api_key' { cfg.api_key = val }
				'model'   { cfg.model = val }
				'api_url' { cfg.api_url = val }
				'temperature' { cfg.temperature = val.f64() }
				'max_tokens'  { cfg.max_tokens = val.int() }
				else {}
			}
		}
	}

	if cfg.api_key == '' {
		return error('API key not found in config file: ${config_path}')
	}

	return cfg
}
