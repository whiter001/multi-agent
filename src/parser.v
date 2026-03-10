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
