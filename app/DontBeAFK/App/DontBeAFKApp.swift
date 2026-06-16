//
//  DontBeAFKApp.swift
//  DontBeAFK
//
//  macOS UI for Don't Be AFK - App entry point
//

import SwiftUI
import AppKit

@main
struct DontBeAFKApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Use @StateObject to properly own and manage the controller lifecycle
    @StateObject private var scriptController = ScriptController()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(scriptController)
        } label: {
            CursorBrandIcon(size: 15, weight: .regular)
                .accessibilityLabel("Don't Be AFK")
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(scriptController)
                .frame(minWidth: 680, idealWidth: 780, maxWidth: .infinity, minHeight: 520, idealHeight: 580, maxHeight: .infinity)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 780, height: 580)
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
        string: AppVersionInfo.productDescription,
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
        .applicationVersion: AppVersionInfo.marketingVersion,
        .version: AppVersionInfo.buildNumber,
        .credits: credits
    ])
}
