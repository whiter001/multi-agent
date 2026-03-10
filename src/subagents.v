module main

import os

// Proxy settings for Gemini
const gemini_proxy = 'http://127.0.0.1:7788'

// run_qwen executes the qwen CLI: qwen -y -p "prompt"
fn run_qwen(prompt string) string {
	println('Calling Qwen sub-agent...')
	// Ensure qwen does not use proxy
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)
	os.setenv('HTTP_PROXY', '', true)
	os.setenv('HTTPS_PROXY', '', true)

	// Note: We need to escape the prompt for shell
	// Using os.execute with a list of arguments is safer
	res := os.execute('qwen -y -p "${prompt.replace('"', '\\"')}"')
	if res.exit_code != 0 {
		return 'Error calling Qwen (exit ${res.exit_code}): ${res.output}'
	}
	return res.output
}

// run_gemini executes the gemini CLI: gemini -y -p "prompt"
fn run_gemini(prompt string) string {
	println('Calling Gemini sub-agent...')
	// Set proxy for Gemini
	os.setenv('http_proxy', gemini_proxy, true)
	os.setenv('https_proxy', gemini_proxy, true)
	os.setenv('HTTP_PROXY', gemini_proxy, true)
	os.setenv('HTTPS_PROXY', gemini_proxy, true)

	res := os.execute('gemini -y -p "${prompt.replace('"', '\\"')}"')
	
	// Reset proxy after call (optional but safer)
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)
	os.setenv('HTTP_PROXY', '', true)
	os.setenv('HTTPS_PROXY', '', true)

	if res.exit_code != 0 {
		return 'Error calling Gemini (exit ${res.exit_code}): ${res.output}'
	}
	return res.output
}
