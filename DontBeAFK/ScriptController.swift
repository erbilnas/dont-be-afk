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
    
    private let scriptPath: String
    private let configFile = "\(NSHomeDirectory())/.dont-be-afk-config"
    private let pidFile = "\(NSHomeDirectory())/.dont-be-afk.pid"
    private let logFile = "\(NSHomeDirectory())/.dont-be-afk.log"
    
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
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
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
        guard FileManager.default.fileExists(atPath: pidFile) else {
            isRunning = false
            statusMessage = "Not running"
            pid = nil
            return
        }
        
        do {
            let pidString = try String(contentsOfFile: pidFile).trimmingCharacters(in: .whitespacesAndNewlines)
            if let pidValue = Int(pidString) {
                pid = pidValue
                
                // Check if process is actually running
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/ps")
                task.arguments = ["-p", String(pidValue)]
                
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                
                try task.run()
                task.waitUntilExit()
                
                if task.terminationStatus == 0 {
                    isRunning = true
                    statusMessage = "Running (PID: \(pidValue))"
                } else {
                    isRunning = false
                    statusMessage = "Not running (stale PID file)"
                    // Clean up stale PID file
                    try? FileManager.default.removeItem(atPath: pidFile)
                    pid = nil
                }
            }
        } catch {
            isRunning = false
            statusMessage = "Error checking status"
            pid = nil
        }
    }
    
    func start() {
        guard !isRunning else {
            statusMessage = "Already running"
            return
        }
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            statusMessage = "Script not found at: \(scriptPath)"
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        var args = [
            scriptPath,
            "start",
            "-x", String(xCoord),
            "-y", String(yCoord),
            "-i", interval,
            "--background"
        ]
        
        if logToFile {
            args.append("--log")
        }
        
        task.arguments = args
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Update status after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkStatus()
            }
        } catch {
            statusMessage = "Error starting: \(error.localizedDescription)"
        }
    }
    
    func stop() {
        guard isRunning else {
            statusMessage = "Not running"
            return
        }
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            statusMessage = "Script not found at: \(scriptPath)"
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath, "stop"]
        
        do {
            try task.run()
            task.waitUntilExit()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkStatus()
            }
        } catch {
            statusMessage = "Error stopping: \(error.localizedDescription)"
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
