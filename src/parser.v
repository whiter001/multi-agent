module main

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

// Function to handle tool execution
fn (mut c ApiClient) execute_tools(tool_calls []ToolCall) []string {
	mut results := []string{}
	for tc in tool_calls {
		name := tc.function.name
		args_json := tc.function.arguments
		
		// Parse arguments
		// Expecting {"prompt": "..."}
		
		// Simplified argument extraction
		if prompt_start := args_json.index('"prompt":"') {
			start := prompt_start + 10
			if end := args_json.last_index('"') {
				if end > start {
					prompt := args_json[start..end]
					
					if name == 'call_qwen' {
						results << run_qwen(prompt)
					} else if name == 'call_gemini' {
						results << run_gemini(prompt)
					} else {
						results << 'Error: Unknown tool ${name}'
					}
					continue
				}
			}
		}
		results << 'Error: Missing or invalid prompt argument in ${name}'
	}
	return results
}
