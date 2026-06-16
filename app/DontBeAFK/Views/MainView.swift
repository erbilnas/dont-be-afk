//
//  MainView.swift
//  DontBeAFK
//
//  Main settings window — Apple System Settings layout
//

import SwiftUI
import AppKit

struct MainView: View {
    @EnvironmentObject var controller: ScriptController
    @State private var selectedPane: SettingsPane = .general
    @State private var showingLogs = false

    private var needsSetup: Bool {
        !controller.isCliclickInstalled || !controller.hasAccessibilityPermission
    }

    private var sidebarPanes: [SettingsPane] {
        needsSetup ? [.setup] + SettingsPane.standardPanes : SettingsPane.standardPanes
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 680, idealWidth: 780, maxWidth: .infinity, minHeight: 520, idealHeight: 580, maxHeight: .infinity)
        .liquidGlassWindowBackdrop()
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .sheet(isPresented: $showingLogs) {
            LogView()
                .environmentObject(controller)
        }
        .alert("Error", isPresented: $controller.showError) {
            Button("OK", role: .cancel) {
                controller.errorMessage = nil
            }
        } message: {
            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
            } else {
                Text("An unknown error occurred")
            }
        }
        .onAppear {
            if needsSetup {
                selectedPane = .setup
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                activateWindow()
            }
        }
        .onChange(of: needsSetup) { _, setupRequired in
            if setupRequired {
                selectedPane = .setup
            } else if selectedPane == .setup {
                selectedPane = .general
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsPane)) { notification in
            if let pane = SettingsWindowOpener.pane(from: notification) {
                selectedPane = pane
            }
            activateWindow()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPane) {
            Section {
                ForEach(sidebarPanes) { pane in
                    SettingsSidebarLabel(
                        pane: pane,
                        showsWarning: pane == .setup && needsSetup
                    )
                    .tag(pane)
                }
            } header: {
                HStack(spacing: 10) {
                    CursorBrandIcon(size: 22, weight: .medium)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Don't Be AFK")
                            .font(.headline)
                    }
                }
                .textCase(nil)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPane: some View {
        switch selectedPane {
        case .general:
            GeneralSettingsPane(showingLogs: $showingLogs)
        case .clickLocation:
            ClickLocationSettingsPane()
        case .timing:
            TimingSettingsPane()
        case .advanced:
            AdvancedSettingsPane()
        case .about:
            AboutSettingsPane()
        case .setup:
            SetupSettingsPane()
        }
    }

    // MARK: - Window

    private func activateWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        autoreleasepool {
            for window in NSApplication.shared.windows {
                guard window.frame.width >= 400, window.isVisible else { continue }

                window.title = "Don't Be AFK"
                window.minSize = NSSize(width: 680, height: 520)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isOpaque = false
                window.backgroundColor = .clear
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

/// SF Symbol branding: click variant (macOS 26+ minimum).
struct CursorBrandIcon: View {
    var size: CGFloat
    var weight: Font.Weight = .light

    var body: some View {
        Image(systemName: "cursorarrow.click")
            .font(.system(size: size, weight: weight))
            .foregroundColor(.primary)
            .symbolRenderingMode(.hierarchical)
    }
}
