//
//  GatewayManager.swift
//  openNanos
//
//  OpenClaw Gateway 连接管理
//

import Foundation

actor GatewayManager {
    // MARK: - Properties

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var gatewayURL: URL?

    private let eventEmitter: EventEmitter

    // MARK: - Initialization

    init(eventEmitter: EventEmitter? = nil) {
        self.eventEmitter = eventEmitter ?? EventEmitter(webView: nil)
    }

    // MARK: - Public Methods

    func connect(url: String, apiKey: String?) async throws -> GatewayConnectResult {
        guard let gatewayURL = URL(string: url) else {
            throw RPCError(code: -32001, message: "Invalid Gateway URL")
        }

        self.gatewayURL = gatewayURL

        // 创建 URLSession
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        // 创建 WebSocket 连接
        var request = URLRequest(url: gatewayURL)

        // 添加认证头
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        self.webSocket = session?.webSocketTask(with: request)
        self.webSocket?.resume()

        // 启动接收循环
        startReceiving()

        // 标记为已连接
        self.isConnected = true

        print("Connected to Gateway: \(url)")

        // 发送状态变化事件
        await eventEmitter.emit("gateway.statusChanged", params: GatewayStatusChangedEvent(
            connected: true,
            reason: nil
        ))

        return GatewayConnectResult(
            connected: true,
            gatewayVersion: "unknown",  // 实际应用中从 Gateway 获取
            userId: nil
        )
    }

    func disconnect() async throws -> [String: Bool] {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        session = nil
        isConnected = false

        print("Disconnected from Gateway")

        // 发送状态变化事件
        await eventEmitter.emit("gateway.statusChanged", params: GatewayStatusChangedEvent(
            connected: false,
            reason: "User initiated"
        ))

        return ["disconnected": true]
    }

    func getStatus() -> GatewayStatus {
        return GatewayStatus(
            connected: isConnected,
            url: gatewayURL?.absoluteString,
            latency: nil,  // TODO: 实现 ping 测试
            lastError: nil
        )
    }

    func sendMessage(content: String, sessionId: String) async throws {
        guard isConnected, let webSocket = webSocket else {
            throw RPCError(code: -32003, message: "Not connected to Gateway")
        }

        // 构造发送给 OpenClaw 的消息
        let message: [String: Any] = [
            "type": "message",
            "sessionId": sessionId,
            "content": content,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]

        let data = try JSONSerialization.data(withJSONObject: message)
        let string = String(data: data, encoding: .utf8)!

        try await webSocket.send(.string(string))

        print("Sent message to Gateway")
    }

    // MARK: - Private Methods

    private func startReceiving() {
        Task {
            await receiveMessage()
        }
    }

    private func receiveMessage() async {
        guard let webSocket = webSocket else { return }

        do {
            let message = try await webSocket.receive()

            switch message {
            case .string(let text):
                await handleMessage(text)

            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    await handleMessage(text)
                }

            @unknown default:
                break
            }

            // 继续接收下一条消息
            await receiveMessage()

        } catch {
            print("WebSocket receive error: \(error)")
            isConnected = false

            // 发送断开事件
            await eventEmitter.emit("gateway.statusChanged", params: GatewayStatusChangedEvent(
                connected: false,
                reason: error.localizedDescription
            ))
        }
    }

    private func handleMessage(_ text: String) async {
        print("Received from Gateway: \(text)")

        // 解析消息
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else {
            print("Failed to parse Gateway message")
            return
        }

        switch type {
        case "message":
            // 收到 AI 助手的消息
            if let content = json["content"] as? String,
               let sessionId = json["sessionId"] as? String {
                let message = Message(
                    messageId: UUID().uuidString,
                    role: .assistant,
                    content: content,
                    attachments: nil,
                    timestamp: Int64(Date().timeIntervalSince1970 * 1000),
                    status: nil
                )

                await eventEmitter.emit("message.received", params: message)
            }

        case "stream":
            // 流式消息
            if let delta = json["delta"] as? String,
               let sessionId = json["sessionId"] as? String,
               let messageId = json["messageId"] as? String,
               let done = json["done"] as? Bool {
                await eventEmitter.emit("message.streaming", params: MessageStreamingEvent(
                    sessionId: sessionId,
                    messageId: messageId,
                    delta: delta,
                    done: done
                ))
            }

        case "error":
            // 错误消息
            if let errorMessage = json["message"] as? String {
                await eventEmitter.emit("error.occurred", params: ErrorOccurredEvent(
                    code: -32005,
                    message: errorMessage,
                    context: nil
                ))
            }

        default:
            print("Unknown message type: \(type)")
        }
    }
}
