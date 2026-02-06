//
//  OpenNanosApp.swift
//  openNanos
//
//  macOS 应用入口
//

import SwiftUI

@main
struct OpenNanosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
