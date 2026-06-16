//
//  SettingsComponents.swift
//  DontBeAFK
//
//  Apple System Settings–style form components
//

import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable, Hashable {
    case general
    case clickLocation
    case timing
    case advanced
    case about
    case setup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .clickLocation: "Click Location"
        case .timing: "Timing"
        case .advanced: "Advanced"
        case .about: "About"
        case .setup: "Setup"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .clickLocation: "cursorarrow.click"
        case .timing: "clock"
        case .advanced: "slider.horizontal.3"
        case .about: "info.circle"
        case .setup: "exclamationmark.triangle"
        }
    }

    /// Panes shown in the sidebar under normal conditions.
    static let standardPanes: [SettingsPane] = [.general, .clickLocation, .timing, .advanced, .about]
}

// MARK: - Detail scaffold

struct SettingsDetailScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 20)

                content()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grouped form

struct SettingsForm<Content: View>: View {
    var footer: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Form {
                Section {
                    content()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(maxWidth: .infinity)

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Rows

struct SettingsStatusRow: View {
    let isActive: Bool
    let isLoading: Bool
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Circle()
                    .fill(isActive ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 9, height: 9)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct SettingsActionButton: View {
    let title: String
    let icon: String
    var isLoading: Bool = false
    var role: SettingsActionRole = .primary
    var disabled: Bool = false
    let action: () -> Void

    enum SettingsActionRole {
        case primary
        case destructive
        case secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .controlSize(.large)
        .disabled(disabled || isLoading)
    }

    private var tintColor: Color {
        switch role {
        case .primary: .accentColor
        case .destructive: .red
        case .secondary: .secondary
        }
    }
}

struct SettingsSidebarLabel: View {
    let pane: SettingsPane
    var showsWarning: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Label(pane.title, systemImage: pane.icon)
            if showsWarning {
                Spacer(minLength: 0)
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.orange)
            }
        }
    }
}
