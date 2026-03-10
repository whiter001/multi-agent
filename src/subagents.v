module main

import os
import time

// agent_timeout is the maximum time to wait for any sub-agent CLI response.
const agent_timeout = 120 * time.second

// run_agent_process spawns a CLI tool directly via os.Process (no shell),
// which prevents shell injection via prompt content (backticks, $(), etc.).
// extra_env keys with an empty value are REMOVED from the subprocess environment;
// non-empty keys are set/overridden. All other parent env vars are inherited.
fn run_agent_process(exe string, args []string, extra_env map[string]string, timeout time.Duration) string {
	exe_path := os.find_abs_path_of_executable(exe) or {
		return 'Error: ${exe} not found in PATH'
	}
	mut env := os.environ()
	for k, v in extra_env {
		if v == '' {
			env.delete(k)
		} else {
			env[k] = v
		}
	}
	mut p := os.new_process(exe_path)
	p.set_args(args)
	p.set_environment(env)
	p.set_redirect_stdio()
	p.run()
	// Timeout: kill the process if it does not finish within the deadline.
	spawn fn [mut p, timeout]() {
		time.sleep(timeout)
		if p.is_alive() {
			p.signal_kill()
		}
	}()
	out := p.stdout_slurp()
	p.wait()
	if p.code != 0 {
		return 'Error (exit ${p.code}): ${out}'
	}
	return out
}

fn run_qwen(prompt string) string {
	println('Calling Qwen sub-agent (model: coder-model)...')
	return run_agent_process('qwen', ['-y', '-m', 'coder-model', '-p', prompt], {
		'http_proxy':  ''
		'https_proxy': ''
		'HTTP_PROXY':  ''
		'HTTPS_PROXY': ''
	}, agent_timeout)
}

fn run_gemini(prompt string) string {
	println('Calling Gemini sub-agent (model: gemini-3-flash-preview)...')
	return run_agent_process('gemini', ['-y', '-m', 'gemini-3-flash-preview', '-p', prompt], {
		'http_proxy':  'http://127.0.0.1:7788'
		'https_proxy': 'http://127.0.0.1:7788'
		'HTTP_PROXY':  'http://127.0.0.1:7788'
		'HTTPS_PROXY': 'http://127.0.0.1:7788'
	}, agent_timeout)
}
