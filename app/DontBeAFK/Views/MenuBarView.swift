//
//  MenuBarView.swift
//  DontBeAFK
//
//  Menu bar extra view
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var controller: ScriptController
    @Environment(\.openWindow) var openWindow

    private var needsSetup: Bool {
        !controller.isCliclickInstalled || !controller.hasAccessibilityPermission
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarAppHeader()

            MenuInsetDivider()

            MenuBarStatusCard(
                isRunning: controller.isRunning,
                isLoading: controller.isLoading || controller.isInstallingCliclick,
                title: controller.statusMessage,
                subtitle: statusSubtitle,
                showsSetupWarning: needsSetup
            )

            MenuInsetDivider()

            MenuSectionHeader(title: "Control")
            MenuButton(
                icon: controller.isRunning ? "stop.fill" : "play.fill",
                label: startStopLabel,
                action: toggleRunning,
                isDisabled: !controller.isRunning && !canStart
            )

            MenuInsetDivider()

            MenuSectionHeader(title: "Navigate")
            MenuButton(
                icon: "gearshape",
                label: "Settings…",
                action: { openSettings() },
                shortcut: "⌘,"
            )
            MenuButton(
                icon: "questionmark.circle",
                label: "Help…",
                action: { showHelpWindow() },
                shortcut: "⌘?"
            )
            MenuButton(
                icon: "info.circle",
                label: "About…",
                action: { openAboutPane() },
                showsChevron: true
            )

            MenuInsetDivider()

            MenuSectionHeader(title: "App")
            MenuButton(
                icon: "power",
                label: "Quit",
                action: { NSApplication.shared.terminate(nil) },
                shortcut: "⌘Q",
                isDestructive: true
            )

            MenuInsetDivider()

            MenuSectionHeader(title: "Configuration")
            configurationSection

            MenuInsetDivider()

            MenuBarFooter()
        }
        .frame(width: 280)
        .liquidGlassMenuPanel(cornerRadius: 14, shadow: true)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMainWindow"))) { _ in
            openSettings()
        }
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 0) {
            MenuConfigRow(
                label: "Coordinates",
                value: "(\(controller.xCoord), \(controller.yCoord))"
            )
            MenuConfigRow(
                label: "Interval",
                value: IntervalFormatter.displayString(for: controller.interval)
            )
            MenuConfigRow(
                label: "cliclick",
                value: controller.isCliclickInstalled ? "Installed" : "Missing",
                valueColor: controller.isCliclickInstalled ? .green : .orange
            )
            MenuConfigRow(
                label: "Accessibility",
                value: controller.hasAccessibilityPermission ? "Allowed" : "Required",
                valueColor: controller.hasAccessibilityPermission ? .green : .orange
            )
        }
        .padding(.bottom, 4)
    }

    // MARK: - Actions

    private var startStopLabel: String {
        if controller.isLoading {
            return controller.isRunning ? "Stopping…" : "Starting…"
        }
        return controller.isRunning ? "Stop" : "Start"
    }

    private var statusSubtitle: String? {
        if let pid = controller.pid, controller.isRunning {
            return "Process ID \(pid)"
        }
        return nil
    }

    private var canStart: Bool {
        controller.isCliclickInstalled
            && controller.hasAccessibilityPermission
            && controller.xCoord >= 0
            && controller.yCoord >= 0
    }

    private func toggleRunning() {
        if controller.isRunning {
            controller.stop()
        } else {
            controller.start()
        }
    }

    private func openSettings() {
        SettingsWindowOpener.open(openWindow: openWindow)
    }

    private func openAboutPane() {
        SettingsWindowOpener.open(pane: .about, openWindow: openWindow)
    }
}
