module main

import os

struct Config {
pub mut:
	api_key       string
	model         string
	api_url       string = 'https://api.minimax.chat/v1/text/chatcompletion_v2'
	temperature   f64    = 0.7
	max_tokens    int    = 4096
	system_prompt string = 'You are an orchestrator AI. You have access to sub-agents: Qwen and Gemini.
Use the tools call_qwen and call_gemini to delegate tasks. 
Qwen is good for logic and general tasks. Gemini is good for creative writing and deep reasoning.
Combine their results to fulfill the user request.
When the task is complete, provide a final answer to the user.'
}

fn load_config() !Config {
	home := os.home_dir()
	// Using the new dedicated config directory for multi-agent
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
