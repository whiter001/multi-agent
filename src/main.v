module main

import os

fn main() {
	// First priority: Check for the --web flag
	mut is_web := false
	for arg in os.args {
		if arg == '--web' {
			is_web = true
			break
		}
	}

	if is_web {
		println('Starting Web Mode...')
		start_web_server()
		return
	}

	// Second priority: CLI mode requires a task
	if os.args.len < 2 {
		println('Usage:')
		println('  multi-agent "your task description"  (CLI Mode)')
		println('  multi-agent --web                    (Web Interface Mode)')
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
