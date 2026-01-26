//
//  OverlayView.swift
//  DontBeAFK
//
//  Pure AppKit/CoreAnimation overlay view - avoids SwiftUI observation issues
//

import AppKit
import QuartzCore

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
