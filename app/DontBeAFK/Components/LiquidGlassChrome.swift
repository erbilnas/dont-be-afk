//
//  LiquidGlassChrome.swift
//  DontBeAFK
//
//  Liquid Glass (macOS 26+) with vibrancy fallback for older systems.
//

import SwiftUI

// MARK: - Panel (menu bar popover, chrome strips)

extension View {
    /// Single-sheet glass or thin material behind content, clipped to a rounded rect.
    func liquidGlassMenuPanel(cornerRadius: CGFloat = 14, shadow: Bool = true) -> some View {
        modifier(LiquidGlassMenuPanelModifier(cornerRadius: cornerRadius, shadow: shadow))
    }

    /// One full-window blur layer (no per-card glass on top — avoids glass-on-glass).
    func liquidGlassWindowBackdrop() -> some View {
        modifier(LiquidGlassWindowBackdropModifier())
    }

    /// Elevated section cards: glass on Tahoe+, material + stroke on older macOS.
    func liquidGlassSectionCard(cornerRadius: CGFloat = 10) -> some View {
        modifier(LiquidGlassSectionCardModifier(cornerRadius: cornerRadius))
    }

    /// Log / sheet title strip: material bar with subtle separator feel.
    func liquidGlassToolbarStrip() -> some View {
        modifier(LiquidGlassToolbarStripModifier())
    }
}

// MARK: - Menu panel

private struct LiquidGlassMenuPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Group {
            #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(.regular, in: shape)
            } else {
                menuPanelFallback(content: content, shape: shape)
            }
            #else
            menuPanelFallback(content: content, shape: shape)
            #endif
        }
    }

    @ViewBuilder
    private func menuPanelFallback(content: Content, shape: RoundedRectangle) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(.thinMaterial)
                    shape.strokeBorder(Color.primary.opacity(0.11), lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(shadow ? 0.22 : 0),
                    radius: shadow ? 20 : 0,
                    y: shadow ? 8 : 0
                )
            }
            .clipShape(shape)
    }
}

// MARK: - Window backdrop

private struct LiquidGlassWindowBackdropModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.thinMaterial)
                    .ignoresSafeArea()
            }
    }
}

// MARK: - Section cards

private struct LiquidGlassSectionCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Group {
            #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(.regular, in: shape)
            } else {
                sectionCardFallback(content: content, shape: shape)
            }
            #else
            sectionCardFallback(content: content, shape: shape)
            #endif
        }
    }

    @ViewBuilder
    private func sectionCardFallback(content: Content, shape: RoundedRectangle) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(.regularMaterial)
                    shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
            }
    }
}

// MARK: - Toolbar strip (logs header, etc.)

private struct LiquidGlassToolbarStripModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.thinMaterial)
            }
    }
}

// MARK: - Secondary actions (View Logs)

/// Applies `.glass` on macOS 26+ when built with a new enough Swift toolchain; otherwise keeps material fill.
struct LiquidGlassSecondaryFullWidthButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Group {
            #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                Button(action: action) {
                    label()
                        .foregroundColor(.primary)
                }
                .buttonStyle(.glass)
            } else {
                legacyMaterialButton
            }
            #else
            legacyMaterialButton
            #endif
        }
    }

    private var legacyMaterialButton: some View {
        Button(action: action) {
            label()
                .background(.regularMaterial)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
