//
//  ClickOverlayView.swift
//  DontBeAFK
//
//  Visual overlay showing click location and feedback
//

import SwiftUI
import AppKit
import QuartzCore

/// Manages the overlay window that shows click location feedback.
/// Uses pure AppKit/CoreAnimation to avoid SwiftUI observation issues that can cause crashes.
class OverlayWindowManager {
    // Lazy singleton - only created when first accessed
    static let shared = OverlayWindowManager()
    
    private var overlayWindow: NSWindow?
    private var overlayView: OverlayView?
    private var clickAnimationWorkItem: DispatchWorkItem?
    private var isCleaningUp = false
    
    // Simple properties - no @Published to avoid observation overhead
    private(set) var showOverlayFlag = false
    private(set) var clickX: Int = 500
    private(set) var clickY: Int = 300
    private(set) var isClicking = false
    
    private init() {
        // Empty init - no side effects
    }
    
    deinit {
        // Cancel any pending animations
        clickAnimationWorkItem?.cancel()
        clickAnimationWorkItem = nil
        
        // Only clean up if we're on the main thread
        if Thread.isMainThread {
            cleanupWindowSync()
        }
    }
    
    func showOverlay(at x: Int, y: Int) {
        clickX = x
        clickY = y
        showOverlayFlag = true
        
        // Ensure window creation happens on main thread with a slight delay
        // to avoid interfering with SwiftUI's window management
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.showOverlayFlag else { return }
            self.createOverlayWindow()
        }
    }
    
    func hideOverlay() {
        showOverlayFlag = false
        
        // Cancel any pending animations
        clickAnimationWorkItem?.cancel()
        clickAnimationWorkItem = nil
        
        // Ensure cleanup happens on main thread
        if Thread.isMainThread {
            cleanupWindowSync()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupWindowSync()
            }
        }
    }
    
    func animateClick() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.animateClick()
            }
            return
        }
        
        // Cancel any existing animation
        clickAnimationWorkItem?.cancel()
        
        isClicking = true
        overlayView?.setClicking(true)
        
        // Create work item for animation completion
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isClicking = false
            self.overlayView?.setClicking(false)
        }
        clickAnimationWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    /// Synchronous cleanup that ensures all animations are stopped before window is released
    private func cleanupWindowSync() {
        guard !isCleaningUp else { return }
        isCleaningUp = true
        defer { isCleaningUp = false }
        
        // Cancel any pending animations first
        clickAnimationWorkItem?.cancel()
        clickAnimationWorkItem = nil
        
        guard let window = overlayWindow else {
            overlayView = nil
            return
        }
        
        // Disable all implicit animations during cleanup
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Remove all animations from the view
        overlayView?.layer?.removeAllAnimations()
        
        // Order out window first (hides it without animation)
        window.orderOut(nil)
        
        CATransaction.commit()
        CATransaction.flush()
        
        // Now safely close the window
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        window.contentView = nil
        window.close()
        
        CATransaction.commit()
        
        // Clear references after window is fully closed
        overlayWindow = nil
        overlayView = nil
    }
    
    private func createOverlayWindow() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.createOverlayWindow()
            }
            return
        }
        
        // Don't create if app is not active or terminating
        guard NSApp.isRunning else { return }
        
        // Clean up existing window first
        cleanupWindowSync()
        
        // Get screen bounds
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        // Disable implicit animations during window creation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Create overlay window
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: true  // Use deferred window creation
        )
        
        // Use a lower window level to avoid conflicts with system UI
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.animationBehavior = .none
        
        // Don't show in window menu or expose
        window.isExcludedFromWindowsMenu = true
        
        // Create pure AppKit overlay view (no SwiftUI)
        let view = OverlayView(frame: screenFrame)
        view.setClickLocation(x: clickX, y: clickY)
        overlayView = view
        
        window.contentView = view
        overlayWindow = window
        
        // Show window without animation
        window.orderFront(nil)
        
        CATransaction.commit()
    }
    
    func updateClickLocation(x: Int, y: Int) {
        clickX = x
        clickY = y
        
        if Thread.isMainThread {
            overlayView?.setClickLocation(x: x, y: y)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.overlayView?.setClickLocation(x: x, y: y)
            }
        }
        
        if overlayView == nil && showOverlayFlag {
            createOverlayWindow()
        }
    }
}

/// Pure AppKit/CoreAnimation overlay view - avoids SwiftUI observation issues
class OverlayView: NSView {
    private var markerLayer: CAShapeLayer?
    private var rippleLayer: CAShapeLayer?
    private var clickX: Int = 500
    private var clickY: Int = 300
    private var isClicking: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Create marker layer
        let marker = CAShapeLayer()
        marker.fillColor = NSColor.systemBlue.withAlphaComponent(0.6).cgColor
        marker.strokeColor = NSColor.white.cgColor
        marker.lineWidth = 2
        layer?.addSublayer(marker)
        markerLayer = marker
        
        // Create ripple layer (hidden by default)
        let ripple = CAShapeLayer()
        ripple.fillColor = NSColor.clear.cgColor
        ripple.strokeColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
        ripple.lineWidth = 2
        ripple.opacity = 0
        layer?.addSublayer(ripple)
        rippleLayer = ripple
        
        updateMarkerPosition()
    }
    
    func setClickLocation(x: Int, y: Int) {
        clickX = x
        clickY = y
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateMarkerPosition()
        CATransaction.commit()
    }
    
    func setClicking(_ clicking: Bool) {
        isClicking = clicking
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if clicking {
            // Expand marker and change color
            markerLayer?.fillColor = NSColor.systemRed.withAlphaComponent(0.8).cgColor
            updateMarkerPosition(size: 30)
            
            // Show ripple effect
            rippleLayer?.opacity = 0.5
            updateRipplePosition()
            
            // Animate ripple
            CATransaction.commit()
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 3.0
            scaleAnimation.duration = 0.3
            
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0.5
            opacityAnimation.toValue = 0.0
            opacityAnimation.duration = 0.3
            
            rippleLayer?.add(scaleAnimation, forKey: "scale")
            rippleLayer?.add(opacityAnimation, forKey: "opacity")
        } else {
            // Reset marker
            markerLayer?.fillColor = NSColor.systemBlue.withAlphaComponent(0.6).cgColor
            updateMarkerPosition(size: 20)
            
            // Hide ripple
            rippleLayer?.opacity = 0
            rippleLayer?.removeAllAnimations()
            
            CATransaction.commit()
        }
    }
    
    private func updateMarkerPosition(size: CGFloat = 20) {
        guard let markerLayer = markerLayer else { return }
        
        // Convert screen coordinates (bottom-left origin) to layer coordinates
        let screenHeight = bounds.height
        let viewY = screenHeight - CGFloat(clickY)
        
        let rect = CGRect(
            x: CGFloat(clickX) - size/2,
            y: viewY - size/2,
            width: size,
            height: size
        )
        markerLayer.path = CGPath(ellipseIn: rect, transform: nil)
    }
    
    private func updateRipplePosition() {
        guard let rippleLayer = rippleLayer else { return }
        
        let screenHeight = bounds.height
        let viewY = screenHeight - CGFloat(clickY)
        let size: CGFloat = 20
        
        let rect = CGRect(
            x: CGFloat(clickX) - size/2,
            y: viewY - size/2,
            width: size,
            height: size
        )
        rippleLayer.path = CGPath(ellipseIn: rect, transform: nil)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Make view completely transparent to mouse events
        return nil
    }
}
