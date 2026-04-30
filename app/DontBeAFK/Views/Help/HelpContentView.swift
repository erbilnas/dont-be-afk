//
//  HelpContentView.swift
//  DontBeAFK
//
//  Help content view with all topic sections
//

import SwiftUI

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
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassWindowBackdrop()
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
