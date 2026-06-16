//
//  SettingsPaneViews.swift
//  DontBeAFK
//
//  Individual settings panes (Apple System Settings layout)
//

import SwiftUI
import AppKit

// MARK: - General

struct GeneralSettingsPane: View {
    @EnvironmentObject var controller: ScriptController
    @Binding var showingLogs: Bool

    var body: some View {
        SettingsDetailScaffold(title: "General") {
            SettingsForm(
                footer: "Don't Be AFK simulates mouse clicks to keep your Mac awake and your status active."
            ) {
                SettingsStatusRow(
                    isActive: controller.isRunning,
                    isLoading: controller.isLoading || controller.isInstallingCliclick,
                    title: controller.statusMessage,
                    subtitle: controller.pid.map { "Process ID \($0)" }
                )
            }

            SettingsForm {
                SettingsActionButton(
                    title: controller.isLoading
                        ? (controller.isRunning ? "Stopping…" : "Starting…")
                        : (controller.isRunning ? "Stop" : "Start"),
                    icon: controller.isRunning ? "stop.fill" : "play.fill",
                    isLoading: controller.isLoading,
                    role: controller.isRunning ? .destructive : .primary,
                    disabled: !canStart
                ) {
                    if controller.isRunning {
                        controller.stop()
                    } else {
                        controller.start()
                    }
                }

                Button("View Logs…") {
                    showingLogs = true
                }
                .frame(maxWidth: .infinity)
            }

            if !canStart && !controller.isRunning {
                validationBanner
            }
        }
    }

    private var canStart: Bool {
        controller.isCliclickInstalled
            && controller.hasAccessibilityPermission
            && controller.xCoord >= 0
            && controller.yCoord >= 0
    }

