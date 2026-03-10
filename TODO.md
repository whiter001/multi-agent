# Multi-Agent Project Plan & TODO

## Project Overview

A multi-agent system implemented in V, using **Minimax-m2.5** as the main orchestrator.
The orchestrator can delegate tasks to sub-agents via CLI tools:

- **Qwen**: `qwen -y -p "..."` (No proxy)
- **Gemini**: `gemini -y -p "..."` (Uses proxy `http://127.0.0.1:7788`)

## Implementation Progress

- [x] **Project Structure**: Initialized `v.mod` and `src/` directory.
- [x] **Sub-Agent Integration**: Implemented CLI execution with proxy management in `src/subagents.v`.
- [x] **API Client**: Implemented Minimax V2 API client with tool-calling loop in `src/client.v`.
- [x] **Response Parsing**: Implemented JSON parsing for Minimax responses in `src/parser.v`.
- [x] **Main Entry**: Created `src/main.v` for CLI usage.
- [ ] **Advanced Error Handling**: Improve parsing for complex tool arguments.
- [ ] **Streaming Support**: (Optional) Add streaming for better UX.

## How to Run

1. **Set API Key**:

   ```powershell
   $env:MINIMAX_API_KEY = "your_minimax_api_key_here"
   ```

2. **Build and Run**:

   ```powershell
   v run src . "Ask Qwen for a coding plan and Gemini to review it."
   ```

## Design Highlights

- **Proxy Isolation**: Proxy settings are set only during Gemini calls and reset immediately after.
- **V-Native**: Built entirely in V for speed and small binary size.
- **Orchestrator Logic**: Minimax-m2.5 is instructed to combine strengths of both sub-agents.
