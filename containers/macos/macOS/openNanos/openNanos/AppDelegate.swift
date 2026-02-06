//
//  AppDelegate.swift
//  openNanos
//
//  应用生命周期管理
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("openNanos launched successfully")

        // 配置主窗口
        if let window = NSApplication.shared.windows.first {
            window.title = "openNanos"
            window.setContentSize(NSSize(width: 1200, height: 800))
            window.center()
            window.minSize = NSSize(width: 800, height: 600)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("openNanos terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
