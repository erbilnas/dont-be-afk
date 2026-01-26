//
//  MenuBarView.swift
//  DontBeAFK
//
//  Menu bar extra view
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var controller: ScriptController
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status Header
            HStack(spacing: 10) {
                Circle()
                    .fill(controller.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(controller.isRunning ? "Running" : "Stopped")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(controller.statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Quick actions
            VStack(spacing: 0) {
                MenuButton(
                    icon: controller.isRunning ? "stop.fill" : "play.fill",
                    label: controller.isRunning ? "Stop" : "Start",
                    action: {
                        if controller.isRunning {
                            controller.stop()
                        } else {
                            controller.start()
                        }
                    }
                )
                
                MenuButton(
                    icon: "gearshape",
                    label: "Open Settings",
                    action: {
                        openOrActivateMainWindow()
                    }
                )
                
                MenuButton(
                    icon: "info.circle",
                    label: "About",
                    action: {
                        showAboutPanel()
                    }
                )
                
                MenuButton(
                    icon: "power",
                    label: "Quit",
                    action: {
                        NSApplication.shared.terminate(nil)
                    },
                    isDestructive: true
                )
            }
            
            Divider()
            
            // Current settings
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "location",
                    label: "COORDINATES",
                    value: "(\(controller.xCoord), \(controller.yCoord))"
                )
                
                InfoRow(
                    icon: "clock",
                    label: "INTERVAL",
                    value: controller.interval
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 240)
        .background(.regularMaterial)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
            openOrActivateMainWindow()
        }
    }
    
    private func openOrActivateMainWindow() {
        // Use autoreleasepool to ensure proper memory management
        autoreleasepool {
            // Find existing main window
            var foundWindow: NSWindow?
            for window in NSApplication.shared.windows {
                if window.frame.width >= 400 && window.frame.height >= 400 && window.isVisible {
                    foundWindow = window
                    break
                }
            }
            
            if let existingWindow = foundWindow {
                // Window exists, bring it to front
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                existingWindow.makeKeyAndOrderFront(nil)
            } else {
                // No window exists, open a new one
                openWindow(id: "main")
                activateApp()
            }
        }
    }
    
    private func activateApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            autoreleasepool {
                for window in NSApplication.shared.windows {
                    if window.frame.width >= 400 && window.frame.height >= 400 && window.isVisible {
                        window.makeKeyAndOrderFront(nil)
                        break
                    }
                }
            }
        }
    }
}

// Apple-style menu button
struct MenuButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 18)
                
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Info row for displaying settings
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
        }
    }
}
