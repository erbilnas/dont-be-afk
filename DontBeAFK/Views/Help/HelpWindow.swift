//
//  HelpWindow.swift
//  DontBeAFK
//
//  Help window creation and management
//

import SwiftUI
import AppKit

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
