module main

import os

// Proxy settings for Gemini
const gemini_proxy = 'http://127.0.0.1:7788'

// run_qwen executes the qwen CLI: qwen -y -m coder-model -p "prompt"
fn run_qwen(prompt string) string {
	println('Calling Qwen sub-agent (model: coder-model)...')
	// Ensure qwen does not use proxy
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)
	os.setenv('HTTP_PROXY', '', true)
	os.setenv('HTTPS_PROXY', '', true)

	// Escape the prompt for shell
	res := os.execute('qwen -y -m coder-model -p "${prompt.replace('"', '\\"')}"')
	if res.exit_code != 0 {
		return 'Error calling Qwen (exit ${res.exit_code}): ${res.output}'
	}
	return res.output
}

// run_gemini executes the gemini CLI: gemini -y -m gemini-3-flash-preview -p "prompt"
fn run_gemini(prompt string) string {
	println('Calling Gemini sub-agent (model: gemini-3-flash-preview)...')
	// Set proxy for Gemini
	os.setenv('http_proxy', gemini_proxy, true)
	os.setenv('https_proxy', gemini_proxy, true)
	os.setenv('HTTP_PROXY', gemini_proxy, true)
	os.setenv('HTTPS_PROXY', gemini_proxy, true)

	res := os.execute('gemini -y -m gemini-3-flash-preview -p "${prompt.replace('"', '\\"')}"')
	
	// Reset proxy after call
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)
	os.setenv('HTTP_PROXY', '', true)
	os.setenv('HTTPS_PROXY', '', true)

	if res.exit_code != 0 {
		return 'Error calling Gemini (exit ${res.exit_code}): ${res.output}'
	}
	return res.output
}
