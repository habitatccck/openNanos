//
//  WebViewController.swift
//  openNanos
//
//  WebView 控制器 - 管理 UI 加载和通信
//

import WebKit
import Combine
import AppKit

class WebViewController: NSObject, ObservableObject {
    // MARK: - Properties

    let webView: WKWebView
    private let rpcHandler: RPCHandler
    private let eventEmitter: EventEmitter
    private var bridgeManager: NativeBridgeManager?

    @Published var isWebViewLoaded = false

    // MARK: - Initialization

    override init() {
        // 配置 WebView
        let configuration = WKWebViewConfiguration()

        // 启用开发者工具和文件访问
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // 创建 WebView
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        // 创建服务
        self.rpcHandler = RPCHandler()
        self.eventEmitter = EventEmitter(webView: webView)

        super.init()

        // 注入消息处理器（必须在 WebView 创建后，通过 webView.configuration 访问）
        webView.configuration.userContentController.add(self, name: "nativeBridge")

        // 设置代理
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // 创建 NativeBridgeManager（它的 init 会自动触发连接）
        self.bridgeManager = NativeBridgeManager(webView: webView)
    }

    // MARK: - Public Methods

    func loadWebUI() {
        #if DEBUG
        // 开发模式：从 Vite 开发服务器加载
        if let url = URL(string: "http://localhost:5173") {
            print("Loading UI from development server: \(url)")
            webView.load(URLRequest(url: url))
            return
        }
        #endif

        // 尝试从多个位置加载 UI
        let possiblePaths = [
            // 开发模式：从 UI/dist 加载
            Bundle.main.resourceURL?
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("UI/dist/index.html"),

            // 生产模式：从 Resources/web 加载
            Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web"),
        ]

        for path in possiblePaths {
            if let url = path, FileManager.default.fileExists(atPath: url.path) {
                print("Loading UI from: \(url.path)")
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                return
            }
        }

        // 如果找不到本地文件，加载一个临时的 HTML
        loadFallbackHTML()
    }

    private func loadFallbackHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>openNanos</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .container {
                    text-align: center;
                    color: white;
                    padding: 40px;
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 20px;
                    backdrop-filter: blur(10px);
                }
                h1 { font-size: 48px; margin-bottom: 20px; }
                p { font-size: 18px; opacity: 0.9; margin-bottom: 30px; }
                button {
                    background: white;
                    color: #667eea;
                    border: none;
                    padding: 12px 30px;
                    font-size: 16px;
                    border-radius: 25px;
                    cursor: pointer;
                    font-weight: 600;
                    transition: transform 0.2s;
                }
                button:hover { transform: scale(1.05); }
                button:active { transform: scale(0.95); }
                #status { margin-top: 20px; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎵 openNanos</h1>
                <p>Your Digital Mind, Enhanced Intelligence</p>
                <button onclick="testBridge()">Test Native Bridge</button>
                <div id="status"></div>
            </div>

            <script>
                function testBridge() {
                    const request = {
                        jsonrpc: '2.0',
                        id: Date.now(),
                        method: 'gateway.getStatus'
                    };

                    window.webkit.messageHandlers.nativeBridge.postMessage(request);
                    document.getElementById('status').innerText = '✓ Request sent to native bridge!';
                }

                window.addEventListener('message', (event) => {
                    console.log('Response from native:', event.data);
                    document.getElementById('status').innerText = '✓ Received: ' + JSON.stringify(event.data);
                });
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - Private Methods

    @MainActor
    private func sendResponse(_ response: RPCResponse) {
        guard let data = try? JSONEncoder().encode(response),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            print("Failed to encode response")
            return
        }

        let script = """
        window.dispatchEvent(new MessageEvent('message', {
            data: \(jsonString)
        }));
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Failed to send response: \(error)")
            }
        }
    }
}

// MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "nativeBridge" else { return }

        // 解析请求
        guard let body = message.body as? [String: Any] else {
            print("❌ Failed to parse message body")
            return
        }

        print("📨 Received message from WebView: \(body)")

        // 使用 NativeBridgeManager 处理消息
        bridgeManager?.handleMessage(from: body) { [weak self] result in
            guard let self = self else { return }

            let requestId = body["id"] as? Int ?? 0

            switch result {
            case .success(let responseData):
                // 构造 JSON-RPC 响应
                let response: [String: Any] = [
                    "jsonrpc": "2.0",
                    "id": requestId,
                    "result": responseData
                ]

                Task { @MainActor in
                    self.sendJSONResponse(response)
                }

            case .failure(let error):
                // 构造错误响应
                let response: [String: Any] = [
                    "jsonrpc": "2.0",
                    "id": requestId,
                    "error": [
                        "code": -1,
                        "message": error.localizedDescription
                    ]
                ]

                Task { @MainActor in
                    self.sendJSONResponse(response)
                }
            }
        }
    }

    @MainActor
    private func sendJSONResponse(_ response: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: response),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize response")
            return
        }

        let script = """
        window.dispatchEvent(new MessageEvent('message', {
            data: \(jsonString)
        }));
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Failed to send response to WebView: \(error)")
            } else {
                print("✅ Response sent to WebView")
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView loaded successfully")
        DispatchQueue.main.async {
            self.isWebViewLoaded = true
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        print("WebView failed to load: \(error)")
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {
    // 处理 alert
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "openNanos"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    // 处理 confirm
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "openNanos"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }
}
