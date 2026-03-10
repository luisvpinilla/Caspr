import SwiftUI
import SwiftData
import KeyboardShortcuts
import Combine

// MARK: - Global Hotkey

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.r, modifiers: [.option, .command]))
}

// MARK: - App Entry Point

@main
struct CasprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var observationTask: Task<Void, Never>?

    let modelContainer: ModelContainer = {
        let schema = Schema([Recording.self, Transcript.self, Summary.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupKeyboardShortcut()
        observeRecordingState()
        MainWindowController.shared.modelContainer = modelContainer

        // Show main window + Dock icon on launch
        showMainWindow()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Caspr")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .modelContainer(modelContainer)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Main Window + Dock Icon

    func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        MainWindowController.shared.showWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Clicking Dock icon re-opens the main window
        if !flag {
            showMainWindow()
        }
        return true
    }

    // MARK: - Keyboard Shortcut

    private func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) {
            Task { @MainActor in
                let recorder = AudioCaptureService.shared
                if recorder.isRecording {
                    recorder.stop()
                } else {
                    recorder.start()
                }
            }
        }
    }

    // MARK: - Recording State Observation

    private func observeRecordingState() {
        observationTask = Task { @MainActor [weak self] in
            let recorder = AudioCaptureService.shared
            var previousState = false

            for await isRecording in recorder.$isRecording.values {
                guard let self else { return }

                self.updateMenuBarIcon(isRecording: isRecording)

                if isRecording && !previousState {
                    GhostModeService.shared.showPanel()
                } else if !isRecording && previousState {
                    GhostModeService.shared.hidePanel()
                }

                previousState = isRecording
            }
        }
    }

    private func updateMenuBarIcon(isRecording: Bool) {
        guard let button = statusItem.button else { return }
        if isRecording {
            button.image = NSImage(
                systemSymbolName: "waveform.badge.mic",
                accessibilityDescription: "Caspr — Recording"
            )
            button.contentTintColor = NSColor(DesignTokens.ledRecording)
        } else {
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "Caspr"
            )
            button.contentTintColor = nil
        }
    }
}
