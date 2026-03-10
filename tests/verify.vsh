#!/usr/bin/v run

import os

fn main() {
	println('🚀 Starting Multi-Agent Functional Test...')

	// 1. Build the project
	println('Step 1: Compiling project...')
	build_res := os.execute('v src -o multi_agent_test.exe')
	if build_res.exit_code != 0 {
		println('❌ Compilation failed:')
		println(build_res.output)
		exit(1)
	}
	println('✅ Compilation successful.')

	// 2. Run a functional test case
	// We use a prompt that forces the use of sub-agents
	test_prompt := '请分别让 Qwen 和 Gemini 说一句你好，然后你汇总一下。'
	println('Step 2: Running orchestrator with prompt: "${test_prompt}"')
	
	run_res := os.execute('./multi_agent_test.exe "${test_prompt}"')
	
	if run_res.exit_code != 0 {
		println('❌ Execution failed:')
		println(run_res.output)
		cleanup()
		exit(1)
	}

	// 3. Verify the output
	println('Step 3: Verifying output content...')
	output := run_res.output
	
	mut success := true
	
	// Check for tool execution markers
	if !output.contains('Executing sub-agent tool: call_qwen') {
		println('⚠️  Warning: "call_qwen" execution marker not found.')
		success = false
	}
	if !output.contains('Executing sub-agent tool: call_gemini') {
		println('⚠️  Warning: "call_gemini" execution marker not found.')
		success = false
	}
	if !output.contains('Final Result:') {
		println('⚠️  Warning: "Final Result" section not found.')
		success = false
	}

	if success {
		println('✅ Functional test PASSED.')
		println('\n--- Execution Snippet ---')
		// Print a part of the output for visual confirmation
		lines := output.split('\n')
		snippet_limit := if lines.len > 15 { 15 } else { lines.len }
		for i in 0 .. snippet_limit {
			println(lines[i])
		}
		println('... (truncated)')
	} else {
		println('❌ Functional test FAILED.')
		println('Full Output for debugging:')
		println(output)
	}

	cleanup()
}

fn cleanup() {
	println('Step 4: Cleaning up...')
	if os.exists('multi_agent_test.exe') {
		os.rm('multi_agent_test.exe') or { println('Failed to remove test exe') }
	}
	println('Done.')
}
