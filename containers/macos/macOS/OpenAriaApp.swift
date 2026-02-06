//
//  OpenAriaApp.swift
//  OpenAria
//
//  macOS 应用入口
//

import SwiftUI

@main
struct OpenAriaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // 初始化代码（如果需要）
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 移除默认的"新建"菜单项
            CommandGroup(replacing: .newItem) { }
        }
    }
}