    @ViewBuilder
    private var validationBanner: some View {
        SettingsForm(footer: "Complete setup and enter valid coordinates before starting.") {
            if !controller.isCliclickInstalled {
                Label("cliclick is not installed", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.orange)
            }
            if !controller.hasAccessibilityPermission {
                Label("Accessibility permission required", systemImage: "lock.shield")
                    .foregroundStyle(.orange)
            }
            if controller.xCoord < 0 || controller.yCoord < 0 {
                Label("Coordinates must be zero or greater", systemImage: "location.slash")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Click Location

struct ClickLocationSettingsPane: View {
    @EnvironmentObject var controller: ScriptController

    var body: some View {
        SettingsDetailScaffold(title: "Click Location") {
            SettingsForm(
                footer: "Choose screen coordinates for automatic clicks. Pick an empty area or corner to avoid clicking apps or buttons."
            ) {
                LabeledContent("X") {
                    TextField("X", value: $controller.xCoord, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: controller.xCoord) { _, _ in
                            controller.saveConfig()
                            logChange("X coordinate changed to: \(controller.xCoord)")
                        }
                }

                LabeledContent("Y") {
                    TextField("Y", value: $controller.yCoord, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: controller.yCoord) { _, _ in
                            controller.saveConfig()
                            logChange("Y coordinate changed to: \(controller.yCoord)")
                        }
                }
            }

            SettingsForm(
                footer: "Current position: (\(controller.xCoord), \(controller.yCoord))"
            ) {
                LabeledContent("Preview") {
                    HStack(spacing: 6) {
                        Image(systemName: "cursorarrow.click")
                            .foregroundStyle(.secondary)
                        Text("(\(controller.xCoord), \(controller.yCoord))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding(.top, 16)
        }
    }

    private func logChange(_ message: String) {
        if controller.debugMode {
            controller.addDebugMessage(message)
        }
    }
}

// MARK: - Timing

struct TimingSettingsPane: View {
    @EnvironmentObject var controller: ScriptController

    private let presets = ["15", "30", "60", "120", "300", "600"]

    var body: some View {
        SettingsDetailScaffold(title: "Timing") {
            SettingsForm(
                footer: "How often the app clicks. Shorter intervals keep your Mac more active; longer intervals use fewer resources."
            ) {
                LabeledContent("Interval") {
                    HStack(spacing: 8) {
                        TextField("seconds", text: $controller.interval)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: controller.interval) { _, _ in
                                controller.saveConfig()
                                if controller.debugMode {
                                    controller.addDebugMessage("Interval changed to: \(controller.interval)")
                                }
                            }
                    }
                }
            }

            SettingsForm(footer: "Quick presets") {
                Picker("Preset", selection: intervalBinding) {
                    ForEach(presets, id: \.self) { preset in
                        Text(IntervalFormatter.compactString(for: preset)).tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            .padding(.top, 16)
        }
    }

    private var intervalBinding: Binding<String> {
        Binding(
            get: {
                presets.contains(controller.interval) ? controller.interval : presets[2]
            },
            set: { newValue in
                controller.interval = newValue
                controller.saveConfig()
                if controller.debugMode {
                    controller.addDebugMessage("Interval changed to: \(newValue)")
                }
            }
        )
    }
}

// MARK: - About

struct AboutSettingsPane: View {
    private let githubURL = URL(string: "https://github.com/erbilnas/dont-be-afk")!

    var body: some View {
        SettingsDetailScaffold(title: "About") {
            VStack(spacing: 16) {
                aboutHero

                SettingsForm {
                    LabeledContent("Version") {
                        Text(AppVersionInfo.marketingVersion)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Build") {
                        Text(AppVersionInfo.buildNumber)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    LabeledContent("Copyright") {
                        Text(AppVersionInfo.copyright)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SettingsForm(footer: AppVersionInfo.productDescription) {
                    Button("About Don't Be AFK…") {
                        showAboutPanel()
                    }
                    .frame(maxWidth: .infinity)

                    Button("View on GitHub") {
                        NSWorkspace.shared.open(githubURL)
                    }
                    .frame(maxWidth: .infinity)

                    Button("Help") {
                        showHelpWindow()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var aboutHero: some View {
        VStack(spacing: 12) {
            Image("BrandLogo")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)

            VStack(spacing: 4) {
                Text("Don't Be AFK")
                    .font(.system(size: 22, weight: .semibold))

                Text(AppVersionInfo.fullVersion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Advanced

struct AdvancedSettingsPane: View {
    @EnvironmentObject var controller: ScriptController

    var body: some View {
        SettingsDetailScaffold(title: "Advanced") {
            SettingsForm(
                footer: "Optional logging and developer diagnostics."
            ) {
                Toggle("Log to File", isOn: $controller.logToFile)
                    .onChange(of: controller.logToFile) { _, _ in
                        controller.saveConfig()
                        if controller.debugMode {
                            controller.addDebugMessage("Log to file changed to: \(controller.logToFile)")
                        }
                    }

                Toggle("Debug Mode", isOn: $controller.debugMode)
                    .onChange(of: controller.debugMode) { _, _ in
                        controller.saveConfig()
                        if controller.debugMode {
                            controller.addDebugMessage("Debug mode enabled")
                        } else {
                            controller.addDebugMessage("Debug mode disabled")
                        }
                    }
            }

            if controller.debugMode && !controller.debugMessages.isEmpty {
                SettingsForm(footer: "Recent debug output from the app.") {
                    HStack {
                        Text("Debug Log")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            controller.debugMessages = []
                        }
                        .buttonStyle(.link)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(controller.debugMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Setup

struct SetupSettingsPane: View {
    @EnvironmentObject var controller: ScriptController

    var body: some View {
        SettingsDetailScaffold(title: "Setup") {
            if !controller.isCliclickInstalled {
                cliclickSection
            }

            if !controller.hasAccessibilityPermission {
                accessibilitySection
                    .padding(.top, controller.isCliclickInstalled ? 0 : 16)
            }

            if let error = controller.installationError {
                SettingsForm {
                    Label {
                        Text(error)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private var cliclickSection: some View {
        SettingsForm(
            footer: "cliclick automates mouse clicks. It will be installed via Homebrew if available."
        ) {
            LabeledContent("cliclick") {
                Text(controller.isCliclickInstalled ? "Installed" : "Not Installed")
                    .foregroundStyle(controller.isCliclickInstalled ? .green : .orange)
            }

            SettingsActionButton(
                title: controller.isInstallingCliclick ? "Installing…" : "Install cliclick",
                icon: "arrow.down.circle.fill",
                isLoading: controller.isInstallingCliclick,
                role: .primary,
                disabled: controller.isInstallingCliclick
            ) {
                controller.addDebugMessage("Install cliclick requested from Settings")
                DispatchQueue.main.async {
                    controller.isInstallingCliclick = true
                    controller.statusMessage = "Starting installation..."
                    controller.installationError = nil
                }
                controller.installCliclick()
            }
        }
    }

    private var accessibilitySection: some View {
        SettingsForm(
            footer: accessibilityFooter
        ) {
            LabeledContent("Accessibility") {
                Text(controller.hasAccessibilityPermission ? "Allowed" : "Required")
                    .foregroundStyle(controller.hasAccessibilityPermission ? .green : .orange)
            }

            if !controller.hasAccessibilityPermission {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable this exact app in the list:")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(controller.accessibilityAppPath)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            SettingsActionButton(
                title: "Request Permission",
                icon: "lock.open.fill",
                role: .primary
            ) {
                controller.requestAccessibilityPermission()
            }
        }
    }

    private var accessibilityFooter: String {
        #if DEBUG
        return """
        Debug builds from Xcode use a new path each time, so permission may not stick. \
        Run ./scripts/build/run-dev.sh for a stable dev install, or click + in System Settings \
        and select the app path above. Permission is rechecked when you return to the app.
        """
        #else
        return "After enabling Accessibility, return to the app or press Start again."
        #endif
    }
}
