//
//  AppDelegate.swift
//  DontBeAFK
//
//  App delegate for managing application lifecycle
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var hasLaunched = false
    private var windowObserver: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory (no dock icon) - menu bar only
        NSApp.setActivationPolicy(.accessory)
        hasLaunched = true
        
        // Observe window visibility changes to hide/show dock icon
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            // When a main window becomes visible, show in dock
            if self?.isMainAppWindow(window) == true {
                NSApp.setActivationPolicy(.regular)
            }
        }
        
        // Also observe window closing
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            // When main window closes, hide from dock
            if self?.isMainAppWindow(window) == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Check if any main windows are still visible
                    let hasVisibleMainWindow = NSApp.windows.contains { w in
                        self?.isMainAppWindow(w) == true && w.isVisible && w != window
                    }
                    if !hasVisibleMainWindow {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
        }
    }
    
    /// Check if window is a main app window (not menu bar, not panel, not help)
    private func isMainAppWindow(_ window: NSWindow) -> Bool {
        // Exclude menu bar extra windows, panels, and small utility windows
        let isLargeEnough = window.frame.width >= 400 && window.frame.height >= 400
        let isNotPanel = !(window is NSPanel)
        let isNotMenuBarWindow = window.level == .normal
        return isLargeEnough && isNotPanel && isNotMenuBarWindow
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When app is reopened (e.g., clicking dock icon), show main window
        if !flag && hasLaunched {
            showMainWindow()
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up observer
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't terminate when windows are closed - we have a menu bar item
        return false
    }
    
    /// Shows the main window and makes the app visible in the dock
    func showMainWindow() {
        // Show in dock first
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        for window in NSApp.windows {
            if isMainAppWindow(window) {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
}
