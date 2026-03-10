const chatMessages = document.getElementById('chat-messages');
const userInput = document.getElementById('user-input');
const sendBtn = document.getElementById('send-btn');
const connectionStatus = document.getElementById('connection-status');
const statusQwen = document.getElementById('status-qwen');
const statusGemini = document.getElementById('status-gemini');
const taskStatusEl = document.getElementById('task-status');

let socket;
let reconnectInterval = 5000;

// --- Task Queue ---
let isRunning = false;
const taskQueue = [];

function updateTaskStatus() {
    if (!isRunning && taskQueue.length === 0) {
        taskStatusEl.style.display = 'none';
        sendBtn.textContent = '发送';
        sendBtn.classList.remove('btn-queue');
        return;
    }
    taskStatusEl.style.display = 'flex';
    const queuePart = taskQueue.length > 0 ? ` &nbsp;·&nbsp; <span class="queue-badge">${taskQueue.length} 个等待</span>` : '';
    taskStatusEl.innerHTML = `<span class="ts-spinner"></span>&nbsp;执行中...${queuePart}`;
    if (taskQueue.length > 0) {
        sendBtn.textContent = `加入队列 (${taskQueue.length})`;
        sendBtn.classList.add('btn-queue');
    } else {
        sendBtn.textContent = '发送';
        sendBtn.classList.remove('btn-queue');
    }
}

function sendTask(text) {
    isRunning = true;
    updateTaskStatus();
    socket.send(JSON.stringify({ type: 'user_input', data: text }));
}

function connect() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    // Use port 18082 for WebSocket to match the backend change
    socket = new WebSocket(`${protocol}//${window.location.hostname}:18082/ws`);

    socket.onopen = () => {
        connectionStatus.textContent = '在线';
        connectionStatus.className = 'status-online';
    };

    socket.onclose = () => {
        connectionStatus.textContent = '离线 (重连中...)';
        connectionStatus.className = 'status-offline';
        // Reset running state on disconnect; preserve queue so tasks retry after reconnect.
        isRunning = false;
        updateTaskStatus();
        setTimeout(connect, reconnectInterval);
    };

    socket.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        handleServerMessage(msg);
    };
}

function handleServerMessage(msg) {
    switch (msg.type) {
        case 'ping':
            // Reply to server heartbeat to confirm the connection is alive.
            if (socket.readyState === WebSocket.OPEN) {
                socket.send(JSON.stringify({ type: 'pong', data: '' }));
            }
            break;
        case 'orchestrator_text':
            appendMessage('assistant', msg.data);
            break;
        case 'tool_start':
            updateAgentStatus(msg.agent, true);
            appendToolCall(msg.agent, msg.data);
            break;
        case 'tool_result':
            updateAgentStatus(msg.agent, false);
            updateToolResult(msg.agent, msg.data);
            break;
        case 'final_result':
            appendMessage('assistant', msg.data, true);
            isRunning = false;
            if (taskQueue.length > 0) {
                const next = taskQueue.shift();
                updateTaskStatus();
                sendTask(next);
            } else {
                updateTaskStatus();
            }
            break;
    }
}

function appendMessage(role, text, isMarkdown = false) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${role}`;
    
    const bubble = document.createElement('div');
    bubble.className = 'bubble';
    
    if (isMarkdown) {
        bubble.innerHTML = marked.parse(text);
    } else {
        bubble.textContent = text;
    }
    
    messageDiv.appendChild(bubble);
    chatMessages.appendChild(messageDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function appendToolCall(agent, input) {
    const toolDiv = document.createElement('div');
    toolDiv.className = 'tool-call';
    toolDiv.id = `tool-${agent}-latest`;
    
    toolDiv.innerHTML = `
        <span class="tool-name">Calling ${agent}...</span>
        <div class="tool-input">${input}</div>
        <div class="tool-result-container"></div>
    `;
    
    chatMessages.appendChild(toolDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function updateToolResult(agent, result) {
    const toolDiv = document.getElementById(`tool-${agent}-latest`);
    if (toolDiv) {
        const resultContainer = toolDiv.querySelector('.tool-result-container');
        resultContainer.innerHTML = `<div class="tool-result">${result}</div>`;
        toolDiv.id = ''; // Remove ID so next call gets a new card
    }
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function updateAgentStatus(agent, isActive) {
    const element = agent === 'qwen' ? statusQwen : statusGemini;
    if (isActive) {
        element.classList.add('active');
    } else {
        element.classList.remove('active');
    }
}

function sendMessage() {
    const text = userInput.value.trim();
    if (!text || socket.readyState !== WebSocket.OPEN) return;

    appendMessage('user', text);
    userInput.value = '';
    userInput.style.height = 'auto';

    if (isRunning) {
        // Previous task still running — enqueue.
        taskQueue.push(text);
        updateTaskStatus();
    } else {
        sendTask(text);
    }
}

sendBtn.addEventListener('click', sendMessage);

userInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

// Auto-resize textarea
userInput.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
});

connect();
