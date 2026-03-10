module main

import os

fn main() {
	if os.args.len < 2 {
		println('Usage: multi-agent "your task description"')
		return
	}

	task := os.args[1]
	
	cfg := load_config() or {
		println('Error loading config: ${err}')
		return
	}

	println('Task: ${task}')
	println('Model: ${cfg.model}')
	println('Starting orchestrator...')

	mut client := new_api_client(cfg.api_key, cfg.model)
	client.set_config(cfg)
	
	result := client.chat(task) or {
		println('Error: ${err}')
		return
	}

	println('\nFinal Result:\n${result}')
}
