module main

import json

// Tool argument structure for robust parsing
struct ToolArgs {
	prompt string
}

// MiniMax V2 Response Structs
struct ApiResponse {
	id      string
	model   string
	choices []Choice
}

struct Choice {
	index         int
	message       AssistantMessage
	finish_reason string @[json: "finish_reason"]
}

struct AssistantMessage {
	role       string
	content    string
	tool_calls []ToolCall @[json: "tool_calls"]
}

struct ToolCall {
	id       string
	type     string
	function FunctionCall
}

struct FunctionCall {
	name      string
	arguments string
}

// execute_tool_call handles a single tool call with robust JSON parsing
fn execute_tool_call(tc ToolCall) string {
	name := tc.function.name
	args_json := tc.function.arguments
	
	// Use json.decode for robust parameter extraction
	args := json.decode(ToolArgs, args_json) or {
		// Fallback for simple strings if JSON decode fails
		return 'Error: Failed to parse tool arguments for ${name}: ${err}'
	}

	if args.prompt == '' {
		return 'Error: Missing prompt argument for ${name}'
	}

	return match name {
		'call_qwen' { run_qwen(args.prompt) }
		'call_gemini' { run_gemini(args.prompt) }
		else { 'Error: Unknown tool ${name}' }
	}
}
// ToolCallResult holds the output of one executed tool call.
struct ToolCallResult {
	id        string
	tool_name string
	result    string
}

// tool_agent_name maps a tool function name to a human-readable agent label.
fn tool_agent_name(tool_name string) string {
	return match tool_name {
		'call_qwen'   { 'qwen' }
		'call_gemini' { 'gemini' }
		else          { tool_name }
	}
}

// execute_tool_calls_parallel runs all tool calls concurrently via goroutines
// and collects results through a buffered channel. Results arrive in completion
// order, not submission order; callers match by ToolCallResult.id.
fn execute_tool_calls_parallel(tool_calls []ToolCall) []ToolCallResult {
	ch := chan ToolCallResult{cap: tool_calls.len}
	for tc in tool_calls {
		spawn fn [tc, ch]() {
			ch <- ToolCallResult{
				id:        tc.id
				tool_name: tc.function.name
				result:    execute_tool_call(tc)
			}
		}()
	}
	mut results := []ToolCallResult{cap: tool_calls.len}
	for _ in tool_calls {
		results << <-ch
	}
	return results
}