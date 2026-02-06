//
//  EventEmitter.swift
//  OpenAria
//
//  事件发射器 - 发送事件到 Web UI
//

import WebKit

class EventEmitter {
    // MARK: - Properties

    private weak var webView: WKWebView?

    // MARK: - Initialization

    init(webView: WKWebView?) {
        self.webView = webView
    }

    // MARK: - Public Methods

    func emit(_ eventName: String, params: Codable) async {
        let notification = RPCNotification(method: eventName, params: params)

        guard let data = try? JSONEncoder().encode(notification),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            print("Failed to encode event: \(eventName)")
            return
        }

        let script = """
        window.dispatchEvent(new CustomEvent('native:\(eventName)', {
            detail: \(jsonString).params
        }));
        """

        await MainActor.run {
            webView?.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Failed to emit event \(eventName): \(error)")
                } else {
                    print("Event emitted: \(eventName)")
                }
            }
        }
    }
}
