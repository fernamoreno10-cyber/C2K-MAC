import Cocoa
import SwiftUI

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem!
    private let appState = AppState.shared
    private let keyboardBlocker = KeyboardBlocker()
    private let overlayController = OverlayWindowController()
    private var settingsWindow: NSWindow?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(locked: false)
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let cleanItem = NSMenuItem(
            title: "Limpiar teclado",
            action: #selector(startCleaning),
            keyEquivalent: ""
        )
        cleanItem.target = self
        menu.addItem(cleanItem)

        let settingsItem = NSMenuItem(
            title: "Configurar...",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Salir",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    @objc private func startCleaning() {
        guard !appState.isLocked else { return }
        guard keyboardBlocker.start() else { return }

        appState.onUnlock = { [weak self] in
            self?.keyboardBlocker.stop()
            self?.overlayController.hide()
            self?.updateIcon(locked: false)
            NSSound.beep()
        }

        appState.startCleaning()
        overlayController.show(state: appState) { [weak self] in
            self?.appState.stopCleaning()
        }
        updateIcon(locked: true)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView { [weak self] in
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
            }
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 160),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "Configurar"
            panel.contentViewController = NSHostingController(rootView: view)
            panel.center()
            panel.isReleasedWhenClosed = false
            settingsWindow = panel
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateIcon(locked: Bool) {
        let name = locked ? "lock.fill" : "keyboard"
        statusItem.button?.image = NSImage(
            systemSymbolName: name,
            accessibilityDescription: locked ? "Limpiando" : "Keyboard Cleaner"
        )
    }
}
