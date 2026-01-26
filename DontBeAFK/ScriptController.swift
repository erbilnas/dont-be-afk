//
//  ScriptController.swift
//  DontBeAFK
//
//  Controller for interacting with the bash script
//

import Foundation
import Combine

class ScriptController: ObservableObject {
    @Published var isRunning = false
    @Published var statusMessage = "Not running"
    @Published var xCoord: Int = 500
    @Published var yCoord: Int = 300
    @Published var interval: String = "10m"
    @Published var logToFile = false
    @Published var pid: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let scriptPath: String
    private let configFile = "\(NSHomeDirectory())/.dont-be-afk-config"
    private let pidFile = "\(NSHomeDirectory())/.dont-be-afk.pid"
    private let logFile = "\(NSHomeDirectory())/.dont-be-afk.log"
    private var statusTimer: Timer?
    
    // Expose script path for debugging
    var scriptPathForDebugging: String {
        return scriptPath
    }
    
    init() {
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
        
        // Try using which to find it
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["dont-be-afk"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0,
           let data = try? pipe.fileHandleForReading.readToEnd(),
           let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !path.isEmpty {
            possiblePaths.insert(path, at: 0)
        }
        
        // Use the first path that exists
        scriptPath = possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? possiblePaths.first ?? "/usr/local/bin/dont-be-afk"
        
        // Load configuration
        loadConfig()
        checkStatus()
        
        // Set up timer to periodically check status
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }
    
    deinit {
        statusTimer?.invalidate()
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
        
        // Validate interval format (should be like "10m", "5s", "1h", or just a number)
        let trimmedInterval = interval.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInterval.isEmpty {
            showError("Interval cannot be empty")
            return false
        }
        
        // Check if it's a valid format (number followed by optional s/m/h, or just a number)
        let intervalPattern = #"^\d+[smh]?$"#
        let regex = try? NSRegularExpression(pattern: intervalPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: trimmedInterval.utf16.count)
        if regex?.firstMatch(in: trimmedInterval, options: [], range: range) == nil {
            showError("Invalid interval format. Use formats like: 10m, 5s, 1h, or 600")
            return false
        }
        
        return true
    }
    
    func loadConfig() {
        guard FileManager.default.fileExists(atPath: configFile) else { return }
        
        do {
            let content = try String(contentsOfFile: configFile)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                if line.hasPrefix("x_coord=") {
                    if let value = Int(line.replacingOccurrences(of: "x_coord=", with: "")) {
                        xCoord = value
                    }
                } else if line.hasPrefix("y_coord=") {
                    if let value = Int(line.replacingOccurrences(of: "y_coord=", with: "")) {
                        yCoord = value
                    }
                } else if line.hasPrefix("interval=") {
                    let value = line.replacingOccurrences(of: "interval=", with: "")
                    if let seconds = Int(value) {
                        interval = formatInterval(seconds: seconds)
                    }
                } else if line.hasPrefix("log_to_file=") {
                    logToFile = line.contains("true")
                }
            }
        } catch {
            print("Error loading config: \(error)")
        }
    }
    
