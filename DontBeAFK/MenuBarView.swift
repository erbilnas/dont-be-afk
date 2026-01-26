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
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                Circle()
                    .fill(controller.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(controller.isRunning ? "Running" : "Stopped")
                    .font(.headline)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            // Quick actions
            Button(action: {
                if controller.isRunning {
                    controller.stop()
                } else {
                    controller.start()
                }
            }) {
                HStack {
                    Image(systemName: controller.isRunning ? "stop.fill" : "play.fill")
                    Text(controller.isRunning ? "Stop" : "Start")
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Button(action: {
                openWindow(id: "main")
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Divider()
            
            // Current settings
            VStack(alignment: .leading, spacing: 4) {
                Text("Coordinates: (\(controller.xCoord), \(controller.yCoord))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Interval: \(controller.interval)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 200)
        .padding(.vertical, 8)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
            openWindow(id: "main")
            activateApp()
        }
    }
    
    private func activateApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApplication.shared.windows where window.frame.width >= 400 && window.frame.height >= 400 {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
