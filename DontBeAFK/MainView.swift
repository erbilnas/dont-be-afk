//
//  MainView.swift
//  DontBeAFK
//
//  Main window view
//

import SwiftUI
import AppKit

struct MainView: View {
    @EnvironmentObject var controller: ScriptController
    @State private var showingLogs = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cursorarrow.click")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Don't Be AFK")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)
            
            // Status Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Status")
                    .font(.headline)
                
                HStack {
                    if controller.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 12, height: 12)
                    } else {
                        Circle()
                            .fill(controller.isRunning ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(controller.statusMessage)
                        .font(.body)
                }
                
                if let pid = controller.pid {
                    Text("Process ID: \(pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Configuration Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Configuration")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("X Coordinate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("X", value: $controller.xCoord, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Coordinate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Y", value: $controller.yCoord, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interval")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("10m", text: $controller.interval)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                
                Toggle("Log to file", isOn: $controller.logToFile)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Controls
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: {
                        if controller.isRunning {
                            controller.stop()
                        } else {
                            controller.start()
                        }
                    }) {
                        HStack {
                            if controller.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: controller.isRunning ? "stop.fill" : "play.fill")
                            }
                            Text(controller.isLoading ? (controller.isRunning ? "Stopping..." : "Starting...") : (controller.isRunning ? "Stop" : "Start"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(controller.isLoading || controller.xCoord < 0 || controller.yCoord < 0)
                    
                    Button(action: {
                        showingLogs.toggle()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("View Logs")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(controller.isLoading)
                }
                
                // Validation feedback
                if !controller.isLoading && !controller.isRunning && (controller.xCoord < 0 || controller.yCoord < 0) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Please enter valid coordinates (≥ 0)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
            }
                
            
            Spacer()
            
            // Help text
            Text("The script will automatically click at the specified coordinates to prevent your Mac from going idle.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .padding()
        .frame(width: 500, height: 600)
        .sheet(isPresented: $showingLogs) {
            LogView()
                .environmentObject(controller)
        }
        .alert("Error", isPresented: $controller.showError) {
            Button("OK", role: .cancel) {
                controller.errorMessage = nil
            }
        } message: {
            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
            } else {
                Text("An unknown error occurred")
            }
        }
        .onAppear {
            activateWindow()
        }
    }
    
    private func activateWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.frame.width >= 400 }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct LogView: View {
    @EnvironmentObject var controller: ScriptController
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                Text(controller.getLogs())
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 600, height: 400)
    }
}
