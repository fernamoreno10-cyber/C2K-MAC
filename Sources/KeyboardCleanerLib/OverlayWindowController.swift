import Cocoa
import SwiftUI

@MainActor
class OverlayWindowController {
    private var window: NSWindow?

    func show(state: AppState, onDone: @escaping () -> Void) {
        hide()
        guard let screen = NSScreen.main else { return }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 140

        // Position: top-center, just below the menu bar
        let x = screen.frame.midX - panelWidth / 2
        let y = screen.visibleFrame.maxY - panelHeight - 12

        let hosting = NSHostingController(rootView: OverlayView(state: state, onDone: onDone))
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear

        let win = NSWindow(
            contentRect: NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.contentViewController = hosting
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }

    func hide() {
        window?.close()
        window = nil
    }
}
