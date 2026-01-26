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
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "cursorarrow.click")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.primary)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 4) {
                        Text("Don't Be AFK")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Keep your Mac active automatically")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                
                // Status Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Status", systemImage: "circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 12) {
                        if controller.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Circle()
                                .fill(controller.isRunning ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(controller.statusMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if let pid = controller.pid {
                                Text("Process ID: \(pid)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .sectionStyle()
                
                // Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Configuration", systemImage: "gearshape")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Coordinates
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Click Location")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("X")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                    TextField("X", value: $controller.xCoord, format: .number)
                                        .textFieldStyle(.plain)
                                        .padding(10)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(6)
                                        .font(.system(size: 13))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Y")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                    TextField("Y", value: $controller.yCoord, format: .number)
                                        .textFieldStyle(.plain)
                                        .padding(10)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(6)
                                        .font(.system(size: 13))
                                }
                            }
                            
                            Text("Screen coordinates for automatic click")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Interval
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Interval")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("(seconds)")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("Seconds", text: $controller.interval)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .font(.system(size: 13))
                            
                            Text("Click frequency (e.g., 15, 30, 60)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Toggle("", isOn: $controller.logToFile)
                            .toggleStyle(.switch)
                            .labelsHidden()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Log to file")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Save activity logs to disk")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .sectionStyle()
                
                // Controls
                VStack(spacing: 12) {
                    Button(action: {
                        if controller.isRunning {
                            controller.stop()
                        } else {
                            controller.start()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if controller.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: controller.isRunning ? "stop.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text(controller.isLoading ? (controller.isRunning ? "Stopping..." : "Starting...") : (controller.isRunning ? "Stop" : "Start"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(controller.isRunning ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(controller.isLoading || controller.xCoord < 0 || controller.yCoord < 0)
                    .opacity((controller.isLoading || controller.xCoord < 0 || controller.yCoord < 0) ? 0.5 : 1.0)
                    
                    Button(action: {
                        showingLogs.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12, weight: .medium))
                            Text("View Logs")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(controller.isLoading)
                    .opacity(controller.isLoading ? 0.5 : 1.0)
                    
                    // Validation feedback
                    if !controller.isLoading && !controller.isRunning && (controller.xCoord < 0 || controller.yCoord < 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("Please enter valid coordinates (≥ 0)")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Help text
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("How to use:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Set coordinates: Enter X and Y screen coordinates where automatic clicks will occur. Choose a safe spot like an empty area or corner to avoid accidental clicks on applications.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Choose interval: Recommended 15-60 seconds. Shorter intervals keep your Mac more active but use more resources. Longer intervals are more efficient but may allow brief idle periods.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text("Tip: The app will automatically click at the specified coordinates to prevent your Mac from going idle.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40)
            }
            .padding(32)
            .frame(minWidth: 480, idealWidth: 520, maxWidth: .infinity)
        }
        .frame(minWidth: 480, idealWidth: 520, maxWidth: .infinity, minHeight: 600, idealHeight: 660, maxHeight: .infinity)
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
            // Delay window activation to avoid issues during view setup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                activateWindow()
            }
        }
    }
    
    private func activateWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and configure the main window safely
        // Use autoreleasepool to ensure proper memory management
        autoreleasepool {
            for window in NSApplication.shared.windows {
                // Only process windows that look like our main window
                guard window.frame.width >= 400, window.isVisible else { continue }
                
                window.title = "Don't Be AFK"
                window.minSize = NSSize(width: 480, height: 600)
                window.makeKeyAndOrderFront(nil)
                break // Only configure the first matching window
            }
        }
    }
}
