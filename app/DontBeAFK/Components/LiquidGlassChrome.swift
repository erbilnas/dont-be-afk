//
//  LiquidGlassChrome.swift
//  DontBeAFK
//
//  App minimum deployment: macOS 26+. UI uses SwiftUI materials here; native
//  Liquid Glass (`glassEffect`, etc.) can replace these once adopted in-app.
//

import SwiftUI

// MARK: - Panel (menu bar popover, chrome strips)

extension View {
    /// Single-sheet Liquid Glass behind content, clipped to a rounded rect.
    func liquidGlassMenuPanel(cornerRadius: CGFloat = 14, shadow: Bool = true) -> some View {
        modifier(LiquidGlassMenuPanelModifier(cornerRadius: cornerRadius, shadow: shadow))
    }

    /// One full-window Liquid Glass layer (no per-card glass on top — avoids glass-on-glass).
    func liquidGlassWindowBackdrop() -> some View {
        modifier(LiquidGlassWindowBackdropModifier())
    }

    /// Elevated section cards with Liquid Glass.
    func liquidGlassSectionCard(cornerRadius: CGFloat = 10) -> some View {
        modifier(LiquidGlassSectionCardModifier(cornerRadius: cornerRadius))
    }

    /// Log / sheet title strip with Liquid Glass.
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
        content
            .background {
                shape.fill(.ultraThinMaterial)
            }
            .clipShape(shape)
            .shadow(
                color: Color.black.opacity(shadow ? 0.22 : 0),
                radius: shadow ? 20 : 0,
                y: shadow ? 8 : 0
            )
    }
}

// MARK: - Window backdrop

private struct LiquidGlassWindowBackdropModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
    }
}

// MARK: - Section cards

private struct LiquidGlassSectionCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape.fill(.ultraThinMaterial)
            }
            .clipShape(shape)
    }
}

// MARK: - Toolbar strip (logs header, etc.)

private struct LiquidGlassToolbarStripModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
    }
}

// MARK: - Secondary actions (View Logs)

/// Full-width secondary action with a material background (frosted glass look).
struct LiquidGlassSecondaryFullWidthButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
        }
        .buttonStyle(.plain)
    }
}
