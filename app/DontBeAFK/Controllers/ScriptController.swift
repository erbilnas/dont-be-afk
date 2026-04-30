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
import ApplicationServices

class ScriptController: ObservableObject {
    @Published var isRunning = false
    @Published var statusMessage = "Not running"
    @Published var xCoord: Int = 500
    @Published var yCoord: Int = 300
    @Published var interval: String = "600"
    @Published var logToFile = false
    @Published var debugMode = false
    @Published var pid: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isCliclickInstalled = true // Assume installed by default, check on startup
    @Published var isInstallingCliclick = false
    @Published var installationError: String? // For UI display
    @Published var debugMessages: [String] = [] // For UI debug display
    @Published var hasAccessibilityPermission = false // Track Accessibility permission status
    private var cliclickPath: String? // Store the path to cliclick when found
    
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
        
        // Add initial debug message (will be shown if debug mode is enabled after config loads)
        addDebugMessage("ScriptController initialized")
        addDebugMessage("App support directory: \(appSupportDir)")
        addDebugMessage("Config file: \(configFile)")
        addDebugMessage("PID file: \(pidFile)")
        addDebugMessage("Log file: \(logFile)")
        
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
        guard FileManager.default.fileExists(atPath: configFile) else {
            addDebugMessage("Config file not found, using defaults")
            return
        }
        
