module main

import veb
import net.websocket
import os
import json

// --- Models for WebSocket communication ---

struct WsIncomingMessage {
	msg_type string @[json: 'type']
	data     string @[json: 'data']
}

struct WsOutgoingMessage {
	msg_type string @[json: 'type']
	data     string @[json: 'data']
	agent    string @[json: 'agent']
}

// --- Web Server Context & App ---

struct Context {
	veb.Context
}

struct App {
	veb.StaticHandler
mut:
	ws_server &websocket.Server = unsafe { nil }
	cfg       Config
}

// Controller for the index page
@['/']
fn (mut app App) index(mut ctx Context) veb.Result {
	return ctx.file('static/index.html')
}

// Static assets handler
@['/static/:file...']
fn (mut app App) static_assets(mut ctx Context, file string) veb.Result {
	return ctx.file(os.join_path('static', file))
}

// --- WebSocket Handlers ---

fn (mut app App) on_message(mut ws_client websocket.Client, msg &websocket.Message) ! {
	if msg.opcode == .text_frame {
		payload := msg.payload.bytestr()
		incoming := json.decode(WsIncomingMessage, payload) or { return }
		
		if incoming.msg_type == 'user_input' {
			println('Received user input via WebSocket: ${incoming.data}')
			
			// Launch AI Task in a separate thread to avoid blocking WS
			go app.run_ai_task(mut ws_client, incoming.data)
		}
	}
}

// This function bridges the AI logic with the WebSocket output
fn (mut app App) run_ai_task(mut ws_client websocket.Client, task string) {
	// 1. Initialize API Client with full config
	mut client := new_api_client(app.cfg.api_key, app.cfg.model)
	client.set_config(app.cfg)
	
	send_ws_status(mut ws_client, 'orchestrator_text', '任务已接收，正在统筹调度...', '')
	
	result := client.chat_web(mut ws_client, task) or {
		send_ws_status(mut ws_client, 'orchestrator_text', '发生错误: ${err}', '')
		return
	}
	
	send_ws_status(mut ws_client, 'final_result', result, '')
}

// Helper to send JSON messages back to the frontend
fn send_ws_status(mut ws_client websocket.Client, m_type string, data string, agent string) {
	msg := WsOutgoingMessage{
		msg_type: m_type
		data:     data
		agent:    agent
	}
	payload := json.encode(msg)
	ws_client.write_string(payload) or { println('Failed to send WS message: ${err}') }
}

pub fn start_web_server() {
	// Load config for the web server
	cfg := load_config() or {
		println('Error loading config: ${err}')
		return
	}

	mut app := App{
		cfg: cfg
	}

	// Initialize WebSocket Server on 18082
	mut s := websocket.new_server(.ip, 18082, '/ws')
	app.ws_server = s
	
	// Map WS events
	s.on_message(fn [mut app] (mut ws_client websocket.Client, msg &websocket.Message) ! {
		app.on_message(mut ws_client, msg)!
	})
	
	s.on_connect(fn (mut ws_client websocket.ServerClient) !bool {
		println('New WebSocket client connected: ${ws_client.client.id}')
		return true
	}) or { println('on_connect error: ${err}') }

	// Run WS server in background
	go s.listen()

	println('🚀 Multi-Agent Web Server starting on http://localhost:18081')
	println('📡 WebSocket listening on ws://localhost:18082/ws')
	
	veb.run[App, Context](mut app, 18081)
}
