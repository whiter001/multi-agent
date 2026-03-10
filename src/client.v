module main

import net.http
import json
import net.websocket

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
		system_prompt: '你是主 Agent（Main Agent），负责全局统筹与调度。
你的职责包括：
1. 接收用户的最终目标。
2. 将复杂任务拆解为可执行的子任务。
3. 根据任务类型选择合适的子 Agent。
   - Qwen (model: coder-model): 擅长逻辑推理、代码编写、结构化任务。
   - Gemini (model: gemini-3-flash-preview): 擅长创意写作、深度分析、发散性思维。
4. 向子 Agent 下达指令并收集结果。
5. 整合所有子 Agent 的输出，生成最终答案。
6. 处理异常、冲突、失败重试（如子 Agent 返回错误，应调整策略重新尝试）。
7. 管理上下文、状态与资源，确保任务高效完成。

请利用 call_qwen 和 call_gemini 工具来调度子任务。在任务完成后，给用户提供一个完整、专业且经过整合的最终答复。'
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

// chat_web is the core logic for the Web/WebSocket interface
fn (mut c ApiClient) chat_web(mut ws_client websocket.Client, user_prompt string) !string {
	c.messages << ChatMessage{role: 'user', content: user_prompt}
	
	mut final_answer := ''
	
	for i := 0; i < 10; i++ { // Increased to 10 rounds for complex tasks
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
			// Notify Web UI about orchestrator thought/text.
			// If the client disconnected, abort the entire loop immediately.
			send_ws_status(mut ws_client, 'orchestrator_text', msg.content, '') or { return err }
			println('Orchestrator: ${msg.content}')
		}

		c.messages << ChatMessage{
			role: 'assistant'
			content: msg.content
			tool_calls: msg.tool_calls
		}

		if msg.tool_calls.len > 0 {
			// 1. Notify all tool starts before executing
			for tc in msg.tool_calls {
				agent_name := tool_agent_name(tc.function.name)
				args_obj := json.decode(ToolArgs, tc.function.arguments) or { ToolArgs{prompt: tc.function.arguments} }
				send_ws_status(mut ws_client, 'tool_start', args_obj.prompt, agent_name) or { return err }
				println('Dispatching sub-agent: ${tc.function.name}...')
			}
			// 2. Execute all in parallel
			results := execute_tool_calls_parallel(msg.tool_calls)
			// 3. Collect results and notify Web UI
			for r in results {
				agent_name := tool_agent_name(r.tool_name)
				send_ws_status(mut ws_client, 'tool_result', r.result, agent_name) or { return err }
				preview := if r.result.len > 100 { r.result[..100] + '...' } else { r.result }
				println('Tool Result (${agent_name}): ${preview}')
				c.messages << ChatMessage{
					role: 'tool'
					content: r.result
					tool_call_id: r.id
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

// Keeping original chat method for CLI compatibility
fn (mut c ApiClient) chat(user_prompt string) !string {
	c.messages << ChatMessage{role: 'user', content: user_prompt}
	mut final_answer := ''
	for i := 0; i < 5; i++ {
		body := c.build_request_body()
		mut headers := http.new_header()
		headers.add(.authorization, 'Bearer ${c.api_key}')
		headers.add(.content_type, 'application/json')
		req := http.Request{ method: .post, url: c.api_url, header: headers, data: body }
		resp := req.do() or { return err }
		api_res := json.decode(ApiResponse, resp.body) or { return error('Failed to decode: ${err}') }
		msg := api_res.choices[0].message
		c.messages << ChatMessage{ role: 'assistant', content: msg.content, tool_calls: msg.tool_calls }
		if msg.tool_calls.len > 0 {
			// Execute all tool calls in parallel
			results := execute_tool_calls_parallel(msg.tool_calls)
			for r in results {
				c.messages << ChatMessage{ role: 'tool', content: r.result, tool_call_id: r.id }
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
