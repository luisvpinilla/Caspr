import AppKit
import SwiftUI
import SwiftData

@MainActor
final class MainWindowController {
    static let shared = MainWindowController()

    private var window: NSWindow?
    private var authWindow: NSWindow?
    var modelContainer: ModelContainer?

    private init() {}

    func showWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Caspr"
        window.minSize = NSSize(width: 700, height: 450)
        window.center()
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(DesignTokens.bgApp)
        window.isReleasedWhenClosed = false

        let contentView = MainContentView()
        if let modelContainer {
            window.contentView = NSHostingView(
                rootView: contentView.modelContainer(modelContainer)
            )
        } else {
            window.contentView = NSHostingView(rootView: contentView)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func showAuthWindow() {
        if let authWindow {
            authWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let authWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        authWindow.title = "Caspr — Sign In"
        authWindow.center()
        authWindow.titlebarAppearsTransparent = true
        authWindow.backgroundColor = NSColor(DesignTokens.bgApp)
        authWindow.isReleasedWhenClosed = false

        authWindow.contentView = NSHostingView(rootView: AuthView())

        authWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.authWindow = authWindow
    }
}
