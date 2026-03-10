module main

import net.http
import json

struct ChatMessage {
pub mut:
	role    string
	content string
	// Tool results
	tool_call_id string
	// Tool calls (for assistant role)
	tool_calls []ToolCall
}

struct ApiClient {
pub mut:
	api_key       string
	api_url       string
	model         string
	temperature   f64
	max_tokens    int
	messages      []ChatMessage
	system_prompt string
}

fn new_api_client(api_key string, model string) ApiClient {
	return ApiClient{
		api_key: api_key
		api_url: 'https://api.minimax.chat/v1/text/chatcompletion_v2'
		model: model
		temperature: 0.7
		max_tokens: 4096
		system_prompt: 'You are an orchestrator AI. You have access to sub-agents: Qwen and Gemini.
Use the tools call_qwen and call_gemini to delegate tasks. 
Qwen is good for logic and general tasks. Gemini is good for creative writing and deep reasoning.
Combine their results to fulfill the user request.
When the task is complete, provide a final answer to the user.'
	}
}

fn (mut c ApiClient) set_config(cfg Config) {
	c.api_key = cfg.api_key
	c.model = cfg.model
	c.api_url = cfg.api_url
	c.temperature = cfg.temperature
	c.max_tokens = cfg.max_tokens
	c.system_prompt = cfg.system_prompt
}

fn escape_json_string(s string) string {
	return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
}

fn (mut c ApiClient) chat(user_prompt string) !string {
	c.messages << ChatMessage{role: 'user', content: user_prompt}
	
	mut final_answer := ''
	
	for i := 0; i < 5; i++ { // Max 5 rounds
		body := c.build_request_body()
		
		mut headers := http.new_header()
		headers.add(.authorization, 'Bearer ${c.api_key}')
		headers.add(.content_type, 'application/json')
		
		req := http.Request{
			method: .post
			url: c.api_url
			header: headers
			data: body
		}
		
		resp := req.do() or { return err }
		if resp.status_code != 200 {
			return error('API error: ${resp.status_code} - ${resp.body}')
		}
		
		api_res := json.decode(ApiResponse, resp.body) or {
			return error('Failed to decode response: ${err}\nBody: ${resp.body}')
		}
		
		if api_res.choices.len == 0 {
			return error('No choices returned from API')
		}
		
		msg := api_res.choices[0].message
		if msg.content.len > 0 {
			println('Orchestrator: ${msg.content}')
		}
		
		c.messages << ChatMessage{
			role: 'assistant', 
			content: msg.content,
			tool_calls: msg.tool_calls
		}
		
		if msg.tool_calls.len > 0 {
			for tc in msg.tool_calls {
				println('Executing sub-agent tool: ${tc.function.name}...')
				
				mut prompt := ''
				args := tc.function.arguments
				if args.contains('"prompt"') {
					if start_idx := args.index('"prompt":') {
						if content_start := args.index_after('"', start_idx + 9) {
							if content_end := args.last_index('"') {
								if content_end > content_start {
									prompt = args[content_start + 1..content_end]
								}
							}
						}
					}
				}
				
				if prompt == '' {
					prompt = args
				}

				mut result := ''
				if tc.function.name == 'call_qwen' {
					result = run_qwen(prompt)
				} else if tc.function.name == 'call_gemini' {
					result = run_gemini(prompt)
				}
				
				preview := if result.len > 100 { result[..100] + "..." } else { result }
				println('Tool Result: ${preview}')

				c.messages << ChatMessage{
					role: 'tool'
					content: result
					tool_call_id: tc.id
				}
			}
			continue
		} else {
			final_answer = msg.content
			break
		}
	}
	
	return final_answer
}

fn (c ApiClient) build_request_body() string {
	mut messages_json := '['
	messages_json += '{"role":"system","content":"${escape_json_string(c.system_prompt)}"},'
	for msg in c.messages {
		if msg.role == 'tool' {
			messages_json += '{"role":"tool","content":"${escape_json_string(msg.content)}","tool_call_id":"${msg.tool_call_id}"},'
		} else if msg.role == 'assistant' && msg.tool_calls.len > 0 {
			mut tc_json := '['
			for tc in msg.tool_calls {
				tc_json += '{"id":"${tc.id}","type":"function","function":{"name":"${tc.function.name}","arguments":"${escape_json_string(tc.function.arguments)}"}},'
			}
			if tc_json.ends_with(',') { tc_json = tc_json[..tc_json.len - 1] }
			tc_json += ']'
			messages_json += '{"role":"assistant","content":"${escape_json_string(msg.content)}","tool_calls":${tc_json}},'
		} else {
			messages_json += '{"role":"${msg.role}","content":"${escape_json_string(msg.content)}"},'
		}
	}
	if messages_json.ends_with(',') {
		messages_json = messages_json[..messages_json.len - 1]
	}
	messages_json += ']'

	tools_json := '[
		{
			"type": "function",
			"function": {
				"name": "call_qwen",
				"description": "Delegate a task to the Qwen sub-agent.",
				"parameters": {
					"type": "object",
					"properties": {
						"prompt": {
							"type": "string",
							"description": "The specific task or question for Qwen."
						}
					},
					"required": ["prompt"]
				}
			}
		},
		{
			"type": "function",
			"function": {
				"name": "call_gemini",
				"description": "Delegate a task to the Gemini sub-agent.",
				"parameters": {
					"type": "object",
					"properties": {
						"prompt": {
							"type": "string",
							"description": "The specific task or question for Gemini."
						}
					},
					"required": ["prompt"]
				}
			}
		}
	]'

	return '{"model":"${c.model}","messages":${messages_json},"tools":${tools_json},"temperature":${c.temperature},"max_tokens":${c.max_tokens}}'
}
