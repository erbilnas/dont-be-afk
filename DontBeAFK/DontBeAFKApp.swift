//
//  DontBeAFKApp.swift
//  DontBeAFK
//
//  macOS UI for Don't Be AFK
//

import SwiftUI
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

@main
struct DontBeAFKApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Use @StateObject to properly own and manage the controller lifecycle
    @StateObject private var scriptController = ScriptController()
    
    var body: some Scene {
        MenuBarExtra("Don't Be AFK", systemImage: "cursorarrow.click") {
            MenuBarView()
                .environmentObject(scriptController)
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(scriptController)
                .frame(minWidth: 480, idealWidth: 540, maxWidth: .infinity, minHeight: 600, idealHeight: 660, maxHeight: .infinity)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 540, height: 660)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                Button("About Don't Be AFK") {
                    showAboutPanel()
                }
            }
            CommandGroup(replacing: .help) {
                Button("Don't Be AFK Help") {
                    showHelpWindow()
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Getting Started") {
                    showHelpWindow(topic: "getting-started")
                }
                
                Button("Setting Click Location") {
                    showHelpWindow(topic: "click-location")
                }
                
                Button("Configuring Intervals") {
                    showHelpWindow(topic: "intervals")
                }
                
                Button("Troubleshooting") {
                    showHelpWindow(topic: "troubleshooting")
                }
                
                Divider()
                
                Button("Accessibility Permissions") {
                    showHelpWindow(topic: "accessibility")
                }
                
                Button("Visit Website") {
                    if let url = URL(string: "https://github.com/erbilnas/dont-be-afk") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

// Show native macOS About panel with custom credits
func showAboutPanel() {
    NSApp.activate(ignoringOtherApps: true)
    
    let credits = NSAttributedString(
        string: "Keep your Mac awake by simulating mouse clicks at specified intervals.\n\nPerfect for preventing screen sleep during presentations, downloads, or remote sessions.",
        attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.lineSpacing = 4
                return style
            }()
        ]
    )
    
    NSApp.orderFrontStandardAboutPanel(options: [
        .applicationName: "Don't Be AFK",
        .applicationVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        .version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
        .credits: credits
    ])
}

// MARK: - Help Window

private var helpWindowController: NSWindowController?

func showHelpWindow(topic: String? = nil) {
    NSApp.activate(ignoringOtherApps: true)
    
    // Check if help window already exists
    if let existingController = helpWindowController, let window = existingController.window, window.isVisible {
        window.makeKeyAndOrderFront(nil)
        // Update content if topic specified
        if let topic = topic, let contentView = window.contentView as? NSHostingView<HelpContentView> {
            contentView.rootView = HelpContentView(initialTopic: topic)
        }
        return
    }
    
    // Create new help window
    let helpView = HelpContentView(initialTopic: topic)
    let hostingView = NSHostingView(rootView: helpView)
    
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered,
        defer: false
    )
    
    window.title = "Don't Be AFK Help"
    window.contentView = hostingView
    window.center()
    window.minSize = NSSize(width: 500, height: 400)
    window.isReleasedWhenClosed = false
    
    helpWindowController = NSWindowController(window: window)
    helpWindowController?.showWindow(nil)
}

// MARK: - Help Content View

struct HelpContentView: View {
    @State private var selectedTopic: String
    
    init(initialTopic: String? = nil) {
        _selectedTopic = State(initialValue: initialTopic ?? "getting-started")
    }
    
    private let topics: [(id: String, title: String, icon: String)] = [
        ("getting-started", "Getting Started", "play.circle"),
        ("click-location", "Click Location", "location"),
        ("intervals", "Intervals", "clock"),
        ("accessibility", "Accessibility", "lock.shield"),
        ("troubleshooting", "Troubleshooting", "wrench.and.screwdriver")
    ]
    