        addDebugMessage("Loading config from: \(configFile)")
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
                } else if trimmedLine.hasPrefix("debug_mode=") {
                    debugMode = trimmedLine.contains("true")
                }
            }
            addDebugMessage("Config loaded: x=\(xCoord), y=\(yCoord), interval=\(interval), logToFile=\(logToFile), debugMode=\(debugMode)")
        } catch {
            addDebugMessage("Error loading config: \(error.localizedDescription)")
            // Silently ignore errors - use default values
        }
    }
    
    private func delayedInit() {
        addDebugMessage("Initializing controller...")
        // Stop any existing processes for a clean slate on app open
        stopExistingProcesses()
        
        // Check Accessibility permissions
        checkAccessibilityPermission()
        
        // Check cliclick installation
        checkCliclickInstallation()
        
        // Check status
        checkStatus()
        
        // Set up timer to periodically check status
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
        RunLoop.main.add(timer, forMode: .default)
        self.statusTimer = timer
        addDebugMessage("Controller initialized, status timer started")
    }
    
    /// Stop any existing processes on app startup for a clean slate
    private func stopExistingProcesses() {
        let pidFilePath = self.pidFile
        addDebugMessage("Checking for existing processes at: \(pidFilePath)")
        
        // Check if PID file exists
        guard FileManager.default.fileExists(atPath: pidFilePath) else {
            addDebugMessage("No existing PID file found")
            return
        }
        
        // Read PID and kill the process if running
        do {
            let pidString = try String(contentsOfFile: pidFilePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let pid = Int(pidString) {
                addDebugMessage("Found existing PID: \(pid)")
                // Check if process is actually running
                let result = kill(pid_t(pid), 0)
                if result == 0 || errno == EPERM {
                    // Process is running, kill it
                    addDebugMessage("Stopping existing process PID: \(pid)")
                    kill(pid_t(pid), SIGTERM)
                } else {
                    addDebugMessage("PID \(pid) is not running")
                }
            }
            // Remove the PID file
            try? FileManager.default.removeItem(atPath: pidFilePath)
            addDebugMessage("Cleaned up PID file")
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
        addDebugMessage("Updating overlay for coordinates: (\(xCoord), \(yCoord))")
        overlayUpdatePending = true
        
        // Debounce overlay updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.isRunning else {
                self?.overlayUpdatePending = false
                return
            }
            self.overlayUpdatePending = false
            OverlayWindowManager.shared.updateClickLocation(x: self.xCoord, y: self.yCoord)
            self.addDebugMessage("Overlay updated")
        }
    }
    
    private func findScriptPath() -> String {
        addDebugMessage("Finding script path...")
        // Find the script path - try multiple locations
        let bundlePath = Bundle.main.bundlePath
        var possiblePaths: [String] = []
        
        addDebugMessage("Bundle path: \(bundlePath)")
        // Bundled CLI (copied via XcodeGen resources from repo cli/)
        if bundlePath.contains(".app") {
            possiblePaths.append("\(bundlePath)/Contents/Resources/cli/bin/dont-be-afk")
            possiblePaths.append("\(bundlePath)/Contents/Resources/bin/dont-be-afk")
            let appDir = (bundlePath as NSString).deletingLastPathComponent
            possiblePaths.append("\(appDir)/bin/dont-be-afk")
            possiblePaths.append("\(appDir)/../bin/dont-be-afk")
        }
        
        // Try relative to current working directory
        let currentDir = FileManager.default.currentDirectoryPath
        addDebugMessage("Current directory: \(currentDir)")
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
            addDebugMessage("Found script via 'which': \(whichPath)")
            possiblePaths.insert(whichPath, at: 0)
        } else {
            addDebugMessage("Script not found in PATH via 'which'")
        }
        
        // Use the first path that exists; prefer bundled CLI path for clearer errors when missing
        let fallbackPath: String
        if bundlePath.contains(".app") {
            fallbackPath = "\(bundlePath)/Contents/Resources/cli/bin/dont-be-afk"
        } else {
            fallbackPath = "/usr/local/bin/dont-be-afk"
        }
        let foundPath = possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? fallbackPath
        addDebugMessage("Using script path: \(foundPath)")
        return foundPath
    }
    
    private func findScriptViaWhich() -> String? {
        addDebugMessage("Running 'which dont-be-afk'...")
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
                    addDebugMessage("'which' found script at: \(path)")
                    return path
                }
            } else {
                addDebugMessage("'which' command exited with code: \(task.terminationStatus)")
            }
        } catch {
            addDebugMessage("Error running 'which': \(error.localizedDescription)")
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
        addDebugMessage("Error: \(message)")
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
            self.statusMessage = "Error: \(message)"
        }
    }
    
    private func validateInputs() -> Bool {
        addDebugMessage("Validating inputs: x=\(xCoord), y=\(yCoord), interval=\(interval)")
        // Validate coordinates
        if xCoord < 0 || yCoord < 0 {
            addDebugMessage("Validation failed: Invalid coordinates")
            showError("Coordinates must be non-negative numbers")
            return false
        }
        
        // Validate interval format (should be a number representing seconds)
        let trimmedInterval = interval.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInterval.isEmpty {
            addDebugMessage("Validation failed: Empty interval")
            showError("Interval cannot be empty")
            return false
        }
        
        // Check if it's a valid number (seconds only)
        if let seconds = Int(trimmedInterval) {
            if seconds < 1 {
                addDebugMessage("Validation failed: Interval too small (\(seconds))")
                showError("Interval must be at least 1 second")
                return false
            }
        } else {
            addDebugMessage("Validation failed: Invalid interval format")
            showError("Invalid interval format. Please enter a number (seconds only, e.g., 300, 600)")
            return false
        }
        
        addDebugMessage("Validation passed")
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
                } else if trimmedLine.hasPrefix("debug_mode=") {
                    debugMode = trimmedLine.contains("true")
                }
            }
        } catch {
            // Silently ignore errors - use default values
        }
    }
    
    func checkStatus() {
        // Don't check status while loading to avoid race conditions
        guard !isLoading else {
            addDebugMessage("Status check skipped: loading in progress")
            return
        }
        
        addDebugMessage("Checking status...")
        // Capture the pidFile path to avoid accessing self in background
        let pidFilePath = self.pidFile
        
        // Check file existence on main thread to avoid threading issues
        let fileExists = FileManager.default.fileExists(atPath: pidFilePath)
        
        guard fileExists else {
            addDebugMessage("PID file not found, process not running")
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
            addDebugMessage("Status check error: \(errorMessage)")
            self.isRunning = false
            if !self.isLoading {
                self.statusMessage = "Error checking status: \(errorMessage)"
            }
            self.pid = nil
        } else if let pidValue = pidValue {
            if isProcessRunning {
                addDebugMessage("Status: Running (PID: \(pidValue))")
                self.isRunning = true
                
                // Check Accessibility permissions periodically
                checkAccessibilityPermission()
                
                // Check logs for permission warnings
                checkLogsForPermissionWarnings()
                
                if !self.isLoading {
                    if !self.hasAccessibilityPermission {
                        self.statusMessage = "Running (PID: \(pidValue)) - ⚠️ Check Accessibility permissions"
                    } else {
                        self.statusMessage = "Running (PID: \(pidValue))"
                    }
                }
                self.pid = pidValue
                // Show overlay when running
                self.showClickOverlay()
                // Start monitoring clicks
                self.startClickMonitoring()
            } else {
                addDebugMessage("Status: Stale PID file (PID: \(pidValue) not running)")
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
            addDebugMessage("Status: Invalid PID file")
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
        addDebugMessage("start() called")
        // Check if cliclick is installed first
        guard isCliclickInstalled else {
            addDebugMessage("Cannot start: cliclick not installed")
            // Don't show error dialog - UI will show install button instead
            return
        }
        
        // Validate inputs first
        guard validateInputs() else {
            return
        }
        
        guard !isRunning else {
            addDebugMessage("Cannot start: Already running")
            showError("Script is already running")
            return
        }
        
        addDebugMessage("Script path: \(scriptPath)")
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            addDebugMessage("Script not found at: \(scriptPath)")
            showError("Script not found at: \(scriptPath)\n\nPlease ensure the script is installed correctly.")
            return
        }
        
        // Check if script is executable
        guard FileManager.default.isExecutableFile(atPath: scriptPath) else {
            addDebugMessage("Script is not executable: \(scriptPath)")
            showError("Script is not executable: \(scriptPath)\n\nPlease run: chmod +x \(scriptPath)")
            return
        }
        
        // Check Accessibility permissions
        checkAccessibilityPermission()
        guard hasAccessibilityPermission else {
            addDebugMessage("Cannot start: Accessibility permissions not granted")
            showError("Accessibility permissions are required for mouse control.\n\nThe mouse will not move to the specified location without this permission.\n\nPlease grant Accessibility permissions:\n1. Click 'Open System Settings' button below\n2. Enable 'Don't Be AFK' in the Accessibility list\n3. Restart the app or click Start again")
            return
        }
        
        addDebugMessage("Starting script with x=\(xCoord), y=\(yCoord), interval=\(interval), logToFile=\(logToFile)")
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
                    self?.addDebugMessage("File logging enabled")
                }
                
                self?.addDebugMessage("Script arguments: \(args.joined(separator: " "))")
                task.arguments = args
                
                // Set up environment with Homebrew PATH if cliclick was found in Homebrew
                var env = ProcessInfo.processInfo.environment
                if let cliclickPath = self?.cliclickPath {
                    // Extract Homebrew prefix from cliclick path
                    if cliclickPath.contains("/opt/homebrew") {
                        env["PATH"] = "/opt/homebrew/bin:\(env["PATH"] ?? "")"
                        self?.addDebugMessage("Setting PATH to include /opt/homebrew/bin")
                    } else if cliclickPath.contains("/usr/local") {
                        env["PATH"] = "/usr/local/bin:\(env["PATH"] ?? "")"
                        self?.addDebugMessage("Setting PATH to include /usr/local/bin")
                    }
                } else {
                    // Try to add both common Homebrew paths just in case
                    let currentPath = env["PATH"] ?? ""
                    if !currentPath.contains("/opt/homebrew/bin") {
                        env["PATH"] = "/opt/homebrew/bin:\(currentPath)"
                    }
                    if !currentPath.contains("/usr/local/bin") {
                        env["PATH"] = "/usr/local/bin:\(env["PATH"] ?? "")"
                    }
                    self?.addDebugMessage("Setting PATH to include common Homebrew locations")
                }
                task.environment = env
                self?.addDebugMessage("Environment PATH: \(env["PATH"] ?? "not set")")
                
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
                    
                    // Check if error is related to cliclick not being installed
                    if fullError.contains("cliclick is not installed") || 
                       fullError.contains("cliclick") && fullError.contains("not installed") {
                        // Update installation status instead of showing error
                        self.isCliclickInstalled = false
                        self.statusMessage = "cliclick is not installed"
                    } else {
                        // Show other errors normally
                        self.showError("Failed to start script:\n\(fullError)")
                    }
                } else {
                    self.addDebugMessage("Waiting for PID file to be created...")
                    // Success - check status after a short delay to allow PID file to be created
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self else { return }
                        
                        self.addDebugMessage("Checking status after start...")
                        self.checkStatus()
                        if self.isRunning {
                            self.addDebugMessage("Start confirmed: Process is running")
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
        addDebugMessage("stop() called")
        guard isRunning else {
            addDebugMessage("Cannot stop: Not running")
            showError("Script is not currently running")
            return
        }
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            addDebugMessage("Cannot stop: Script not found at: \(scriptPath)")
            showError("Script not found at: \(scriptPath)")
            return
        }
        
        addDebugMessage("Stopping script...")
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
                    self?.addDebugMessage("Running stop command...")
                    try task.run()
                    task.waitUntilExit()
                    
                    terminationCode = task.terminationStatus
                    success = (terminationCode == 0)
                    self?.addDebugMessage("Stop command exited with code: \(terminationCode), success: \(success)")
                    
                    if !success {
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let stdoutString = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        errorOutput = !stderrString.isEmpty ? stderrString : stdoutString
                        self?.addDebugMessage("Stop error output: \(errorOutput)")
                    } else {
                        self?.addDebugMessage("Stop command succeeded")
                    }
                } catch {
                    errorOutput = error.localizedDescription
                    self?.addDebugMessage("Exception stopping script: \(error.localizedDescription)")
                }
            }
            
            // Dispatch to main thread with captured values
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if !success {
                    let fullError = !errorOutput.isEmpty ? errorOutput : "Script exited with code \(terminationCode)"
                    self.addDebugMessage("Failed to stop: \(fullError)")
                    self.showError("Failed to stop script:\n\(fullError)")
                } else {
                    self.addDebugMessage("Waiting to verify stop...")
                    // Success - check status after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        guard let self = self else { return }
                        
                        self.checkStatus()
                        if !self.isRunning {
                            self.addDebugMessage("Stop confirmed: Process is not running")
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
    
    /// Check if cliclick is installed
    func checkCliclickInstallation() {
        addDebugMessage("Checking cliclick installation...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var installed = false
            let fileManager = FileManager.default
            
            // First try which command
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            task.arguments = ["cliclick"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            var foundPath: String? = nil
            
            do {
                try task.run()
                task.waitUntilExit()
                
                if task.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !path.isEmpty {
                        foundPath = path
                        installed = true
                        self?.addDebugMessage("cliclick found via 'which' command at: \(path)")
                    }
                }
            } catch {
                self?.addDebugMessage("Error running 'which': \(error.localizedDescription)")
            }
            
            // If not found via which, check common Homebrew locations
            if !installed {
                let homebrewPaths = [
                    "/opt/homebrew/bin/cliclick",
                    "/usr/local/bin/cliclick"
                ]
                
                for path in homebrewPaths {
                    if fileManager.fileExists(atPath: path) {
                        foundPath = path
                        installed = true
                        self?.addDebugMessage("cliclick found at: \(path)")
                        break
                    }
                }
            }
            
            // Verify it's executable if we found it
            var verifiedPath: String? = nil
            if installed {
                if let path = foundPath {
                    // Verify the file we found is executable
                    installed = fileManager.isExecutableFile(atPath: path)
                    if installed {
                        verifiedPath = path
                        self?.addDebugMessage("cliclick verified as executable at: \(path)")
                    } else {
                        self?.addDebugMessage("cliclick found but not executable at: \(path)")
                    }
                } else {
                    // Found via which, use the path we already read
                    verifiedPath = foundPath
                    if let path = foundPath {
                        self?.addDebugMessage("cliclick verified via 'which' command at: \(path)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.isCliclickInstalled = installed
                self?.cliclickPath = verifiedPath
                if installed {
                    self?.statusMessage = "cliclick is installed"
                    if let path = verifiedPath {
                        self?.addDebugMessage("cliclick installation verified at: \(path)")
                    } else {
                        self?.addDebugMessage("cliclick installation verified")
                    }
                } else {
                    self?.statusMessage = "cliclick is not installed"
                    self?.addDebugMessage("cliclick not found in PATH or common locations")
                    self?.addDebugMessage("Checked paths: /opt/homebrew/bin/cliclick, /usr/local/bin/cliclick")
                }
            }
        }
    }
    
    /// Install cliclick via Homebrew
    func installCliclick() {
        let debugMsg = "installCliclick() called - isInstallingCliclick: \(isInstallingCliclick)"
        print("DEBUG: \(debugMsg)")
        addDebugMessage(debugMsg)
        
        guard !isInstallingCliclick else {
            let msg = "Already installing, returning early"
            print("DEBUG: \(msg)")
            addDebugMessage(msg)
            return
        }
        
        // Update UI immediately on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isInstallingCliclick = true
            self.installationError = nil
            self.statusMessage = "Installing cliclick..."
            let msg = "UI updated - isInstallingCliclick: \(self.isInstallingCliclick)"
            print("DEBUG: \(msg)")
            self.addDebugMessage(msg)
        }
        
        // Small delay to ensure UI updates before starting the async work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var success = false
            var errorMessage: String?
            
            autoreleasepool {
                // Find Homebrew installation
                var brewPath: String?
                let fileManager = FileManager.default
                
                // Check common Homebrew locations
                let homebrewPaths = [
                    "/opt/homebrew/bin/brew",
                    "/usr/local/bin/brew"
                ]
                
                self?.addDebugMessage("Checking for Homebrew...")
                print("DEBUG: Checking for Homebrew...")
                
                // First try to find brew in PATH
                let brewCheckTask = Process()
                brewCheckTask.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                brewCheckTask.arguments = ["brew"]
                
                let brewPipe = Pipe()
                brewCheckTask.standardOutput = brewPipe
                brewCheckTask.standardError = Pipe()
                
                do {
                    try brewCheckTask.run()
                    brewCheckTask.waitUntilExit()
                    
                    if brewCheckTask.terminationStatus == 0 {
                        let data = brewPipe.fileHandleForReading.readDataToEndOfFile()
                        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !path.isEmpty {
                            brewPath = path
                            let msg = "Found brew in PATH: \(path)"
                            print("DEBUG: \(msg)")
                            self?.addDebugMessage(msg)
                        }
                    }
                    
                    // If not in PATH, check common locations
                    if brewPath == nil {
                        let msg = "Brew not in PATH, checking common locations..."
                        print("DEBUG: \(msg)")
                        self?.addDebugMessage(msg)
                        for path in homebrewPaths {
                            if fileManager.fileExists(atPath: path) {
                                brewPath = path
                                let msg2 = "Found brew at: \(path)"
                                print("DEBUG: \(msg2)")
                                self?.addDebugMessage(msg2)
                                break
                            }
                        }
                    }
                    
                    if brewPath == nil {
                        let msg = "Homebrew not found"
                        print("DEBUG: \(msg)")
                        self?.addDebugMessage(msg)
                        errorMessage = "Homebrew is not installed. Please install Homebrew first:\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    } else {
                        let msg = "Installing cliclick using brew at: \(brewPath!)"
                        print("DEBUG: \(msg)")
                        self?.addDebugMessage(msg)
                        
                        // Use bash to run brew with proper environment setup
                        let installTask = Process()
                        installTask.executableURL = URL(fileURLWithPath: "/bin/bash")
                        
                        // Determine Homebrew prefix based on path
                        var brewPrefix = "/usr/local"
                        if brewPath!.contains("/opt/homebrew") {
                            brewPrefix = "/opt/homebrew"
                        }
                        
                        let prefixMsg = "Using Homebrew prefix: \(brewPrefix)"
                        print("DEBUG: \(prefixMsg)")
                        self?.addDebugMessage(prefixMsg)
                        
                        // Set up environment for Homebrew
                        var env = ProcessInfo.processInfo.environment
                        env["PATH"] = "\(brewPrefix)/bin:\(env["PATH"] ?? "")"
                        env["HOMEBREW_PREFIX"] = brewPrefix
                        installTask.environment = env
                        
                        // Create a shell command that sources Homebrew environment and installs cliclick
                        let installScript = "eval \"$(\(brewPath!) shellenv)\" && brew install cliclick"
                        
                        let scriptMsg = "Running install script"
                        print("DEBUG: \(scriptMsg): \(installScript)")
                        self?.addDebugMessage(scriptMsg)
                        installTask.arguments = ["-c", installScript]
                        
                        let installPipe = Pipe()
                        let errorPipe = Pipe()
                        installTask.standardOutput = installPipe
                        installTask.standardError = errorPipe
                        
                        try installTask.run()
                        installTask.waitUntilExit()
                        
                        success = (installTask.terminationStatus == 0)
                        let exitMsg = "Install task finished with exit code: \(installTask.terminationStatus), success: \(success)"
                        print("DEBUG: \(exitMsg)")
                        self?.addDebugMessage(exitMsg)
                        
                        if !success {
                            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                            let outputData = installPipe.fileHandleForReading.readDataToEndOfFile()
                            
                            var errorString = ""
                            if let errorStr = String(data: errorData, encoding: .utf8), !errorStr.isEmpty {
                                errorString = errorStr
                                print("DEBUG: Error output: \(errorStr)")
                                self?.addDebugMessage("ERROR: \(errorStr)")
                            }
                            if let outputStr = String(data: outputData, encoding: .utf8), !outputStr.isEmpty {
                                print("DEBUG: Standard output: \(outputStr)")
                                self?.addDebugMessage("OUTPUT: \(outputStr)")
                                if !errorString.isEmpty {
                                    errorString += "\n" + outputStr
                                } else {
                                    errorString = outputStr
                                }
                            }
                            
                            if errorString.isEmpty {
                                errorMessage = "Failed to install cliclick. Exit code: \(installTask.terminationStatus)"
                            } else {
                                errorMessage = errorString
                            }
                        } else {
                            let msg = "Installation successful!"
                            print("DEBUG: \(msg)")
                            self?.addDebugMessage(msg)
                        }
                    }
                } catch {
                    let msg = "Exception caught: \(error.localizedDescription)"
                    print("DEBUG: \(msg)")
                    self?.addDebugMessage("EXCEPTION: \(error.localizedDescription)")
                    errorMessage = "Error running installation: \(error.localizedDescription)"
                }
            }
            
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.isInstallingCliclick = false
                    
                    if success {
                        self.installationError = nil
                        self.addDebugMessage("Installation command completed successfully")
                        // Wait a bit longer and check in common Homebrew locations
                        // Don't set isCliclickInstalled = true yet, let checkCliclickInstallation verify it
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.addDebugMessage("Verifying cliclick installation...")
                            self.checkCliclickInstallation()
                        }
                    } else {
                        self.statusMessage = "Failed to install cliclick"
                        let fullError = errorMessage ?? "Unknown error occurred"
                        self.installationError = fullError
                        self.addDebugMessage("FAILED: \(fullError)")
                        if let errorMessage = errorMessage {
                            self.showError("Failed to install cliclick:\n\(errorMessage)")
                        } else {
                            self.showError("Failed to install cliclick. Please install it manually:\nbrew install cliclick")
                        }
                    }
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
    
    /// Save configuration to file
    func saveConfig() {
        let configContent = """
        x_coord=\(xCoord)
        y_coord=\(yCoord)
        interval=\(interval)
        log_to_file=\(logToFile)
        debug_mode=\(debugMode)
        """
        
        do {
            try configContent.write(toFile: configFile, atomically: true, encoding: .utf8)
            if debugMode {
                addDebugMessage("Config saved: x=\(xCoord), y=\(yCoord), interval=\(interval), logToFile=\(logToFile), debugMode=\(debugMode)")
            }
        } catch {
            if debugMode {
                addDebugMessage("Failed to save config: \(error.localizedDescription)")
            }
        }
    }
    
    /// Check if Accessibility permissions are granted
    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async { [weak self] in
            self?.hasAccessibilityPermission = trusted
            if trusted {
                self?.addDebugMessage("Accessibility permissions: Granted")
            } else {
                self?.addDebugMessage("Accessibility permissions: Not granted")
            }
        }
    }
    
    /// Check logs for permission warnings (cursor not moving)
    private func checkLogsForPermissionWarnings() {
        guard logToFile, FileManager.default.fileExists(atPath: logFile) else {
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let logContent = try String(contentsOfFile: self.logFile, encoding: .utf8)
                let lastLines = logContent.components(separatedBy: .newlines).suffix(10)
                
                // Check for permission warnings
                let hasWarning = lastLines.contains { line in
                    line.contains("WARNING: Cursor did not move") ||
                    line.contains("Check Accessibility permissions") ||
                    line.contains("Accessibility")
                }
                
                if hasWarning && !self.hasAccessibilityPermission {
                    DispatchQueue.main.async {
                        self.addDebugMessage("⚠️ Log shows permission warnings - mouse may not be moving")
                        if self.isRunning && self.statusMessage.contains("Running") && !self.statusMessage.contains("⚠️") {
                            self.statusMessage = "\(self.statusMessage) - ⚠️ Check Accessibility permissions"
                        }
                    }
                }
            } catch {
                // Silently ignore log read errors
            }
        }
    }
    
    /// Request Accessibility permissions (opens System Settings)
    func requestAccessibilityPermission() {
        addDebugMessage("Requesting Accessibility permissions...")
        openAccessibilitySettings()
    }
    
    /// Open System Settings to Accessibility pane
    private func openAccessibilitySettings() {
        addDebugMessage("Opening System Settings → Privacy & Security → Accessibility")
        // For macOS Ventura (13.0+) and later - use new System Settings URL
        if #available(macOS 13.0, *) {
            // Try the new System Settings URL format
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                return
            }
            // Fallback: open System Settings and let user navigate
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
        } else {
            // For macOS Monterey (12.0) and earlier - use System Preferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            } else {
                // Fallback: open System Preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
            }
        }
    }
    
    /// Add debug message to UI (public so view can call it)
    func addDebugMessage(_ message: String) {
        // Always collect debug messages, but only show in UI when debug mode is enabled
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.debugMessages.append("[\(timestamp)] \(message)")
            // Keep only last 100 messages when debug mode is on (more than before)
            if self.debugMode && self.debugMessages.count > 100 {
                self.debugMessages.removeFirst()
            } else if !self.debugMode && self.debugMessages.count > 20 {
                // Keep fewer when debug mode is off
                self.debugMessages.removeFirst()
            }
        }
    }
}
