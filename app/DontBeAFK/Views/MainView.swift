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
                        if controller.isLoading || controller.isInstallingCliclick {
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
                
                // Debug info and error display
                VStack(alignment: .leading, spacing: 12) {
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEBUG: isCliclickInstalled = \(controller.isCliclickInstalled ? "true" : "false")")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                        Text("DEBUG: isInstallingCliclick = \(controller.isInstallingCliclick ? "true" : "false")")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                    #endif
                    
                    // Installation error display
                    if let error = controller.installationError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Installation Error")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Debug messages display (only shown when debug mode is enabled)
                    if controller.debugMode && !controller.debugMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Debug Log")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.blue)
                                Spacer()
                                Button("Clear") {
                                    controller.debugMessages = []
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 9))
                                .foregroundColor(.blue)
                            }
                            
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(controller.debugMessages, id: \.self) { msg in
                                        Text(msg)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                // Cliclick Installation Section
                if !controller.isCliclickInstalled {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Setup Required", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("cliclick is not installed")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("This app requires cliclick to automate mouse clicks. Please install it to continue.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button {
                                // Add debug message immediately
                                controller.addDebugMessage("Button clicked!")
                                print("DEBUG: Button clicked - isInstallingCliclick: \(controller.isInstallingCliclick)")
                                print("DEBUG: isCliclickInstalled: \(controller.isCliclickInstalled)")
                                
                                // Force immediate UI update
                                DispatchQueue.main.async {
                                    controller.isInstallingCliclick = true
                                    controller.statusMessage = "Starting installation..."
                                    controller.installationError = nil
                                }
                                
                                // Call the install function
                                controller.installCliclick()
                            } label: {
                                HStack(spacing: 8) {
                                    if controller.isInstallingCliclick {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    Text(controller.isInstallingCliclick ? "Installing..." : "Install cliclick")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(controller.isInstallingCliclick)
                            .opacity(controller.isInstallingCliclick ? 0.5 : 1.0)
                            
                            Text("This will install cliclick using Homebrew. If Homebrew is not installed, you'll need to install it first.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .sectionStyle()
                }
                
                // Accessibility Permissions Section
                if !controller.hasAccessibilityPermission {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Permissions Required", systemImage: "lock.shield")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accessibility permissions are required")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Don't Be AFK needs Accessibility permissions to control your mouse. Without this permission, the mouse will not move to the specified location.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button {
                                controller.requestAccessibilityPermission()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.open.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Open System Settings")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Text("After enabling Accessibility permissions, restart the app or click Start again.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .sectionStyle()
                }
                
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
                                        .onChange(of: controller.xCoord) { _ in
                                            controller.saveConfig()
                                            if controller.debugMode {
                                                controller.addDebugMessage("X coordinate changed to: \(controller.xCoord)")
                                            }
                                        }
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
                                        .onChange(of: controller.yCoord) { _ in
                                            controller.saveConfig()
                                            if controller.debugMode {
                                                controller.addDebugMessage("Y coordinate changed to: \(controller.yCoord)")
                                            }
                                        }
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
                                .onChange(of: controller.interval) { _ in
                                    controller.saveConfig()
                                    if controller.debugMode {
                                        controller.addDebugMessage("Interval changed to: \(controller.interval)")
                                    }
                                }
                            
                            Text("Click frequency (e.g., 15, 30, 60)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Toggle("", isOn: $controller.logToFile)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: controller.logToFile) { _ in
                                controller.saveConfig()
                                if controller.debugMode {
                                    controller.addDebugMessage("Log to file changed to: \(controller.logToFile)")
                                }
                            }
                        
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
                    
                    HStack(spacing: 12) {
                        Toggle("", isOn: $controller.debugMode)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: controller.debugMode) { _ in
                                controller.saveConfig()
                                if controller.debugMode {
                                    controller.addDebugMessage("Debug mode enabled")
                                } else {
                                    controller.addDebugMessage("Debug mode disabled")
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Debug mode")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Show detailed debug logs in UI")
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
                    .disabled(controller.isLoading || controller.xCoord < 0 || controller.yCoord < 0 || !controller.isCliclickInstalled || !controller.hasAccessibilityPermission)
                    .opacity((controller.isLoading || controller.xCoord < 0 || controller.yCoord < 0 || !controller.isCliclickInstalled || !controller.hasAccessibilityPermission) ? 0.5 : 1.0)
                    
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
