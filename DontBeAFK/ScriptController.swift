//
//  ScriptController.swift
//  DontBeAFK
//
//  Controller for interacting with the bash script
//

import Foundation
import Combine
import AppKit
import CoreGraphics
import Darwin

class ScriptController: ObservableObject {
    @Published var isRunning = false
    @Published var statusMessage = "Not running"
    @Published var xCoord: Int = 500
    @Published var yCoord: Int = 300
    @Published var interval: String = "600"
    @Published var logToFile = false
    @Published var pid: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var _scriptPath: String?
    private let configFile: String
    private let pidFile: String
    private let logFile: String
    private var statusTimer: Timer?
    private var clickMonitorTimer: Timer?
    private var lastLogSize: UInt64 = 0
    private var overlayUpdatePending = false
    
    // Lazily compute script path to avoid blocking during init
    private var scriptPath: String {
        if let path = _scriptPath {
            return path
        }
        let path = findScriptPath()
        _scriptPath = path
        return path
    }
    
    // Expose script path for debugging
    var scriptPathForDebugging: String {
        return scriptPath
    }
    
    init() {
        // Use Application Support directory to avoid permission prompts
        // This is the proper location for app data on macOS
        let appSupportDir = Self.getAppSupportDirectory()
        self.configFile = "\(appSupportDir)/config"
        self.pidFile = "\(appSupportDir)/pid"
        self.logFile = "\(appSupportDir)/log"
        
        // Load config synchronously - it's a small file read
        loadConfigSync()
        
        // Schedule delayed initialization on a strong reference
        // Using Timer instead of DispatchQueue to ensure the object stays alive
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.delayedInit()
        }
    }
    
    /// Get or create the Application Support directory for this app
    private static func getAppSupportDirectory() -> String {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("DontBeAFK")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        return appDir.path
    }
    
    private func loadConfigSync() {
        guard FileManager.default.fileExists(atPath: configFile) else { return }
        
        do {
            let content = try String(contentsOfFile: configFile, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("x_coord=") {
                    let valueStr = String(trimmedLine.dropFirst("x_coord=".count))
                    if let x = Int(valueStr) { xCoord = x }
                } else if trimmedLine.hasPrefix("y_coord=") {
                    let valueStr = String(trimmedLine.dropFirst("y_coord=".count))
                    if let y = Int(valueStr) { yCoord = y }
                } else if trimmedLine.hasPrefix("interval=") {
                    let valueStr = String(trimmedLine.dropFirst("interval=".count))
                    if let seconds = Int(valueStr) {
                        interval = String(seconds)
                    }
                } else if trimmedLine.hasPrefix("log_to_file=") {
                    logToFile = trimmedLine.contains("true")
                }
            }
        } catch {
            // Silently ignore errors - use default values
        }
    }
    
    private func delayedInit() {
        // Stop any existing processes for a clean slate on app open
        stopExistingProcesses()
        
        // Check status
        checkStatus()
        
        // Set up timer to periodically check status
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
        RunLoop.main.add(timer, forMode: .default)
        self.statusTimer = timer
    }
    
    /// Stop any existing processes on app startup for a clean slate
    private func stopExistingProcesses() {
        let pidFilePath = self.pidFile
        
        // Check if PID file exists
        guard FileManager.default.fileExists(atPath: pidFilePath) else { return }
        
        // Read PID and kill the process if running
        do {
            let pidString = try String(contentsOfFile: pidFilePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let pid = Int(pidString) {
                // Check if process is actually running
                let result = kill(pid_t(pid), 0)
                if result == 0 || errno == EPERM {
                    // Process is running, kill it
                    kill(pid_t(pid), SIGTERM)
                }
            }
            // Remove the PID file
            try? FileManager.default.removeItem(atPath: pidFilePath)
        } catch {
            // Silently ignore errors - just ensure PID file is removed
            try? FileManager.default.removeItem(atPath: pidFilePath)
        }
        
        // Ensure UI shows not running
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
            self?.statusMessage = "Not running"
            self?.pid = nil
            self?.hideClickOverlay()
            self?.stopClickMonitoring()
        }
    }
    
    /// Call this when coordinates change to update the overlay (if running)
    func updateOverlayIfNeeded() {
        guard isRunning, !overlayUpdatePending else { return }
        overlayUpdatePending = true
        
        // Debounce overlay updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.isRunning else {
                self?.overlayUpdatePending = false
                return
            }
            self.overlayUpdatePending = false
            OverlayWindowManager.shared.updateClickLocation(x: self.xCoord, y: self.yCoord)
        }
    }
    
    private func findScriptPath() -> String {
        // Find the script path - try multiple locations
        let bundlePath = Bundle.main.bundlePath
        var possiblePaths: [String] = []
        
        // If running from Xcode or as app bundle
        if bundlePath.contains(".app") {
            let appDir = (bundlePath as NSString).deletingLastPathComponent
            possiblePaths.append("\(appDir)/bin/dont-be-afk")
            possiblePaths.append("\(appDir)/../bin/dont-be-afk")
        }
        
        // Try relative to current working directory
        let currentDir = FileManager.default.currentDirectoryPath
        possiblePaths.append("\(currentDir)/bin/dont-be-afk")
        possiblePaths.append("\(currentDir)/../bin/dont-be-afk")
        
        // Standard install locations
        possiblePaths.append("/usr/local/bin/dont-be-afk")
        possiblePaths.append("/opt/homebrew/bin/dont-be-afk")
        
        // Try using which to find it - run on background thread to avoid blocking
        // Note: This is called lazily, not during init, so it's safe to do synchronously
        // when the script path is first needed (e.g., when user clicks Start)
        let whichPath = findScriptViaWhich()
        if let whichPath = whichPath {
            possiblePaths.insert(whichPath, at: 0)
        }
        
        // Use the first path that exists
        return possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/local/bin/dont-be-afk"
    }
    
    private func findScriptViaWhich() -> String? {
        // Run 'which' command to find the script in PATH
        // This is safe to call synchronously because it's only called lazily
        // when the user first interacts with start/stop, not during app init
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["dont-be-afk"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Use a new Pipe instead of nullDevice to avoid shared object issues
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Ignore errors - we'll fall back to other paths
        }
        
        return nil
    }
    
    deinit {
        // Only invalidate timer - don't modify any @Published properties in deinit
        // as this can cause crashes with SwiftUI's observation system
        statusTimer?.invalidate()
        clickMonitorTimer?.invalidate()
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
            self.statusMessage = "Error: \(message)"
        }
    }
    
    private func validateInputs() -> Bool {
        // Validate coordinates
        if xCoord < 0 || yCoord < 0 {
            showError("Coordinates must be non-negative numbers")
            return false
        }
        
        // Validate interval format (should be a number representing seconds)
        let trimmedInterval = interval.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInterval.isEmpty {
            showError("Interval cannot be empty")
            return false
        }
        
        // Check if it's a valid number (seconds only)
        if let seconds = Int(trimmedInterval) {
            if seconds < 1 {
                showError("Interval must be at least 1 second")
                return false
            }
        } else {
            showError("Invalid interval format. Please enter a number (seconds only, e.g., 300, 600)")
            return false
        }
        
        return true
    }
    
    func loadConfig() {
        guard FileManager.default.fileExists(atPath: configFile) else { return }
        
        do {
            let content = try String(contentsOfFile: configFile, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("x_coord=") {
                    let valueStr = String(trimmedLine.dropFirst("x_coord=".count))
                    if let x = Int(valueStr) { xCoord = x }
                } else if trimmedLine.hasPrefix("y_coord=") {
                    let valueStr = String(trimmedLine.dropFirst("y_coord=".count))
                    if let y = Int(valueStr) { yCoord = y }
                } else if trimmedLine.hasPrefix("interval=") {
                    let valueStr = String(trimmedLine.dropFirst("interval=".count))
                    if let seconds = Int(valueStr) {
                        interval = String(seconds)
                    }
                } else if trimmedLine.hasPrefix("log_to_file=") {
                    logToFile = trimmedLine.contains("true")
                }
            }
        } catch {
            // Silently ignore errors - use default values
        }
    }
    
    func checkStatus() {
        // Don't check status while loading to avoid race conditions
        guard !isLoading else { return }
        
        // Capture the pidFile path to avoid accessing self in background
        let pidFilePath = self.pidFile
        
        // Check file existence on main thread to avoid threading issues
        let fileExists = FileManager.default.fileExists(atPath: pidFilePath)
        
        guard fileExists else {
            // Update directly on main thread
            self.isRunning = false
            if !self.isLoading {
                self.statusMessage = "Not running"
            }
            self.pid = nil
            return
        }
        
        // Read file content on main thread to avoid complex threading
        // File is small (just a PID), so this is fast
        var pidValue: Int?
        var isProcessRunning = false
        var errorOccurred = false
        var errorMessage = ""
        
        autoreleasepool {
            do {
                let pidString = try String(contentsOfFile: pidFilePath, encoding: .utf8)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let pid = Int(pidString) {
                    pidValue = pid
                    // Check if process is actually running using kill -0
                    let result = kill(pid_t(pid), 0)
                    isProcessRunning = (result == 0 || errno == EPERM)
                }
            } catch {
                errorOccurred = true
                errorMessage = error.localizedDescription
            }
        }
        
        // Update state
        if errorOccurred {
            self.isRunning = false
            if !self.isLoading {
                self.statusMessage = "Error checking status: \(errorMessage)"
            }
            self.pid = nil
        } else if let pidValue = pidValue {
            if isProcessRunning {
                self.isRunning = true
                if !self.isLoading {
                    self.statusMessage = "Running (PID: \(pidValue))"
                }
                self.pid = pidValue
                // Show overlay when running
                self.showClickOverlay()
                // Start monitoring clicks
                self.startClickMonitoring()
            } else {
                self.isRunning = false
                if !self.isLoading {
                    self.statusMessage = "Not running (stale PID file)"
                }
                // Clean up stale PID file
                try? FileManager.default.removeItem(atPath: pidFilePath)
                self.pid = nil
                // Hide overlay when stopped
                self.hideClickOverlay()
                self.stopClickMonitoring()
            }
        } else {
            self.isRunning = false
            if !self.isLoading {
                self.statusMessage = "Invalid PID file"
            }
            self.pid = nil
            // Hide overlay
            self.hideClickOverlay()
            self.stopClickMonitoring()
        }
    }
    
    func start() {
        // Validate inputs first
        guard validateInputs() else {
            return
        }
        
        guard !isRunning else {
            showError("Script is already running")
            return
        }
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            showError("Script not found at: \(scriptPath)\n\nPlease ensure the script is installed correctly.")
            return
        }
        
        // Check if script is executable
        guard FileManager.default.isExecutableFile(atPath: scriptPath) else {
            showError("Script is not executable: \(scriptPath)\n\nPlease run: chmod +x \(scriptPath)")
            return
        }
        
        isLoading = true
        statusMessage = "Starting..."
        
        // Capture values needed for the background task
        let scriptPathCopy = scriptPath
        let xCoordCopy = xCoord
        let yCoordCopy = yCoord
        let intervalCopy = interval.trimmingCharacters(in: .whitespacesAndNewlines)
        let logToFileCopy = logToFile
        let pidFilePath = pidFile
        let logFilePath = logFile
        
        // Run asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Capture results before dispatching to main thread
            var success = false
            var errorOutput = ""
            var terminationCode: Int32 = 0
            
            autoreleasepool {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                
                var args = [
                    scriptPathCopy,
                    "start",
                    "-x", String(xCoordCopy),
                    "-y", String(yCoordCopy),
                    "-i", intervalCopy,
                    "--background"
                ]
                
                if logToFileCopy {
                    args.append("--log")
                }
                
                task.arguments = args
                
                // Capture stdout and stderr
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                let stdinPipe = Pipe()
                task.standardOutput = stdoutPipe
                task.standardError = stderrPipe
                task.standardInput = stdinPipe
                
                // Write "y\n" to stdin before starting to auto-confirm any prompts
                let confirmInput = "y\n"
                if let inputData = confirmInput.data(using: .utf8) {
                    stdinPipe.fileHandleForWriting.write(inputData)
                    try? stdinPipe.fileHandleForWriting.close()
                }
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    terminationCode = task.terminationStatus
                    success = (terminationCode == 0)
                    
                    if !success {
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        errorOutput = !stderrString.isEmpty ? stderrString : stdoutString
                    }
                } catch {
                    errorOutput = error.localizedDescription
                }
            }
            
            // Dispatch to main thread with captured values
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if !success {
                    let fullError = !errorOutput.isEmpty ? errorOutput : "Script exited with code \(terminationCode)"
                    self.showError("Failed to start script:\n\(fullError)")
                } else {
                    // Success - check status after a short delay to allow PID file to be created
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self else { return }
                        
                        self.checkStatus()
                        if self.isRunning {
                            self.statusMessage = "Started successfully"
                            // Show overlay immediately when started
                            self.showClickOverlay()
                            self.startClickMonitoring()
                        } else {
                            // Provide more detailed error information
                            var errorDetails = "Script started but process not found.\n\n"
                            
                            // Check if PID file exists
                            if FileManager.default.fileExists(atPath: pidFilePath) {
                                if let pidContent = try? String(contentsOfFile: pidFilePath).trimmingCharacters(in: .whitespacesAndNewlines),
                                   let pidValue = Int(pidContent) {
                                    errorDetails += "PID file exists with PID: \(pidValue)\n"
                                    errorDetails += "But process is not running.\n\n"
                                } else {
                                    errorDetails += "PID file exists but contains invalid data.\n\n"
                                }
                            } else {
                                errorDetails += "PID file not found at: \(pidFilePath)\n"
                                errorDetails += "The background process may have failed to start.\n\n"
                            }
                            
                            // Check logs if available
                            if FileManager.default.fileExists(atPath: logFilePath) {
                                if let logContent = try? String(contentsOfFile: logFilePath) {
                                    let lastLines = logContent.components(separatedBy: .newlines).suffix(5).joined(separator: "\n")
                                    if !lastLines.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        errorDetails += "Last log entries:\n\(lastLines)"
                                    }
                                }
                            } else {
                                errorDetails += "No log file found. Try enabling logging."
                            }
                            
                            self.showError(errorDetails)
                        }
                    }
                }
            }
        }
    }
    
    func stop() {
        guard isRunning else {
            showError("Script is not currently running")
            return
        }
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            showError("Script not found at: \(scriptPath)")
            return
        }
        
        isLoading = true
        statusMessage = "Stopping..."
        
        // Capture values needed for the background task
        let scriptPathCopy = scriptPath
        
        // Run asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Capture results before dispatching to main thread
            var success = false
            var errorOutput = ""
            var terminationCode: Int32 = 0
            
            autoreleasepool {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.arguments = [scriptPathCopy, "stop"]
                
                // Capture output
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                let stdinPipe = Pipe()
                task.standardOutput = stdoutPipe
                task.standardError = stderrPipe
                task.standardInput = stdinPipe
                
                // Write "y\n" to stdin before starting to auto-confirm any prompts
                let confirmInput = "y\n"
                if let inputData = confirmInput.data(using: .utf8) {
                    stdinPipe.fileHandleForWriting.write(inputData)
                    try? stdinPipe.fileHandleForWriting.close()
                }
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    terminationCode = task.terminationStatus
                    success = (terminationCode == 0)
                    
                    if !success {
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        errorOutput = !stderrString.isEmpty ? stderrString : stdoutString
                    }
                } catch {
                    errorOutput = error.localizedDescription
                }
            }
            
            // Dispatch to main thread with captured values
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if !success {
                    let fullError = !errorOutput.isEmpty ? errorOutput : "Script exited with code \(terminationCode)"
                    self.showError("Failed to stop script:\n\(fullError)")
                } else {
                    // Success - check status after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        guard let self = self else { return }
                        
                        self.checkStatus()
                        if !self.isRunning {
                            self.statusMessage = "Stopped successfully"
                            // Hide overlay when stopped
                            self.hideClickOverlay()
                            self.stopClickMonitoring()
                        }
                    }
                }
            }
        }
    }
    
    private func showClickOverlay() {
        // Overlay feature disabled - it causes app termination due to
        // conflicts with SwiftUI's window management system.
        // The core functionality (auto-clicking) works without the overlay.
    }
    
    private func hideClickOverlay() {
        // Overlay feature disabled
    }
    
    private func startClickMonitoring() {
        // Click monitoring disabled - overlay feature is disabled
    }
    
    private func stopClickMonitoring() {
        clickMonitorTimer?.invalidate()
        clickMonitorTimer = nil
        lastLogSize = 0
    }
    
    private func checkForClicks() {
        // Click monitoring disabled - overlay feature is disabled
    }
    
    func getLogs() -> String {
        guard FileManager.default.fileExists(atPath: logFile) else {
            return "No log file found"
        }
        
        do {
            return try String(contentsOfFile: logFile)
        } catch {
            return "Error reading log: \(error.localizedDescription)"
        }
    }
}