    var body: some View {
        NavigationSplitView {
            List(topics, id: \.id, selection: $selectedTopic) { topic in
                Label(topic.title, systemImage: topic.icon)
                    .tag(topic.id)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            ScrollView {
                helpContent(for: selectedTopic)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
        }
    }
    
    @ViewBuilder
    private func helpContent(for topic: String) -> some View {
        switch topic {
        case "getting-started":
            gettingStartedContent
        case "click-location":
            clickLocationContent
        case "intervals":
            intervalsContent
        case "accessibility":
            accessibilityContent
        case "troubleshooting":
            troubleshootingContent
        default:
            gettingStartedContent
        }
    }
    
    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Getting Started", icon: "play.circle") {
                Text("Don't Be AFK keeps your Mac active by simulating mouse clicks at regular intervals. This prevents your Mac from going to sleep, showing screensavers, or marking you as \"away\" in communication apps.")
                
                Text("Perfect for:")
                    .font(.headline)
                    .padding(.top, 8)
                
                BulletList(items: [
                    "Long downloads or uploads",
                    "Remote desktop sessions",
                    "Presentations and demos",
                    "Video calls where you're mostly listening",
                    "Keeping your status active in chat apps"
                ])
            }
            
            HelpSection(title: "Quick Start", icon: "bolt") {
                NumberedList(items: [
                    "Set the X and Y coordinates where clicks will occur",
                    "Choose a click interval (15-60 seconds recommended)",
                    "Click \"Start\" to begin",
                    "The app will click at the specified location automatically"
                ])
            }
            
            HelpSection(title: "Menu Bar", icon: "menubar.rectangle") {
                Text("Don't Be AFK runs in your menu bar for easy access. Click the cursor icon to quickly start/stop the app or adjust settings.")
            }
        }
    }
    
    private var clickLocationContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Setting Click Location", icon: "location") {
                Text("The click location determines where on your screen the automatic clicks will occur. Choose a safe location to avoid accidentally clicking on important buttons or links.")
            }
            
            HelpSection(title: "Recommended Locations", icon: "checkmark.circle") {
                BulletList(items: [
                    "Desktop area (when no windows are maximized)",
                    "Empty corner of your screen",
                    "A blank area in a non-critical application",
                    "The menu bar area (clicks won't activate menus)"
                ])
            }
            
            HelpSection(title: "Finding Coordinates", icon: "scope") {
                Text("To find screen coordinates:")
                
                NumberedList(items: [
                    "Open the Screenshot app (Cmd + Shift + 5)",
                    "Move your cursor to the desired location",
                    "Note the coordinates shown in the screenshot toolbar",
                    "Enter these values in Don't Be AFK"
                ])
                
                Text("Tip: Coordinates start from (0, 0) at the top-left corner of your primary display.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            HelpSection(title: "Multi-Monitor Setup", icon: "display.2") {
                Text("If you have multiple monitors, coordinates extend across all displays. The primary display starts at (0, 0), and secondary displays have coordinates relative to their position.")
            }
        }
    }
    
    private var intervalsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Click Intervals", icon: "clock") {
                Text("The interval setting controls how often automatic clicks occur. Choose an interval based on your needs and system requirements.")
            }
            
            HelpSection(title: "Recommended Intervals", icon: "slider.horizontal.3") {
                VStack(alignment: .leading, spacing: 12) {
                    IntervalRecommendation(
                        range: "15-30 seconds",
                        description: "Best for apps that detect idle quickly",
                        useCase: "Chat apps, remote desktop"
                    )
                    
                    IntervalRecommendation(
                        range: "30-60 seconds",
                        description: "Balanced option for most use cases",
                        useCase: "General use, downloads"
                    )
                    
                    IntervalRecommendation(
                        range: "60+ seconds",
                        description: "Minimal activity, power efficient",
                        useCase: "Preventing sleep only"
                    )
                }
            }
            
            HelpSection(title: "System Sleep Settings", icon: "moon") {
                Text("For best results, ensure your interval is shorter than your Mac's sleep timer. Check System Settings > Energy Saver (or Battery) to see your current sleep settings.")
            }
        }
    }
    
    private var accessibilityContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Accessibility Permissions", icon: "lock.shield") {
                Text("Don't Be AFK requires Accessibility permissions to simulate mouse clicks. Without this permission, the app cannot function.")
            }
            
            HelpSection(title: "Granting Permission", icon: "checkmark.shield") {
                NumberedList(items: [
                    "Open System Settings (or System Preferences)",
                    "Go to Privacy & Security > Accessibility",
                    "Click the lock icon to make changes",
                    "Find \"Don't Be AFK\" in the list",
                    "Enable the toggle next to the app",
                    "Restart Don't Be AFK if needed"
                ])
            }
            
            HelpSection(title: "Why This Permission?", icon: "questionmark.circle") {
                Text("macOS requires explicit permission for apps to control your computer. This is a security feature that prevents malicious software from taking control of your Mac.")
                
                Text("Don't Be AFK only uses this permission to simulate clicks at the location you specify. The app does not access any other system features or personal data.")
                    .padding(.top, 8)
            }
            
            HelpSection(title: "Permission Not Working?", icon: "exclamationmark.triangle") {
                BulletList(items: [
                    "Try removing and re-adding the app in Accessibility settings",
                    "Restart the app after granting permission",
                    "Make sure you're granting permission to the correct app",
                    "Check if your organization manages these settings"
                ])
            }
        }
    }
    
    private var troubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Troubleshooting", icon: "wrench.and.screwdriver") {
                Text("Common issues and solutions for Don't Be AFK.")
            }
            
            TroubleshootingItem(
                problem: "Clicks aren't working",
                solutions: [
                    "Verify Accessibility permission is granted",
                    "Check that coordinates are within your screen bounds",
                    "Try restarting the app",
                    "Ensure no other app is blocking input"
                ]
            )
            
            TroubleshootingItem(
                problem: "Mac still goes to sleep",
                solutions: [
                    "Decrease the click interval",
                    "Check System Settings > Energy Saver settings",
                    "Ensure the app is running (check menu bar icon)",
                    "Verify the click location is valid"
                ]
            )
            
            TroubleshootingItem(
                problem: "App won't start",
                solutions: [
                    "Check if another instance is already running",
                    "Try restarting your Mac",
                    "Re-download the app from the official source",
                    "Check Console.app for error messages"
                ]
            )
            
            TroubleshootingItem(
                problem: "High CPU usage",
                solutions: [
                    "Increase the click interval",
                    "Disable logging if enabled",
                    "Check for app updates"
                ]
            )
            
            HelpSection(title: "Still Need Help?", icon: "questionmark.bubble") {
                Text("Visit our GitHub repository for more help, to report bugs, or to request features:")
                
                Link("github.com/erbilnas/dont-be-afk", destination: URL(string: "https://github.com/erbilnas/dont-be-afk")!)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Help View Components

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
            
            content()
                .font(.body)
        }
    }
}

struct BulletList: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                }
            }
        }
    }
}

struct NumberedList: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)
                    Text(item)
                }
            }
        }
    }
}

struct IntervalRecommendation: View {
    let range: String
    let description: String
    let useCase: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(range)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
            Text("Use case: \(useCase)")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TroubleshootingItem: View {
    let problem: String
    let solutions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(problem, systemImage: "exclamationmark.circle")
                .font(.headline)
            
            BulletList(items: solutions)
                .padding(.leading, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(10)
    }
}
