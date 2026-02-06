import Foundation
import WebKit

// Native Bridge 管理器：连接 React UI 和 OpenClaw Gateway
class NativeBridgeManager: NSObject {
    private let webSocketClient: OpenClawWebSocketClient
    private weak var webView: WKWebView?

    // 存储待处理的请求（ID -> 回调）
    private var pendingRequests: [Int: (Result<String, Error>) -> Void] = [:]
    private var requestIdCounter = 0

    init(webView: WKWebView) {
        self.webView = webView
        self.webSocketClient = OpenClawWebSocketClient()
        super.init()

        setupWebSocketHandlers()

        // Auto-connect on initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.connect()
        }
    }

    // 设置 WebSocket 事件处理
    private func setupWebSocketHandlers() {
        // 连接成功
        webSocketClient.onConnected = { [weak self] in
            print("✅ OpenClaw WebSocket connected")
            self?.notifyWebView(event: "openclaw.connected", data: [:])
        }

        // 连接断开
        webSocketClient.onDisconnected = { [weak self] in
            print("⚠️ OpenClaw WebSocket disconnected")
            self?.notifyWebView(event: "openclaw.disconnected", data: [:])
        }

        // 接收消息（流式输出）
        webSocketClient.onMessageReceived = { [weak self] content in
            print("📥 Received content chunk: \(content.prefix(50))...")

            // 通知 WebView 有新的内容块
            self?.notifyWebView(event: "openclaw.message.chunk", data: [
                "content": content,
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ])
        }

        // 错误处理
        webSocketClient.onError = { [weak self] error in
            print("❌ OpenClaw error: \(error.localizedDescription)")
            self?.notifyWebView(event: "openclaw.error", data: [
                "error": error.localizedDescription
            ])
        }
    }

    // 连接到 OpenClaw Gateway
    func connect() {
        webSocketClient.connect()
    }

    // 断开连接
    func disconnect() {
        webSocketClient.disconnect()
    }

    // 处理来自 WebView 的消息
    func handleMessage(from body: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let method = body["method"] as? String else {
            completion(.failure(NSError(domain: "NativeBridge", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing method"])))
            return
        }

        print("📨 Handling method: \(method)")

        switch method {
        case "sendMessage":
            handleSendMessage(params: body["params"] as? [String: Any], completion: completion)

        case "connect":
            connect()
            completion(.success(["status": "connecting"]))

        case "disconnect":
            disconnect()
            completion(.success(["status": "disconnected"]))

        case "getStatus":
            completion(.success([
                "connected": true,
                "gateway": "ws://127.0.0.1:18789"
            ]))

        default:
            completion(.failure(NSError(domain: "NativeBridge", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown method: \(method)"])))
        }
    }

    // 处理发送消息
    private func handleSendMessage(params: [String: Any]?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let params = params,
              let message = params["message"] as? String else {
            completion(.failure(NSError(domain: "NativeBridge", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing message parameter"])))
            return
        }

        let sessionKey = params["sessionKey"] as? String ?? "agent:main:main"

        print("📤 Sending message to OpenClaw: \(message)")

        // 发送消息到 OpenClaw
        webSocketClient.sendMessage(message, sessionKey: sessionKey)

        // 立即返回成功（实际的回复会通过 WebSocket 流式传输）
        completion(.success([
            "status": "sent",
            "message": message,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]))
    }

    // 通知 WebView 发生事件
    private func notifyWebView(event: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "type": event,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize event payload")
            return
        }

        // 转义 JSON 字符串中的特殊字符
        let escapedJson = jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")

        let script = """
        window.dispatchEvent(new MessageEvent('message', {
            data: '\(escapedJson)'
        }));
        """

        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("❌ Failed to send event to WebView: \(error)")
                } else {
                    print("✅ Event sent to WebView: \(event)")
                }
            }
        }
    }
}
