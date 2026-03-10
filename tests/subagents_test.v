module tests

import os

// This is a standard V test. It will be picked up by `v test tests`
fn test_subagents_connectivity() {
	println('--- Testing Qwen (No Proxy) ---')
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)
	qwen_res := os.execute('qwen -y -p "你好"')
	assert qwen_res.exit_code == 0
	println('Qwen Output OK.')

	println('\n--- Testing Gemini (With Proxy) ---')
	os.setenv('http_proxy', 'http://127.0.0.1:7788', true)
	os.setenv('https_proxy', 'http://127.0.0.1:7788', true)
	gemini_res := os.execute('gemini -y -p "Hi"')

	// Reset proxy immediately
	os.setenv('http_proxy', '', true)
	os.setenv('https_proxy', '', true)

	assert gemini_res.exit_code == 0
	println('Gemini Output OK.')
}

fn main() {
	test_subagents_connectivity()
}
