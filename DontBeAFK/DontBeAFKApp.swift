//
//  DontBeAFKApp.swift
//  DontBeAFK
//
//  macOS UI for Don't Be AFK
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app can show windows (not just menu bar)
        NSApp.setActivationPolicy(.regular)
        
        // Post notification to trigger window opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: NSNotification.Name("OpenMainWindow"), object: nil)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When app is reopened (e.g., clicking dock icon), show main window
        if !flag {
            NotificationCenter.default.post(name: NSNotification.Name("OpenMainWindow"), object: nil)
        }
        return true
    }
}

@main
struct DontBeAFKApp: App {
    @StateObject private var scriptController = ScriptController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Don't Be AFK", systemImage: "cursorarrow.click") {
            MenuBarView()
                .environmentObject(scriptController)
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(scriptController)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 500, height: 600)
    }
}