    func checkStatus() {
        // Don't check status while loading to avoid race conditions
        guard !isLoading else { return }
        
        guard FileManager.default.fileExists(atPath: pidFile) else {
            DispatchQueue.main.async {
                self.isRunning = false
                if !self.isLoading {
                    self.statusMessage = "Not running"
                }
                self.pid = nil
            }
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let pidString = try String(contentsOfFile: self.pidFile).trimmingCharacters(in: .whitespacesAndNewlines)
                if let pidValue = Int(pidString) {
                    // Check if process is actually running
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/bin/ps")
                    task.arguments = ["-p", String(pidValue)]
                    
                    let pipe = Pipe()
                    task.standardOutput = pipe
                    task.standardError = pipe
                    
                    try task.run()
                    task.waitUntilExit()
                    
                    DispatchQueue.main.async {
                        if task.terminationStatus == 0 {
                            self.isRunning = true
                            if !self.isLoading {
                                self.statusMessage = "Running (PID: \(pidValue))"
                            }
                            self.pid = pidValue
                        } else {
                            self.isRunning = false
                            if !self.isLoading {
                                self.statusMessage = "Not running (stale PID file)"
                            }
                            // Clean up stale PID file
                            try? FileManager.default.removeItem(atPath: self.pidFile)
                            self.pid = nil
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isRunning = false
                        if !self.isLoading {
                            self.statusMessage = "Invalid PID file"
                        }
                        self.pid = nil
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRunning = false
                    if !self.isLoading {
                        self.statusMessage = "Error checking status: \(error.localizedDescription)"
                    }
                    self.pid = nil
                }
            }
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
        
        // Run asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            
            var args = [
                scriptPath,
                "start",
                "-x", String(self.xCoord),
                "-y", String(self.yCoord),
                "-i", self.interval.trimmingCharacters(in: .whitespacesAndNewlines),
                "--background"
            ]
            
            if self.logToFile {
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
            // This handles the coordinate validation warning prompt that appears during script execution
            let confirmInput = "y\n"
            if let inputData = confirmInput.data(using: .utf8) {
                stdinPipe.fileHandleForWriting.write(inputData)
                // Don't close yet - keep it open in case more input is needed
            }
            
            do {
                try task.run()
                
                // Close stdin after a brief delay to ensure the input is processed
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    stdinPipe.fileHandleForWriting.closeFile()
                }
                
                // Read output asynchronously
                let stdoutHandle = stdoutPipe.fileHandleForReading
                let stderrHandle = stderrPipe.fileHandleForReading
                
                var stdoutData = Data()
                var stderrData = Data()
                
                stdoutHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stdoutData.append(data)
                    }
                }
                
                stderrHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stderrData.append(data)
                    }
                }
                
                task.waitUntilExit()
                
                // Stop reading
                stdoutHandle.readabilityHandler = nil
                stderrHandle.readabilityHandler = nil
                
                let terminationStatus = task.terminationStatus
                let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if terminationStatus != 0 {
                        let errorMsg = !stderrString.isEmpty ? stderrString : stdoutString
                        let fullError = !errorMsg.isEmpty ? errorMsg : "Script exited with code \(terminationStatus)"
                        self.showError("Failed to start script:\n\(fullError)")
                    } else {
                        // Success - check status after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.checkStatus()
                            if self.isRunning {
                                self.statusMessage = "Started successfully"
                            } else {
                                self.showError("Script started but process not found. Check logs for details.")
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showError("Failed to start script: \(error.localizedDescription)\n\nError details: \(error)")
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
        
        // Run asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [self.scriptPath, "stop"]
            
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
            }
            
            do {
                try task.run()
                
                // Close stdin after a brief delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    stdinPipe.fileHandleForWriting.closeFile()
                }
                
                let stdoutHandle = stdoutPipe.fileHandleForReading
                let stderrHandle = stderrPipe.fileHandleForReading
                
                var stdoutData = Data()
                var stderrData = Data()
                
                stdoutHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stdoutData.append(data)
                    }
                }
                
                stderrHandle.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stderrData.append(data)
                    }
                }
                
                task.waitUntilExit()
                
                stdoutHandle.readabilityHandler = nil
                stderrHandle.readabilityHandler = nil
                
                let terminationStatus = task.terminationStatus
                let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if terminationStatus != 0 {
                        let errorMsg = !stderrString.isEmpty ? stderrString : stdoutString
                        let fullError = !errorMsg.isEmpty ? errorMsg : "Script exited with code \(terminationStatus)"
                        self.showError("Failed to stop script:\n\(fullError)")
                    } else {
                        // Success - check status after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.checkStatus()
                            if !self.isRunning {
                                self.statusMessage = "Stopped successfully"
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showError("Failed to stop script: \(error.localizedDescription)")
                }
            }
        }
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
    
    // Helper function for interval formatting
    private func formatInterval(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(secs)s"
        }
    }
}
