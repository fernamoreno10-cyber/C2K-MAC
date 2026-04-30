import Cocoa
import SwiftUI

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem!
    private let appState = AppState.shared
    private let keyboardBlocker = KeyboardBlocker()
    private let overlayController = OverlayWindowController()
    private var settingsWindow: NSWindow?
    private var globalHotkeyMonitor: Any?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(locked: false)
        buildMenu()
        registerGlobalHotkey()
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let cleanItem = NSMenuItem(
            title: "Limpiar teclado",
            action: #selector(startCleaning),
            keyEquivalent: ""
        )
        cleanItem.target = self
        menu.addItem(cleanItem)

        let emergencyItem = NSMenuItem(
            title: "⚡ Emergencia (30 seg)  ⌘⌥K",
            action: #selector(startEmergencyFromMenu),
            keyEquivalent: ""
        )
        emergencyItem.target = self
        menu.addItem(emergencyItem)

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

    // MARK: - Cleaning

    /// Limpieza normal con duración configurada
    @objc private func startCleaning() {
        beginCleaning()
    }

    /// Modo emergencia desde menú
    @objc private func startEmergencyFromMenu() {
        beginCleaning(overrideDuration: 30)
    }

    /// Modo emergencia (llamado desde hotkey o URL scheme)
    func startEmergencyCleaning() {
        beginCleaning(overrideDuration: 30)
    }

    private func beginCleaning(overrideDuration: Int? = nil) {
        guard !appState.isLocked else { return }
        guard keyboardBlocker.start() else { return }

        appState.onUnlock = { [weak self] in
            self?.keyboardBlocker.stop()
            self?.overlayController.hide()
            self?.updateIcon(locked: false)
            NSSound.beep()
        }

        appState.startCleaning(overrideDuration: overrideDuration)
        overlayController.show(state: appState) { [weak self] in
            self?.appState.stopCleaning()
        }
        updateIcon(locked: true)
    }

    // MARK: - Global Hotkey (⌘⌥K)

    private func registerGlobalHotkey() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            // keyCode 40 = 'k' en QWERTY
            guard flags == [.command, .option], event.keyCode == 40 else { return }
            DispatchQueue.main.async {
                self?.startEmergencyCleaning()
            }
        }
    }

    // MARK: - Settings

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
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Icon

    private func updateIcon(locked: Bool) {
        let name = locked ? "lock.fill" : "keyboard"
        statusItem.button?.image = NSImage(
            systemSymbolName: name,
            accessibilityDescription: locked ? "C2K - Limpiando" : "C2K"
        )
    }

    deinit {
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
