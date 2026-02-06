import Foundation

// OpenClaw Gateway WebSocket 客户端
class OpenClawWebSocketClient: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private let gatewayURL = "ws://127.0.0.1:18789"

    // 握手状态
    private var isHandshakeComplete = false
    private var connectNonce: String?

    var onMessageReceived: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // 连接到 OpenClaw Gateway
    func connect() {
        guard let url = URL(string: gatewayURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }

        print("🔌🔌🔌 OPENNANOS CONNECTING TO OPENCLAW GATEWAY: \(gatewayURL) 🔌🔌🔌")
        isHandshakeComplete = false
        connectNonce = nil

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        // 开始接收消息（等待 connect.challenge）
        receiveMessage()
    }

    // 断开连接
    func disconnect() {
        print("🔌 Disconnecting from OpenClaw Gateway")
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    // 发送握手请求
    private func sendConnect() {
        print("🔑 Starting connect handshake, nonce: \(connectNonce ?? "none")")

        // 构造 connect 请求（JSON-RPC 格式）
        // 使用网关 token 进行认证，跳过设备身份验证
        let request: [String: Any] = [
            "type": "req",
            "id": UUID().uuidString,
            "method": "connect",
            "params": [
                "minProtocol": 3,
                "maxProtocol": 3,
                "client": [
                    "id": "openclaw-macos",
                    "displayName": "openNanos Mac",
                    "version": "1.0.0",
                    "platform": "darwin",
                    "mode": "ui"
                ],
                "auth": [
                    "token": "7d27a9fd381cb48b8c993246c126c78b19c1e5bd639cec2b"
                ],
                "role": "operator",
                "scopes": ["operator.admin"]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: request),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize connect request")
            return
        }

        print("📤 Sending connect request")
        let message = URLSessionWebSocketTask.Message.string(jsonString)

        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("❌ Failed to send connect: \(error)")
                self?.onError?(error)
            } else {
                print("✅ Connect request sent")
            }
        }
    }

    // 发送消息到 AI
    func sendMessage(_ message: String, sessionKey: String = "agent:main:main") {
        guard isHandshakeComplete else {
            print("❌ Handshake not complete, cannot send message")
            onError?(NSError(domain: "OpenClawWebSocket", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Not connected to gateway"]))
            return
        }

        guard let webSocketTask = webSocketTask else {
            print("❌ WebSocket not connected")
            return
        }

        // 构造 OpenClaw 的消息请求（JSON-RPC 格式）
        // 使用正确的 chat.send 方法
        let request: [String: Any] = [
            "type": "req",
            "id": UUID().uuidString,
            "method": "chat.send",
            "params": [
                "sessionKey": sessionKey,
                "message": message,
                "idempotencyKey": UUID().uuidString,
                "thinking": "low"
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: request),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize message")
            return
        }

        print("📤 Sending message to OpenClaw: \(message)")
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)

        webSocketTask.send(wsMessage) { [weak self] error in
            if let error = error {
                print("❌ Failed to send message: \(error)")
                self?.onError?(error)
            } else {
                print("✅ Message sent successfully")
            }
        }
    }

    // 接收消息
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received message: \(text.prefix(100))...")
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📥 Received data message: \(text.prefix(100))...")
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }

                // 继续接收下一条消息
                self?.receiveMessage()

            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.onError?(error)
                self?.onDisconnected?()
            }
        }
    }

    // 处理接收到的消息
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Failed to parse JSON message")
            return
        }

        let messageType = json["type"] as? String ?? "unknown"
        print("📨 Message type: \(messageType)")

        switch messageType {
        case "event":
            // 处理事件
            handleEvent(json)

        case "res":
            // 处理响应
            handleResponse(json)

        default:
            print("ℹ️ Unhandled message type: \(messageType)")
        }
    }

    // 处理事件消息
    private func handleEvent(_ json: [String: Any]) {
        guard let event = json["event"] as? String else {
            print("⚠️ Event message missing 'event' field")
            return
        }

        print("📨 Event: \(event)")

        switch event {
        case "connect.challenge":
            // 握手挑战：提取 nonce 并发送 connect 请求
            if let payload = json["payload"] as? [String: Any],
               let nonce = payload["nonce"] as? String {
                print("🔑 Received connect challenge with nonce")
                connectNonce = nonce
                sendConnect()
            }

        case "chat":
            // 处理 chat 事件 - 包含 AI 回复的流式输出
            if let payload = json["payload"] as? [String: Any] {
                let state = payload["state"] as? String ?? "unknown"
                print("💬 Chat event state: \(state)")

                switch state {
                case "delta":
                    // 流式输出块
                    if let delta = payload["delta"] as? String {
                        onMessageReceived?(delta)
                    }

                case "final":
                    // 回复结束
                    if let message = payload["message"] as? [String: Any],
                       let content = message["content"] as? [[String: Any]] {
                        // 提取文本内容
                        var fullText = ""
                        for item in content {
                            if let type = item["type"] as? String, type == "text",
                               let text = item["text"] as? String {
                                fullText += text
                            }
                        }
                        if !fullText.isEmpty {
                            onMessageReceived?(fullText)
                        }
                    }
                    print("✅ Chat reply completed")

                case "error":
                    // 错误
                    if let errorMessage = payload["errorMessage"] as? String {
                        print("❌ Chat error: \(errorMessage)")
                        onError?(NSError(domain: "OpenClaw", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    }

                default:
                    print("ℹ️ Unhandled chat state: \(state)")
                }
            }

        case "agent.reply.chunk":
            // 旧版流式输出的文本块（保留兼容性）
            if let payload = json["payload"] as? [String: Any],
               let content = payload["content"] as? String {
                onMessageReceived?(content)
            }

        case "agent.reply.end":
            // 旧版回复结束（保留兼容性）
            print("✅ Reply completed")

        case "agent.tool.start":
            // 工具调用开始
            if let payload = json["payload"] as? [String: Any],
               let toolName = payload["tool"] as? String {
                print("🔧 Tool started: \(toolName)")
            }

        case "agent.tool.end":
            // 工具调用结束
            if let payload = json["payload"] as? [String: Any],
               let toolName = payload["tool"] as? String {
                print("✅ Tool completed: \(toolName)")
            }

        case "tick":
            // 心跳
            print("💓 Tick received")

        case "health":
            // 健康检查
            print("💚 Health event received")

        default:
            print("ℹ️ Unhandled event: \(event)")
        }
    }

    // 处理响应消息
    private func handleResponse(_ json: [String: Any]) {
        print("📨 Processing response: \(json)")

        guard let ok = json["ok"] as? Bool else {
            print("⚠️ Response missing 'ok' field")
            return
        }

        if !ok {
            // 错误响应
            if let error = json["error"] as? [String: Any] {
                let errorCode = error["code"] as? String ?? "unknown"
                let errorMsg = error["message"] as? String ?? "unknown error"
                print("❌ Gateway error [\(errorCode)]: \(errorMsg)")
                onError?(NSError(domain: "OpenClaw", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg]))
            } else {
                print("❌ Gateway error: unknown")
            }
            return
        }

        // 成功响应 - 检查 payload 是否包含 HelloOk
        if let payload = json["payload"] as? [String: Any] {
            print("✅ Response payload keys: \(payload.keys.joined(separator: ", "))")

            if let type = payload["type"] as? String {
                print("📦 Payload type: \(type)")

                if type == "hello-ok" {
                    // 握手成功
                    isHandshakeComplete = true
                    print("✅ Handshake completed, connected to OpenClaw Gateway")
                    onConnected?()
                }
            } else {
                print("⚠️ Payload missing 'type' field")
            }
        } else {
            print("⚠️ Response missing 'payload' field")
        }
    }
}

// URLSessionWebSocketDelegate
extension OpenClawWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connection opened, waiting for connect.challenge...")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket connection closed: \(closeCode)")
        isHandshakeComplete = false
        onDisconnected?()
    }
}
