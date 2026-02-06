//
//  ContentView.swift
//  OpenAria
//
//  主视图 - 包含 WebView
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var webViewController = WebViewController()

    var body: some View {
        ZStack {
            WebViewRepresentable(controller: webViewController)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 连接状态指示器
            if !webViewController.isWebViewLoaded {
                VStack {
                    ProgressView()
                    Text("Loading OpenAria...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            webViewController.loadWebUI()
        }
    }
}

// WebView 包装器
struct WebViewRepresentable: NSViewRepresentable {
    let controller: WebViewController

    func makeNSView(context: Context) -> WKWebView {
        return controller.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 不需要更新
    }
}

#Preview {
    ContentView()
}
