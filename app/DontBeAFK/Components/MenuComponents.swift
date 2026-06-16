//
//  MenuComponents.swift
//  DontBeAFK
//
//  Reusable components for menu bar view
//

import SwiftUI

private enum MenuMetrics {
    static let horizontalPadding: CGFloat = 16
    static let rowHeight: CGFloat = 30
}

// MARK: - Section chrome

struct MenuSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MenuMetrics.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }
}

struct MenuInsetDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, MenuMetrics.horizontalPadding)
    }
}

// MARK: - Menu button

struct MenuButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var subtitle: String? = nil
    var shortcut: String? = nil
    var isDestructive: Bool = false
    var isDisabled: Bool = false
    var showsChevron: Bool = false

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundStyle(foregroundColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, MenuMetrics.horizontalPadding)
            .frame(minHeight: MenuMetrics.rowHeight, alignment: .center)
            .contentShape(Rectangle())
            .background(isHovered && !isDisabled ? Color.primary.opacity(0.06) : Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var foregroundColor: Color {
        isDestructive ? .red : .primary
    }
}

// MARK: - Header & status

struct MenuBarAppHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            CursorBrandIcon(size: 28, weight: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text("Don't Be AFK")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(AppVersionInfo.shortVersion)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, MenuMetrics.horizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

struct MenuBarStatusCard: View {
    let isRunning: Bool
    let isLoading: Bool
    let title: String
    let subtitle: String?
    let showsSetupWarning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Circle()
                        .fill(isRunning ? Color.green : Color.secondary.opacity(0.45))
                        .frame(width: 9, height: 9)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRunning ? "Running" : "Stopped")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(title)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if showsSetupWarning {
                Label("Setup required", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, MenuMetrics.horizontalPadding)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
        .padding(.horizontal, MenuMetrics.horizontalPadding)
        .padding(.bottom, 4)
    }
}

// MARK: - Configuration rows

struct MenuConfigRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, MenuMetrics.horizontalPadding)
        .frame(minHeight: 24, alignment: .center)
    }
}

// MARK: - Footer

struct MenuBarFooter: View {
    var body: some View {
        Text(AppVersionInfo.fullVersion)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MenuMetrics.horizontalPadding)
            .padding(.vertical, 10)
    }
}

// MARK: - Legacy info row (kept for compatibility)

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text(value)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
        }
    }
}
