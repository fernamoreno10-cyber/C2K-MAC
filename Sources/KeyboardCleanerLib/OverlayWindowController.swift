import Cocoa
import SwiftUI

@MainActor
class OverlayWindowController {
    private var window: NSWindow?

    func show(state: AppState, onDone: @escaping () -> Void) {
        hide() // close any existing window before showing a new one
        guard let screen = NSScreen.main else { return }

        let hosting = NSHostingController(rootView: OverlayView(state: state, onDone: onDone))

        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .screenSaver
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.isOpaque = true
        win.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        win.contentViewController = hosting
        win.makeKeyAndOrderFront(nil)
        self.window = win
    }

    func hide() {
        window?.close()
        window = nil
    }
}
